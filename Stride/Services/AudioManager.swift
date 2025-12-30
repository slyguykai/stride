import AVFoundation

@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private var players: [Sound: AVAudioPlayer] = [:]

    private init() {
        preload()
    }

    enum Sound: String, CaseIterable {
        case completeSoft = "complete_soft"
        case completeMajor = "complete_major"
        case focusStart = "focus_start"
    }

    private func preload() {
        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else { continue }
            let player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            if let player {
                players[sound] = player
            }
        }
    }

    func play(_ sound: Sound) {
        guard let player = players[sound] else { return }
        player.currentTime = 0
        player.play()
    }
}
