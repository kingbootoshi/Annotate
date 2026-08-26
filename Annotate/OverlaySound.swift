import AVFoundation

@MainActor
final class OverlaySound {
    static let shared = OverlaySound()

    private let activatePlayer: AVAudioPlayer?
    private let deactivatePlayer: AVAudioPlayer?

    private init() {
        activatePlayer = Self.makePlayer(named: "overlay-on")
        deactivatePlayer = Self.makePlayer(named: "overlay-off")
    }

    private static func makePlayer(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3"),
            let player = try? AVAudioPlayer(contentsOf: url)
        else { return nil }
        player.volume = 0.6
        player.prepareToPlay()
        return player
    }

    func playActivate() {
        replay(activatePlayer)
    }

    func playDeactivate() {
        replay(deactivatePlayer)
    }

    private func replay(_ player: AVAudioPlayer?) {
        guard let player else { return }
        player.currentTime = 0
        player.play()
    }
}
