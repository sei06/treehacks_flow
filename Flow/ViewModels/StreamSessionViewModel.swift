/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// StreamSessionViewModel.swift
//
// Core view model for the SoundTrack app. Manages the full pipeline:
// glasses camera → Gemini analysis → Suno music generation → AVPlayer streaming.
//

import AVFoundation
import MWDATCamera
import MWDATCore
import SwiftUI

enum StreamingStatus {
  case streaming
  case waiting
  case stopped
}

@MainActor
class StreamSessionViewModel: ObservableObject {
  @Published var currentVideoFrame: UIImage?
  @Published var hasReceivedFirstFrame: Bool = false
  @Published var streamingStatus: StreamingStatus = .stopped
  @Published var showError: Bool = false
  @Published var errorMessage: String = ""
  @Published var hasActiveDevice: Bool = false

  var isStreaming: Bool {
    streamingStatus != .stopped
  }

  var isSessionReady: Bool {
    streamingStatus == .streaming
  }

  // Music therapy result from Gemini
  @Published var therapyResponse: MusicTherapyResponse?
  @Published var therapyError: String?
  @Published var capturedFrame: UIImage?

  // Music generation pipeline
  @Published var musicPhase: MusicPhase = .idle
  @Published var isAudioPlaying: Bool = false
  @Published var makeInstrumental: Bool = true
  @Published var stressLevel: StressLevel = .high

  // AVPlayer for streaming audio
  private var audioPlayer: AVPlayer?
  private var playerStatusObservation: NSKeyValueObservation?
  private var pollingTask: Task<Void, Never>?

  // The core DAT SDK StreamSession
  private var streamSession: StreamSession
  private var stateListenerToken: AnyListenerToken?
  private var videoFrameListenerToken: AnyListenerToken?
  private var errorListenerToken: AnyListenerToken?
  private let wearables: WearablesInterface
  private let deviceSelector: AutoDeviceSelector
  private var deviceMonitorTask: Task<Void, Never>?

  init(wearables: WearablesInterface) {
    self.wearables = wearables
    self.deviceSelector = AutoDeviceSelector(wearables: wearables)
    let config = StreamSessionConfig(
      videoCodec: VideoCodec.raw,
      resolution: StreamingResolution.low,
      frameRate: 2)
    streamSession = StreamSession(streamSessionConfig: config, deviceSelector: deviceSelector)

    // Monitor device availability — auto-start session when a device connects
    deviceMonitorTask = Task { @MainActor in
      for await device in deviceSelector.activeDeviceStream() {
        let deviceAvailable = device != nil
        self.hasActiveDevice = deviceAvailable
        if deviceAvailable && self.streamingStatus == .stopped {
          self.startBackgroundSession()
        }
      }
    }

    stateListenerToken = streamSession.statePublisher.listen { [weak self] state in
      Task { @MainActor [weak self] in
        self?.updateStatusFromState(state)
      }
    }

    videoFrameListenerToken = streamSession.videoFramePublisher.listen { [weak self] videoFrame in
      Task { @MainActor [weak self] in
        guard let self else { return }
        if let image = videoFrame.makeUIImage() {
          self.currentVideoFrame = image
          if !self.hasReceivedFirstFrame {
            self.hasReceivedFirstFrame = true
          }
        }
      }
    }

    errorListenerToken = streamSession.errorPublisher.listen { [weak self] error in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let newErrorMessage = self.formatStreamingError(error)
        if newErrorMessage != self.errorMessage {
          self.showError(newErrorMessage)
        }
      }
    }

