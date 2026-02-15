import UIKit

enum LLMError: Error, LocalizedError {
  case invalidImage
  case invalidResponse
  case apiError(String)

  var errorDescription: String? {
    switch self {
    case .invalidImage: return "Failed to encode image."
    case .invalidResponse: return "Invalid response from LLM."
    case .apiError(let msg): return msg
    }
  }
}

struct MusicTherapyResponse {
  let sceneDescription: String
  let activity: String
  let reasoning: String
  let sunoPrompt: String
  let sunoTags: String
  let targetBpm: Int
  let energy: String
  let mood: String
}

// MARK: - Provider Config

enum LLMProvider {
  case gemini
  case openai
}

struct LLMConfig {
  // ── Switch provider here ──
  static let provider: LLMProvider = .gemini

  // ── Gemini ──
  static let geminiApiKey = "YOUR_GEMINI_API_KEY"
  // Options: "gemini-2.5-flash", "gemini-2.5-flash-lite", "gemini-2.5-pro", "gemini-2.0-flash"
  static let geminiModel = "gemini-2.5-flash"

  // ── OpenAI ──
  static let openaiApiKey = "YOUR_OPENAI_API_KEY"
  // Options: "gpt-5.2-chat-latest" (Instant), "gpt-5.2" (Thinking), "gpt-5.2-pro", "gpt-4o", "gpt-4o-mini", "gpt-4.1", "gpt-4.1-mini"
  static let openaiModel = "gpt-5.2-chat-latest"

  // ── Spotify ──
  static let spotifyClientId = "YOUR_SPOTIFY_CLIENT_ID"
  static let spotifyClientSecret = "YOUR_SPOTIFY_CLIENT_SECRET"
}

// MARK: - Stress Level

enum StressLevel: String, CaseIterable {
  case high
  case moderate
  case low

  var label: String {
    switch self {
    case .high: return "High"
    case .moderate: return "Moderate"
    case .low: return "Low"
    }
  }

  var biometricReading: String {
    switch self {
    case .high:
      return """
        Heart Rate: 92 bpm
        HRV (RMSSD): 15 ms

        Stress Level: High
        """
    case .moderate:
      return """
        Heart Rate: 78 bpm
        HRV (RMSSD): 32 ms

        Stress Level: Moderate
        """
    case .low:
      return """
        Heart Rate: 65 bpm
        HRV (RMSSD): 55 ms

        Stress Level: Low
        """
    }
  }
}

// MARK: - Shared

struct GeminiService {

  // Music taste — loaded from user questionnaire (UserDefaults)
  static var musicTaste: String {
    if let prefs = MusicPreferences.load() {
      return prefs.formatted()
    }
    return """
      - "Sunflower" by Post Malone
      - "Freedom" by Pharrell Williams
      """
  }

