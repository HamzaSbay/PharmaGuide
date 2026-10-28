import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keyboard shortcut bindings for the Pharmacist Web Dashboard
/// Provides efficient desktop-class navigation for pharmacists
///
/// Shortcuts:
///   Ctrl+1  →  Switch to Hold Queue tab
///   Ctrl+2  →  Switch to Stock Management tab
///   Ctrl+3  →  Switch to CSV Import tab
///   Ctrl+4  →  Switch to B2B Network tab
///   Ctrl+R  →  Refresh data / reload
///   Ctrl+S  →  Quick save / sync stock
///   Ctrl+F  →  Focus search bar
///   Ctrl+N  →  New B2B request
///   Escape  →  Close modal / dialog
class DashboardShortcuts extends StatelessWidget {
  final Widget child;
  final TabController tabController;
  final VoidCallback? onRefresh;
  final VoidCallback? onSave;
  final VoidCallback? onFocusSearch;
  final VoidCallback? onNewRequest;

  const DashboardShortcuts({
    super.key,
    required this.child,
    required this.tabController,
    this.onRefresh,
    this.onSave,
    this.onFocusSearch,
    this.onNewRequest,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        // Tab navigation: Ctrl+1/2/3/4
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () {
          tabController.animateTo(0);
        },
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () {
          tabController.animateTo(1);
        },
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () {
          tabController.animateTo(2);
        },
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () {
          tabController.animateTo(3);
        },
        // Ctrl+R → Refresh
        if (onRefresh != null)
          const SingleActivator(LogicalKeyboardKey.keyR, control: true): onRefresh!,
        // Ctrl+S → Save/Sync
        if (onSave != null)
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): onSave!,
        // Ctrl+F → Focus search
        if (onFocusSearch != null)
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): onFocusSearch!,
        // Ctrl+N → New B2B request
        if (onNewRequest != null)
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): onNewRequest!,
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}

/// Shortcut help overlay widget that shows available keyboard shortcuts
class ShortcutHelpOverlay extends StatelessWidget {
  const ShortcutHelpOverlay({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ShortcutHelpOverlay(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.keyboard, size: 24),
          SizedBox(width: 10),
          Text('Raccourcis Clavier'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ShortcutRow(keys: 'Ctrl + 1', description: 'File d\'attente des réservations'),
          _ShortcutRow(keys: 'Ctrl + 2', description: 'Gestion du stock'),
          _ShortcutRow(keys: 'Ctrl + 3', description: 'Import CSV'),
          _ShortcutRow(keys: 'Ctrl + 4', description: 'Réseau B2B'),
          Divider(),
          _ShortcutRow(keys: 'Ctrl + R', description: 'Rafraîchir les données'),
          _ShortcutRow(keys: 'Ctrl + S', description: 'Synchroniser le stock'),
          _ShortcutRow(keys: 'Ctrl + F', description: 'Rechercher'),
          _ShortcutRow(keys: 'Ctrl + N', description: 'Nouvelle demande B2B'),
          _ShortcutRow(keys: 'Ctrl + ?', description: 'Afficher l\'aide'),
          _ShortcutRow(keys: 'Échap', description: 'Fermer la fenêtre'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final String keys;
  final String description;

  const _ShortcutRow({required this.keys, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(
              keys,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(description, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
