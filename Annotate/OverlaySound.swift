import AVFoundation

@MainActor
final class OverlaySound {
    static let shared = OverlaySound()

    private let togglePlayer: AVAudioPlayer?

    private init() {
        togglePlayer = Self.makePlayer(named: "overlay-toggle")
    }

    private static func makePlayer(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3"),
            let player = try? AVAudioPlayer(contentsOf: url)
        else { return nil }
        player.volume = 0.15
        player.prepareToPlay()
        return player
    }

    func playToggle() {
        guard let togglePlayer else { return }
        togglePlayer.currentTime = 0
        togglePlayer.play()
    }
}