  static let systemPrompt = """
    You are a music therapist and composer AI. Your job is to generate a short, precise music generation prompt for Suno AI that creates a personalized soundtrack to help the user manage their current stress level.

    You receive three inputs:

    1. **Photo** — A first-person POV image from a camera mounted on the user's glasses. You are seeing exactly what they see — this is NOT a photo of the user, it's a photo FROM the user's perspective. Infer the environment and activity from what's visible in front of them.
    2. **Biometric Reading** — Heart rate, heart rate variability (HRV/RMSSD), and stress level.
    3. **Music Taste** — Songs the user loves. Don't blindly use all of them — analyze each song's genre, energy, and mood, then select the one(s) that best match the user's current stress level, activity, and therapeutic need. Use the selected song(s) as your primary sonic/stylistic anchor. Explain your choice in the reasoning field.

    ## Output Format

    Respond with ONLY valid JSON, no markdown, no preamble:

    {
      "scene_description": "1-2 sentences describing the environment AND what the user appears to be doing. e.g. 'The user is sitting at a cluttered desk in a dimly lit room, working on a laptop with multiple tabs open.'",
      "activity": "A short label for the user's detected activity. e.g. 'studying', 'commuting', 'exercising', 'working', 'relaxing', 'walking', 'socializing', 'cooking', 'meditating', 'shopping'",
      "reasoning": "2-3 sentences on your therapeutic approach — factor in BOTH the user's stress state AND tsheir activity. Explain why this musical direction suits what they're doing right now.",
      "suno_prompt": "2-4 sentence vivid music generation prompt for Suno, STRICTLY UNDER 500 CHARACTERS. Include: genre, exact BPM, mood, specific instruments, texture, energy. The music should complement the user's current activity. For well-known artists (e.g. Taylor Swift, Drake), describe their sonic style instead of naming them. For lesser-known or indie artists, reference them by name AND also describe their style as best you can (e.g. 'in the style of Cairokee — Arabic alt-rock with driving guitars and anthemic melodies'). Always include a style description alongside any artist name, since Suno may strip the name. Count your characters — must be under 500.",
      "suno_tags": "Short comma-separated style tags for Suno, STRICTLY UNDER 100 CHARACTERS total. e.g. 'ambient electronic, downtempo, atmospheric, instrumental'",
      "target_bpm": 72,
      "energy": "low",
      "mood": "calming"
    }

    ## Therapeutic Rules

    Your goal is to produce music that FITS the user's current state and activity. Context matters — high stress during exercise is DIFFERENT from high stress while sitting:

    - **High stress + sedentary (waiting, working, sitting):** The user is anxious or overwhelmed. Produce CALMING, grounding music. Target BPM 60-75. Warm pads, gentle rhythms, soft dynamics. A sonic safe harbour.
    - **High stress + physical activity (exercise, sports, movement):** This is adrenaline, not anxiety. MATCH and AMPLIFY the intensity. High BPM (100-140), driving rhythm, powerful energy. Fuel the fire.
    - **Moderate stress (HRV 20-40ms):** Gently guide toward ease. Target BPM 65-80. Major keys, simplified textures, steady pulse. Keep it supportive and focused.
    - **Low stress (HRV > 40ms):** Maintain and deepen. Target BPM 55-70. Simple harmony, open textures, slow evolution.

    ## Activity-Aware Rules

    The user's activity (detected from the photo) is just as important as their stress level. ALWAYS adapt the music to what they're DOING:

    - **Studying/Working:** Prioritize focus. Minimal distractions, steady rhythm, no sudden changes. Lo-fi, ambient, or minimal electronic. BPM 60-80. Even if stressed, don't make it emotional — keep it functional.
    - **Exercising/Sports/Running:** Match or exceed their movement energy. Higher BPM (100-140 for running/sports, 90-110 for walking). Rhythmic, driving, powerful. High HR here is physical, not emotional — fuel it.
    - **Commuting (train, bus, car):** Create a personal sonic space. Immersive textures, headphone-friendly spatial sound. Adapt to stress — cocoon if stressed, uplifting if calm.
    - **Relaxing (couch, bed, lounging):** Lean into comfort. Warm pads, slow tempo, gentle. If low stress, deepen relaxation. If high stress, this is a wind-down moment — gradually ease.
    - **Socializing (with people, cafe):** Light, unobtrusive background music. Warm and feel-good.
    - **Cooking/Chores:** Upbeat, rhythmic, feel-good. Match the domestic energy. BPM 90-120.
    - **Nature/Outdoors:** Blend with the environment. Organic instruments, field-recording textures. Let the music feel like an extension of the surroundings.
    - **Unknown/Unclear:** Fall back to stress-based rules above.

    ## Suno Prompt Tips

    - Be specific: "fingerpicked nylon guitar" not "guitar"
    - Include texture: "warm", "lo-fi", "crystalline", "hazy", "analog"
    - Mention dynamics: "gradual build", "gentle swells", "steady and unhurried"
    - Say what to EXCLUDE when appropriate: "no drums", "no sudden changes"
    - Keep to 2-4 sentences — Suno works best with concise, vivid prompts
    - HARD LIMIT: suno_prompt must be under 500 characters, suno_tags must be under 100 characters
    - {VOCAL_INSTRUCTION}
    - IMPORTANT: Do NOT contradict the vocal instruction above. If vocals are requested, NEVER say "no vocals" or "instrumental" in the suno_prompt or suno_tags.
    """

  // MARK: - Demo Mode (text-only, no image)

