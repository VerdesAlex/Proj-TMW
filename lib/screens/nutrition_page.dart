import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NutritionPage extends StatefulWidget {
  final String? initialQuery;

  const NutritionPage({
    super.key,
    this.initialQuery,
  });

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  static const navy = Color(0xFF0B1120);
  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);
  static const navyText = Color(0xFF0F172A);

  final searchController = TextEditingController();

  bool isLoading = false;
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      searchController.text = widget.initialQuery!.trim();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        searchNutrition();
      });
    }
  }

  String normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll("ă", "a")
        .replaceAll("â", "a")
        .replaceAll("î", "i")
        .replaceAll("ș", "s")
        .replaceAll("ş", "s")
        .replaceAll("ț", "t")
        .replaceAll("ţ", "t");
  }

  String translateFood(String query) {
    final normalized = normalizeText(query);

    final foodMap = {
      "pui": "chicken",
      "piept de pui": "chicken breast",
      "carne de pui": "chicken",
      "ou": "egg",
      "oua": "egg",
      "orez": "rice",
      "orez brun": "brown rice",
      "ovaz": "oats",
      "fulgi de ovaz": "oats",
      "somon": "salmon",
      "vita": "beef",
      "carne de vita": "beef",
      "cartof": "potato",
      "cartofi": "potato",
      "cartofi dulci": "sweet potato",
      "avocado": "avocado",
      "iaurt": "yogurt",
      "iaurt grecesc": "greek yogurt",
      "lapte": "milk",
      "branza": "cheese",
      "branza cottage": "cottage cheese",
      "cascaval": "cheese",
      "mar": "apple",
      "mere": "apple",
      "banana": "banana",
      "banane": "banana",
      "paine": "bread",
      "paine integrala": "whole wheat bread",
      "ton": "tuna",
      "paste": "pasta",
      "paste integrale": "whole wheat pasta",
      "rosie": "tomato",
      "rosii": "tomato",
      "castravete": "cucumber",
      "castraveti": "cucumber",
      "morcov": "carrot",
      "morcovi": "carrot",
      "salata": "lettuce",
      "spanac": "spinach",
      "broccoli": "broccoli",
      "mazare": "peas",
      "fasole": "beans",
      "linte": "lentils",
      "naut": "chickpeas",
      "migdale": "almonds",
      "nuci": "walnuts",
      "arahide": "peanuts",
      "unt de arahide": "peanut butter",
      "ulei de masline": "olive oil",
      "miere": "honey",
      "ciocolata": "chocolate",
      "cafea": "coffee",
      "ceai": "tea",
    };

    return foodMap[normalized] ?? normalized;
  }

  Future<void> searchNutrition() async {
    final rawQuery = searchController.text.trim();

    if (rawQuery.isEmpty) {
      showMessage("Please enter a food name.");
      return;
    }

    if (rawQuery.length < 2) {
      showMessage("Search term must have at least 2 characters.");
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      products = [];
    });

    final query = translateFood(rawQuery);
    final encodedQuery = Uri.encodeComponent(query);

    final url = Uri.parse(
      "https://world.openfoodfacts.org/cgi/search.pl?search_terms=$encodedQuery&search_simple=1&action=process&json=1&page_size=20",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data["products"] ?? [];

        final filteredProducts = results
            .where((product) {
              final nutriments = product["nutriments"];
              return nutriments != null &&
                  (nutriments["energy-kcal_100g"] != null ||
                      nutriments["proteins_100g"] != null ||
                      nutriments["carbohydrates_100g"] != null ||
                      nutriments["fat_100g"] != null);
            })
            .map((product) => Map<String, dynamic>.from(product))
            .toList();

        setState(() {
          products = filteredProducts;
        });

        if (filteredProducts.isEmpty) {
          showMessage("No nutrition results found.");
        }
      } else {
        showMessage("Could not load nutrition data.");
      }
    } catch (e) {
      showMessage("Something went wrong while searching.");
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  String getProductName(Map<String, dynamic> product) {
    final name = product["product_name"]?.toString() ?? "";
    final brands = product["brands"]?.toString() ?? "";

    if (name.isNotEmpty) return name;
    if (brands.isNotEmpty) return brands;

    return "Unnamed product";
  }

  String getProductImage(Map<String, dynamic> product) {
    return product["image_front_small_url"]?.toString() ??
        product["image_url"]?.toString() ??
        "";
  }

  double getNutriment(Map<String, dynamic> product, String key) {
    final nutriments = product["nutriments"];

    if (nutriments == null) return 0.0;

    final value = nutriments[key];

    if (value == null) return 0.0;

    return double.tryParse(value.toString()) ?? 0.0;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: cardNavy,
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        margin: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: green, width: 1),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        title: const Text("Nutrition Search"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Find nutrition facts",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Search for a food and check calories, protein, carbs and fat per 100g.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => searchNutrition(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: cardNavy,
                  hintText: "Ex: chicken, oats, yogurt, banana",
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: green),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              products = [];
                            });
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white54,
                          ),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: searchNutrition,
                  icon: const Icon(Icons.manage_search_rounded),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: navyText,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  label: const Text(
                    "Search",
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
                  child: CircularProgressIndicator(color: green),
                )
              else if (products.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardNavy,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        color: green,
                        size: 34,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "Search for a food to see nutrition information.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: products.take(10).map((product) {
                    final name = getProductName(product);
                    final imageUrl = getProductImage(product);
                    final calories =
                        getNutriment(product, "energy-kcal_100g");
                    final protein = getNutriment(product, "proteins_100g");
                    final carbs =
                        getNutriment(product, "carbohydrates_100g");
                    final fat = getNutriment(product, "fat_100g");

                    return _NutritionCard(
                      name: name,
                      imageUrl: imageUrl,
                      calories: calories,
                      protein: protein,
                      carbs: carbs,
                      fat: fat,
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

class _NutritionCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const _NutritionCard({
    required this.name,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardNavy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: imageUrl.isEmpty
                ? Container(
                    width: 86,
                    height: 86,
                    color: const Color(0xFF0F172A),
                    child: const Icon(
                      Icons.restaurant,
                      color: green,
                      size: 36,
                    ),
                  )
                : Image.network(
                    imageUrl,
                    width: 86,
                    height: 86,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 86,
                        height: 86,
                        color: const Color(0xFF0F172A),
                        child: const Icon(
                          Icons.restaurant,
                          color: green,
                          size: 36,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Values per 100g",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _NutritionMiniValue(
                      label: "Kcal",
                      value: calories.toStringAsFixed(0),
                    ),
                    _NutritionMiniValue(
                      label: "Protein",
                      value: "${protein.toStringAsFixed(1)}g",
                    ),
                    _NutritionMiniValue(
                      label: "Carbs",
                      value: "${carbs.toStringAsFixed(1)}g",
                    ),
                    _NutritionMiniValue(
                      label: "Fat",
                      value: "${fat.toStringAsFixed(1)}g",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionMiniValue extends StatelessWidget {
  final String label;
  final String value;

  const _NutritionMiniValue({
    required this.label,
    required this.value,
  });

  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: green,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}