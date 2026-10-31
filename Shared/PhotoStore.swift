import Foundation
import UIKit

/// مخزن الصور المشترك بين التطبيق والويدجت (عن طريق App Group)
enum PhotoStore {
    /// لازم يكون نفس القيمة الموجودة بملفات الـ entitlements
    static let appGroupID = "group.com.hassansamer.dot"

    private static let currentKey = "currentPhoto"

    /// الحد الأقصى لأبعاد الصورة (الويدجت الصغير ما بحتاج أكبر من هيك، وهاد بيحميه من حدود الذاكرة)
    private static let maxPixelSize: CGFloat = 700

    // MARK: - Locations

    static var folderURL: URL {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = base.appendingPathComponent("Photos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    // MARK: - Read

    /// أسماء كل الصور، الأحدث أولاً
    static func allNames() -> [String] {
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return urls
            .filter { $0.pathExtension.lowercased() == "jpg" }
            .sorted {
                let a = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let b = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return a > b
            }
            .map { $0.lastPathComponent }
    }

    static func image(named name: String) -> UIImage? {
        UIImage(contentsOfFile: folderURL.appendingPathComponent(name).path)
    }

    // MARK: - Write

    @discardableResult
    static func save(_ image: UIImage) -> String? {
        let resized = downscale(image)
        guard let data = resized.jpegData(compressionQuality: 0.85) else { return nil }
        let name = UUID().uuidString + ".jpg"
        do {
            try data.write(to: folderURL.appendingPathComponent(name), options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func delete(_ name: String) {
        try? FileManager.default.removeItem(at: folderURL.appendingPathComponent(name))
        if currentName == name { currentName = nil }
    }

    // MARK: - Current photo

    static var currentName: String? {
        get { defaults.string(forKey: currentKey) }
        set { defaults.set(newValue, forKey: currentKey) }
    }

    /// الصورة الحالية، ولو مش موجودة بيختار وحدة عشوائية
    static func currentOrRandom() -> String? {
        let names = allNames()
        if let current = currentName, names.contains(current) { return current }
        let pick = names.randomElement()
        currentName = pick
        return pick
    }

    /// بينقل لصورة عشوائية ثانية (مش نفس الصورة الحالية)
    static func advanceRandom() {
        let names = allNames()
        guard !names.isEmpty else { currentName = nil; return }
        let others = names.filter { $0 != currentName }
        currentName = (others.isEmpty ? names : others).randomElement()
    }

    // MARK: - Helpers

    private static func downscale(_ image: UIImage) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height) * image.scale
        guard longest > maxPixelSize else { return image }
        let ratio = maxPixelSize / longest
        let target = CGSize(width: size.width * image.scale * ratio,
                            height: size.height * image.scale * ratio)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