  static let demoSystemPrompt = """
    You are a music therapist and composer AI. Your job is to generate a short, precise music generation prompt for Suno AI that creates a deeply personalized soundtrack to help the user through a specific moment in their day.

    You receive four inputs:

    1. **Scene** — A vivid description of the user's environment and emotional state, written from their first-person perspective. Immerse yourself in this scene.
    2. **Biometric Reading** — Heart rate, heart rate variability (HRV/RMSSD), and stress level from their wearable.
    3. **Music Taste** — Songs the user loves. THIS IS YOUR PRIMARY SONIC ANCHOR. Analyze each song's genre, energy, instrumentation, and mood. The generated music MUST sound like it comes from the user's world — their genres, their artists, their sonic palette. A hip-hop fan should get hip-hop-influenced music. A rock fan should get rock-influenced music. An Arabic music fan should get Arabic-influenced music. The user should IMMEDIATELY recognize their taste in the output. In the reasoning field, explicitly name which song(s) you're drawing from and how you're adapting their style to fit this moment.
    4. **Musical Direction** — The energy, mood, and therapeutic intent for this specific scene. This tells you HOW to shape the user's taste — the tempo, the intensity, the emotional target. But the SONIC PALETTE (instruments, genre, style) should come from the user's taste, not from generic defaults.

    ## Output Format

    Respond with ONLY valid JSON, no markdown, no preamble:

    {
      "scene_description": "1-2 sentences describing the environment AND what the user appears to be doing.",
      "activity": "A short label for the user's detected activity. e.g. 'studying', 'commuting', 'waiting', 'walking', 'working', 'relaxing'",
      "reasoning": "2-3 sentences on your therapeutic approach — factor in the user's stress state, their activity, AND the emotional texture of the moment. Explain which song(s) from their taste you're drawing from and why.",
      "suno_prompt": "2-4 sentence vivid music generation prompt for Suno, STRICTLY UNDER 500 CHARACTERS. The prompt MUST reflect the user's music taste — reference their genres and describe the sonic style of their favorite artists. Include: genre drawn from user taste, exact BPM, mood, specific instruments that fit their taste, texture, energy. For well-known artists, describe their sonic style instead of naming them. For lesser-known artists, reference them by name AND describe their style. Count your characters — must be under 500.",
      "suno_tags": "Short comma-separated style tags for Suno, STRICTLY UNDER 100 CHARACTERS total. e.g. 'ambient electronic, downtempo, atmospheric, instrumental'",
      "target_bpm": 72,
      "energy": "low",
      "mood": "calming"
    }

    ## Therapeutic Rules

    Your goal is to produce music that FITS the user's current state and activity. Context matters — high stress during exercise is DIFFERENT from high stress while sitting:

    - **High stress + sedentary (waiting, sitting):** The user is anxious. Produce CALMING, grounding music. Target BPM 60-75. Warm, gentle, soothing.
    - **High stress + physical activity (exercise, sports):** This is adrenaline, not anxiety. MATCH and AMPLIFY the intensity. High BPM (100-140), driving rhythm, powerful energy.
    - **Moderate stress (HRV 20-40ms):** Gently guide toward ease. Target BPM 65-80. Supportive and focused.
    - **Low stress (HRV > 40ms):** Maintain and deepen. Target BPM 55-70. Simple harmony, open textures, slow evolution.

    ## Activity-Aware Rules

    The user's activity is just as important as their stress level. Always adapt the music to what they're DOING:

    - **Studying/Working:** Prioritize focus. Steady rhythm, no sudden changes. Lo-fi, ambient, or minimal electronic. BPM 60-80.
    - **Exercising/Sports/Running:** Match or exceed their movement energy. BPM 100-140. Rhythmic, driving, powerful. High HR here is physical — fuel it.
    - **Waiting (transit, appointments):** Create a personal sonic cocoon. Warm, immersive. If stressed, soothe and ground.
    - **Relaxing (couch, bed, lounging):** Lean into comfort. Warm pads, slow tempo, gentle.
    - **Nature/Outdoors:** Blend with the environment. Organic instruments, field-recording textures. Let the music feel like an extension of the surroundings.

    ## Suno Prompt Tips

    - Be SPECIFIC and VIVID: "fingerpicked nylon guitar over tape-hiss warmth" not "guitar"
    - Include texture: "warm", "lo-fi", "crystalline", "hazy", "analog", "sun-drenched"
    - Mention dynamics: "gradual build", "gentle swells", "steady and unhurried"
    - Reference the SCENE in your sonic choices: a nature walk should sound organic, a squash match should sound intense and driving, a quiet moment should sound warm and intimate
    - Say what to EXCLUDE when appropriate: "no drums", "no sudden changes"
    - {VOCAL_INSTRUCTION}
    - IMPORTANT: Do NOT contradict the vocal instruction above.
    - HARD LIMIT: suno_prompt must be under 500 characters, suno_tags must be under 100 characters
    """

