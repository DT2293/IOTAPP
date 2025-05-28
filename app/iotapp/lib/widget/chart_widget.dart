import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:iotapp/models/sensor_data.dart';

class DailyTemperatureHumidityChart extends StatelessWidget {
  final List<SensorData> data;

  const DailyTemperatureHumidityChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final double pixelPerPoint = 50;
    final maxSmoke = data
        .map((e) => e.averageSmokeLevel)
        .fold<int>(0, (a, b) => a > b ? a : b);

    List<FlSpot> tempSpots =
        data
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.averageTemperature))
            .toList();

    List<FlSpot> humidSpots =
        data
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.averageHumidity))
            .toList();

    List<FlSpot> smokeSpots =
        data
            .asMap()
            .entries
            .map(
              (e) => FlSpot(
                e.key.toDouble(),
                (e.value.averageSmokeLevel / maxSmoke) * 100,
              ),
            )
            .toList();

    final chartWidth = data.length * pixelPerPoint;
    final chartHeight = 400.0;

    return Column(
      children: [
        SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Trục Y cố định bên trái
              SizedBox(
                width: 40,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value % 20 == 0) {
                              return Text(value.toInt().toString());
                            }
                            return Container();
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    minY: 0,
                    maxY: 250,
                  ),
                ),
              ),

              // Chart scroll được bên phải
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    height: chartHeight,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 250,
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index < 0 || index >= data.length)
                                  return const Text('');
                                final date = DateFormat.Md().format(
                                  data[index].date,
                                );
                                return Text(
                                  date,
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: 20,
                              getTitlesWidget: (value, meta) {
                                int smokeValue =
                                    ((value / 100) * maxSmoke).round();
                                if (value % 20 == 0) {
                                  return Text(
                                    smokeValue.toString(),
                                    style: const TextStyle(color: Colors.green),
                                  );
                                }
                                return Container();
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: tempSpots,
                            isCurved: true,
                            color: Colors.red,
                            dotData: FlDotData(show: false),
                            barWidth: 3,
                            belowBarData: BarAreaData(show: false),
                          ),
                          LineChartBarData(
                            spots: humidSpots,
                            isCurved: true,
                            color: Colors.blue,
                            dotData: FlDotData(show: false),
                            barWidth: 3,
                            belowBarData: BarAreaData(show: false),
                          ),
                          LineChartBarData(
                            spots: smokeSpots,
                            isCurved: true,
                            color: Colors.green,
                            dotData: FlDotData(show: false),
                            barWidth: 3,
                            belowBarData: BarAreaData(show: false),
                            dashArray: [5, 5],
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          handleBuiltInTouches: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) {
                              return spots.map((spot) {
                                String label;
                                if (spot.barIndex == 0) {
                                  label =
                                      'Nhiệt độ: ${spot.y.toStringAsFixed(1)}°C';
                                } else if (spot.barIndex == 1) {
                                  label =
                                      'Độ ẩm: ${spot.y.toStringAsFixed(1)}%';
                                } else {
                                  final realSmoke =
                                      ((spot.y / 100) * maxSmoke).round();
                                  label = 'Khói: $realSmoke';
                                }
                                return LineTooltipItem(
                                  label,
                                  const TextStyle(color: Colors.white),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    const SizedBox(height: 20),
                                              Text(
                                                tr("staticscal"),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
        const SizedBox(height: 10),

        // Legend nằm riêng biệt bên dưới, KHÔNG bị scroll
        SizedBox(
          width: chartWidth + 40, // thêm 40 để bù chiều rộng trục Y cố định
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.red, '${tr('temperature')} (°C)'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.blue, '${tr('humidity')} (%)'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.green, tr('smoke_level')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
