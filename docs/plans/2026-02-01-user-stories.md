# LilyNotes — User Stories, Acceptance Criteria & Test Scenarios

---

## Epic 1: Page Management

### US-1.1: Create a new page
**As a** user, **I want to** create a new page with a custom name, **so that** I can organize my widgets into separate workspaces.

**Acceptance Criteria:**
- AC1: User can tap a "New Page" button to create a page
- AC2: User is prompted to enter a page name
- AC3: Page name must be 1–50 characters
- AC4: New page is created empty and navigated to immediately
- AC5: Page is persisted locally and survives app restart

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Create page with valid name | App is open | User taps "New Page" and enters "Work" | Page "Work" is created and displayed |
| T2 | Create page with empty name | New page dialog open | User submits empty name | Validation error shown, page not created |
| T3 | Create page with max length name | New page dialog open | User enters 50 characters | Page created successfully |
| T4 | Create page exceeding max length | New page dialog open | User enters 51+ characters | Input is truncated or error shown |
| T5 | Page persists after restart | Page "Work" exists | User closes and reopens app | Page "Work" still exists with all widgets |

---

### US-1.2: Switch between pages
**As a** user, **I want to** switch between my pages, **so that** I can view different workspaces.

**Acceptance Criteria:**
- AC1: A page list/drawer is accessible from the main screen
- AC2: Tapping a page name switches to that page
- AC3: The currently active page is visually highlighted
- AC4: Last visited page is remembered on app restart

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Switch pages | Pages "Work" and "Personal" exist | User opens drawer and taps "Personal" | "Personal" page is displayed |
| T2 | Active page highlighted | On "Work" page | User opens drawer | "Work" is visually highlighted |
| T3 | Remember last page | User is on "Personal" | App is restarted | "Personal" page is shown on launch |

---

### US-1.3: Rename a page
**As a** user, **I want to** rename an existing page, **so that** I can keep my workspace names relevant.

**Acceptance Criteria:**
- AC1: User can long-press or use a menu to rename a page
- AC2: Same validation rules as creation (1–50 chars)
- AC3: Rename is persisted immediately

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Rename page | Page "Work" exists | User renames to "Office" | Page title updates to "Office" |
| T2 | Rename to empty | Rename dialog open | User clears name and submits | Validation error, name unchanged |

---

### US-1.4: Delete a page
**As a** user, **I want to** delete a page I no longer need, **so that** I can keep my workspace clean.

**Acceptance Criteria:**
- AC1: User can delete a page via long-press or menu
- AC2: Confirmation dialog is shown before deletion
- AC3: All widgets on the page are deleted with it
- AC4: If the deleted page was active, navigate to another page
- AC5: If it was the last page, a new default page is created

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Delete page with confirmation | Page "Old" exists | User deletes and confirms | Page removed, navigated to another page |
| T2 | Cancel deletion | Delete confirmation shown | User taps "Cancel" | Page still exists |
| T3 | Delete last page | Only one page exists | User deletes it | New default "My Page" is created |

---

### US-1.5: Reorder pages
**As a** user, **I want to** reorder my pages, **so that** I can prioritize the ones I use most.

**Acceptance Criteria:**
- AC1: User can drag-and-drop pages in the drawer to reorder
- AC2: New order is persisted

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Reorder pages | Pages A, B, C exist | User drags C above A | Order is C, A, B and persists |

---

## Epic 2: Widget Management

### US-2.1: Add a widget to a page
**As a** user, **I want to** add a widget to my page using the floating "+" button, **so that** I can build my workspace.

**Acceptance Criteria:**
- AC1: FAB is always visible at the bottom-right of the screen
- AC2: Tapping FAB opens a widget picker with all 11 widget types
- AC3: Each widget type shows an icon and label
- AC4: Selecting a type adds the widget at the bottom of the page
- AC5: Page scrolls to the newly added widget

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Add a Notes widget | On empty page | User taps FAB → selects "Notes" | Notes widget appears on page |
| T2 | Add multiple widgets | Page has 1 widget | User adds 3 more widgets | All 4 widgets displayed in order |
| T3 | Scroll to new widget | Page has many widgets | User adds a new widget | Page scrolls to show the new widget |

