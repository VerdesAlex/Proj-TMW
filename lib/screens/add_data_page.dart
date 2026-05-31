import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AddDataPage extends StatefulWidget {
  const AddDataPage({super.key});

  @override
  State<AddDataPage> createState() => _AddDataPageState();
}

class _AddDataPageState extends State<AddDataPage> {
  final formKey = GlobalKey<FormState>();

  static const navy = Color(0xFF0B1120);
  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);
  static const navyText = Color(0xFF0F172A);

  final weightController = TextEditingController();
  final waistController = TextEditingController();
  final breakfastController = TextEditingController();
  final lunchController = TextEditingController();
  final dinnerController = TextEditingController();
  final snacksController = TextEditingController();

  bool submitted = false;

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

  double? parseValue(String value) {
    return double.tryParse(value.trim().replaceAll(",", "."));
  }

  String? validateNumber(
    String? value,
    String fieldName,
    double min,
    double max,
  ) {
    final text = value?.trim() ?? "";

    if (text.isEmpty) return "$fieldName is required.";

    final number = parseValue(text);

    if (number == null) return "$fieldName must be a valid number.";
    if (number < min || number > max) {
      return "$fieldName must be between ${min.toStringAsFixed(0)} and ${max.toStringAsFixed(0)}.";
    }

    return null;
  }

  Future<void> saveDailyEntry() async {
    FocusScope.of(context).unfocus();

    setState(() {
      submitted = true;
    });

    if (!(formKey.currentState?.validate() ?? false)) return;

    final settingsBox = Hive.box('settingsBox');
    final dailyEntriesBox = Hive.box('dailyEntriesBox');
    final currentUserEmail = settingsBox.get("currentUserEmail");

    if (currentUserEmail == null) {
      showMessage("No authenticated user found.");
      return;
    }

    final weight = parseValue(weightController.text)!;
    final waist = parseValue(waistController.text)!;
    final breakfast = parseValue(breakfastController.text)!;
    final lunch = parseValue(lunchController.text)!;
    final dinner = parseValue(dinnerController.text)!;
    final snacks = parseValue(snacksController.text)!;

    final totalCalories = breakfast + lunch + dinner + snacks;

    final entry = {
      "userEmail": currentUserEmail,
      "date": DateTime.now().toIso8601String(),
      "weight": weight,
      "waist": waist,
      "breakfast": breakfast,
      "lunch": lunch,
      "dinner": dinner,
      "snacks": snacks,
      "totalCalories": totalCalories,
    };

    await dailyEntriesBox.add(entry);

    if (!mounted) return;

    showMessage("Daily data saved successfully.");
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    weightController.dispose();
    waistController.dispose();
    breakfastController.dispose();
    lunchController.dispose();
    dinnerController.dispose();
    snacksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        title: const Text("Daily Data"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 110),
          child: Form(
            key: formKey,
            autovalidateMode: submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Log Today’s Progress",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Add your weight, waist measurement and meal calories for today.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardNavy,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.monitor_weight_rounded,
                            color: green,
                            size: 30,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Body Measurements",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _InputField(
                        controller: weightController,
                        label: "Weight",
                        hint: "Ex: 72.5",
                        icon: Icons.monitor_weight_rounded,
                        suffix: "kg",
                        validator: (value) =>
                            validateNumber(value, "Weight", 30, 250),
                      ),
                      const SizedBox(height: 18),
                      _InputField(
                        controller: waistController,
                        label: "Waist",
                        hint: "Ex: 82",
                        icon: Icons.straighten_rounded,
                        suffix: "cm",
                        validator: (value) =>
                            validateNumber(value, "Waist", 40, 180),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardNavy,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.restaurant_menu_rounded,
                            color: green,
                            size: 30,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Meal Calories",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _InputField(
                        controller: breakfastController,
                        label: "Breakfast",
                        hint: "Ex: 450",
                        icon: Icons.free_breakfast_rounded,
                        suffix: "kcal",
                        validator: (value) =>
                            validateNumber(value, "Breakfast", 0, 3000),
                      ),
                      const SizedBox(height: 18),
                      _InputField(
                        controller: lunchController,
                        label: "Lunch",
                        hint: "Ex: 700",
                        icon: Icons.lunch_dining_rounded,
                        suffix: "kcal",
                        validator: (value) =>
                            validateNumber(value, "Lunch", 0, 3000),
                      ),
                      const SizedBox(height: 18),
                      _InputField(
                        controller: dinnerController,
                        label: "Dinner",
                        hint: "Ex: 600",
                        icon: Icons.dinner_dining_rounded,
                        suffix: "kcal",
                        validator: (value) =>
                            validateNumber(value, "Dinner", 0, 3000),
                      ),
                      const SizedBox(height: 18),
                      _InputField(
                        controller: snacksController,
                        label: "Snacks",
                        hint: "Ex: 250",
                        icon: Icons.cookie_rounded,
                        suffix: "kcal",
                        validator: (value) =>
                            validateNumber(value, "Snacks", 0, 3000),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: saveDailyEntry,
                    icon: const Icon(Icons.check_circle_rounded),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: navyText,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    label: const Text(
                      "Save Daily Data",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String suffix;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.suffix,
    required this.validator,
  });

  static const navy = Color(0xFF0B1120);
  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      cursorColor: green,
      decoration: InputDecoration(
        filled: true,
        fillColor: navy,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(
          icon,
          color: green,
        ),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: Colors.white70),
        errorStyle: const TextStyle(
          color: Color(0xFFFCA5A5),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: green, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
        ),
      ),
    );
  }
}