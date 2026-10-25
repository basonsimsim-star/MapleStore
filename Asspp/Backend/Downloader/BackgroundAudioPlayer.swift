//
//  BackgroundAudioPlayer.swift
//  Asspp
//

#if canImport(UIKit)
    import AVFoundation

    /// Plays inaudible audio to keep the app alive in the background while downloads are active.
    /// Uses `.mixWithOthers` so other apps' audio is unaffected.
    final class BackgroundAudioPlayer {
        static let shared = BackgroundAudioPlayer()

        private var player: AVAudioPlayer?
        private var active = false

        func setActive(_ shouldBeActive: Bool) {
            guard shouldBeActive != active else { return }
            active = shouldBeActive
            shouldBeActive ? startPlaying() : stopPlaying()
        }

        private func startPlaying() {
            do {
                try AVAudioSession.sharedInstance().setCategory(
                    .playback,
                    mode: .default,
                    options: [.mixWithOthers],
                )
                try AVAudioSession.sharedInstance().setActive(true)

                let player = try AVAudioPlayer(data: Self.silentWAV)
                player.numberOfLoops = -1
                player.volume = 0
                player.play()
                self.player = player
            } catch {
                logger.error("BackgroundAudioPlayer failed: \(error)")
            }
        }

        private func stopPlaying() {
            player?.stop()
            player = nil
            try? AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation,
            )
        }

        // MARK: - Silent WAV Generation

        /// 1 second of silence — mono 8 kHz 16-bit PCM, ~16 KB in memory.
        private static let silentWAV: Data = {
            let sampleRate: UInt32 = 8000
            let channels: UInt16 = 1
            let bps: UInt16 = 16
            let dataSize: UInt32 = sampleRate * UInt32(channels) * UInt32(bps / 8)

            var d = Data(capacity: 44 + Int(dataSize))

            func append(_ v: UInt32) {
                withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) }
            }
            func append(_ v: UInt16) {
                withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) }
            }

            // RIFF header
            d.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
            append(36 + dataSize)
            d.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"

            // fmt sub-chunk
            d.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
            append(UInt32(16))
            append(UInt16(1)) // PCM
            append(channels)
            append(sampleRate)
            append(sampleRate * UInt32(channels) * UInt32(bps / 8)) // byte rate
            append(channels * (bps / 8)) // block align
            append(bps)

            // data sub-chunk
            d.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
            append(dataSize)
            d.append(Data(count: Int(dataSize)))

            return d
        }()
    }
#endif