---

### US-2.2: Delete a widget
**As a** user, **I want to** remove a widget from my page, **so that** I can clean up content I no longer need.

**Acceptance Criteria:**
- AC1: Each widget has a delete option (via long-press menu or icon)
- AC2: Confirmation dialog before deletion
- AC3: Widget and its data are permanently removed

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Delete widget | Notes widget exists | User long-presses → Delete → Confirms | Widget removed from page |
| T2 | Cancel deletion | Delete confirmation shown | User cancels | Widget remains |

---

### US-2.3: Reorder widgets
**As a** user, **I want to** reorder widgets on my page, **so that** I can arrange them how I like.

**Acceptance Criteria:**
- AC1: User can long-press and drag widgets to reorder
- AC2: Visual feedback during drag (widget lifts, insertion indicator shown)
- AC3: New order persisted immediately

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Reorder widgets | Widgets A, B, C on page | User drags C above A | Order is C, A, B |

---

## Epic 3: Notes Widget

### US-3.1: Write and edit notes
**As a** user, **I want to** write and edit text in a notes widget, **so that** I can capture thoughts quickly.

**Acceptance Criteria:**
- AC1: Notes widget shows an editable text field
- AC2: Supports multi-line text input
- AC3: Text is auto-saved as the user types (debounced)
- AC4: Supports basic formatting: **bold**, *italic*, ~~strikethrough~~
- AC5: Widget has an optional title field

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Type text | Empty notes widget | User types "Hello world" | Text displayed and saved |
| T2 | Multi-line | Notes widget with text | User presses Enter and types more | Multiple lines displayed |
| T3 | Auto-save | User types text | User navigates away and returns | Text is preserved |
| T4 | Bold formatting | User selects text | User taps bold button | Selected text is bold |
| T5 | Add title | Notes widget shown | User taps title area and types | Title displayed above content |

---

## Epic 4: Score Widget

### US-4.1: Track a score
**As a** user, **I want to** track a numeric score with increment/decrement buttons, **so that** I can keep count of things.

**Acceptance Criteria:**
- AC1: Widget displays a label/title and a numeric value (default 0)
- AC2: "+" button increments by 1
- AC3: "−" button decrements by 1
- AC4: Score can go negative
- AC5: User can set a custom step value (e.g., +5, +10)
- AC6: User can tap the number to manually edit it
- AC7: Long-press +/− for rapid increment/decrement

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Increment | Score is 0 | User taps "+" | Score shows 1 |
| T2 | Decrement | Score is 0 | User taps "−" | Score shows -1 |
| T3 | Custom step | Step set to 5 | User taps "+" | Score increases by 5 |
| T4 | Manual edit | Score is 10 | User taps number, types 50 | Score shows 50 |
| T5 | Rapid increment | Score is 0 | User long-presses "+" for 2 seconds | Score increases rapidly |
| T6 | Persistence | Score is 42 | App restarts | Score still shows 42 |

---

## Epic 5: Counter List Widget

### US-5.1: Manage a counted item list
**As a** user, **I want to** maintain a list of named items each with a count, **so that** I can track quantities of multiple things.

**Acceptance Criteria:**
- AC1: Widget has a title and a list of items
- AC2: Each item has a name and a count (default 0)
- AC3: Each item has "+" and "−" buttons
- AC4: User can add new items via a text field at the bottom
- AC5: User can delete items by swiping
- AC6: Items are persisted
- AC7: Widget shows a total count of all items

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Add item | Counter list exists | User types "Apples" and confirms | "Apples — 0" appears with +/− buttons |
| T2 | Increment item | "Apples — 0" exists | User taps "+" on Apples | Shows "Apples — 1" |
| T3 | Decrement item | "Apples — 1" exists | User taps "−" on Apples | Shows "Apples — 0" |
| T4 | Delete item | "Apples" exists | User swipes left on Apples | Item removed |
| T5 | Total displayed | Apples=2, Oranges=3 | User views widget | Total shows 5 |
| T6 | Empty list | No items | User views widget | "Add your first item" placeholder shown |

