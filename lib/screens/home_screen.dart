import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lilynotes/models/models.dart';
import 'package:lilynotes/providers/providers.dart';
import 'package:lilynotes/widgets/widgets.dart';
import 'search_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _widgetTypeInfo = <WidgetType, ({IconData icon, String label})>{
    WidgetType.score: (icon: Icons.poll, label: 'Score'),
    WidgetType.counterList: (icon: Icons.format_list_numbered, label: 'Counter List'),
    WidgetType.checklist: (icon: Icons.checklist, label: 'Checklist'),
    WidgetType.habitTracker: (icon: Icons.calendar_month, label: 'Habit Tracker'),
    WidgetType.timer: (icon: Icons.timer, label: 'Timer'),
    WidgetType.bookmark: (icon: Icons.bookmark, label: 'Bookmark'),
    WidgetType.divider: (icon: Icons.horizontal_rule, label: 'Divider'),
    WidgetType.progressBar: (icon: Icons.trending_up, label: 'Progress'),
    WidgetType.expenseTracker: (icon: Icons.account_balance_wallet, label: 'Expenses'),
  };

  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final themeProvider = context.watch<ThemeProvider>();
    final currentPage = appState.currentPage;
    final widgets = appState.currentWidgets;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Builder(builder: (_) {
          if (currentPage != null && _titleController.text != currentPage.name) {
            _titleController.text = currentPage.name;
          }
          return TextField(
            controller: _titleController,
            style: Theme.of(context).appBarTheme.titleTextStyle,
            decoration: const InputDecoration(
              hintText: 'Page title...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onChanged: (_) {
              final name = _titleController.text.trim();
              if (name.isNotEmpty && appState.currentPageId != null) {
                appState.renamePage(appState.currentPageId!, name);
              }
            },
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(_themeIcon(themeProvider.themeMode)),
            tooltip: 'Toggle theme',
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      drawer: _buildDrawer(context, appState),
      body: widgets.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.note_add_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'No widgets yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add your first widget',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              itemCount: widgets.length,
              itemBuilder: (context, index) {
                final widget = widgets[index];
                return WidgetCard(
                  key: ValueKey(widget.id),
                  widget: widget,
                  isLastTextBlock: widget.type == WidgetType.text && index == widgets.length - 1,
                  onUpdate: (updated) => appState.updateWidget(updated),
                  onDelete: () => appState.deleteWidget(widget.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWidgetPicker(context),
        tooltip: 'Add widget',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppState appState) {
    final pages = appState.pages;
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Lily Notes',
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const Divider(),
            Expanded(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: pages.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  final ids = pages.map((p) => p.id).toList();
                  final movedId = ids.removeAt(oldIndex);
                  ids.insert(newIndex, movedId);
                  appState.reorderPages(ids);
                },
                itemBuilder: (context, index) {
                  final page = pages[index];
                  final isActive = page.id == appState.currentPageId;
                  return ListTile(
                    key: ValueKey(page.id),
                    title: Text(
                      page.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: isActive,
                    leading: Icon(
                      Icons.description_outlined,
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      appState.switchToPage(page.id);
                      Navigator.of(context).pop();
                    },
                    onLongPress: () => _showPageContextMenu(context, page, appState),
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton.icon(
                onPressed: () => _showNewPageDialog(context, appState),
                icon: const Icon(Icons.add),
                label: const Text('New Page'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPageContextMenu(BuildContext context, AppPage page, AppState appState) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenamePageDialog(context, page, appState);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                title: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeletePage(context, page, appState);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenamePageDialog(BuildContext context, AppPage page, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) {
        return _RenamePageDialog(page: page, appState: appState);
      },
    );
  }

  void _confirmDeletePage(BuildContext context, AppPage page, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Page'),
          content: Text('Delete "${page.name}" and all its widgets? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                appState.deletePage(page.id);
                Navigator.pop(ctx);
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNewPageDialog(BuildContext context, AppState appState) {
    final navigator = Navigator.of(context);
    showDialog<String>(
      context: context,
      builder: (ctx) {
        return const _NewPageDialog();
      },
    ).then((name) {
      if (name != null && name.isNotEmpty) {
        appState.addPage(name);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
    });
  }

  void _showWidgetPicker(BuildContext context) {
    final appState = context.read<AppState>();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 16),
                child: Text('Add Widget', style: theme.textTheme.titleLarge),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.1,
                children: WidgetType.values.where((t) => t != WidgetType.text).map((type) {
                  final info = _widgetTypeInfo[type]!;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      appState.addWidget(type);
                      Navigator.pop(ctx);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(info.icon, size: 28, color: theme.colorScheme.primary),
                        const SizedBox(height: 8),
                        Text(
                          info.label,
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}


class _NewPageDialog extends StatefulWidget {
  const _NewPageDialog();

  @override
  State<_NewPageDialog> createState() => _NewPageDialogState();
}

class _NewPageDialogState extends State<_NewPageDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    Navigator.pop(context, name.isEmpty ? null : name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Page'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Page name'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _RenamePageDialog extends StatefulWidget {
  final AppPage page;
  final AppState appState;

  const _RenamePageDialog({required this.page, required this.appState});

  @override
  State<_RenamePageDialog> createState() => _RenamePageDialogState();
}

class _RenamePageDialogState extends State<_RenamePageDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.page.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      widget.appState.renamePage(widget.page.id, name);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Page'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Page name'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
