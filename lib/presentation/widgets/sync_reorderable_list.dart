import 'package:flutter/material.dart';

/// Liste réordonnable par glisser-déposer avec mise à jour optimiste synchrone.
/// Évite le décalage d'une frame des StreamProviders lors du relâchement (drop)
/// et garantit la stabilité de l'arbre d'Elements Flutter.
class SyncReorderableList<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T item) idOf;
  final ValueChanged<List<T>> onReordered;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const SyncReorderableList({
    super.key,
    required this.items,
    required this.idOf,
    required this.onReordered,
    required this.itemBuilder,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<SyncReorderableList<T>> createState() => _SyncReorderableListState<T>();
}

class _SyncReorderableListState<T> extends State<SyncReorderableList<T>> {
  late List<T> _localItems;

  @override
  void initState() {
    super.initState();
    _localItems = [...widget.items];
  }

  @override
  void didUpdateWidget(covariant SyncReorderableList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _localItems = [...widget.items];
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) => Material(
        color: Colors.transparent,
        elevation: 6,
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
      itemCount: _localItems.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        if (oldIndex == newIndex) return;
        setState(() {
          final moved = _localItems.removeAt(oldIndex);
          _localItems.insert(newIndex, moved);
        });
        widget.onReordered(List<T>.unmodifiable(_localItems));
      },
      itemBuilder: (context, index) {
        final item = _localItems[index];
        return KeyedSubtree(
          key: ValueKey(widget.idOf(item)),
          child: widget.itemBuilder(context, item, index),
        );
      },
    );
  }
}