---

## Epic 6: Checklist/Todo Widget

### US-6.1: Manage a checklist
**As a** user, **I want to** create and manage a checklist, **so that** I can track tasks and to-dos.

**Acceptance Criteria:**
- AC1: Widget has a title and a list of checkbox items
- AC2: Tapping a checkbox toggles it checked/unchecked
- AC3: Checked items are visually distinct (strikethrough, dimmed)
- AC4: User can add new items via text field
- AC5: User can delete items by swiping
- AC6: User can reorder items by dragging
- AC7: Widget shows progress (e.g., "3/5 done")

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Add item | Empty checklist | User types "Buy milk" | Unchecked item added |
| T2 | Check item | "Buy milk" unchecked | User taps checkbox | Item checked, strikethrough applied |
| T3 | Uncheck item | "Buy milk" checked | User taps checkbox | Item unchecked |
| T4 | Progress display | 2 of 4 items checked | User views widget | Shows "2/4 done" |
| T5 | Delete item | Item exists | User swipes left | Item removed, progress updated |
| T6 | Reorder items | Items A, B, C | User drags C above A | Order is C, A, B |

---

## Epic 7: Habit Tracker Widget

### US-7.1: Track daily habits
**As a** user, **I want to** track habits with a daily check-off grid, **so that** I can build consistency.

**Acceptance Criteria:**
- AC1: Widget has a title/habit name
- AC2: Displays a grid of the last 30 days (or current month)
- AC3: Each day cell can be tapped to mark as done (filled) or undone (empty)
- AC4: Current day is visually highlighted
- AC5: Shows a streak count (consecutive days completed)
- AC6: Shows completion rate (e.g., "18/30 days")

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Mark today done | Today is unmarked | User taps today's cell | Cell fills in, streak updates |
| T2 | Unmark a day | Today is marked | User taps today's cell | Cell empties, streak updates |
| T3 | Streak counting | Days 1–5 marked, day 6 unmarked, days 7–9 marked | User views widget | Streak shows 3 (days 7–9) |
| T4 | Completion rate | 18 of 30 days marked | User views widget | Shows "18/30 days" |
| T5 | Current day highlight | Viewing the grid | User looks at grid | Today's cell has distinct border/highlight |
| T6 | Month navigation | Viewing January | User swipes or taps arrow | February grid shown |

---

## Epic 8: Timer/Stopwatch Widget

### US-8.1: Use a timer
**As a** user, **I want to** set a countdown timer, **so that** I can time activities.

**Acceptance Criteria:**
- AC1: User can set hours, minutes, seconds
- AC2: Start, pause, resume, and reset controls
- AC3: Timer counts down and shows remaining time
- AC4: Notification/sound when timer reaches zero
- AC5: Timer continues running when widget is not visible (in background)

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Set and start timer | Timer at 00:00:00 | User sets 5:00 and taps Start | Timer counts down from 5:00 |
| T2 | Pause timer | Timer running at 3:22 | User taps Pause | Timer stops at 3:22 |
| T3 | Resume timer | Timer paused at 3:22 | User taps Resume | Timer continues from 3:22 |
| T4 | Reset timer | Timer paused at 1:00 | User taps Reset | Timer returns to 5:00 (original) |
| T5 | Timer completes | Timer at 0:01 | 1 second passes | Timer shows 0:00, alarm triggers |
| T6 | Background running | Timer running | User switches pages | Timer still running on return |

