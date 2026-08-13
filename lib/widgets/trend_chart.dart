import 'package:flutter/material.dart';

/// 单月数据点。
class MonthPoint {
  const MonthPoint(this.label, this.amount);

  final String label;
  final double amount;
}

/// 近 6 个月支出趋势柱状图（CustomPaint 自绘，无第三方依赖）。
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.points});

  final List<MonthPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxAmount = points.fold<double>(
      0,
      (m, p) => p.amount > m ? p.amount : m,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '近 6 个月支出趋势',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: CustomPaint(
            size: const Size(double.infinity, 160),
            painter: _TrendChartPainter(
              points: points,
              maxAmount: maxAmount,
              barColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({
    required this.points,
    required this.maxAmount,
    required this.barColor,
    required this.labelColor,
  });

  final List<MonthPoint> points;
  final double maxAmount;
  final Color barColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const labelHeight = 22.0;
    const valueHeight = 18.0;
    final chartHeight = size.height - labelHeight - valueHeight;
    final slotWidth = size.width / points.length;
    final barWidth = slotWidth * 0.5;

    final barPaint = Paint()..color = barColor;
    final faintPaint = Paint()..color = barColor.withValues(alpha: 0.25);
    final labelStyle = TextStyle(color: labelColor, fontSize: 11);
    final valueStyle = TextStyle(color: barColor, fontSize: 10);

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final centerX = slotWidth * i + slotWidth / 2;
      final ratio = maxAmount == 0 ? 0.0 : p.amount / maxAmount;
      final barHeight = chartHeight * ratio;
      final top = valueHeight + (chartHeight - barHeight);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - barWidth / 2, top, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, p.amount > 0 ? barPaint : faintPaint);

      // 金额（非零才显示）
      if (p.amount > 0) {
        final valueText = TextPainter(
          text: TextSpan(
            text: p.amount >= 10000
                ? '${(p.amount / 10000).toStringAsFixed(1)}万'
                : p.amount.toStringAsFixed(0),
            style: valueStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        valueText.paint(
          canvas,
          Offset(centerX - valueText.width / 2, top - valueText.height - 2),
        );
      }

      // 月份标签
      final labelText = TextPainter(
        text: TextSpan(text: p.label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      labelText.paint(
        canvas,
        Offset(
          centerX - labelText.width / 2,
          size.height - labelText.height,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.maxAmount != maxAmount;
}
