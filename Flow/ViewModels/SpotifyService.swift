import Foundation

enum SpotifyError: Error, LocalizedError {
  case authFailed
  case invalidResponse
  case apiError(String)

  var errorDescription: String? {
    switch self {
    case .authFailed: return "Failed to authenticate with Spotify."
    case .invalidResponse: return "Invalid response from Spotify."
    case .apiError(let msg): return msg
    }
  }
}

struct SpotifyTrack: Identifiable, Equatable {
  let id: String
  let name: String
  let artistName: String
  let albumArtURL: URL?

  var displayString: String {
    "\(name) - \(artistName)"
  }

  static func == (lhs: SpotifyTrack, rhs: SpotifyTrack) -> Bool {
    lhs.id == rhs.id
  }
}

struct SpotifyService {
  // Client credentials token (for search)
  private static var cachedToken: String?
  private static var tokenExpiry: Date?

  // MARK: - Client Credentials OAuth (for search)

  static func getToken() async throws -> String {
    if let token = cachedToken, let expiry = tokenExpiry, Date() < expiry {
      return token
    }

    let url = URL(string: "https://accounts.spotify.com/api/token")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let credentials = "\(LLMConfig.spotifyClientId):\(LLMConfig.spotifyClientSecret)"
    let base64 = Data(credentials.utf8).base64EncodedString()
    request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")

    request.httpBody = "grant_type=client_credentials".data(using: .utf8)

    let (data, _) = try await URLSession.shared.data(for: request)

    guard
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let accessToken = json["access_token"] as? String,
      let expiresIn = json["expires_in"] as? Int
    else {
      throw SpotifyError.authFailed
    }

    cachedToken = accessToken
    tokenExpiry = Date().addingTimeInterval(TimeInterval(expiresIn - 60))
    return accessToken
  }

  // MARK: - Search (uses client credentials)

  static func searchTracks(query: String) async throws -> [SpotifyTrack] {
    guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

    let token = try await getToken()

    let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
    let url = URL(string: "https://api.spotify.com/v1/search?q=\(encoded)&type=track&limit=5")!

    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (data, _) = try await URLSession.shared.data(for: request)

    guard
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let tracks = json["tracks"] as? [String: Any],
      let items = tracks["items"] as? [[String: Any]]
    else {
      if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let error = json["error"] as? [String: Any],
        let message = error["message"] as? String
      {
        throw SpotifyError.apiError(message)
      }
      throw SpotifyError.invalidResponse
    }

    return items.compactMap { parseTrack($0) }
  }

  // MARK: - Playlist (via embed page — no auth needed)

  static func fetchPlaylistTracks(playlistId: String) async throws -> [SpotifyTrack] {
    let url = URL(string: "https://open.spotify.com/embed/playlist/\(playlistId)")!
    var request = URLRequest(url: url)
    request.setValue(
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
      forHTTPHeaderField: "User-Agent"
    )

    let (data, response) = try await URLSession.shared.data(for: request)
    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

    guard statusCode == 200 else {
      throw SpotifyError.apiError("Failed to load playlist (\(statusCode))")
    }

    guard let html = String(data: data, encoding: .utf8) else {
      throw SpotifyError.invalidResponse
    }

    // Extract __NEXT_DATA__ JSON from the embed page
    guard let startRange = html.range(of: "<script id=\"__NEXT_DATA__\" type=\"application/json\">"),
          let endRange = html.range(of: "</script>", range: startRange.upperBound..<html.endIndex)
    else {
      throw SpotifyError.apiError("Could not find track data in playlist page.")
    }

    let jsonString = String(html[startRange.upperBound..<endRange.lowerBound])

    guard let jsonData = jsonString.data(using: .utf8),
          let root = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
          let props = root["props"] as? [String: Any],
          let pageProps = props["pageProps"] as? [String: Any],
          let state = pageProps["state"] as? [String: Any],
          let stateData = state["data"] as? [String: Any],
          let entity = stateData["entity"] as? [String: Any],
          let trackList = entity["trackList"] as? [[String: Any]]
    else {
      throw SpotifyError.apiError("Could not parse track data from playlist.")
    }

    return trackList.compactMap { item -> SpotifyTrack? in
      guard let title = item["title"] as? String,
            let subtitle = item["subtitle"] as? String,
            let uri = item["uri"] as? String
      else { return nil }

      // Extract track ID from URI (spotify:track:ID)
      let id = uri.components(separatedBy: ":").last ?? uri

      return SpotifyTrack(id: id, name: title, artistName: subtitle, albumArtURL: nil)
    }
  }

  // MARK: - URL Parsing

  static func extractPlaylistId(from urlString: String) -> String? {
    let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.hasPrefix("https://open.spotify.com/playlist/") else { return nil }
    let afterPrefix = trimmed.dropFirst("https://open.spotify.com/playlist/".count)
    let id = String(afterPrefix.prefix(while: { $0 != "?" && $0 != "/" }))
    return id.isEmpty ? nil : id
  }

  // MARK: - Shared Track Parser (for search results)

  private static func parseTrack(_ item: [String: Any]) -> SpotifyTrack? {
    guard
      let id = item["id"] as? String,
      let name = item["name"] as? String,
      let artists = item["artists"] as? [[String: Any]]
    else { return nil }

    let artistName = artists.compactMap { $0["name"] as? String }.joined(separator: ", ")

    var albumArtURL: URL? = nil
    if let album = item["album"] as? [String: Any],
      let images = album["images"] as? [[String: Any]],
      let smallest = images.last,
      let urlStr = smallest["url"] as? String
    {
      albumArtURL = URL(string: urlStr)
    }

    return SpotifyTrack(id: id, name: name, artistName: artistName, albumArtURL: albumArtURL)
  }
}
