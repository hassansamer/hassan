import WidgetKit
import SwiftUI

// MARK: - Entry

struct PhotoEntry: TimelineEntry {
    let date: Date
    let name: String?
    let image: UIImage?
}

// MARK: - Provider

struct PhotoProvider: TimelineProvider {
    func placeholder(in context: Context) -> PhotoEntry {
        PhotoEntry(date: .now, name: nil, image: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (PhotoEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PhotoEntry>) -> Void) {
        // الصورة بتتغير بس لما تكبس عليها
        completion(Timeline(entries: [makeEntry()], policy: .never))
    }

    private func makeEntry() -> PhotoEntry {
        let name = PhotoStore.currentOrRandom()
        let image = name.flatMap { PhotoStore.image(named: $0) }
        return PhotoEntry(date: .now, name: name, image: image)
    }
}

// MARK: - View

struct PhotoWidgetView: View {
    let entry: PhotoEntry

    var body: some View {
        if let image = entry.image {
            Button(intent: NextPhotoIntent()) {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .containerBackground(for: .widget) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .id(entry.name)
                    .transition(.push(from: .trailing))
            }
        } else {
            // ما في صور: الكبسة بتفتح التطبيق
            VStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                Text("ضيف صور")
                    .font(.caption.bold())
            }
            .foregroundStyle(.white.opacity(0.8))
            .containerBackground(for: .widget) { Color.black }
        }
    }
}

// MARK: - Widget

struct PhotoWidget: Widget {
    let kind = "PhotoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PhotoProvider()) { entry in
            PhotoWidgetView(entry: entry)
        }
        .configurationDisplayName("صورة")
        .description("اكبس على الصورة عشان تقلب لصورة عشوائية.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    PhotoWidget()
} timeline: {
    PhotoEntry(date: .now, name: nil, image: nil)
}
