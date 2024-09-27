library configurable_expansion_tile;

import 'package:flutter/material.dart';

class ConfigurableExpansionTile extends StatefulWidget {
  const ConfigurableExpansionTile({
    Key? key,
    this.headerBackgroundColorStart = Colors.transparent,
    this.onExpansionChanged,
    this.initiallyExpanded = false,
    required this.header,
    this.animatedWidgetFollowingHeader,
    this.animatedWidgetPrecedingHeader,
    this.expandedBackgroundColor,
    this.borderColorStart = Colors.transparent,
    this.borderColorEnd = Colors.transparent,
    this.topBorderOn = true,
    this.bottomBorderOn = true,
    this.kExpand = const Duration(milliseconds: 200),
    this.headerBackgroundColorEnd,
    this.headerExpanded,
    this.headerAnimationTween,
    this.borderAnimationTween,
    this.controller,
    this.animatedWidgetTurnTween,
    this.animatedWidgetTween,
    this.childrenBody,
    this.enableExpanded = true,
  }) : super(key: key);

  final ValueChanged<bool>? onExpansionChanged;
  final bool enableExpanded;
  final Widget? childrenBody;
  final Color headerBackgroundColorStart;
  final Color? headerBackgroundColorEnd;
  final Color? expandedBackgroundColor;
  final bool initiallyExpanded;
  final ConfigurableExpansionTileController? controller;
  final Widget Function(
    bool isExpanded,
    Animation<double> iconTurns,
    Animation<double> heightFactor,
    ConfigurableExpansionTileController controller,
  ) header;
  final Widget? headerExpanded;
  final Widget? animatedWidgetFollowingHeader;
  final Widget? animatedWidgetPrecedingHeader;
  final Duration kExpand;
  final Color borderColorStart;
  final Color borderColorEnd;
  final bool topBorderOn;
  final bool bottomBorderOn;
  final Animatable<double>? headerAnimationTween;
  final Animatable<double>? borderAnimationTween;
  final Animatable<double>? animatedWidgetTurnTween;
  final Animatable<double>? animatedWidgetTween;

  static final Animatable<double> _easeInTween =
      CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _halfTween =
      Tween<double>(begin: 0.0, end: 0.5);
  static final Animatable<double> _easeOutTween =
      CurveTween(curve: Curves.easeOut);

  @override
  ConfigurableExpansionTileState createState() =>
      ConfigurableExpansionTileState();
}

class ConfigurableExpansionTileState extends State<ConfigurableExpansionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;
  late ConfigurableExpansionTileController _stateController =
      widget.controller ?? ConfigurableExpansionTileController();

  late Animation<Color?> _borderColor;
  Animation<Color?>? _headerColor;

  final ColorTween _borderColorTween = ColorTween();
  final ColorTween _headerColorTween = ColorTween();

  bool _isExpanded = false;

  void _bindController() {
    _stateController.bind(this);
  }

  @override
  void initState() {
    super.initState();
    _bindController();
    _controller = AnimationController(duration: widget.kExpand, vsync: this);
    _heightFactor = _controller.drive(ConfigurableExpansionTile._easeInTween);
    _iconTurns = _controller.drive(
        (widget.animatedWidgetTurnTween ?? ConfigurableExpansionTile._halfTween)
            .chain(widget.animatedWidgetTween ??
                ConfigurableExpansionTile._easeInTween));

    _borderColor = _controller.drive(_borderColorTween.chain(
        widget.borderAnimationTween ??
            ConfigurableExpansionTile._easeOutTween));
    _borderColorTween.end = widget.borderColorEnd;

    _headerColor = _controller.drive(_headerColorTween.chain(
        widget.headerAnimationTween ?? ConfigurableExpansionTile._easeInTween));
    _headerColorTween.end =
        widget.headerBackgroundColorEnd ?? widget.headerBackgroundColorStart;
    _isExpanded =
        PageStorage.of(context).readState(context) ?? widget.initiallyExpanded;
    if (_isExpanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enableExpanded) {
      return;
    }
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse().then<void>((void value) {
          if (!mounted) return;
          setState(() {
            // Rebuild without widget.children.
          });
        });
      }
      PageStorage.of(context).writeState(context, _isExpanded);
    });
    if (widget.onExpansionChanged != null)
      widget.onExpansionChanged!(_isExpanded);
  }

  Widget _buildChildren(BuildContext context, Widget? child) {
    final Color borderSideColor = _borderColor.value ?? widget.borderColorStart;
    final Color headerColor =
        _headerColor?.value ?? widget.headerBackgroundColorStart;
    return Container(
      decoration: BoxDecoration(
          border: Border(
        top: BorderSide(
            color: widget.topBorderOn ? borderSideColor : Colors.transparent),
        bottom: BorderSide(
            color:
                widget.bottomBorderOn ? borderSideColor : Colors.transparent),
      )),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
              onTap: _handleTap,
              child: Container(
                  color: headerColor,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      RotationTransition(
                        turns: _iconTurns,
                        child:
                            widget.animatedWidgetPrecedingHeader ?? Container(),
                      ),
                      _getHeader(),
                      RotationTransition(
                        turns: _iconTurns,
                        child:
                            widget.animatedWidgetFollowingHeader ?? Container(),
                      )
                    ],
                  ))),
          ClipRect(
            child: Align(
              heightFactor: _heightFactor.value,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  /// Retrieves the header to display for the tile, derived from [_isExpanded] state
  Widget _getHeader() {
    if (!_isExpanded) {
      return widget.header(
          _isExpanded, _iconTurns, _heightFactor, _stateController);
    } else {
      return widget.headerExpanded ??
          widget.header(
              _isExpanded, _iconTurns, _heightFactor, _stateController);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool closed = !_isExpanded && _controller.isDismissed;
    return AnimatedBuilder(
      animation: _controller.view,
      builder: _buildChildren,
      child: closed
          ? null
          : widget.childrenBody ??
              Container(
                  color: widget.expandedBackgroundColor ?? Colors.transparent,
                  child: SizedBox()),
    );
  }

  @override
  void didUpdateWidget(covariant ConfigurableExpansionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _bindController();
    }
  }
}

/// The controller allows programmatic control over the expansion and collapse
/// of the ConfigurableExpansionTile.
class ConfigurableExpansionTileController {
  late ConfigurableExpansionTileState state;

  // Bind the controller to the tile state
  void bind(ConfigurableExpansionTileState state) {
    this.state = state;
  }

  // Programmatically expand the tile
  void expand() {
    if (!state._isExpanded) {
      state._handleTap();
    }
  }

  // Programmatically collapse the tile
  void collapse() {
    if (state._isExpanded) {
      state._handleTap();
    }
  }

  // Programmatically toggle the tile
  void toggle() {
    state._handleTap();
  }

  // Get the current expansion state (true if expanded, false otherwise)
  bool get isExpanded => state._isExpanded;
}
