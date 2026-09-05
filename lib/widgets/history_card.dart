import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/history_model.dart';

class HistoryCard extends StatefulWidget {
  final InspectionHistory item;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onCFS;
  final VoidCallback? onEIR;
  final VoidCallback? onChecklist;

  const HistoryCard({
    super.key,
    required this.item,
    required this.formattedDate,
    required this.onTap,
    this.onView,
    this.onEdit,
    this.onCFS,
    this.onEIR,
    this.onChecklist,
  });

  @override
  State<HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<HistoryCard> {
  bool _isHovered = false;

  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    try {
      return value.toString();
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = _safeString(widget.item.status).trim().toLowerCase();
    final String decision = _safeString(widget.item.overallDecision).trim().toLowerCase();
    final bool isDraft = status == 'draft' || decision == 'draft';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0, 0.0),
        child: Card(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: _isHovered ? 8 : 1,
          shadowColor: _isHovered ? Colors.black38 : Colors.black12,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: widget.onTap,
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  // 🟢 80% LEFT SECTION (CONTAINER DETAILS)
                  Expanded(
                    flex: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.item.containerNumber.isEmpty ? '-' : widget.item.containerNumber,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _DecisionBadge(decision: widget.item.overallDecision),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Data Grid
                        _buildGridRow('Invoice No', widget.item.invoiceNo, 'Shipping Line', widget.item.shippingLine),
                        _buildGridRow('Truck No', widget.item.truckNo, 'Type', widget.item.trucktype),
                        _buildGridRow('Checked By', widget.item.checkedBy, 'Date', widget.formattedDate),
                      ],
                    ),
                  ),

                  // VERTICAL SEPARATOR
                  Container(
                    width: 1,
                    height: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: Colors.grey.shade200,
                  ),

                  // 🟢 20% RIGHT SECTION (ACTION BUTTONS - TOTAL 5)
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Edit
                        _ActionButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          color: AppColors.primary,
                          onTap: widget.onEdit ?? widget.onTap,
                        ),

                        // 2. View
                        if (!isDraft && widget.item.id.isNotEmpty)
                          _ActionButton(
                            icon: Icons.visibility_outlined,
                            label: 'View',
                            color: AppColors.textSecondary,
                            onTap: widget.onView ?? widget.onTap,
                          ),

                        // 3. CFS
                        _ActionButton(
                          icon: Icons.warehouse_outlined,
                          label: 'CFS',
                          color: Colors.indigo,
                          onTap: widget.onCFS ?? () {},
                        ),

                        // 4. EIR
                        _ActionButton(
                          icon: Icons.receipt_long_outlined,
                          label: 'EIR',
                          color: Colors.teal,
                          onTap: widget.onEIR ?? () {},
                        ),

                        // 5. Checklist
                        _ActionButton(
                          icon: Icons.fact_check_outlined,
                          label: 'Checklist',
                          color: Colors.deepOrange,
                          onTap: widget.onChecklist ?? () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridRow(String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(child: _detailItem(label1, value1)),
        const SizedBox(width: 4),
        Expanded(child: _detailItem(label2, value2)),
      ],
    );
  }

  Widget _detailItem(String label, String value) {
    final displayValue = value.trim().isEmpty ? '-' : value;
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: displayValue,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionBadge extends StatelessWidget {
  final String decision;
  const _DecisionBadge({required this.decision});

  @override
  Widget build(BuildContext context) {
    final lower = decision.toLowerCase().trim();
    Color color = AppColors.warning;
    Color bgColor = Colors.orange.shade100;

    if (lower.contains('accept')) {
      color = AppColors.success;
      bgColor = Colors.green.shade100;
    } else if (lower.contains('reject')) {
      color = AppColors.danger;
      bgColor = Colors.red.shade100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        decision.isEmpty ? 'Pending' : decision,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}