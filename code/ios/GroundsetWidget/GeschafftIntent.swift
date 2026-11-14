import AppIntents
import WidgetKit

/// "Heute geschafft" directly in the Fokus widget, without opening the app.
struct GeschafftIntent: AppIntent {
  static var title: LocalizedStringResource = "Heute geschafft"
  static var description = IntentDescription("Hakt deinen Fokus der Woche für heute ab.")

  func perform() async throws -> some IntentResult {
    Speicher.geschafftHeute()
    WidgetCenter.shared.reloadAllTimelines()
    return .result()
  }
}
