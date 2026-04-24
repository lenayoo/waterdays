import SwiftUI
import WidgetKit

private enum WidgetStore {
  static let suiteName = "group.com.verydays.waterdays.shared"
  static let drankKey = "drankCups"
  static let goalKey = "goalCups"
}

private struct WidgetCopy {
  private let languageCode: String

  init(locale: Locale = .current) {
    let code: String
    if #available(iOSApplicationExtension 16.0, macOS 13.0, *) {
      code = locale.language.languageCode?.identifier.lowercased() ?? "en"
    } else {
      code = locale.languageCode?.lowercased() ?? "en"
    }
    if code == "ko" || code == "ja" {
      self.languageCode = code
    } else {
      self.languageCode = "en"
    }
  }

  var configurationDisplayName: String {
    switch languageCode {
    case "ko": return "워터 데이즈"
    case "ja": return "ウォーターデイズ"
    default: return "Water Days"
    }
  }

  var configurationDescription: String {
    switch languageCode {
    case "ko": return "오늘 마신 물의 양과 목표를 바로 확인합니다."
    case "ja": return "今日の水分量と目標をすぐ確認できます。"
    default: return "Check today's water progress and goal at a glance."
    }
  }
}

struct WaterdaysEntry: TimelineEntry {
  let date: Date
  let drankCups: Int
  let goalCups: Int
}

struct WaterdaysProvider: TimelineProvider {
  func placeholder(in context: Context) -> WaterdaysEntry {
    WaterdaysEntry(date: Date(), drankCups: 3, goalCups: 8)
  }

  func getSnapshot(in context: Context, completion: @escaping (WaterdaysEntry) -> Void) {
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<WaterdaysEntry>) -> Void) {
    let entry = loadEntry()
    let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
    completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
  }

  private func loadEntry() -> WaterdaysEntry {
    let defaults = UserDefaults(suiteName: WidgetStore.suiteName)
    let goal = max(defaults?.integer(forKey: WidgetStore.goalKey) ?? 8, 1)
    let drank = min(max(defaults?.integer(forKey: WidgetStore.drankKey) ?? 0, 0), goal)
    return WaterdaysEntry(date: Date(), drankCups: drank, goalCups: goal)
  }
}

struct WaterdaysWidgetEntryView: View {
  var entry: WaterdaysProvider.Entry
  @Environment(\.widgetFamily) private var family

  private var progress: Double {
    guard entry.goalCups > 0 else { return 0 }
    return min(Double(entry.drankCups) / Double(entry.goalCups), 1)
  }

  private var isGoalComplete: Bool {
    entry.drankCups >= entry.goalCups
  }

  private var lockscreenProgressText: String {
    "💧 \(entry.drankCups) / \(entry.goalCups)"
  }

  private var lockscreenStatusText: String {
    isGoalComplete ? "You did it!" : "Hydrated"
  }

  private var homeProgressText: String {
    "\(entry.drankCups) / \(entry.goalCups)"
  }

  private var progressBarText: String {
    let totalBlocks = 10
    let filledBlocks = max(
      0,
      min(totalBlocks, Int((progress * Double(totalBlocks)).rounded()))
    )
    return String(repeating: "█", count: filledBlocks) +
      String(repeating: "░", count: totalBlocks - filledBlocks)
  }

  var body: some View {
    Group {
      switch family {
      case .accessoryRectangular:
        accessoryRectangularView
      default:
        homeWidgetView
      }
    }
  }

  private var homeWidgetView: some View {
    ZStack {
      LinearGradient(
        colors: [Color(red: 0.95, green: 0.98, blue: 1.0), Color(red: 0.90, green: 0.96, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      VStack(alignment: .leading, spacing: family == .systemMedium ? 18 : 14) {
        Text("💧 Water Days")
          .font(.system(size: 16, weight: .semibold, design: .rounded))
          .foregroundColor(Color(red: 0.19, green: 0.37, blue: 0.52))

        Spacer(minLength: 0)

        Text(homeProgressText)
          .font(.system(size: family == .systemMedium ? 30 : 26, weight: .bold, design: .rounded))
          .foregroundColor(Color(red: 0.16, green: 0.31, blue: 0.44))
          .frame(maxWidth: .infinity, alignment: .center)

        Text(progressBarText)
          .font(.system(size: family == .systemMedium ? 24 : 20, weight: .bold, design: .monospaced))
          .foregroundColor(Color(red: 0.22, green: 0.47, blue: 0.66))
          .frame(maxWidth: .infinity, alignment: .center)

        Spacer(minLength: 0)
      }
      .padding(family == .systemMedium ? 20 : 16)
    }
  }

  private var accessoryRectangularView: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(lockscreenProgressText)
        .font(.system(size: 15, weight: .semibold, design: .rounded))
      Text(lockscreenStatusText)
        .font(.system(size: 13, weight: .medium, design: .rounded))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct WaterdaysWidget: Widget {
  let kind: String = "WaterdaysWidget"
  private let copy = WidgetCopy()

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: WaterdaysProvider()) { entry in
      WaterdaysWidgetEntryView(entry: entry)
    }
    .configurationDisplayName(copy.configurationDisplayName)
    .description(copy.configurationDescription)
    .supportedFamilies(supportedFamilies)
  }

  private var supportedFamilies: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, *) {
      return [
        .systemSmall,
        .systemMedium,
        .accessoryRectangular,
      ]
    }

    return [.systemSmall, .systemMedium]
  }
}

@main
struct WaterdaysWidgetBundle: WidgetBundle {
  var body: some Widget {
    WaterdaysWidget()
  }
}
