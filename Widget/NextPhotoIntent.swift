import AppIntents
import WidgetKit

/// بينفذ لما تكبس على الويدجت: بيختار صورة عشوائية ثانية بدون ما يفتح التطبيق
struct NextPhotoIntent: AppIntent {
    static var title: LocalizedStringResource = "الصورة التالية"
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        PhotoStore.advanceRandom()
        return .result()
    }
}
