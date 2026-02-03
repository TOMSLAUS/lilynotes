import WidgetKit
import SwiftUI

@main
struct LilyNotesWidgets: WidgetBundle {
    var body: some Widget {
        HabitWidget()
        ProgressWidget()
        ChecklistWidget()
    }
}