  static func generateDemoPrompt(sceneDescription: String, narrative: String, musicalDirection: String, stressLevel: StressLevel, musicTaste: String, instrumental: Bool = true) async throws -> MusicTherapyResponse {

    let vocalInstruction = instrumental
      ? "ALWAYS specify it should be instrumental — no vocals, no lyrics. Include 'no vocals' in the suno_prompt and 'instrumental' in suno_tags."
      : "This track MUST have vocals with lyrics. In the suno_prompt, explicitly request 'with vocals and lyrics' and describe the vocal style (e.g. 'powerful male vocals', 'energetic vocals', 'anthemic chanting'). In suno_tags, include 'vocals' as a tag. Do NOT say 'instrumental', 'no vocals', or 'no lyrics' anywhere."
    let finalPrompt = demoSystemPrompt.replacingOccurrences(of: "{VOCAL_INSTRUCTION}", with: vocalInstruction)

    let userMessage = """
      Here is the user's current data:

      **Biometric Reading:**
      \(stressLevel.biometricReading)

      **Music Taste:**
      \(musicTaste)

      **Scene:**
      \(sceneDescription)

      **What this moment feels like (first-person):**
      \(narrative)

      **Musical Direction (FOLLOW THIS CLOSELY):**
      \(musicalDirection)

      Generate the music therapy JSON. The user's MUSIC TASTE is your primary sonic anchor — the generated track should sound like it belongs in their playlist. The musical direction tells you the energy and mood to aim for. Combine them: take the user's genres and artists, and shape them to fit this moment's energy. In your reasoning, explicitly name which song(s) you're drawing from. Do NOT default to generic ambient/lo-fi — make it sound like THEIR music.
      """

    let text: String

    switch LLMConfig.provider {
    case .gemini:
      text = try await callGeminiTextOnly(systemPrompt: finalPrompt, userMessage: userMessage)
    case .openai:
      text = try await callOpenAITextOnly(systemPrompt: finalPrompt, userMessage: userMessage)
    }

    return try parseResponse(text)
  }

  // MARK: - Public Entry Point

  static func generateMusicTherapy(_ image: UIImage, instrumental: Bool, stressLevel: StressLevel = .high) async throws -> MusicTherapyResponse {
    let resized = resizeImage(image, maxDimension: 512)

    guard let jpegData = resized.jpegData(compressionQuality: 0.4) else {
      throw LLMError.invalidImage
    }
    let base64 = jpegData.base64EncodedString()

    let vocalInstruction = instrumental
      ? "ALWAYS specify it should be instrumental — no vocals, no lyrics. Include 'no vocals' in the suno_prompt and 'instrumental' in suno_tags."
      : "This track MUST have vocals with lyrics. In the suno_prompt, explicitly request 'with vocals and lyrics' and describe the vocal style (e.g. 'soft female vocals', 'dreamy male vocals', 'ethereal harmonies'). In suno_tags, include 'vocals' as a tag. Do NOT say 'instrumental', 'no vocals', or 'no lyrics' anywhere."
    let finalPrompt = systemPrompt.replacingOccurrences(of: "{VOCAL_INSTRUCTION}", with: vocalInstruction)

    let userMessage = """
      Here is the user's current data:

      **Biometric Reading:**
      \(stressLevel.biometricReading)

      **Music Taste:**
      \(musicTaste)

      **Photo** is attached. Generate the music therapy JSON.
      """

    let text: String

    switch LLMConfig.provider {
    case .gemini:
      text = try await callGemini(base64: base64, systemPrompt: finalPrompt, userMessage: userMessage)
    case .openai:
      text = try await callOpenAI(base64: base64, systemPrompt: finalPrompt, userMessage: userMessage)
    }

    return try parseResponse(text)
  }

  // MARK: - Gemini

  private static func callGemini(base64: String, systemPrompt: String, userMessage: String) async throws -> String {
    let url = URL(
      string:
        "https://generativelanguage.googleapis.com/v1beta/models/\(LLMConfig.geminiModel):generateContent?key=\(LLMConfig.geminiApiKey)"
    )!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
      "system_instruction": [
        "parts": [
          ["text": systemPrompt]
        ]
      ],
      "contents": [
        [
          "parts": [
            ["text": userMessage],
            [
              "inline_data": [
                "mime_type": "image/jpeg",
                "data": base64,
              ]
            ],
          ]
        ]
      ],
      "generationConfig": [
        "response_mime_type": "application/json"
      ],
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, _) = try await URLSession.shared.data(for: request)

    guard
      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let candidates = json["candidates"] as? [[String: Any]],
      let content = candidates.first?["content"] as? [String: Any],
      let parts = content["parts"] as? [[String: Any]],
      let text = parts.first?["text"] as? String
    else {
      if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let error = json["error"] as? [String: Any],
        let message = error["message"] as? String
      {
        throw LLMError.apiError(message)
      }
      throw LLMError.invalidResponse
    }

