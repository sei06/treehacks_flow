/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// NonStreamView.swift
//
// Main screen after glasses are connected.
// "Generate Soundtrack" button that captures a frame, analyzes with Gemini,
// generates music via Suno, and streams it with AVPlayer.
//

import MWDATCore
import SwiftUI

struct DescribeSceneView: View {
  @ObservedObject var viewModel: StreamSessionViewModel
  @ObservedObject var wearablesVM: WearablesViewModel
  @State private var showMusicTasteEditor = false

  var body: some View {
    ZStack {
      AuraTheme.bg.edgesIgnoringSafeArea(.all)

      ScrollView {
        VStack(spacing: 20) {
          // Settings gear
          HStack {
            Spacer()
            Menu {
              Button {
                showMusicTasteEditor = true
              } label: {
                Label("Edit Music Taste", systemImage: "music.note.list")
              }
              Button("Disconnect", role: .destructive) {
                wearablesVM.disconnectGlasses()
              }
              .disabled(wearablesVM.registrationState != .registered)
            } label: {
              Image(systemName: "gearshape")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(AuraTheme.textSecondary)
                .frame(width: 24, height: 24)
            }
          }

          Spacer().frame(height: 40)

          // Center content
          VStack(spacing: 16) {
            Image(.cameraAccessIcon)
              .resizable()
              .renderingMode(.template)
              .foregroundColor(AuraTheme.accent)
              .aspectRatio(contentMode: .fit)
              .frame(width: 80)

            Text("flow")
              .font(AuraFont.brand(28))
              .foregroundColor(AuraTheme.textPrimary)

            Text("Compose for this moment")
              .font(.system(size: 15))
              .multilineTextAlignment(.center)
              .foregroundColor(AuraTheme.textSecondary)
              .padding(.horizontal, 12)
          }

          // Instrumental / Vocals toggle
          HStack {
            Text("Vocals")
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(AuraTheme.textSecondary)
            Toggle("", isOn: Binding(
              get: { !viewModel.makeInstrumental },
              set: { viewModel.makeInstrumental = !$0 }
            ))
            .labelsHidden()
            .tint(AuraTheme.accent)
          }
          .padding(.horizontal, 4)

          // Stress level segmented control
          HStack(spacing: 0) {
            ForEach(StressLevel.allCases, id: \.self) { level in
              Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                  viewModel.stressLevel = level
                }
              } label: {
                Text(level.label)
                  .font(.system(size: 11, weight: .semibold))
                  .foregroundColor(viewModel.stressLevel == level ? level.themeColor : AuraTheme.textTertiary)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 7)
                  .background(
                    viewModel.stressLevel == level
                      ? RoundedRectangle(cornerRadius: 8).fill(AuraTheme.surface)
                          .shadow(color: AuraTheme.cardShadow, radius: 3, y: 1)
                      : nil
                  )
              }
            }
          }
          .padding(3)
          .background(
            RoundedRectangle(cornerRadius: 10)
              .fill(AuraTheme.well)
          )

          Spacer().frame(height: 12)

          // Error display
          if let error = viewModel.therapyError {
            HStack {
              Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
              Text(error)
                .font(.system(size: 14))
                .foregroundColor(.orange)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
            )
          }

          // Phase-specific content
          switch viewModel.musicPhase {
          case .idle:
            EmptyView()

          case .analyzingScene:
            PhaseProgressView(text: "Analyzing scene...")

          case .generatingMusic:
            if let response = viewModel.therapyResponse {
              CompactTherapyView(response: response, capturedFrame: viewModel.capturedFrame)
            }
            PhaseProgressView(text: "Generating music with Suno...")

          case .waitingForStream:
            if let response = viewModel.therapyResponse {
              CompactTherapyView(response: response, capturedFrame: viewModel.capturedFrame)
            }
            PhaseProgressView(text: "Waiting for music to start streaming...")

          case .streaming(_, let clip):
            if let response = viewModel.therapyResponse {
              CompactTherapyView(response: response, capturedFrame: viewModel.capturedFrame)
            }
            NowPlayingView(
              clip: clip,
              isPlaying: viewModel.isAudioPlaying,
              onPlayPause: { viewModel.togglePlayback() },
              onDismiss: { viewModel.dismissMusic() }
            )

          case .complete(let clip):
            if let response = viewModel.therapyResponse {
              CompactTherapyView(response: response, capturedFrame: viewModel.capturedFrame)
            }
            NowPlayingView(
              clip: clip,
              isPlaying: viewModel.isAudioPlaying,
              onPlayPause: { viewModel.togglePlayback() },
              onDismiss: { viewModel.dismissMusic() }
            )

          case .failed:
            EmptyView()
          }

          // Waiting for device / session status
          if !viewModel.isSessionReady && !viewModel.musicPhase.isInProgress {
            HStack(spacing: 8) {
              ProgressView()
                .tint(AuraTheme.accent)
                .scaleEffect(0.8)
              Text(
                viewModel.hasActiveDevice
                  ? "Connecting to glasses..." : "Waiting for an active device"
              )
              .font(.system(size: 14))
              .foregroundColor(AuraTheme.textSecondary)
            }
            .padding(.bottom, 12)
          }

          // Breathing orb or standard button
          if viewModel.musicPhase.showOrb {
            BreathingOrbView(
              color: viewModel.stressLevel.themeColor,
              size: 120,
              isDisabled: !viewModel.isSessionReady || viewModel.musicPhase.isInProgress
            ) {
              viewModel.generateSoundtrack()
            }
            .frame(maxWidth: .infinity)
          } else {
            CustomButton(
              title: buttonTitle,
              style: .primary,
              isDisabled: !viewModel.isSessionReady || viewModel.musicPhase.isInProgress
            ) {
              viewModel.generateSoundtrack()
            }
          }
        }
        .padding(.all, 24)
      }
    }
    .sheet(isPresented: $showMusicTasteEditor) {
      MusicTasteView {
        showMusicTasteEditor = false
      }
    }
  }

  private var buttonTitle: String {
    switch viewModel.musicPhase {
    case .idle: return "Generate Soundtrack"
    case .analyzingScene: return "Analyzing..."
    case .generatingMusic: return "Generating..."
    case .waitingForStream: return "Waiting for stream..."
    case .streaming: return "Generate New Soundtrack"
    case .complete: return "Generate New Soundtrack"
    case .failed: return "Try Again"
    }
  }
}

