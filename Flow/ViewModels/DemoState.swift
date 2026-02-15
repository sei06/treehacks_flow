import AVFoundation
import SwiftUI

class DemoState: ObservableObject {
    // Generation
    @Published var track1URL: URL? = nil
    @Published var track2URL: URL? = nil
    @Published var track3URL: URL? = nil
    @Published var allTracksReady: Bool = false
    @Published var generationError: String? = nil
    @Published var generationProgress: String = ""

    // Navigation
    @Published var currentScreen: DemoScreen = .opening
    @Published var scenarioIndex: Int = 0

    enum DemoScreen: Equatable {
        case opening
        case intermission
        case scenario
        case orbTransition
        case end
    }

    var currentScenario: DemoScenario {
        demoScenarios[scenarioIndex]
    }

    var currentTrackURL: URL? {
        switch scenarioIndex {
        case 0: return track1URL
        case 1: return track2URL
        case 2: return track3URL
        default: return nil
        }
    }

    var momentLabel: String {
        switch scenarioIndex {
        case 0: return "MOMENT ONE"
        case 1: return "MOMENT TWO"
        case 2: return "MOMENT THREE"
        default: return ""
        }
    }

    // MARK: - Generation

    func generateAllTracks() async {
        print("[Demo] Starting parallel generation for all 3 tracks")
        let startTime = Date()

        await MainActor.run {
            generationProgress = "Generating soundtracks..."
        }

        let prefs = MusicPreferences.load()
        let musicTaste = prefs?.formatted() ?? "No preferences set"
        print("[Demo] Music taste loaded: \(musicTaste.prefix(80))...")

        async let t1 = generateTrack(scenario: demoScenarios[0], musicTaste: musicTaste)
        async let t2 = generateTrack(scenario: demoScenarios[1], musicTaste: musicTaste)
        async let t3 = generateTrack(scenario: demoScenarios[2], musicTaste: musicTaste)

        let results = await (t1, t2, t3)

        let elapsed = Date().timeIntervalSince(startTime)
        print("[Demo] All 3 tracks done in \(String(format: "%.1f", elapsed))s")
        print("[Demo] Track 1 (\(demoScenarios[0].id)): \(results.0?.absoluteString ?? "FAILED")")
        print("[Demo] Track 2 (\(demoScenarios[1].id)): \(results.1?.absoluteString ?? "FAILED")")
        print("[Demo] Track 3 (\(demoScenarios[2].id)): \(results.2?.absoluteString ?? "FAILED")")

        await MainActor.run {
            track1URL = results.0
            track2URL = results.1
            track3URL = results.2
            allTracksReady = true
            generationProgress = ""
        }
    }

    private func generateTrack(scenario: DemoScenario, musicTaste: String) async -> URL? {
        let trackStart = Date()
        print("[Demo][\(scenario.id)] Starting generation")

        do {
            // 1. Build stress level
            let stressEnum: StressLevel = switch scenario.stressLevel {
            case "high": .high
            case "moderate": .moderate
            case "low": .low
            default: .moderate
            }

            // 2. Call LLM to generate Suno prompt
            print("[Demo][\(scenario.id)] Calling LLM...")
            let llmStart = Date()
            let response = try await GeminiService.generateDemoPrompt(
                sceneDescription: scenario.sceneDescription,
                narrative: scenario.subtitle,
                musicalDirection: scenario.musicalDirection,
                stressLevel: stressEnum,
                musicTaste: musicTaste,
                instrumental: scenario.instrumental
            )
            let llmElapsed = Date().timeIntervalSince(llmStart)
            print("[Demo][\(scenario.id)] LLM done in \(String(format: "%.1f", llmElapsed))s")
            print("[Demo][\(scenario.id)] Suno prompt: \(response.sunoPrompt.prefix(100))...")
            print("[Demo][\(scenario.id)] Suno tags: \(response.sunoTags)")

            // 3. Call Suno to generate music
            print("[Demo][\(scenario.id)] Calling Suno generate...")
            let clipId = try await SunoService.generate(
                topic: response.sunoPrompt,
                tags: response.sunoTags,
                makeInstrumental: scenario.instrumental
            )
            print("[Demo][\(scenario.id)] Suno clip ID: \(clipId)")

            // 4. Poll until audio URL available
            var attempts = 0
            while attempts < 90 {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3s polling
                let clip = try await SunoService.fetchClip(id: clipId)
                let pollElapsed = Date().timeIntervalSince(trackStart)
                print("[Demo][\(scenario.id)] Poll #\(attempts + 1): status=\(clip.status), audioUrl=\(clip.audioUrl != nil ? "YES" : "nil"), elapsed=\(String(format: "%.0f", pollElapsed))s")

                if let audioUrlStr = clip.audioUrl, let remoteURL = URL(string: audioUrlStr) {
                    // Stream directly — no download needed, AVPlayer handles remote URLs
                    print("[Demo][\(scenario.id)] Audio URL available at \(clip.status) status, using remote URL")
                    let totalElapsed = Date().timeIntervalSince(trackStart)
                    print("[Demo][\(scenario.id)] DONE in \(String(format: "%.1f", totalElapsed))s")
                    return remoteURL
                }

                if clip.status == "complete" {
                    print("[Demo][\(scenario.id)] Complete but no audio URL!")
                    break
                }

                if clip.status == "error" {
                    print("[Demo][\(scenario.id)] Suno returned error status")
                    return nil
                }

                attempts += 1
            }

            print("[Demo][\(scenario.id)] Timed out after \(attempts) attempts")
        } catch {
            let elapsed = Date().timeIntervalSince(trackStart)
            print("[Demo][\(scenario.id)] ERROR after \(String(format: "%.1f", elapsed))s: \(error.localizedDescription)")
            await MainActor.run {
                generationError = error.localizedDescription
            }
        }
        return nil
    }

    private func downloadToLocal(remoteURL: URL, id: String) async throws -> URL {
        let (data, _) = try await URLSession.shared.data(from: remoteURL)
        let tempDir = FileManager.default.temporaryDirectory
        let localURL = tempDir.appendingPathComponent("demo_\(id).mp3")
        try data.write(to: localURL)
        print("[Demo][\(id)] Downloaded \(data.count / 1024)KB to local file")
        return localURL
    }

    // MARK: - Navigation

    func reset() {
        track1URL = nil
        track2URL = nil
        track3URL = nil
        allTracksReady = false
        generationError = nil
        generationProgress = ""
        currentScreen = .opening
        scenarioIndex = 0
    }
}
