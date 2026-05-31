import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'meal_details_page.dart';

class MealSuggestionsPage extends StatefulWidget {
  const MealSuggestionsPage({super.key});

  @override
  State<MealSuggestionsPage> createState() => _MealSuggestionsPageState();
}

class _MealSuggestionsPageState extends State<MealSuggestionsPage> {
  static const navy = Color(0xFF0B1120);
  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);
  static const navyText = Color(0xFF0F172A);

  String selectedMealType = "Breakfast";
  String selectedIngredient = "chicken";
  bool isLoading = false;
  List<dynamic> meals = [];

  final Map<String, String> ingredients = {
    "Chicken": "chicken",
    "Eggs": "egg",
    "Rice": "rice",
    "Oats": "oats",
    "Salmon": "salmon",
    "Beef": "beef",
    "Potatoes": "potato",
    "Avocado": "avocado",
  };

  Future<void> fetchMeals() async {
    setState(() {
      isLoading = true;
      meals = [];
    });

    final url = Uri.parse(
      "https://www.themealdb.com/api/json/v1/1/filter.php?i=$selectedIngredient",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          meals = data["meals"] ?? [];
        });
      }
    } catch (e) {
      setState(() {
        meals = [];
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  String getGoalMode() {
    final settingsBox = Hive.box('settingsBox');
    return settingsBox.get("goalMode", defaultValue: "Slabit");
  }

  String displayGoalMode(String goalMode) {
    if (goalMode == "Slabit") return "Weight Loss";
    if (goalMode == "Gains") return "Muscle Gain";
    return goalMode;
  }

  String getRecommendationText(String goalMode) {
    if (goalMode == "Slabit") {
      return "For Weight Loss, choose lighter meals with high protein and moderate portions.";
    }

    return "For Muscle Gain, choose more filling meals with protein, healthy carbs and enough calories.";
  }

  @override
  Widget build(BuildContext context) {
    final goalMode = getGoalMode();

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        title: const Text("Meal Suggestions"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Healthy meal ideas",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Active goal: ${displayGoalMode(goalMode)}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
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
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: green.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: green,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        getRecommendationText(goalMode),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              _DropdownBox(
                label: "Meal type",
                value: selectedMealType,
                items: const ["Breakfast", "Lunch", "Dinner", "Snack"],
                onChanged: (value) {
                  setState(() {
                    selectedMealType = value!;
                  });
                },
              ),
              const SizedBox(height: 18),
              _DropdownBox(
                label: "Main ingredient",
                value: ingredients.entries
                    .firstWhere((entry) => entry.value == selectedIngredient)
                    .key,
                items: ingredients.keys.toList(),
                onChanged: (value) {
                  setState(() {
                    selectedIngredient = ingredients[value]!;
                  });
                },
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: fetchMeals,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: navyText,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  label: const Text(
                    "Generate Suggestions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: green,
                  ),
                )
              else if (meals.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardNavy,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    "Choose an ingredient and tap Generate Suggestions.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                )
              else
                Column(
                  children: meals.take(8).map((meal) {
                    return _MealCard(
                      title: meal["strMeal"] ?? "Recommended Meal",
                      imageUrl: meal["strMealThumb"] ?? "",
                      mealType: selectedMealType,
                      mealId: meal["idMeal"]?.toString() ?? "",
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownBox extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownBox({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF0F172A),
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: green,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.tune_rounded, color: green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _MealCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String mealType;
  final String mealId;

  const _MealCard({
    required this.title,
    required this.imageUrl,
    required this.mealType,
    required this.mealId,
  });

  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MealDetailsPage(
              title: title,
              imageUrl: imageUrl,
              mealType: mealType,
              mealId: mealId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: cardNavy,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(24),
              ),
              child: Image.network(
                imageUrl,
                width: 112,
                height: 112,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 112,
                    height: 112,
                    color: const Color(0xFF0F172A),
                    child: const Icon(
                      Icons.restaurant,
                      color: green,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealType,
                      style: const TextStyle(
                        color: green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Text(
                          "View nutrition details",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white54,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}