// MARK: - Helper Views

private struct PhaseProgressView: View {
  let text: String
  var body: some View {
    HStack(spacing: 8) {
      ProgressView()
        .tint(AuraTheme.accent)
      Text(text)
        .font(.system(size: 14))
        .foregroundColor(AuraTheme.textSecondary)
    }
    .padding(.vertical, 8)
  }
}

private struct CompactTherapyView: View {
  let response: MusicTherapyResponse
  var capturedFrame: UIImage?
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let frame = capturedFrame {
        Image(uiImage: frame)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }
      InfoRow(label: "Scene", text: response.sceneDescription)
      HStack(spacing: 8) {
        Chip(text: response.activity.capitalized, color: AuraTheme.stressMed)
        Chip(text: response.mood.capitalized, color: AuraTheme.accent)
        Chip(text: "\(response.energy.capitalized) energy", color: AuraTheme.accentMuted)
        Chip(text: "\(response.targetBpm) BPM", color: AuraTheme.stressLow)
      }
      InfoRow(label: "Approach", text: response.reasoning)
      InfoRow(label: "Suno Prompt", text: response.sunoPrompt)
    }
    .padding(16)
    .auraCard(cornerRadius: 16)
  }
}

struct InfoRow: View {
  let label: String
  let text: String
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(label)
        .font(AuraFont.data(12))
        .foregroundColor(AuraTheme.textTertiary)
        .textCase(.uppercase)
      Text(text)
        .font(.system(size: 14))
        .foregroundColor(AuraTheme.textPrimary)
    }
  }
}

struct Chip: View {
  let text: String
  let color: Color
  var body: some View {
    Text(text)
      .font(AuraFont.data(10))
      .foregroundColor(color)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(
        Capsule()
          .fill(color.opacity(0.1))
      )
  }
}
