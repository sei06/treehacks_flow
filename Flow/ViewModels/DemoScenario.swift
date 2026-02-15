import SwiftUI

struct DemoScenario {
    let id: String
    let title: String
    let subtitle: String
    let stressLevel: String
    let stressColor: Color
    let stressLabel: String
    let hr: Int
    let hrv: Int
    let trackTitle: String
    let bpm: Int
    let mood: String
    let videoFileName: String
    let sceneDescription: String
    let musicalDirection: String
    var instrumental: Bool = true
}

let demoScenarios: [DemoScenario] = [
    DemoScenario(
        id: "hackathon",
        title: "Late night at\na hackathon",
        subtitle: "2:47 AM. Screens glowing in the dark. Keyboards clicking around you like rainfall. Your heart rate is up — not stress, just deep focus. You need sound that keeps the flow alive without pushing you over the edge.",
        stressLevel: "moderate",
        stressColor: AuraTheme.stressMed,
        stressLabel: "Moderate",
        hr: 78, hrv: 32,
        trackTitle: "Deep Work",
        bpm: 74, mood: "Focused",
        videoFileName: "hackathon.mov",
        sceneDescription: "Indoor hackathon venue, dim lighting with screen glow, late-night coding, moderate focus state",
        musicalDirection: "ENERGY: Focused, driven, locked-in. This is deep work at 3 AM — the music needs steady RHYTHM and forward momentum (70-80 BPM). NOT ambient or floaty — this needs a beat, a groove, something to code to. Think late-night productivity playlist energy. Use the user's favorite genres/artists as the sonic foundation, but shape them into something focused and hypnotic."
    ),
    DemoScenario(
        id: "squash",
        title: "Mid-match\nintensity",
        subtitle: "The ball ricochets off the front wall. Your opponent is closing in. Heart pounding, legs burning, every shot is a split-second decision. This isn't anxiety — it's pure competitive arousal. The music doesn't calm you down. It locks you in.",
        stressLevel: "high",
        stressColor: AuraTheme.stressHigh,
        stressLabel: "High",
        hr: 156, hrv: 18,
        trackTitle: "Match Point",
        bpm: 128, mood: "Focused intensity",
        videoFileName: "squash.mov",
        sceneDescription: "First-person POV playing squash, indoor court, fast movement, competitive high-intensity sport, physical exertion with competitive focus",
        musicalDirection: "ENERGY: Focused intensity — locked-in, razor-sharp, in the zone. This is NOT chaotic or aggressive — it's controlled competitive focus. Every movement is deliberate. The music should channel that tunnel-vision concentration. Fast tempo (120-135 BPM) but TIGHT and precise, not messy. Driving rhythm that locks you into a flow state at high speed. Think: the mental clarity of an athlete mid-rally. Take the most focused, driving qualities of the user's favorite music — the kind of track that sharpens your reflexes and clears everything else from your mind.",
        instrumental: false
    ),
    DemoScenario(
        id: "nature",
        title: "A walk through\nthe trees",
        subtitle: "Morning light filtering through leaves. Birds somewhere above you. Your heart is slow, your breath is easy. The music doesn't compete with any of it. It dissolves into the world around you — as if the trees wrote it themselves.",
        stressLevel: "low",
        stressColor: AuraTheme.stressLow,
        stressLabel: "Low",
        hr: 62, hrv: 58,
        trackTitle: "Canopy",
        bpm: 58, mood: "Serene",
        videoFileName: "nature.mov",
        sceneDescription: "Outdoor nature trail, morning sunlight through trees, peaceful restorative atmosphere, deep relaxation",
        musicalDirection: "ENERGY: Spacious, organic, unhurried. The user is at peace in nature — the music should dissolve into the surroundings, not compete with them. Very slow (55-65 BPM), lots of breathing room between notes, airy and open. Take the user's favorite music and find its most stripped-down, acoustic, organic expression. If they like pop, give them the unplugged version. If they like electronic, give them the most organic textures. The music should feel like it belongs outdoors — nothing artificial or compressed."
    ),
]