### US-8.2: Use a stopwatch
**As a** user, **I want to** use a stopwatch, **so that** I can measure elapsed time.

**Acceptance Criteria:**
- AC1: Stopwatch starts at 00:00:00
- AC2: Start, pause, resume, and reset controls
- AC3: Lap button records split times
- AC4: Lap times displayed in a list

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Start stopwatch | Stopwatch at 0:00 | User taps Start | Time starts counting up |
| T2 | Record lap | Stopwatch running at 1:30 | User taps Lap | "Lap 1: 1:30" recorded, stopwatch continues |
| T3 | Reset stopwatch | Stopwatch paused | User taps Reset | Time returns to 0:00, laps cleared |

---

## Epic 9: Bookmark/Link Widget

### US-9.1: Save bookmarks
**As a** user, **I want to** save URLs with a title, **so that** I can quickly access links.

**Acceptance Criteria:**
- AC1: User can add a URL and an optional title
- AC2: URL is validated (basic format check)
- AC3: Tapping a bookmark opens it in the device browser
- AC4: User can edit or delete bookmarks
- AC5: Shows a favicon or generic link icon

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Add bookmark | Widget exists | User enters "https://flutter.dev" with title "Flutter" | Bookmark saved and displayed |
| T2 | Invalid URL | Add dialog open | User enters "not-a-url" | Validation error shown |
| T3 | Open bookmark | Bookmark exists | User taps it | Browser opens the URL |
| T4 | Delete bookmark | Bookmark exists | User swipes to delete | Bookmark removed |
| T5 | Edit bookmark | Bookmark exists | User taps edit | Can modify URL and title |

---

## Epic 10: Divider/Header Widget

### US-10.1: Add visual separators
**As a** user, **I want to** add dividers and section headers, **so that** I can organize my page visually.

**Acceptance Criteria:**
- AC1: Divider renders as a horizontal line
- AC2: Header renders as large/bold text
- AC3: User can choose between divider and header styles
- AC4: Header text is editable

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Add divider | Page has widgets | User adds divider widget | Horizontal line appears between content |
| T2 | Add header | Page has widgets | User adds header, types "Section 2" | Bold header text displayed |
| T3 | Edit header | Header shows "Old" | User taps and changes to "New" | Header updates |

---

## Epic 11: Progress Bar Widget

### US-11.1: Track progress toward a goal
**As a** user, **I want to** set a goal and track progress visually, **so that** I can see how far I've come.

**Acceptance Criteria:**
- AC1: Widget has a title (e.g., "Books Read")
- AC2: User sets a target number (e.g., 12)
- AC3: User sets current value (e.g., 7) via +/− or manual input
- AC4: Visual progress bar fills proportionally (7/12 = 58%)
- AC5: Percentage and fraction displayed (e.g., "58% — 7/12")
- AC6: Bar turns green/celebratory when 100% reached

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Set goal | New progress widget | User sets target to 12 | Bar shows 0/12, 0% |
| T2 | Increment progress | Current 7/12 | User taps "+" | Shows 8/12, bar updates to 67% |
| T3 | Reach 100% | Current 11/12 | User taps "+" | Shows 12/12, 100%, celebratory style |
| T4 | Exceed target | Current 12/12 | User taps "+" | Shows 13/12, bar stays full |
| T5 | Edit target | Target is 12 | User changes to 20 | Bar recalculates to 7/20, 35% |

---

## Epic 12: Poll/Decision Maker Widget

### US-12.1: Create polls and make decisions
**As a** user, **I want to** add options and assign weights/votes, **so that** I can make informed decisions.

