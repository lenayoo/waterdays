import SwiftUI
import WidgetKit

private enum WidgetStore {
  static let suiteName = "group.com.verydays.waterdays.shared"
  static let drankKey = "drankCups"
  static let goalKey = "goalCups"
  static let defaultGoal = 8
}

private enum WidgetPalette {
  static let backgroundTop = Color(red: 0.973, green: 0.984, blue: 0.992)
  static let backgroundBottom = Color(red: 0.913, green: 0.957, blue: 0.988)
  static let glow = Color(red: 0.741, green: 0.863, blue: 0.953)
  static let accent = Color(red: 0.365, green: 0.624, blue: 0.839)
  static let accentSoft = Color(red: 0.553, green: 0.749, blue: 0.906)
  static let textPrimary = Color(red: 0.129, green: 0.220, blue: 0.294)
  static let textSecondary = Color(red: 0.271, green: 0.396, blue: 0.494)
  static let track = Color.white.opacity(0.66)
  static let stroke = Color.white.opacity(0.72)
  static let accessoryTrack = Color.white.opacity(0.30)
  static let accessoryFill = Color.white.opacity(0.72)
}

private enum ProgressBarStyle {
  case home
  case accessory
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
    let goal = max(storedInt(for: defaults, key: WidgetStore.goalKey, fallback: WidgetStore.defaultGoal), 1)
    let drank = min(max(storedInt(for: defaults, key: WidgetStore.drankKey, fallback: 0), 0), goal)
    return WaterdaysEntry(date: Date(), drankCups: drank, goalCups: goal)
  }

  private func storedInt(for defaults: UserDefaults?, key: String, fallback: Int) -> Int {
    guard let defaults, defaults.object(forKey: key) != nil else {
      return fallback
    }
    return defaults.integer(forKey: key)
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

  private var statusText: String {
    if isGoalComplete {
      return "You did it"
    }
    if entry.drankCups == 0 {
      return "Drink water"
    }
    return "Hydrated"
  }

  private var progressValueText: String {
    "\(entry.drankCups)/\(entry.goalCups)"
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
    widgetChrome {
      switch family {
      case .systemMedium:
        mediumHomeWidgetView
      default:
        smallHomeWidgetView
      }
    }
  }

  private var accessoryRectangularView: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(statusText)
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.8)

      Text(progressValueText)
        .font(.system(size: 14, weight: .bold, design: .rounded))

      accessoryProgressBar(height: 8)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .foregroundColor(WidgetPalette.textPrimary)
  }

  @ViewBuilder
  private func widgetChrome<Content: View>(
    @ViewBuilder content: () -> Content
  ) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      content()
        .padding(contentPadding)
        .containerBackground(for: .widget) {
          widgetBackground
        }
    } else {
      ZStack {
        widgetBackground
        content()
          .padding(contentPadding)
      }
    }
  }

  private var contentPadding: EdgeInsets {
    if family == .systemMedium {
      return EdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20)
    }
    return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
  }

  private var widgetBackground: some View {
    ZStack {
      LinearGradient(
        colors: [WidgetPalette.backgroundTop, WidgetPalette.backgroundBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      Circle()
        .fill(WidgetPalette.glow.opacity(0.45))
        .frame(
          width: family == .systemMedium ? 136 : 92,
          height: family == .systemMedium ? 136 : 92
        )
        .offset(
          x: family == .systemMedium ? 92 : 42,
          y: family == .systemMedium ? -72 : -44
        )

      Circle()
        .fill(Color.white.opacity(0.36))
        .frame(
          width: family == .systemMedium ? 88 : 58,
          height: family == .systemMedium ? 88 : 58
        )
        .offset(
          x: family == .systemMedium ? -118 : -54,
          y: family == .systemMedium ? 64 : 42
        )

      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(WidgetPalette.stroke, lineWidth: 1)
    }
  }

  private var smallHomeWidgetView: some View {
    VStack(alignment: .leading, spacing: 14) {
      Spacer()
        .frame(height: 8)

      widgetHeader

      Spacer(minLength: 0)

      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text("\(entry.drankCups)")
          .font(.system(size: 38, weight: .bold, design: .rounded))
          .foregroundColor(WidgetPalette.textPrimary)
        Text("/\(entry.goalCups)")
          .font(.system(size: 20, weight: .semibold, design: .rounded))
          .foregroundColor(WidgetPalette.textSecondary)
      }

      progressBar(height: 12)
    }
  }

  private var mediumHomeWidgetView: some View {
    HStack(spacing: 20) {
      VStack(alignment: .leading, spacing: 14) {
        Spacer()
          .frame(height: 10)

        widgetHeader

        Spacer(minLength: 0)

        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text("\(entry.drankCups)")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundColor(WidgetPalette.textPrimary)
          Text("/\(entry.goalCups)")
            .font(.system(size: 24, weight: .semibold, design: .rounded))
            .foregroundColor(WidgetPalette.textSecondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      VStack {
        Spacer(minLength: 0)
        progressBar(height: 14)
        Spacer(minLength: 0)
      }
      .frame(width: 120, alignment: .center)
    }
  }

  private var widgetHeader: some View {
    HStack(spacing: 6) {
      Image(systemName: "drop.fill")
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(WidgetPalette.accent)
      Text("Water Days")
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .foregroundColor(WidgetPalette.textSecondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
  }

  private func progressBar(height: CGFloat) -> some View {
    progressBar(
      height: height,
      style: .home,
      showsIndicator: true
    )
  }

  private func accessoryProgressBar(height: CGFloat) -> some View {
    progressBar(
      height: height,
      style: .accessory,
      showsIndicator: false
    )
  }

  private func progressBar(
    height: CGFloat,
    style: ProgressBarStyle,
    showsIndicator: Bool
  ) -> some View {
    GeometryReader { geometry in
      let rawFillWidth = geometry.size.width * progress
      let fillWidth = progress > 0 ? max(rawFillWidth, height) : 0
      let clampedFillWidth = min(fillWidth, geometry.size.width)
      let indicatorOffset = max(0, min(geometry.size.width - height, clampedFillWidth - height))

      ZStack(alignment: .leading) {
        Capsule()
          .fill(trackColor(for: style))

        Capsule()
          .stroke(strokeColor(for: style), lineWidth: 1)

        if clampedFillWidth > 0 {
          if case .home = style {
            Capsule()
              .fill(
                LinearGradient(
                  colors: [WidgetPalette.accentSoft, WidgetPalette.accent],
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
              .frame(width: clampedFillWidth)
          } else {
            Capsule()
              .fill(WidgetPalette.accessoryFill)
              .frame(width: clampedFillWidth)
          }

          if showsIndicator {
            Circle()
              .fill(Color.white.opacity(0.94))
              .frame(width: height - 4, height: height - 4)
              .padding(2)
              .offset(x: indicatorOffset)
          }
        }
      }
    }
    .frame(height: height)
  }

  private func trackColor(for style: ProgressBarStyle) -> Color {
    switch style {
    case .home:
      return WidgetPalette.track
    case .accessory:
      return WidgetPalette.accessoryTrack
    }
  }

  private func strokeColor(for style: ProgressBarStyle) -> Color {
    switch style {
    case .home:
      return Color.white.opacity(0.5)
    case .accessory:
      return Color.white.opacity(0.08)
    }
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
