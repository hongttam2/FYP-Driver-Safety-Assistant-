import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/driving_session.dart';

class SessionBlinkChart extends StatelessWidget {
  final DrivingSession session;

  const SessionBlinkChart({
    Key? key,
    required this.session,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spots = _generateDataPoints();
    
    if (spots['blinks']!.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No data available'),
        ),
      );
    }

    double maxY = 0;
    spots.values.forEach((spotList) {
      if (spotList.isNotEmpty) {
        final listMax = spotList.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
        maxY = maxY > listMax ? maxY : listMax;
      }
    });
    
    final yInterval = _calculateYAxisInterval(spots);
    final xInterval = _calculateXAxisInterval(session.blinkData.length);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: (maxY + yInterval).ceilToDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: yInterval,
                  verticalInterval: xInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                    );
                  },
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      if (touchedBarSpots.isEmpty) return [];
                      final spots = _generateDataPoints();
                      final minute = touchedBarSpots.first.x.toInt(); // Use first spot’s x for consistency
                      final fullTooltipText = _getTooltipText(minute, spots); // Get combined text for display
                      
                    
                      final tooltipLines = fullTooltipText.split('\n');
                      return touchedBarSpots.map((spot) {
                        Color textColor;
                        String text;
                        switch (spot.barIndex) {
                          case 0: // Blinks
                            text = tooltipLines[0];
                            textColor = Colors.blue;
                            break;
                          case 1: // Phone Checks
                            text = tooltipLines[1]; 
                            textColor = Colors.red;
                            break;
                          case 2: // Long Blinks
                            text = tooltipLines[2]; 
                            textColor = Colors.orange;
                            break;
                          default:
                            text = 'Unknown: ${spot.y}';
                            textColor = Colors.white;
                        }
                        return LineTooltipItem(
                          text,
                          TextStyle(
                            color: textColor,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                  touchSpotThreshold: 30,
                ),
                titlesData: _getTitlesData(),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                lineBarsData: [
                  _createLineChartBarData(
                    spots: spots['blinks']!,
                    color: Colors.blue,
                    label: 'Blinks',
                  ),
                  _createLineChartBarData(
                    spots: spots['phoneChecks']!,
                    color: Colors.red,
                    label: 'Phone Checks',
                  ),
                  _createLineChartBarData(
                    spots: spots['longBlinks']!,
                    color: Colors.orange,
                    label: 'Long Blinks',
                  ),
                ],
              ),
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Blinks', Colors.blue),
              const SizedBox(width: 16),
              _buildLegendItem('Phone Checks', Colors.red),
              const SizedBox(width: 16),
              _buildLegendItem('Long Blinks', Colors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  String _getTooltipText(int minute, Map<String, List<FlSpot>> spots) {
    final blinkRate = spots['blinks']![minute].y.toStringAsFixed(1);
    final phoneChecks = spots['phoneChecks']![minute].y.toInt().toString();
    final longBlinks = spots['longBlinks']![minute].y.toInt().toString();
    
    return 'Blinks / Min: $blinkRate\nPhone Checks: $phoneChecks\nLong Blinks: $longBlinks';
  }

  LineChartBarData _createLineChartBarData({
    required List<FlSpot> spots,
    required Color color,
    required String label,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          if (index % _calculateXAxisInterval(session.blinkData.length).toInt() == 0) {
            return FlDotCirclePainter(
              radius: 4,
              color: color,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          }
          return FlDotCirclePainter(
            radius: 0,
            color: Colors.transparent,
            strokeWidth: 0,
            strokeColor: Colors.transparent,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withAlpha(50),
      ),
    );
  }

  Map<String, List<FlSpot>> _generateDataPoints() {
    final blinksSpots = <FlSpot>[];
    final phoneChecksSpots = <FlSpot>[];
    final longBlinksSpots = <FlSpot>[];

    session.blinkData.asMap().forEach((index, data) {
      blinksSpots.add(FlSpot(
        index.toDouble(),
        data.blinksPerMinute,
      ));
      phoneChecksSpots.add(FlSpot(
        index.toDouble(),
        data.phoneChecksInMinute.toDouble(),
      ));
      longBlinksSpots.add(FlSpot(
        index.toDouble(),
        data.longBlinksInMinute.toDouble(),
      ));
    });

    return {
      'blinks': blinksSpots,
      'phoneChecks': phoneChecksSpots,
      'longBlinks': longBlinksSpots,
    };
  }

  FlTitlesData _getTitlesData() {
    final sessionDurationMinutes = session.blinkData.length;
    final xInterval = _calculateXAxisInterval(sessionDurationMinutes);
    //final yInterval = _calculateYAxisInterval(_generateDataPoints());

    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 5.0,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            if (value % 5 != 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                value.toInt().toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: xInterval,
          getTitlesWidget: (value, meta) {
            if (value % xInterval != 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${value.toInt()}m',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  double _calculateXAxisInterval(int totalMinutes) {
    if (totalMinutes <= 10) return 1;
    if (totalMinutes <= 30) return 2;
    if (totalMinutes <= 60) return 5;
    if (totalMinutes <= 120) return 10;
    return 15;
  }

  double _calculateYAxisInterval(Map<String, List<FlSpot>> spots) {
    double maxY = 0;
    spots.values.forEach((spotList) {
      if (spotList.isNotEmpty) {
        final listMax = spotList.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
        maxY = maxY > listMax ? maxY : listMax;
      }
    });

    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    if (maxY <= 30) return 5;
    if (maxY <= 50) return 10;
    return 15;
  }
}