**Acceptance Criteria:**
- AC1: Widget has a question/title field
- AC2: User can add 2+ options
- AC3: Each option has a vote count with +/− buttons
- AC4: Options are sorted by votes (highest first)
- AC5: Visual bar chart shows relative vote distribution
- AC6: "Winner" is highlighted when votes are cast
- AC7: User can reset all votes

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Add options | Empty poll | User adds "Pizza" and "Sushi" | Both options shown with 0 votes |
| T2 | Vote for option | "Pizza" has 0 votes | User taps "+" on Pizza | Pizza shows 1 vote, bar chart updates |
| T3 | Sorting | Pizza=3, Sushi=5 | User views poll | Sushi shown first (5 votes) |
| T4 | Winner highlight | Pizza=3, Sushi=5 | User views poll | Sushi highlighted as winner |
| T5 | Reset votes | Votes exist | User taps Reset | All options return to 0 |
| T6 | Delete option | 3 options exist | User swipes to delete one | Option removed, chart updates |

---

## Epic 13: Expense Tracker Widget

### US-13.1: Track expenses
**As a** user, **I want to** log items with amounts and see a total, **so that** I can track spending.

**Acceptance Criteria:**
- AC1: Widget has a title (e.g., "Trip Budget")
- AC2: User can add items with a name and amount
- AC3: Each item shows name and formatted currency amount
- AC4: Running total displayed at the bottom
- AC5: User can delete items by swiping
- AC6: User can edit item name and amount
- AC7: Amounts support decimals (2 decimal places)

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Add expense | Empty tracker | User adds "Coffee — 4.50" | Item shown, total = 4.50 |
| T2 | Multiple items | Coffee=4.50 | User adds "Lunch — 12.00" | Both shown, total = 16.50 |
| T3 | Delete item | Two items, total=16.50 | User swipes to delete Coffee | Total updates to 12.00 |
| T4 | Edit amount | Coffee=4.50 | User edits to 5.00 | Amount updates, total recalculated |
| T5 | Decimal handling | Add dialog open | User enters "9.999" | Amount stored as 10.00 (rounded) |
| T6 | Empty state | No items | User views widget | Shows "No expenses yet" and total = 0.00 |

---

## Epic 14: App-Level Features

### US-14.1: Dark mode
**As a** user, **I want to** switch between light and dark themes, **so that** I can use the app comfortably in any lighting.

**Acceptance Criteria:**
- AC1: Toggle in settings or app bar
- AC2: All widgets and UI elements respect the theme
- AC3: Theme preference is persisted
- AC4: Follows system theme by default, with manual override

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Toggle dark mode | Light mode active | User toggles dark mode | All UI switches to dark theme |
| T2 | Persist preference | Dark mode enabled | App restarts | Dark mode still active |
| T3 | System default | No manual preference set | System is in dark mode | App uses dark mode |

---

### US-14.2: Widget picker
**As a** user, **I want to** see all available widget types in a clear picker, **so that** I can choose what to add.

**Acceptance Criteria:**
- AC1: Picker opens from FAB tap
- AC2: Shows all 11 widget types with icons and labels
- AC3: Organized in a grid or list layout
- AC4: Tapping a type creates the widget and dismisses picker

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Open picker | On any page | User taps FAB | Picker appears with all 11 types |
| T2 | Select widget | Picker open | User taps "Checklist" | Checklist added to page, picker closes |
| T3 | Dismiss picker | Picker open | User taps outside or back | Picker dismissed, nothing added |

---

### US-14.3: Search across widgets
**As a** user, **I want to** search for content across all widgets and pages, **so that** I can find things quickly.

**Acceptance Criteria:**
- AC1: Search icon in app bar
- AC2: Searches across all pages and widget content
- AC3: Results show matching widget with page name
- AC4: Tapping a result navigates to that page and highlights the widget

**Test Scenarios:**
| # | Scenario | Given | When | Then |
|---|----------|-------|------|------|
| T1 | Search with results | "Buy milk" exists in Checklist on "Personal" page | User searches "milk" | Result shows the checklist item on "Personal" |
| T2 | Search no results | No matching content | User searches "xyz123" | "No results found" displayed |
| T3 | Navigate to result | Result shown | User taps it | Navigated to correct page, widget highlighted |
