import WidgetKit
import SwiftUI

private struct HabitEntry: TimelineEntry {
    let date: Date
    let title: String
    let habits: [[String: Any]]
}

private struct HabitProvider: TimelineProvider {
    private let suiteName = "group.com.lilynotes.app.widgets"

    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: .now, title: "Habits", habits: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> HabitEntry {
        let defaults = UserDefaults(suiteName: suiteName)
        let widgetId = defaults?.string(forKey: "default_habit") ?? ""
        let title = defaults?.string(forKey: "widget_\(widgetId)_title") ?? "Habits"
        let dataJson = defaults?.string(forKey: "widget_\(widgetId)_data") ?? "[]"

        var habits: [[String: Any]] = []
        if let data = dataJson.data(using: .utf8),
           let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            habits = arr
        }
        return HabitEntry(date: .now, title: title, habits: habits)
    }
}

struct HabitWidgetView: View {
    let entry: HabitEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.title)
                .font(.system(size: 16, weight: .bold))
                .lineLimit(1)

            if entry.habits.isEmpty {
                Text("No habits yet — open app to add")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            } else {
                ForEach(Array(entry.habits.prefix(6).enumerated()), id: \.offset) { _, habit in
                    HabitRow(habit: habit)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .widgetURL(URL(string: "lilynotes://open"))
    }
}

private struct HabitRow: View {
    let habit: [String: Any]

    private var name: String { habit["name"] as? String ?? "" }
    private var done: Bool { habit["done"] as? Bool ?? false }
    private var streak: Int { habit["streak"] as? Int ?? 0 }
    private var habitColor: Color {
        if let c = habit["color"] as? Int {
            return Color(red: Double((c >> 16) & 0xFF) / 255,
                         green: Double((c >> 8) & 0xFF) / 255,
                         blue: Double(c & 0xFF) / 255)
        }
        return .blue
    }

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(done ? habitColor : Color(white: 0.88))
                    .frame(width: 22, height: 22)
                if done {
                    Text("✓")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
            }
            Text(name)
                .font(.system(size: 13))
                .lineLimit(1)
            Spacer(minLength: 0)
            if streak > 0 {
                Text("\(streak)d")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 0, green: 0.588, blue: 0.533))
            }
        }
    }
}

struct HabitWidget: Widget {
    let kind = "HabitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitProvider()) { entry in
            HabitWidgetView(entry: entry)
                .containerBackground(Color(white: 0.96), for: .widget)
        }
        .configurationDisplayName("Habit Tracker")
        .description("Track your daily habits.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