    return text
  }

  // MARK: - OpenAI

  private static func callOpenAI(base64: String, systemPrompt: String, userMessage: String) async throws -> String {
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(LLMConfig.openaiApiKey)", forHTTPHeaderField: "Authorization")

    let body: [String: Any] = [
      "model": LLMConfig.openaiModel,
      "messages": [
        [
          "role": "system",
          "content": systemPrompt,
        ],
        [
          "role": "user",
          "content": [
            [
              "type": "text",
              "text": userMessage,
            ],
            [
              "type": "image_url",
              "image_url": [
                "url": "data:image/jpeg;base64,\(base64)"
              ],
            ],
          ] as [[String: Any]],
        ] as [String: Any],
      ],
      "response_format": ["type": "json_object"],
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, _) = try await URLSession.shared.data(for: request)

    guard
      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let choices = json["choices"] as? [[String: Any]],
      let message = choices.first?["message"] as? [String: Any],
      let text = message["content"] as? String
    else {
      if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let error = json["error"] as? [String: Any],
        let message = error["message"] as? String
      {
        throw LLMError.apiError(message)
      }
      throw LLMError.invalidResponse
    }

    return text
  }

  // MARK: - Text-Only Calls (Demo Mode)

  private static func callGeminiTextOnly(systemPrompt: String, userMessage: String) async throws -> String {
    let url = URL(
      string:
        "https://generativelanguage.googleapis.com/v1beta/models/\(LLMConfig.geminiModel):generateContent?key=\(LLMConfig.geminiApiKey)"
    )!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
      "system_instruction": [
        "parts": [["text": systemPrompt]]
      ],
      "contents": [
        ["parts": [["text": userMessage]]]
      ],
      "generationConfig": [
        "response_mime_type": "application/json"
      ],
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    let (data, _) = try await URLSession.shared.data(for: request)

    guard
      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let candidates = json["candidates"] as? [[String: Any]],
      let content = candidates.first?["content"] as? [String: Any],
      let parts = content["parts"] as? [[String: Any]],
      let text = parts.first?["text"] as? String
    else {
      if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let error = json["error"] as? [String: Any],
        let message = error["message"] as? String
      {
        throw LLMError.apiError(message)
      }
      throw LLMError.invalidResponse
    }
    return text
  }

  private static func callOpenAITextOnly(systemPrompt: String, userMessage: String) async throws -> String {
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(LLMConfig.openaiApiKey)", forHTTPHeaderField: "Authorization")

    let body: [String: Any] = [
      "model": LLMConfig.openaiModel,
      "messages": [
        ["role": "system", "content": systemPrompt],
        ["role": "user", "content": userMessage],
      ],
      "response_format": ["type": "json_object"],
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    let (data, _) = try await URLSession.shared.data(for: request)

    guard
      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let choices = json["choices"] as? [[String: Any]],
      let message = choices.first?["message"] as? [String: Any],
      let text = message["content"] as? String
    else {
      if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let error = json["error"] as? [String: Any],
        let message = error["message"] as? String
      {
        throw LLMError.apiError(message)
      }
      throw LLMError.invalidResponse
    }
    return text
  }

  // MARK: - Parse Response

  private static func parseResponse(_ text: String) throws -> MusicTherapyResponse {
    guard
      let responseData = text.data(using: .utf8),
      let parsed = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
      let sceneDescription = parsed["scene_description"] as? String,
      let activity = parsed["activity"] as? String,
      let reasoning = parsed["reasoning"] as? String,
      let sunoPrompt = parsed["suno_prompt"] as? String,
      let sunoTags = parsed["suno_tags"] as? String,
      let targetBpm = parsed["target_bpm"] as? Int,
      let energy = parsed["energy"] as? String,
      let mood = parsed["mood"] as? String
    else {
      throw LLMError.invalidResponse
    }

    return MusicTherapyResponse(
      sceneDescription: sceneDescription,
      activity: activity,
      reasoning: reasoning,
      sunoPrompt: sunoPrompt,
      sunoTags: sunoTags,
      targetBpm: targetBpm,
      energy: energy,
      mood: mood
    )
  }

  // MARK: - Image Resize

  private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
    let size = image.size
    let longestSide = max(size.width, size.height)
    guard longestSide > maxDimension else { return image }

    let scale = maxDimension / longestSide
    let newSize = CGSize(width: size.width * scale, height: size.height * scale)

    let renderer = UIGraphicsImageRenderer(size: newSize)
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: newSize))
    }
  }
}
