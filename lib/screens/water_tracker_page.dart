import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WaterTrackerPage extends StatefulWidget {
  const WaterTrackerPage({super.key});

  @override
  State<WaterTrackerPage> createState() => _WaterTrackerPageState();
}

class _WaterTrackerPageState extends State<WaterTrackerPage> {
  static const navy = Color(0xFF0B1120);
  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);
  static const navyText = Color(0xFF0F172A);

  int waterMl = 0;
  int goalMl = 2000;

  final goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadWaterData();
  }

  String getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";
  }

  String getCurrentUserEmail() {
    final settingsBox = Hive.box('settingsBox');
    return settingsBox.get("currentUserEmail", defaultValue: "");
  }

  String getWaterKey() {
    return "${getCurrentUserEmail()}_${getTodayKey()}";
  }

  String getGoalKey() {
    return "${getCurrentUserEmail()}_waterGoal";
  }

  void loadWaterData() {
    final waterBox = Hive.box('waterBox');

    final savedWater = waterBox.get(getWaterKey(), defaultValue: 0);
    final savedGoal = waterBox.get(getGoalKey(), defaultValue: 2000);

    setState(() {
      waterMl = int.tryParse(savedWater.toString()) ?? 0;
      goalMl = int.tryParse(savedGoal.toString()) ?? 2000;
      goalController.text = goalMl.toString();
    });
  }

  Future<void> saveWaterData() async {
    final waterBox = Hive.box('waterBox');

    await waterBox.put(getWaterKey(), waterMl);
    await waterBox.put(getGoalKey(), goalMl);
  }

  Future<void> addWater(int amount) async {
    setState(() {
      waterMl += amount;

      if (waterMl < 0) {
        waterMl = 0;
      }
    });

    await saveWaterData();
  }

  Future<void> resetWater() async {
    setState(() {
      waterMl = 0;
    });

    await saveWaterData();
    showMessage("Water intake reset.");
  }

  Future<void> saveGoal() async {
    final value = int.tryParse(goalController.text.trim());

    if (value == null) {
      showMessage("Please enter a valid water goal.");
      return;
    }

    if (value < 500 || value > 6000) {
      showMessage("Water goal must be between 500 ml and 6000 ml.");
      return;
    }

    setState(() {
      goalMl = value;
    });

    await saveWaterData();

    if (!mounted) return;

    Navigator.pop(context);
    showMessage("Water goal saved.");
  }

  void openGoalDialog() {
    goalController.text = goalMl.toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: cardNavy,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: SizedBox(
                  width: 46,
                  height: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                "Set Water Goal",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Choose your daily hydration target.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: goalController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: navy,
                  labelText: "Daily goal",
                  hintText: "Ex: 2500",
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white38),
                  suffixText: "ml",
                  suffixStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.water_drop, color: green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: navyText,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Save Goal",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
    goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = goalMl <= 0 ? 0.0 : (waterMl / goalMl).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final remaining = goalMl - waterMl;

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        title: const Text("Water Tracker"),
        actions: [
          IconButton(
            onPressed: openGoalDialog,
            icon: const Icon(Icons.settings_rounded, color: green),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Daily Hydration",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Track how close you are to your daily water goal.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: cardNavy,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 190,
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 190,
                            height: 190,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 16,
                              backgroundColor: Colors.white12,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(green),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.water_drop_rounded,
                                color: green,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "$percent%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "completed",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      "$waterMl ml",
                      style: const TextStyle(
                        color: green,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "of $goalMl ml",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      remaining <= 0
                          ? "Great job! You reached today’s goal."
                          : "${remaining} ml left to reach your goal.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _WaterButton(
                      label: "-250 ml",
                      icon: Icons.remove_rounded,
                      onTap: () => addWater(-250),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _WaterButton(
                      label: "+250 ml",
                      icon: Icons.add_rounded,
                      onTap: () => addWater(250),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _WaterButton(
                      label: "+500 ml",
                      icon: Icons.local_drink_rounded,
                      onTap: () => addWater(500),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _WaterButton(
                      label: "Reset",
                      icon: Icons.restart_alt_rounded,
                      onTap: resetWater,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardNavy,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: green,
                      size: 28,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "Tip: good hydration supports energy, digestion and workout performance.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.45,
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
  }
}

class _WaterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _WaterButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);
  static const navyText = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final isPrimary = label.contains("+");

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isPrimary ? green : cardNavy,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isPrimary ? green : Colors.white12,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isPrimary ? navyText : green,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? navyText : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}