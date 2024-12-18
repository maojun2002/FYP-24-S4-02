import 'package:flutter/material.dart';

class CustomThemeSwitch extends StatefulWidget {
  // Props to control the switch appearance and behavior
  final bool isOn; // True if in "dark mode" position, false if in "light mode"
  final Duration duration; // How long the animation takes
  final VoidCallback onToggle; // Function called when the switch is tapped

  // Colors for the background and icon in light/dark states
  final Color lightBackgroundColor;
  final Color darkBackgroundColor;
  final Color lightIconColor;
  final Color darkIconColor;

  // Optional custom icons/widgets for light and dark states
  final Widget? iconLight;
  final Widget? iconDark;

  const CustomThemeSwitch({
    super.key,
    required this.isOn,
    required this.onToggle,
    this.duration = const Duration(milliseconds: 300),
    this.lightBackgroundColor = Colors.white,
    this.darkBackgroundColor = Colors.black,
    this.lightIconColor = Colors.black,
    this.darkIconColor = Colors.white,
    this.iconLight,
    this.iconDark,
  });

  @override
  CustomThemeSwitchState createState() => CustomThemeSwitchState();
}

class CustomThemeSwitchState extends State<CustomThemeSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // INITIAL SETUP ------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    // Create an animation controller that runs from 0 to 1.
    // Its initial value depends on whether the switch is currently "on" or "off".
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.isOn ? 1.0 : 0.0,
    );

    // Apply a curved animation for a smoother transition.
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }


  // Update the animation if the parent widget changes the `isOn` value.
  @override
  void didUpdateWidget(CustomThemeSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOn != widget.isOn) {
      debugPrint("CustomThemeSwitch updated: isOn = ${widget.isOn}");
      widget.isOn ? _controller.forward() : _controller.reverse();
    }
  }


  @override
  void dispose() {
    // Clean up the animation controller when this widget is removed.
    _controller.dispose();
    super.dispose();
  }

  // BUILDING THE SWITCH UI ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Blend background colors based on the animation value
          final backgroundColor = Color.lerp(
            widget.lightBackgroundColor,
            widget.darkBackgroundColor,
            _animation.value,
          )!;

          final iconColor = Color.lerp(
            widget.lightIconColor,
            widget.darkIconColor,
            _animation.value,
          )!;

          return Container(
            width: 80,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor, // Only depend on animation
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: widget.duration,
                  alignment: widget.isOn
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  curve: Curves.easeInOut,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconColor, // Ensure handle color blends smoothly
                        shape: BoxShape.circle,
                      ),
                      child: widget.isOn
                          ? widget.iconDark ??
                              Icon(Icons.nights_stay, color: widget.darkIconColor)
                          : widget.iconLight ??
                              Icon(Icons.wb_sunny, color: widget.lightIconColor),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}