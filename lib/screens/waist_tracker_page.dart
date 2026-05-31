import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WaistTrackerPage extends StatelessWidget {
  const WaistTrackerPage({super.key});

  static const navy = Color(0xFF0B1120);
  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);
  static const yellow = Color(0xFFFACC15);
  static const red = Color(0xFFF87171);

  List<Map<String, dynamic>> getUserEntries() {
    final settingsBox = Hive.box('settingsBox');
    final dailyEntriesBox = Hive.box('dailyEntriesBox');

    final currentUserEmail = settingsBox.get("currentUserEmail");

    if (currentUserEmail == null) {
      return [];
    }

    final entries = dailyEntriesBox
        .toMap()
        .entries
        .where((entry) {
          final value = entry.value;
          return value is Map && value["userEmail"] == currentUserEmail;
        })
        .map((entry) {
          final data = Map<String, dynamic>.from(entry.value);
          data["_hiveKey"] = entry.key;
          return data;
        })
        .toList();

    entries.sort((a, b) {
      final dateA =
          DateTime.tryParse(a["date"]?.toString() ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dateB =
          DateTime.tryParse(b["date"]?.toString() ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final dateCompare = dateA.compareTo(dateB);

      if (dateCompare != 0) return dateCompare;

      final keyA = int.tryParse(a["_hiveKey"].toString()) ?? 0;
      final keyB = int.tryParse(b["_hiveKey"].toString()) ?? 0;

      return keyA.compareTo(keyB);
    });

    return entries;
  }

  double getDouble(dynamic value) {
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String displayGoalMode(String goalMode) {
    if (goalMode == "Slabit") return "Weight Loss";
    if (goalMode == "Gains") return "Muscle Gain";
    return goalMode;
  }

  Color getTrafficColor(List<Map<String, dynamic>> entries, String goalMode) {
    if (entries.length < 2) {
      return yellow;
    }

    final previous = getDouble(entries[entries.length - 2]["waist"]);
    final current = getDouble(entries.last["waist"]);

    if (current == previous) {
      return yellow;
    }

    if (goalMode == "Slabit") {
      return current < previous ? green : red;
    }

    return current > previous ? green : red;
  }

  String getTrafficText(List<Map<String, dynamic>> entries, String goalMode) {
    if (entries.length < 2) {
      return "Status: waiting for more data. Add at least two waist entries to compare progress.";
    }

    final previous = getDouble(entries[entries.length - 2]["waist"]);
    final current = getDouble(entries.last["waist"]);

    if (current == previous) {
      return "Status: stable. Your waist measurement is the same as your previous entry.";
    }

    if (goalMode == "Slabit") {
      return current < previous
          ? "Status: on track. Your waist measurement is going down, which matches your Weight Loss goal."
          : "Status: attention needed. Your waist measurement increased compared to your previous entry.";
    }

    return current > previous
        ? "Status: on track. Your waist measurement is going up, which matches your Muscle Gain goal."
        : "Status: attention needed. Your waist measurement decreased compared to your previous entry.";
  }

  double getMinY(List<Map<String, dynamic>> entries) {
    final values = entries.map((entry) => getDouble(entry["waist"])).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    return minValue - 2;
  }

  double getMaxY(List<Map<String, dynamic>> entries) {
    final values = entries.map((entry) => getDouble(entry["waist"])).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return maxValue + 2;
  }

  String getLatestWaistText(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) return "--";
    final waist = getDouble(entries.last["waist"]);
    return "${waist.toStringAsFixed(1)} cm";
  }

  String getChangeText(List<Map<String, dynamic>> entries) {
    if (entries.length < 2) return "Not enough data";

    final previous = getDouble(entries[entries.length - 2]["waist"]);
    final current = getDouble(entries.last["waist"]);
    final diff = current - previous;

    if (diff == 0) return "No change";

    final sign = diff > 0 ? "+" : "";
    return "$sign${diff.toStringAsFixed(1)} cm";
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('dailyEntriesBox').listenable(),
      builder: (context, box, child) {
        final settingsBox = Hive.box('settingsBox');
        final goalMode = settingsBox.get("goalMode", defaultValue: "Slabit");
        final entries = getUserEntries();

        if (entries.isEmpty) {
          return Scaffold(
            backgroundColor: navy,
            appBar: AppBar(title: const Text("Waist Tracker")),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: cardNavy,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.straighten_rounded, color: green, size: 58),
                      SizedBox(height: 18),
                      Text(
                        "No waist data yet",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Add your daily data from the Dashboard to start tracking your waist progress.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final lineSpots = entries.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), getDouble(entry.value["waist"]));
        }).toList();

        final trafficColor = getTrafficColor(entries, goalMode);
        final trafficText = getTrafficText(entries, goalMode);
        final latestWaist = getLatestWaistText(entries);
        final changeText = getChangeText(entries);

        return Scaffold(
          backgroundColor: navy,
          appBar: AppBar(title: const Text("Waist Tracker")),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(25, 25, 25, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Waist Progress",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Active goal: ${displayGoalMode(goalMode)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: "Current",
                          value: latestWaist,
                          icon: Icons.straighten_rounded,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SummaryCard(
                          title: "Last Change",
                          value: changeText,
                          icon: Icons.trending_up_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    "Trend",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 280,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardNavy,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: LineChart(
                      LineChartData(
                        minY: getMinY(entries),
                        maxY: getMaxY(entries),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.white.withOpacity(0.08),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 38,
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            color: green,
                            barWidth: 4,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: green.withOpacity(0.15),
                            ),
                            spots: lineSpots,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "Entries",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 280,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardNavy,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: BarChart(
                      BarChartData(
                        minY: getMinY(entries),
                        maxY: getMaxY(entries),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.white.withOpacity(0.08),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 38,
                            ),
                          ),
                        ),
                        barGroups: entries.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: getDouble(entry.value["waist"]),
                                color: green,
                                width: 18,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: cardNavy,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: trafficColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            trafficText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardNavy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: green, size: 30),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
