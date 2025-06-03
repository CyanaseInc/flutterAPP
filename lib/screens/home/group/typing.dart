import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart'; // Your theme file

class TypingIndicator extends StatefulWidget {
  final Set<String> typingUsers;
  final String groupId;

  const TypingIndicator({
    super.key,
    required this.typingUsers,
    required this.groupId,
  });

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dot1, _dot2, _dot3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    // Staggered animations for bouncing dots
    _dot1 = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.33, curve: Curves.easeInOut),
      ),
    );
    _dot2 = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.33, 0.66, curve: Curves.easeInOut),
      ),
    );
    _dot3 = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getTypingText() {
    final users = widget.typingUsers.toList();
    if (users.isEmpty) return '';
    if (users.length == 1) return '${users[0]} is typing...';
    if (users.length == 2) return '${users[0]} and ${users[1]} are typing...';
    return '${users[0]}, ${users[1]} and ${users.length - 2} others are typing...';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _controller, // Smooth fade-in/out
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          margin: const EdgeInsets.only(left: 16, bottom: 8, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.9),
                primaryTwo.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _getTypingText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Row(
                  children: [
                    _buildDot(_dot1.value),
                    const SizedBox(width: 4),
                    _buildDot(_dot2.value),
                    const SizedBox(width: 4),
                    _buildDot(_dot3.value),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(double offset) {
    return Transform.translate(
      offset: Offset(0, offset),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}