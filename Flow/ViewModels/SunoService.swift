import Foundation

enum SunoError: Error, LocalizedError {
  case invalidResponse
  case apiError(String)
  case timeout

  var errorDescription: String? {
    switch self {
    case .invalidResponse: return "Invalid response from Suno."
    case .apiError(let msg): return msg
    case .timeout: return "Music generation timed out."
    }
  }
}

struct SunoClip: Equatable {
  let id: String
  let status: String
  let audioUrl: String?
  let title: String?
  let imageUrl: String?
}

enum MusicPhase: Equatable {
  case idle
  case analyzingScene
  case generatingMusic
  case waitingForStream(clipId: String)
  case streaming(clipId: String, clip: SunoClip)
  case complete(clip: SunoClip)
  case failed(String)

  var isInProgress: Bool {
    switch self {
    case .idle, .complete, .failed: return false
    default: return true
    }
  }

  var isTerminal: Bool {
    switch self {
    case .complete, .failed: return true
    default: return false
    }
  }

  var showOrb: Bool {
    switch self {
    case .idle, .failed: return true
    default: return false
    }
  }
}

struct SunoService {
  static let baseURL = "https://studio-api.prod.suno.com/api/v2/external/hackathons/"
  // Paste your Suno TreeHacks token here
  static let bearerToken = "YOUR_SUNO_BEARER_TOKEN"

  /// POST /generate — returns the clip ID
  static func generate(topic: String, tags: String, makeInstrumental: Bool = true) async throws
    -> String
  {
    let url = URL(string: "\(baseURL)generate")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

    let body: [String: Any] = [
      "topic": topic,
      "tags": tags,
      "make_instrumental": makeInstrumental,
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, _) = try await URLSession.shared.data(for: request)

    guard
      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let id = json["id"] as? String
    else {
      if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let detail = json["detail"] as? String
      {
        throw SunoError.apiError(detail)
      }
      throw SunoError.invalidResponse
    }

    return id
  }

  /// GET /clips?ids=<id> — returns clip status and audio URL
  static func fetchClip(id: String) async throws -> SunoClip {
    let url = URL(string: "\(baseURL)clips?ids=\(id)")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

    let (data, _) = try await URLSession.shared.data(for: request)

    guard
      let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
      let clip = array.first,
      let clipId = clip["id"] as? String,
      let status = clip["status"] as? String
    else {
      throw SunoError.invalidResponse
    }

    return SunoClip(
      id: clipId,
      status: status,
      audioUrl: clip["audio_url"] as? String,
      title: clip["title"] as? String,
      imageUrl: clip["image_url"] as? String
    )
  }
}
