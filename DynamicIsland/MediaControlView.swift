import SwiftUI

struct MediaInfo {
    let app: String // "Music" or "Spotify"
    let title: String
    let artist: String
    let isPlaying: Bool
}

struct MediaControlView: View {
    let mediaInfo: MediaInfo
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onStop: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mediaInfo.app == "Spotify" ? "music.note.list" : "music.note")
                .font(.title2)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(mediaInfo.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(mediaInfo.artist)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: onPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                Button(action: onPlayPause) {
                    Image(systemName: mediaInfo.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
} 