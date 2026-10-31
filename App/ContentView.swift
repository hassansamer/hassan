import SwiftUI
import PhotosUI
import WidgetKit

struct ContentView: View {
    @State private var names: [String] = []
    @State private var selection: [PhotosPickerItem] = []
    @State private var isImporting = false
    @State private var toDelete: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        NavigationStack {
            Group {
                if names.isEmpty && !isImporting {
                    emptyState
                } else {
                    grid
                }
            }
            .navigationTitle("صوري")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .overlay {
                if isImporting {
                    ProgressView("جاري الإضافة…")
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .confirmationDialog("حذف الصورة؟", isPresented: Binding(
                get: { toDelete != nil },
                set: { if !$0 { toDelete = nil } }
            ), titleVisibility: .visible) {
                Button("حذف", role: .destructive) {
                    if let name = toDelete { remove(name) }
                }
                Button("إلغاء", role: .cancel) {}
            }
        }
        .onAppear(perform: reload)
        .onChange(of: selection) { _, items in
            guard !items.isEmpty else { return }
            Task { await importItems(items) }
        }
    }

    // MARK: - Views

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("ما في صور لسا")
                .font(.title3.bold())
            Text("اضغط + وضيف الصور اللي بدك ياها تظهر بالويدجت.\nبعدين اكبس على الويدجت عشان تقلب لصورة عشوائية.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
                Label("إضافة صور", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.white, in: Capsule())
                    .foregroundStyle(.black)
            }
        }
        .padding(32)
    }

    private var grid: some View {
        ScrollView {
            Text("\(names.count) صورة • اضغط مطولاً على أي صورة لحذفها")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(names, id: \.self) { name in
                    Thumbnail(name: name)
                        .contextMenu {
                            Button(role: .destructive) {
                                toDelete = name
                            } label: {
                                Label("حذف", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 6)
        }
    }

    // MARK: - Actions

    private func reload() {
        names = PhotoStore.allNames()
    }

    private func importItems(_ items: [PhotosPickerItem]) async {
        isImporting = true
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                PhotoStore.save(image)
            }
        }
        selection = []
        isImporting = false
        reload()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func remove(_ name: String) {
        PhotoStore.delete(name)
        toDelete = nil
        reload()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private struct Thumbnail: View {
    let name: String

    var body: some View {
        Color.gray.opacity(0.2)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image = PhotoStore.image(named: name) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ContentView()
}
