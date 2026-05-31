import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  static const navy = Color(0xFF0B1120);
  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);
  static const navyText = Color(0xFF0F172A);

  final searchController = TextEditingController();

  bool isLoading = false;
  List<Map<String, dynamic>> exercises = [];

  String selectedCategory = "All";

  final Map<String, int> categories = {
    "All": 0,
    "Abs": 10,
    "Arms": 8,
    "Back": 12,
    "Calves": 14,
    "Chest": 11,
    "Legs": 9,
    "Shoulders": 13,
  };

  @override
  void initState() {
    super.initState();
    fetchExercises();
  }

  Future<void> fetchExercises() async {
    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      exercises = [];
    });

    final query = searchController.text.trim();
    final categoryId = categories[selectedCategory] ?? 0;

    String url =
        "https://wger.de/api/v2/exercise/?language=2&status=2&limit=40";

    if (categoryId != 0) {
      url += "&category=$categoryId";
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data["results"] ?? [];

        final filtered = results
            .map((item) => Map<String, dynamic>.from(item))
            .where((exercise) {
          final name = exercise["name"]?.toString().toLowerCase() ?? "";
          final description =
              exercise["description"]?.toString().toLowerCase() ?? "";

          if (query.isEmpty) return true;

          return name.contains(query.toLowerCase()) ||
              description.contains(query.toLowerCase());
        }).toList();

        setState(() {
          exercises = filtered;
        });
      } else {
        showMessage("Nu s-au putut incarca exercitiile.");
      }
    } catch (e) {
      showMessage("A aparut o eroare la incarcarea exercitiilor.");
    }

    setState(() {
      isLoading = false;
    });
  }

  String cleanDescription(String html) {
    return html
        .replaceAll(RegExp(r"<[^>]*>"), "")
        .replaceAll("&nbsp;", " ")
        .replaceAll("&amp;", "&")
        .replaceAll("&quot;", "\"")
        .replaceAll("&#39;", "'")
        .trim();
  }

  String getCategoryName(dynamic category) {
    final id = int.tryParse(category.toString()) ?? 0;

    final match = categories.entries.where((entry) => entry.value == id);

    if (match.isEmpty) return "General";

    return match.first.key;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: cardNavy,
        behavior: SnackBarBehavior.floating,
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
        title: const Text("Exercise Library"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Find exercises",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Search exercises by name or filter them by body area.",
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
                onSubmitted: (_) => fetchExercises(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: cardNavy,
                  hintText: "Ex: squat, press, curl",
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white),
                iconEnabledColor: green,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: cardNavy,
                  labelText: "Category",
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.fitness_center, color: green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: categories.keys.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value ?? "All";
                  });

                  fetchExercises();
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: fetchExercises,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: navyText,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
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
              else if (exercises.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardNavy,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    "No exercises found. Try another search.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                )
              else
                Column(
                  children: exercises.map((exercise) {
                    final name = exercise["name"]?.toString() ?? "Exercise";
                    final description = cleanDescription(
                      exercise["description"]?.toString() ?? "",
                    );
                    final category = getCategoryName(exercise["category"]);

                    return _ExerciseCard(
                      name: name,
                      description: description,
                      category: category,
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

class _ExerciseCard extends StatelessWidget {
  final String name;
  final String description;
  final String category;

  const _ExerciseCard({
    required this.name,
    required this.description,
    required this.category,
  });

  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardNavy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: green.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: green,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        color: green,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              description,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            const Text(
              "No instructions available for this exercise.",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 15,
              ),
            ),
          ],
        ],
      ),
    );
  }
}