import WidgetKit
import SwiftUI

private struct ChecklistEntry: TimelineEntry {
    let date: Date
    let title: String
    let items: [[String: Any]]
}

private struct ChecklistProvider: TimelineProvider {
    private let suiteName = "group.com.lilynotes.app.widgets"

    func placeholder(in context: Context) -> ChecklistEntry {
        ChecklistEntry(date: .now, title: "Checklist", items: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (ChecklistEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChecklistEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> ChecklistEntry {
        let defaults = UserDefaults(suiteName: suiteName)
        let widgetId = defaults?.string(forKey: "default_checklist") ?? ""
        let title = defaults?.string(forKey: "widget_\(widgetId)_title") ?? "Checklist"
        let dataJson = defaults?.string(forKey: "widget_\(widgetId)_data") ?? "[]"

        var items: [[String: Any]] = []
        if let data = dataJson.data(using: .utf8),
           let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            items = arr
        }
        return ChecklistEntry(date: .now, title: title, items: items)
    }
}

struct ChecklistWidgetView: View {
    let entry: ChecklistEntry

    private var checkedCount: Int {
        entry.items.filter { $0["checked"] as? Bool ?? false }.count
    }
    private var total: Int { entry.items.count }
    private let teal = Color(red: 0, green: 0.588, blue: 0.533)

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.title)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                Spacer()
                if total > 0 {
                    Text("\(checkedCount)/\(total)")
                        .font(.system(size: 12))
                        .foregroundStyle(checkedCount == total ? teal : .gray)
                }
            }
            Spacer().frame(height: 2)

            if total == 0 {
                Text("No items — open app to add")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            } else {
                ForEach(Array(entry.items.prefix(8).enumerated()), id: \.offset) { _, item in
                    ChecklistRow(item: item, teal: teal)
                }
                if total > 8 {
                    Text("+\(total - 8) more")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .widgetURL(URL(string: "lilynotes://open"))
    }
}

private struct ChecklistRow: View {
    let item: [String: Any]
    let teal: Color

    private var text: String { item["text"] as? String ?? "" }
    private var isChecked: Bool { item["checked"] as? Bool ?? false }

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isChecked ? teal : Color(white: 0.88))
                    .frame(width: 20, height: 20)
                if isChecked {
                    Text("✓")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                }
            }
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(isChecked ? .gray : .primary)
                .lineLimit(1)
        }
    }
}

struct ChecklistWidget: Widget {
    let kind = "ChecklistWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChecklistProvider()) { entry in
            ChecklistWidgetView(entry: entry)
                .containerBackground(Color(white: 0.96), for: .widget)
        }
        .configurationDisplayName("Checklist")
        .description("View your checklist items.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
