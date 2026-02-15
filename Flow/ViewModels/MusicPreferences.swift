import Foundation

struct MusicPreferences: Codable {
  var genres: [String]
  var favoriteSongs: [String]
  var energyPreference: String

  private static let key = "musicPreferences"

  static func load() -> MusicPreferences? {
    guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
    return try? JSONDecoder().decode(MusicPreferences.self, from: data)
  }

  func save() {
    if let data = try? JSONEncoder().encode(self) {
      UserDefaults.standard.set(data, forKey: MusicPreferences.key)
    }
  }

  static func clear() {
    UserDefaults.standard.removeObject(forKey: key)
  }

  func formatted() -> String {
    var lines: [String] = []
    lines.append("Genres: \(genres.joined(separator: ", "))")
    lines.append("Favorite songs/artists:")
    for song in favoriteSongs {
      lines.append("- \(song)")
    }
    let energy = energyPreference.replacingOccurrences(of: "_", with: " ")
    lines.append("Energy preference: \(energy)")
    return lines.joined(separator: "\n")
  }
}
