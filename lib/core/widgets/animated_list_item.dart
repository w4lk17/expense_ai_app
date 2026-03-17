import 'package:flutter/material.dart';

class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index; // Pour décaler l'animation

  const AnimatedListItem({super.key, required this.child, required this.index});

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);

    // Décalage progressif selon l'index (max 10 items de décalage pour éviter l'attente)
    final delay = (widget.index * 100).clamp(0, 1000);

    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Commence à droite
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _offsetAnimation, child: widget.child);
  }
}
