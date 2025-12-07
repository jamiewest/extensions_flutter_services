import 'dart:async';
import 'dart:io' show Platform;

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

class DebugTerminalOverlay extends StatefulWidget {
  const DebugTerminalOverlay({
    super.key,
    required this.terminal,
    required this.child,
  });

  final Terminal terminal;
  final Widget child;

  @override
  State<DebugTerminalOverlay> createState() => _DebugTerminalOverlayState();
}

class _DebugTerminalOverlayState extends State<DebugTerminalOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final ValueNotifier<String?> _tooltipMessage = ValueNotifier<String?>(null);
  Timer? _tooltipTimer;

  static const double _maxHeight = 0.7; // 70% of screen height
  static const double _maxWidth = 800.0; // Max width for desktop/web

  bool get _isDesktop {
    if (kIsWeb) return true;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tooltipTimer?.cancel();
    _tooltipMessage.dispose();
    super.dispose();
  }

  void _toggleTerminal() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _copyTerminalContent() async {
    final buffer = widget.terminal.buffer;
    final lines = <String>[];

    // Extract all lines from the terminal buffer
    for (var i = 0; i < buffer.lines.length; i++) {
      final line = buffer.lines[i];
      final text = line.getText().trim();
      if (text.isNotEmpty) {
        lines.add(text);
      }
    }

    final content = lines.join('\n');

    if (content.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: content));

      // Trigger haptic feedback
      HapticFeedback.lightImpact();

      // Show tooltip near copy button
      if (mounted) {
        _showTooltip('Copied!');
      }
    } else {
      // No content to copy - show feedback
      if (mounted) {
        HapticFeedback.mediumImpact();
        _showTooltip('Nothing to copy');
      }
    }
  }

  void _showTooltip(String message) {
    if (!mounted) return;

    _tooltipMessage.value = message;

    _tooltipTimer?.cancel();
    _tooltipTimer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _tooltipMessage.value = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topLeft,
      textDirection: TextDirection.ltr,
      children: [
        KeyedSubtree(key: _navigatorKey, child: widget.child),
        // Backdrop to detect taps outside the terminal
        if (_isExpanded)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return GestureDetector(
                  onTap: () {
                    if (_isExpanded) {
                      _toggleTerminal();
                    }
                  },
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.3 * _animation.value,
                    ),
                  ),
                );
              },
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final height =
                  MediaQuery.of(context).size.height *
                  _maxHeight *
                  _animation.value;

              // Don't render anything when collapsed
              if (height <= 0) {
                return const SizedBox.shrink();
              }

              return Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: SharedAxisTransition(
                    animation: _animation,
                    secondaryAnimation: ReverseAnimation(_animation),
                    transitionType: SharedAxisTransitionType.vertical,
                    fillColor: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        // Absorb taps on the terminal itself to prevent closing
                      },
                      child: Container(
                        height: height,
                        constraints: _isDesktop
                            ? const BoxConstraints(maxWidth: _maxWidth)
                            : null,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHandle(),
                            Expanded(child: _buildTerminalView()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Floating action button to toggle terminal
        if (!_isExpanded)
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: _toggleTerminal,
                  backgroundColor: Colors.black87,
                  child: const Icon(Icons.terminal, color: Colors.greenAccent),
                ),
              ),
            ),
          ),
        // Tooltip
        if (_isExpanded)
          ValueListenableBuilder<String?>(
            valueListenable: _tooltipMessage,
            builder: (context, message, child) {
              final screenHeight = MediaQuery.of(context).size.height;
              final tooltipTop = screenHeight * (1 - _maxHeight) + 50;

              return Positioned(
                top: tooltipTop,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: message != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Center(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              message ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildButton({required IconData icon, required VoidCallback onTap}) {
    return _HoverButton(icon: icon, onTap: onTap);
  }

  Widget _buildHandle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.greenAccent, size: 16),
          const SizedBox(width: 8),
          const Text(
            'Debug Terminal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _buildButton(icon: Icons.copy, onTap: _copyTerminalContent),

          const SizedBox(width: 4),
          _buildButton(icon: Icons.close, onTap: _toggleTerminal),
        ],
      ),
    );
  }

  Widget _buildTerminalView() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: TerminalView(
          widget.terminal,
          textStyle: const TerminalStyle(fontSize: 12),
          autoResize: true,
          padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
          backgroundOpacity: 0.0,
          readOnly: true,
        ),
      ),
    );
  }
}

class _HoverButton extends StatefulWidget {
  const _HoverButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: _isHovering
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            widget.icon,
            color: _isHovering ? Colors.white : Colors.white70,
            size: 18,
          ),
        ),
      ),
    );
  }
}
