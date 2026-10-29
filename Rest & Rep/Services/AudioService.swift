import AVFoundation

/// Plays alert sounds over the user's music.
///
/// The session uses `.playback` with `.mixWithOthers` and `.duckOthers`. It is only active while
/// an alert is playing, so other audio dips during the alert and comes back straight after.
final class AudioService {
    enum Sound: String, CaseIterable {
        case tick, work, rest, finish

        var fileName: String { "\(rawValue).wav" }
    }

    private var players: [Sound: AVAudioPlayer] = [:]
    private var activeUntil: Date = .distantPast
    private var deactivateTask: Task<Void, Never>?

    init() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default,
            options: [.mixWithOthers, .duckOthers]
        )
        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.prepareToPlay()
            players[sound] = player
        }
    }

    static func sound(for event: TimerEvent) -> Sound {
        switch event {
        case .tick: .tick
        case .phaseStarted(.work): .work
        case .phaseStarted(.rest), .phaseStarted(.getReady): .rest
        case .finished: .finish
        }
    }

    func play(for event: TimerEvent) {
        play(Self.sound(for: event))
    }

    func play(_ sound: Sound) {
        guard AppSettings.soundEnabled, let player = players[sound] else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true)
        player.currentTime = 0
        player.play()

        activeUntil = max(activeUntil, .now.addingTimeInterval(player.duration + 0.15))
        deactivateTask?.cancel()
        deactivateTask = Task { [activeUntil] in
            try? await Task.sleep(for: .seconds(max(0, activeUntil.timeIntervalSinceNow)))
            guard !Task.isCancelled else { return }
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}
