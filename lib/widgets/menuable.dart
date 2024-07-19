import 'package:flutter/material.dart';

class Menuable<TMenuOption> extends StatefulWidget {
  final List<(TMenuOption, IconData, String)> options;
  final void Function(TMenuOption) onOptionSelected;
  final Widget Function(BuildContext context, void Function(Offset) openMenu)
      builder;

  const Menuable({
    super.key,
    required this.options,
    required this.onOptionSelected,
    required this.builder,
  });

  @override
  State<Menuable<TMenuOption>> createState() => _MenuableState<TMenuOption>();
}

class _MenuableState<TMenuOption> extends State<Menuable<TMenuOption>> {
  final MenuController _menuController = MenuController();
  bool _menuOpened = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _menuController.close(),
      onSecondaryTapUp: (details) => _menuController.open(
          position: details.localPosition + const Offset(0, 1)),
      child: MenuAnchor(
        controller: _menuController,
        onOpen: () => setState(() {
          _menuOpened = true;
        }),
        onClose: () => setState(() {
          _menuOpened = false;
        }),
        menuChildren: widget.options
            .map(((o) => MenuItemButton(
                  leadingIcon: Icon(o.$2),
                  onPressed: () => {widget.onOptionSelected(o.$1)},
                  child: Text(o.$3),
                )))
            .toList(),
        builder: (context, controller, child) => AbsorbPointer(
          absorbing: _menuOpened,
          child: widget.builder(
              context,
              (position) => setState(() {
                    _menuController.open(position: position);
                  })),
        ),
      ),
    );
  }
}
