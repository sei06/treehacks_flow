# Flow

Flow is a music therapy app for Meta AI glasses. It watches what you're doing through the glasses camera, reads your stress level, and generates music that fits the moment — all in real time.

Studying late at night? It'll make something calm and focused. Walking outside on a sunny day? Something brighter. The idea is that your music should respond to your life, not the other way around.

## How it works

1. You put on your Meta AI glasses and open Flow on your phone
2. The app streams video from the glasses camera
3. You set your current stress level (high, moderate, or low)
4. Hit **Compose** — Flow captures a frame, sends it to Gemini for scene analysis, then generates a custom track through Suno based on what it sees, how you're feeling, and your music taste
5. Music plays through the glasses' open-ear speakers

The whole pipeline takes about 30-60 seconds from pressing Compose to hearing music.

## Setup

### What you need

- Meta AI glasses (Ray-Ban Meta) with Developer Mode on
- iPhone running iOS 17.0+
- Xcode 14.0+
- API keys for: Google Gemini, OpenAI (optional), Spotify, and Suno

### API keys

Open `Flow/ViewModels/GeminiService.swift` and fill in:

```swift
static let geminiApiKey = "YOUR_GEMINI_API_KEY"
static let openaiApiKey = "YOUR_OPENAI_API_KEY"
static let spotifyClientId = "YOUR_SPOTIFY_CLIENT_ID"
static let spotifyClientSecret = "YOUR_SPOTIFY_CLIENT_SECRET"
```

Open `Flow/ViewModels/SunoService.swift` and fill in:

```swift
static let bearerToken = "YOUR_SUNO_BEARER_TOKEN"
```

### Build and run

1. Open `Flow.xcodeproj` in Xcode
2. Select your iPhone as the target device
3. Build and run (`Cmd+R`)

## First launch

When you open the app for the first time:

1. **Connect your glasses** — the app will redirect you to the Meta AI app for authorization, then bring you back
2. **Set your music taste** — pick your favorite genres, search for songs you like on Spotify, and choose your energy preference
3. **Watch the demo** — a short walkthrough showing what Flow can do with three example scenarios
4. **Start using it** — you're on the main screen with live video, stress controls, and the Compose button

## The music generation pipeline

When you tap Compose, here's what happens behind the scenes:

- **Capture** — grabs the current frame from the glasses camera
- **Analyze** — Gemini looks at the image and describes what's happening (scene, activity, mood)
- **Fuse** — combines the scene analysis with your stress level and music preferences
- **Reason** — the LLM decides what kind of music would be therapeutic for this moment
- **Compose** — sends a prompt to Suno to generate a track
- **Play** — streams the audio once it's ready

You can switch between Gemini and OpenAI as the LLM provider in `GeminiService.swift` by changing `LLMConfig.provider`.

## Project structure

```
Flow/
├── ViewModels/
│   ├── GeminiService.swift      # LLM integration (Gemini + OpenAI)
│   ├── SpotifyService.swift     # Song search and playlist parsing
│   ├── SunoService.swift        # Music generation
│   ├── StreamSessionViewModel   # Glasses video stream management
│   └── WearablesViewModel       # Device discovery and connection
├── Views/
│   ├── DemoView.swift           # Main app screen
│   ├── HomeScreenView.swift     # Welcome / connect screen
│   ├── OnboardingContainer.swift # Music taste setup flow
│   ├── DemoContainer.swift      # Guided demo walkthrough
│   ├── NowPlayingCard.swift     # Track info and playback controls
│   └── ...
└── Assets.xcassets/
```

## Built with

- SwiftUI
- Meta Wearables Device Access Toolkit
- Google Gemini API
- Suno API
- Spotify Web API
- AVFoundation

## License

See the [LICENSE](../../LICENSE) file in the root directory.
