import SwiftUI

class PipelineState: ObservableObject {
    enum Step: Int, CaseIterable, Comparable {
        case idle, capturing, analyzing, fusing, reasoning, composing, playing

        static func < (lhs: Step, rhs: Step) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    @Published var currentStep: Step = .idle

    // Step 1: Photo
    @Published var capturedPhoto: UIImage? = nil

    // Step 2: Scene analysis (from LLM)
    @Published var sceneDescription: String? = nil

    // Step 3: Context (biometrics + music taste)
    @Published var stressLevel: String = "high"
    @Published var heartRate: Int = 92
    @Published var hrv: Int = 15
    @Published var songs: [String] = []
    @Published var makeInstrumental: Bool = true

    // Step 4: AI reasoning (from LLM)
    @Published var reasoning: String? = nil

    // Step 5: Suno prompt + generation
    @Published var sunoPrompt: String? = nil
    @Published var sunoTags: String? = nil

    // Now Playing
    @Published var trackTitle: String? = nil
    @Published var trackBPM: Int? = nil
    @Published var trackMood: String? = nil
    @Published var trackEnergy: String? = nil
    @Published var audioURL: URL? = nil
    @Published var albumArtURL: URL? = nil
    @Published var isPlaying: Bool = false
    @Published var playbackProgress: Double = 0

    // Feedback
    @Published var feedbackGiven: Bool = false

    func reset() {
        currentStep = .idle
        capturedPhoto = nil
        sceneDescription = nil
        reasoning = nil
        sunoPrompt = nil
        sunoTags = nil
        trackTitle = nil
        trackBPM = nil
        trackMood = nil
        trackEnergy = nil
        audioURL = nil
        albumArtURL = nil
        isPlaying = false
        playbackProgress = 0
        feedbackGiven = false
    }

    var stressColor: Color {
        AuraTheme.stressColor(for: stressLevel)
    }

    var biometricSummary: String {
        "HR \(heartRate) bpm, HRV \(hrv)ms, \(stressLevel) stress"
    }
}
