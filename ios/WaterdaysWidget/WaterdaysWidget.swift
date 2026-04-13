import SwiftUI
import WidgetKit

private enum WidgetStore {
  static let suiteName = "group.com.verydays.waterdays.shared"
  static let drankKey = "drankCups"
  static let goalKey = "goalCups"
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

  private var progress: Double {
    guard entry.goalCups > 0 else { return 0 }
    return min(Double(entry.drankCups) / Double(entry.goalCups), 1)
  }

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color(red: 0.95, green: 0.98, blue: 1.0), Color(red: 0.90, green: 0.96, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("💧")
            .font(.system(size: 22))
          Spacer()
          Text("waterdays")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(red: 0.19, green: 0.37, blue: 0.52))
        }

        ZStack {
          SemiCircleBackground()
            .stroke(Color(red: 0.78, green: 0.86, blue: 0.91), style: StrokeStyle(lineWidth: 16, lineCap: .round))
            .frame(height: 72)

          SemiCircleBackground()
            .trim(from: 0, to: progress)
            .stroke(
              LinearGradient(
                colors: [Color(red: 0.26, green: 0.66, blue: 0.95), Color(red: 0.39, green: 0.84, blue: 0.98)],
                startPoint: .leading,
                endPoint: .trailing
              ),
              style: StrokeStyle(lineWidth: 16, lineCap: .round)
            )
            .frame(height: 72)

          VStack(spacing: 2) {
            Text("\(entry.drankCups)/\(entry.goalCups)")
              .font(.system(size: 26, weight: .bold, design: .rounded))
              .foregroundStyle(Color(red: 0.16, green: 0.31, blue: 0.44))
            Text("물마시기")
              .font(.system(size: 11, weight: .medium, design: .rounded))
              .foregroundStyle(Color(red: 0.39, green: 0.52, blue: 0.61))
          }
          .padding(.top, 12)
        }
        .padding(.top, 4)

        Text("실제 물 마신양")
          .font(.system(size: 11, weight: .medium, design: .rounded))
          .foregroundStyle(Color(red: 0.38, green: 0.53, blue: 0.62))

        Text("\(entry.drankCups)컵 / \(entry.goalCups)컵")
          .font(.system(size: 16, weight: .semibold, design: .rounded))
          .foregroundStyle(Color(red: 0.17, green: 0.35, blue: 0.48))
      }
      .padding(16)
    }
  }
}

struct SemiCircleBackground: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let radius = min(rect.width / 2, rect.height)
    let center = CGPoint(x: rect.midX, y: rect.maxY)
    path.addArc(
      center: center,
      radius: radius,
      startAngle: .degrees(180),
      endAngle: .degrees(0),
      clockwise: false
    )
    return path
  }
}

struct WaterdaysWidget: Widget {
  let kind: String = "WaterdaysWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: WaterdaysProvider()) { entry in
      WaterdaysWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Waterdays")
    .description("오늘 마신 물의 양과 목표를 바로 확인합니다.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@main
struct WaterdaysWidgetBundle: WidgetBundle {
  var body: some Widget {
    WaterdaysWidget()
  }
}
