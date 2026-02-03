enum WidgetType {
  text,
  score,
  counterList,
  checklist,
  habitTracker,
  timer,
  bookmark,
  divider,
  progressBar,
  expenseTracker;

  static WidgetType fromString(String value) {
    // Backward compat: old "poll" data maps to score
    if (value == 'poll') return WidgetType.score;
    return WidgetType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WidgetType.score,
    );
  }
}
