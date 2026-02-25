import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatefulWidget {
  const CustomTitleBar({super.key});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      windowManager.addListener(this);
      _syncMaximizedState();
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _syncMaximizedState() async {
    if (!Platform.isWindows) return;
    final isMaximized = await windowManager.isMaximized();
    if (!mounted) return;
    setState(() {
      _isMaximized = isMaximized;
    });
  }

  @override
  void onWindowMaximize() {
    _syncMaximizedState();
  }

  @override
  void onWindowUnmaximize() {
    _syncMaximizedState();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 36,
      color: const Color(0xFF09090B),
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Image.asset(
                    'assets/anima_favicon.png',
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Anima',
                    style: TextStyle(
                      color: Color(0xFFE4E4E7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _CaptionButton(
            icon: Icons.remove,
            onPressed: () => windowManager.minimize(),
          ),
          _CaptionButton(
            icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
            onPressed: () async {
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
              _syncMaximizedState();
            },
          ),
          _CaptionButton(
            icon: Icons.close,
            hoverColor: const Color(0xFFE11D48),
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}

class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.icon,
    required this.onPressed,
    this.hoverColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? hoverColor;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 46,
          height: 36,
          alignment: Alignment.center,
          color: _hovered
              ? (widget.hoverColor ?? Colors.white.withAlpha(20))
              : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 16,
            color: const Color(0xFFE4E4E7),
          ),
        ),
      ),
    );
  }
}
