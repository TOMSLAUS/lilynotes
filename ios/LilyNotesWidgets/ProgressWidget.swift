import WidgetKit
import SwiftUI

private struct ProgressEntry: TimelineEntry {
    let date: Date
    let title: String
    let current: Int
    let target: Int
    let percent: Int
}

private struct ProgressProvider: TimelineProvider {
    private let suiteName = "group.com.lilynotes.app.widgets"

    func placeholder(in context: Context) -> ProgressEntry {
        ProgressEntry(date: .now, title: "Progress", current: 0, target: 10, percent: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (ProgressEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProgressEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> ProgressEntry {
        let defaults = UserDefaults(suiteName: suiteName)
        let widgetId = defaults?.string(forKey: "default_progress") ?? ""
        let title = defaults?.string(forKey: "widget_\(widgetId)_title") ?? "Progress"
        let dataJson = defaults?.string(forKey: "widget_\(widgetId)_data") ?? "{}"

        var current = 0, target = 10, percent = 0
        if let data = dataJson.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            current = obj["current"] as? Int ?? 0
            target = obj["target"] as? Int ?? 10
            percent = obj["percent"] as? Int ?? 0
        }
        return ProgressEntry(date: .now, title: title, current: current, target: target, percent: percent)
    }
}

struct ProgressWidgetView: View {
    let entry: ProgressEntry

    private var fraction: Double {
        entry.target > 0 ? min(Double(entry.current) / Double(entry.target), 1.0) : 0
    }
    private var barColor: Color {
        entry.percent >= 100
            ? Color(red: 0.298, green: 0.686, blue: 0.314)
            : Color(red: 0, green: 0.588, blue: 0.533)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.title)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                Spacer()
                Text("\(entry.current)/\(entry.target)")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }

            ProgressView(value: fraction)
                .tint(barColor)

            HStack {
                Spacer()
                Text("\(entry.percent)%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(barColor)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .widgetURL(URL(string: "lilynotes://open"))
    }
}

struct ProgressWidget: Widget {
    let kind = "ProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProgressProvider()) { entry in
            ProgressWidgetView(entry: entry)
                .containerBackground(Color(white: 0.96), for: .widget)
        }
        .configurationDisplayName("Progress Bar")
        .description("Track your progress toward a goal.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
