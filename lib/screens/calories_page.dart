import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CaloriesPage extends StatelessWidget {
  const CaloriesPage({super.key});

  static const navy = Color(0xFF0B1120);
  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);

  Map<String, dynamic>? getLastEntry() {
    final settingsBox = Hive.box('settingsBox');
    final dailyEntriesBox = Hive.box('dailyEntriesBox');

    final currentUserEmail = settingsBox.get("currentUserEmail");

    if (currentUserEmail == null) return null;

    final entries = dailyEntriesBox.toMap().entries
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

    if (entries.isEmpty) return null;

    entries.sort((a, b) {
      final dateA = DateTime.tryParse(a["date"]?.toString() ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse(b["date"]?.toString() ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final dateCompare = dateB.compareTo(dateA);

      if (dateCompare != 0) return dateCompare;

      final keyA = int.tryParse(a["_hiveKey"].toString()) ?? 0;
      final keyB = int.tryParse(b["_hiveKey"].toString()) ?? 0;

      return keyB.compareTo(keyA);
    });

    return entries.first;
  }

  double getDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('dailyEntriesBox').listenable(),
      builder: (context, box, child) {
        final lastEntry = getLastEntry();

        if (lastEntry == null) {
          return Scaffold(
            backgroundColor: navy,
            appBar: AppBar(
              title: const Text("Calories"),
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Text(
                  "No calorie data saved yet. Add your daily data from the Dashboard.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          );
        }

        final breakfast = getDouble(lastEntry["breakfast"]);
        final lunch = getDouble(lastEntry["lunch"]);
        final dinner = getDouble(lastEntry["dinner"]);
        final snacks = getDouble(lastEntry["snacks"]);
        final totalCalories = getDouble(lastEntry["totalCalories"]);
        final hasCalories = totalCalories > 0;

        return Scaffold(
          backgroundColor: navy,
          appBar: AppBar(
            title: const Text("Calories"),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(25, 25, 25, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Calorie Tracker",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Latest entry: ${totalCalories.round()} kcal",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 35),
                  SizedBox(
                    height: 300,
                    child: hasCalories
                        ? PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 60,
                              sections: [
                                PieChartSectionData(
                                  value: breakfast,
                                  color: const Color(0xFF4ADE80),
                                  title: "B",
                                  radius: 76,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: lunch,
                                  color: const Color(0xFF60A5FA),
                                  title: "L",
                                  radius: 76,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: dinner,
                                  color: const Color(0xFFFACC15),
                                  title: "D",
                                  radius: 76,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: snacks,
                                  color: const Color(0xFFF87171),
                                  title: "S",
                                  radius: 76,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Center(
                            child: Text(
                              "No calories logged for this entry.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: cardNavy,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      children: [
                        _MealRow(
                          title: "Breakfast",
                          calories: breakfast.round(),
                          color: const Color(0xFF4ADE80),
                        ),
                        const Divider(color: Colors.white12),
                        _MealRow(
                          title: "Lunch",
                          calories: lunch.round(),
                          color: const Color(0xFF60A5FA),
                        ),
                        const Divider(color: Colors.white12),
                        _MealRow(
                          title: "Dinner",
                          calories: dinner.round(),
                          color: const Color(0xFFFACC15),
                        ),
                        const Divider(color: Colors.white12),
                        _MealRow(
                          title: "Snacks",
                          calories: snacks.round(),
                          color: const Color(0xFFF87171),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${totalCalories.round()} kcal",
                              style: const TextStyle(
                                color: green,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

class _MealRow extends StatelessWidget {
  final String title;
  final int calories;
  final Color color;

  const _MealRow({
    required this.title,
    required this.calories,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: color,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
              ),
            ),
          ),
          Text(
            "$calories kcal",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}