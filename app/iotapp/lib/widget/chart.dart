import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iotapp/models/sensor_data.dart';

class MiniLineChart extends StatelessWidget {
  final List<SensorData> data;

  const MiniLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 200, child: LineChart(_buildChartData())),
        const SizedBox(height: 12),
        const _LegendRow(),
      ],
    );
  }

  LineChartData _buildChartData() {
    final spotsTemp = _mapSensorToSpots((s) => s.temperature);
    final spotsHum = _mapSensorToSpots((s) => s.humidity);
    final spotsSmoke = _mapSensorToSpots((s) => s.smoke);

    return LineChartData(
      minY: 0,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, interval: 10),
        ),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: true, horizontalInterval: 10),
      lineBarsData: [
        _buildLine(spotsTemp, Colors.red),
        _buildLine(spotsHum, Colors.blue),
        _buildLine(spotsSmoke, Colors.grey.shade700),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.black87,
          getTooltipItems:
              (touchedSpots) =>
                  touchedSpots.map((e) {
                    String label;
                    if (e.barIndex == 0)
                      label = 'Nhiệt độ';
                    else if (e.barIndex == 1)
                      label = 'Độ ẩm';
                    else
                      label = 'Khói';
                    return LineTooltipItem(
                      '$label: ${e.y.toStringAsFixed(1)}',
                      const TextStyle(color: Colors.white),
                    );
                  }).toList(),
        ),
      ),
    );
  }

  List<FlSpot> _mapSensorToSpots(double Function(SensorData) selector) {
    return data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), selector(e.value)))
        .toList();
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _LegendDot(color: Colors.red, label: 'Nhiệt độ'),
        SizedBox(width: 12),
        _LegendDot(color: Colors.blue, label: 'Độ ẩm'),
        SizedBox(width: 12),
        _LegendDot(color: Colors.grey, label: 'Khói'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
