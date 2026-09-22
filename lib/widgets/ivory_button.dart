import 'package:flutter/material.dart';

import 'gold_shimmer.dart';

/// Raised ceramic key with mouse, keyboard and touch feedback.
class IvoryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;
  final bool compact;
  const IvoryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.compact = false,
  });
  @override
  State<IvoryButton> createState() => _IvoryButtonState();
}

class _IvoryButtonState extends State<IvoryButton> {
  bool _hover = false, _pressed = false, _focus = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final raised = enabled && (_hover || _focus) && !_pressed;
    final active = enabled && _pressed;
    final foreground = widget.selected ? Colors.white : const Color(0xFF10382F);
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.label,
      child: AnimatedContainer(
        duration: reduced ? Duration.zero : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..translateByDouble(
            0,
            reduced
                ? 0
                : active
                ? 2
                : raised
                ? -5
                : 0,
            0,
            1,
          )
          ..rotateZ(reduced || !raised || widget.compact ? 0 : -0.018),
        padding: EdgeInsets.only(bottom: active ? 1 : 5),
        decoration: BoxDecoration(
          color: widget.selected
              ? const Color(0xFF10372F)
              : const Color(0xFFB99760),
          borderRadius: BorderRadius.circular(widget.compact ? 16 : 22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF655333)
                  .withValues(alpha: enabled ? 0.20 : 0.08),
              blurRadius: raised
                  ? 18
                  : active
                  ? 3
                  : 9,
              offset: Offset(
                0,
                raised
                    ? 10
                    : active
                    ? 1
                    : 5,
              ),
            ),
          ],
        ),
        child: Material(
          color: !enabled
              ? const Color(0xFFE7E5DF)
              : widget.selected
              ? const Color(0xFF174B40)
              : const Color(0xFFFFFDF8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.compact ? 16 : 22),
            side: BorderSide(
              color: raised
                  ? const Color(0xFF478975)
                  : widget.selected
                  ? const Color(0xFF387969)
                  : const Color(0xFFE7D9BD),
              width: 1.3,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: GoldShimmer(
            enabled: enabled && !reduced,
            radius: widget.compact ? 16 : 22,
            child: InkWell(
              onTap: widget.onPressed,
              onHover: (value) => setState(() => _hover = value),
              onFocusChange: (value) => setState(() => _focus = value),
              onHighlightChanged: (value) => setState(() => _pressed = value),
              excludeFromSemantics: true,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 5 : 14,
                  vertical: widget.compact ? 12 : 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      size: widget.compact ? 25 : 32,
                      color: !enabled
                          ? Colors.grey
                          : widget.selected
                          ? Colors.white
                          : const Color(0xFF9A763B),
                      shadows: const [
                        Shadow(
                          color: Color(0x22795A25),
                          offset: Offset(0, 2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    if (widget.compact)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: enabled ? foreground : Colors.grey,
                          ),
                        ),
                      )
                    else
                      Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: widget.compact ? 11 : 14,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: enabled ? foreground : Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IvoryNavigation extends StatelessWidget {
  final int selected;
  final ValueChanged<int>? onSelected;
  const IvoryNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) {
    const labels = [
      'Ana Sayfa',
      'Kartvizitler',
      'Hatırlatmalar',
      'Kartım',
      'Ayarlar',
    ];
    const icons = [
      Icons.home_outlined,
      Icons.contacts_outlined,
      Icons.notifications_outlined,
      Icons.qr_code_2,
      Icons.settings_outlined,
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF6F5F0),
        border: Border(top: BorderSide(color: Color(0xFFE4D9C7))),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 24) / 5;
            final minWidth = MediaQuery.textScalerOf(context).scale(74);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: SizedBox(
                        width: width < minWidth ? minWidth : width - 4,
                        child: IvoryButton(
                          label: labels[i],
                          icon: icons[i],
                          compact: true,
                          selected: selected == i,
                          onPressed: onSelected == null
                              ? null
                              : () => onSelected!(i),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
