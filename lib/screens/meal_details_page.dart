import 'dart:convert';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

class MealDetailsPage extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String mealType;
  final String? mealId;

  const MealDetailsPage({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.mealType,
    this.mealId,
  });

  @override
  State<MealDetailsPage> createState() => _MealDetailsPageState();
}

class _MealDetailsPageState extends State<MealDetailsPage> {
  static const navy = Color(0xFF0B1120);
  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);
  static const navyText = Color(0xFF0F172A);
  static const orange = Color(0xFFF97316);
  static const red = Color(0xFFEF4444);

  bool isLoading = false;
  Map<String, dynamic>? mealDetails;

  @override
  void initState() {
    super.initState();
    fetchMealDetails();
  }

  Future<void> fetchMealDetails() async {
    if (widget.mealId == null || widget.mealId!.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
      "https://www.themealdb.com/api/json/v1/1/lookup.php?i=${widget.mealId}",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data["meals"] ?? [];

        if (meals.isNotEmpty) {
          setState(() {
            mealDetails = Map<String, dynamic>.from(meals.first);
          });
        }
      }
    } catch (e) {
      mealDetails = null;
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  String displayGoalMode(String goalMode) {
    if (goalMode == "Slabit") return "Weight Loss";
    if (goalMode == "Gains") return "Muscle Gain";
    return goalMode;
  }

  int getEstimatedCalories(String goalMode) {
    final random = Random(widget.title.hashCode);

    if (goalMode == "Slabit") {
      return 350 + random.nextInt(201);
    }

    return 650 + random.nextInt(251);
  }

  double getProtein(int calories) {
    return calories * 0.32 / 4;
  }

  double getCarbs(int calories, String goalMode) {
    if (goalMode == "Slabit") {
      return calories * 0.28 / 4;
    }

    return calories * 0.42 / 4;
  }

  double getFat(int calories, String goalMode) {
    if (goalMode == "Slabit") {
      return calories * 0.40 / 9;
    }

    return calories * 0.26 / 9;
  }

  List<String> getIngredients() {
    if (mealDetails == null) {
      return [
        "Main protein",
        "Fresh vegetables",
        "Balanced carbs",
        "Light seasoning",
        "Healthy fats",
      ];
    }

    final ingredients = <String>[];

    for (int i = 1; i <= 20; i++) {
      final ingredient =
          mealDetails!["strIngredient$i"]?.toString().trim() ?? "";
      final measure = mealDetails!["strMeasure$i"]?.toString().trim() ?? "";

      if (ingredient.isNotEmpty) {
        if (measure.isNotEmpty) {
          ingredients.add("$measure - $ingredient");
        } else {
          ingredients.add(ingredient);
        }
      }
    }

    if (ingredients.isEmpty) {
      return [
        "Main protein",
        "Fresh vegetables",
        "Balanced carbs",
        "Light seasoning",
        "Healthy fats",
      ];
    }

    return ingredients;
  }

  String getInstructions(String goalMode) {
    final apiInstructions =
        mealDetails?["strInstructions"]?.toString().trim() ?? "";

    if (apiInstructions.isNotEmpty) {
      return apiInstructions;
    }

    if (goalMode == "Slabit") {
      return "Prepare this meal with a small amount of oil, keep portions moderate, and add vegetables for volume and satiety.";
    }

    return "Prepare this meal in a larger portion, add a good source of carbohydrates, and complete it with enough protein.";
  }

  int getMacroPercent(double value, double total) {
    if (total <= 0) return 0;
    return ((value / total) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settingsBox');
    final goalMode = settingsBox.get("goalMode", defaultValue: "Slabit");
    final calories = getEstimatedCalories(goalMode);
    final protein = getProtein(calories);
    final carbs = getCarbs(calories, goalMode);
    final fat = getFat(calories, goalMode);
    final totalMacros = protein + carbs + fat;
    final proteinPercent = getMacroPercent(protein, totalMacros);
    final carbsPercent = getMacroPercent(carbs, totalMacros);
    final fatPercent = getMacroPercent(fat, totalMacros);
    final ingredients = getIngredients();

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        title: const Text("Recipe Details"),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: green),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(25, 25, 25, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.network(
                        widget.imageUrl,
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 240,
                            color: cardNavy,
                            child: const Icon(
                              Icons.restaurant,
                              color: green,
                              size: 70,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${widget.mealType} • ${displayGoalMode(goalMode)}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 25),
                    _QuickStatsCard(
                      calories: calories,
                      protein: protein,
                      carbs: carbs,
                      fat: fat,
                    ),
                    const SizedBox(height: 25),
                    _SectionCard(
                      title: "Preparation Instructions",
                      child: Text(
                        getInstructions(goalMode),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    _SectionCard(
                      title: "Ingredients",
                      child: Column(
                        children: ingredients.map((ingredient) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "• ",
                                  style: TextStyle(
                                    color: green,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    ingredient,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 25),
                    _SectionCard(
                      title: "Macronutrient Distribution",
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 0,
                                sections: [
                                  PieChartSectionData(
                                    value: protein,
                                    title: "",
                                    color: green,
                                    radius: 58,
                                  ),
                                  PieChartSectionData(
                                    value: carbs,
                                    title: "",
                                    color: red,
                                    radius: 58,
                                  ),
                                  PieChartSectionData(
                                    value: fat,
                                    title: "",
                                    color: orange,
                                    radius: 58,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _MacroLegend(
                                  color: green,
                                  label: "Protein",
                                  percent: proteinPercent,
                                  value: protein,
                                ),
                                const SizedBox(height: 10),
                                _MacroLegend(
                                  color: red,
                                  label: "Carbs",
                                  percent: carbsPercent,
                                  value: carbs,
                                ),
                                const SizedBox(height: 10),
                                _MacroLegend(
                                  color: orange,
                                  label: "Fat",
                                  percent: fatPercent,
                                  value: fat,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    _SectionCard(
                      title: "Estimated Nutrition Facts",
                      child: Column(
                        children: [
                          _NutritionRow("Calories", "$calories kcal"),
                          _NutritionRow(
                            "Protein",
                            "${protein.toStringAsFixed(1)} g",
                          ),
                          _NutritionRow(
                            "Carbs",
                            "${carbs.toStringAsFixed(1)} g",
                          ),
                          _NutritionRow(
                            "Fat",
                            "${fat.toStringAsFixed(1)} g",
                          ),
                          _NutritionRow(
                            "Fiber",
                            "${(carbs * 0.12).toStringAsFixed(1)} g",
                          ),
                          _NutritionRow(
                            "Sugars",
                            "${(carbs * 0.20).toStringAsFixed(1)} g",
                          ),
                          _NutritionRow(
                            "Salt",
                            "${(calories * 0.002).toStringAsFixed(2)} g",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _QuickStatsCard extends StatelessWidget {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const _QuickStatsCard({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  static const green = Color(0xFF4ADE80);
  static const navyText = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: navyText,
                size: 34,
              ),
              const SizedBox(width: 14),
              Text(
                "$calories kcal estimate",
                style: const TextStyle(
                  color: navyText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _QuickStatItem(
                  label: "Protein",
                  value: "${protein.toStringAsFixed(1)}g",
                ),
              ),
              Expanded(
                child: _QuickStatItem(
                  label: "Carbs",
                  value: "${carbs.toStringAsFixed(1)}g",
                ),
              ),
              Expanded(
                child: _QuickStatItem(
                  label: "Fat",
                  value: "${fat.toStringAsFixed(1)}g",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStatItem extends StatelessWidget {
  final String label;
  final String value;

  const _QuickStatItem({
    required this.label,
    required this.value,
  });

  static const navyText = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: navyText,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: navyText,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  static const cardNavy = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardNavy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MacroLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int percent;
  final double value;

  const _MacroLegend({
    required this.color,
    required this.label,
    required this.percent,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "$label: $percent% (${value.toStringAsFixed(1)}g)",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final String value;

  const _NutritionRow(this.label, this.value);

  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: green,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}