    updateStatusFromState(streamSession.state)
  }

  // MARK: - Background Session

  func startBackgroundSession() {
    guard streamingStatus == .stopped else { return }
    Task {
      let permission = Permission.camera
      do {
        let status = try await wearables.checkPermissionStatus(permission)
        if status != .granted {
          let requestStatus = try await wearables.requestPermission(permission)
          if requestStatus != .granted {
            self.showError("Permission denied")
            return
          }
        }
        await streamSession.start()
      } catch {
        self.showError("Permission error: \(error.localizedDescription)")
      }
    }
  }

  func stopSession() async {
    await streamSession.stop()
  }

  // MARK: - Music Generation Pipeline

  func generateSoundtrack() {
    // Allow starting from idle, failed, or complete states
    switch musicPhase {
    case .idle, .failed, .complete: break
    default: return
    }
    guard let frame = currentVideoFrame else { return }

    therapyResponse = nil
    therapyError = nil
    capturedFrame = frame
    stopPlayback()
    musicPhase = .analyzingScene

    Task {
      do {
        // Step 1: Gemini analysis
        let response = try await GeminiService.generateMusicTherapy(frame, instrumental: self.makeInstrumental, stressLevel: self.stressLevel)
        self.therapyResponse = response

        // Step 2: Suno generation
        self.musicPhase = .generatingMusic
        let clipId = try await SunoService.generate(
          topic: response.sunoPrompt,
          tags: response.sunoTags,
          makeInstrumental: self.makeInstrumental
        )

        // Step 3: Begin polling
        self.musicPhase = .waitingForStream(clipId: clipId)
        self.startPolling(clipId: clipId)

      } catch {
        self.therapyError = error.localizedDescription
        self.musicPhase = .failed(error.localizedDescription)
      }
    }
  }

  // MARK: - Polling

  private func startPolling(clipId: String) {
    pollingTask?.cancel()
    pollingTask = Task {
      var attempts = 0
      let maxAttempts = 60  // 5 minutes max

      while !Task.isCancelled && attempts < maxAttempts {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        guard !Task.isCancelled else { return }

        do {
          let clip = try await SunoService.fetchClip(id: clipId)

          switch clip.status {
          case "streaming":
            if case .waitingForStream = self.musicPhase {
              self.musicPhase = .streaming(clipId: clipId, clip: clip)
              if let urlString = clip.audioUrl, let url = URL(string: urlString) {
                self.startPlayback(url: url)
              }
            } else {
              self.musicPhase = .streaming(clipId: clipId, clip: clip)
            }

          case "complete":
            self.musicPhase = .complete(clip: clip)
            return

          case "error":
            self.musicPhase = .failed("Music generation failed.")
            return

          default:
            break
          }
        } catch {
          // Transient poll failure — continue
        }

        attempts += 1
      }

      if attempts >= maxAttempts && !Task.isCancelled {
        self.musicPhase = .failed("Music generation timed out.")
      }
    }
  }

  // MARK: - Audio Playback

  func startPlayback(url: URL) {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Audio session error: \(error)")
    }

    let playerItem = AVPlayerItem(url: url)
    audioPlayer = AVPlayer(playerItem: playerItem)
    audioPlayer?.play()
    isAudioPlaying = true

    playerStatusObservation = playerItem.observe(\.status, options: [.new]) {
      [weak self] item, _ in
      Task { @MainActor [weak self] in
        if item.status == .failed {
          self?.isAudioPlaying = false
        }
      }
    }
  }

  func togglePlayback() {
    guard let player = audioPlayer else { return }
    if isAudioPlaying {
      player.pause()
    } else {
      player.play()
    }
    isAudioPlaying.toggle()
  }

  func stopPlayback() {
    pollingTask?.cancel()
    pollingTask = nil
    audioPlayer?.pause()
    audioPlayer = nil
    playerStatusObservation = nil
    isAudioPlaying = false
  }

  func dismissMusic() {
    stopPlayback()
    musicPhase = .idle
    therapyResponse = nil
    therapyError = nil
    capturedFrame = nil
  }

  // MARK: - Error Handling

  func dismissError() {
    showError = false
    errorMessage = ""
  }

  private func showError(_ message: String) {
    errorMessage = message
    showError = true
  }

  // MARK: - DAT SDK State

  private func updateStatusFromState(_ state: StreamSessionState) {
    switch state {
    case .stopped:
      currentVideoFrame = nil
      streamingStatus = .stopped
    case .waitingForDevice, .starting, .stopping, .paused:
      streamingStatus = .waiting
    case .streaming:
      streamingStatus = .streaming
    }
  }

  private func formatStreamingError(_ error: StreamSessionError) -> String {
    switch error {
    case .internalError:
      return "An internal error occurred. Please try again."
    case .deviceNotFound:
      return "Device not found. Please ensure your device is connected."
    case .deviceNotConnected:
      return "Device not connected. Please check your connection and try again."
    case .timeout:
      return "The operation timed out. Please try again."
    case .videoStreamingError:
      return "Video streaming failed. Please try again."
    case .audioStreamingError:
      return "Audio streaming failed. Please try again."
    case .permissionDenied:
      return "Camera permission denied. Please grant permission in Settings."
    case .hingesClosed:
      return "The hinges on the glasses were closed. Please open the hinges and try again."
    @unknown default:
      return "An unknown streaming error occurred."
    }
  }
}
