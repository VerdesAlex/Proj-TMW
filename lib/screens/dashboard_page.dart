import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'add_data_page.dart';
import 'kg_tracker_page.dart';
import 'waist_tracker_page.dart';
import 'calories_page.dart';
import 'meal_suggestions_page.dart';
import 'profile_page.dart';
import 'shopping_lists_page.dart';
import 'nutrition_page.dart';
import 'water_tracker_page.dart';

class DashboardPage extends StatefulWidget {
  final String goalMode;

  const DashboardPage({super.key, required this.goalMode});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const navy = Color(0xFF0B1120);
  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);
  static const navyText = Color(0xFF0F172A);

  int selectedIndex = 0;

  Map<String, dynamic>? getCurrentUser() {
    final usersBox = Hive.box('usersBox');
    final settingsBox = Hive.box('settingsBox');
    final email = settingsBox.get("currentUserEmail");

    if (email == null || !usersBox.containsKey(email)) return null;

    return Map<String, dynamic>.from(usersBox.get(email));
  }

  Map<String, dynamic>? getLastEntry() {
    final settingsBox = Hive.box('settingsBox');
    final dailyEntriesBox = Hive.box('dailyEntriesBox');
    final currentUserEmail = settingsBox.get("currentUserEmail");

    if (currentUserEmail == null) return null;

    final entries = dailyEntriesBox.toMap().entries.where((entry) {
      final value = entry.value;
      return value is Map && value["userEmail"] == currentUserEmail;
    }).map((entry) {
      final data = Map<String, dynamic>.from(entry.value);
      data["_hiveKey"] = entry.key;
      return data;
    }).toList();

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

  Future<void> openAddDataPage() async {
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddDataPage()),
    );

    if (saved == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardHomePage(
        goalMode: widget.goalMode,
        lastEntry: getLastEntry(),
        user: getCurrentUser(),
      ),
      const _ProgressPage(),
      const ShoppingListsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: navy,
      body: IndexedStack(index: selectedIndex, children: pages),
      floatingActionButton: FloatingActionButton(
        heroTag: "dashboard_add_data_fab",
        onPressed: openAddDataPage,
        backgroundColor: green,
        foregroundColor: navyText,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: cardNavy,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: BottomAppBar(
            color: cardNavy,
            shape: const CircularNotchedRectangle(),
            notchMargin: 9,
            child: SizedBox(
              height: 74,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: "Home",
                    selected: selectedIndex == 0,
                    onTap: () => setState(() => selectedIndex = 0),
                  ),
                  _NavItem(
                    icon: Icons.show_chart_rounded,
                    label: "Progress",
                    selected: selectedIndex == 1,
                    onTap: () => setState(() => selectedIndex = 1),
                  ),
                  const SizedBox(width: 48),
                  _NavItem(
                    icon: Icons.shopping_cart_rounded,
                    label: "Shopping",
                    selected: selectedIndex == 2,
                    onTap: () => setState(() => selectedIndex = 2),
                  ),
                  _NavItem(
                    icon: Icons.person_rounded,
                    label: "Profile",
                    selected: selectedIndex == 3,
                    onTap: () => setState(() => selectedIndex = 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHomePage extends StatelessWidget {
  final String goalMode;
  final Map<String, dynamic>? lastEntry;
  final Map<String, dynamic>? user;

  const _DashboardHomePage({
    required this.goalMode,
    required this.lastEntry,
    required this.user,
  });

  static const navy = Color(0xFF0B1120);
  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);
  static const orange = Color(0xFFF97316);

  double parseDouble(dynamic value) {
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String displayGoalMode(String value) {
    if (value == "Slabit") return "Weight Loss";
    if (value == "Gains") return "Muscle Gain";
    return value;
  }

  String getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";
  }

  String getCurrentUserEmail() {
    final settingsBox = Hive.box('settingsBox');
    return settingsBox.get("currentUserEmail", defaultValue: "");
  }

  int getTodayWater() {
    final waterBox = Hive.box('waterBox');
    final key = "${getCurrentUserEmail()}_${getTodayKey()}";
    return int.tryParse(waterBox.get(key, defaultValue: 0).toString()) ?? 0;
  }

  int getWaterGoal() {
    final waterBox = Hive.box('waterBox');
    final key = "${getCurrentUserEmail()}_waterGoal";
    return int.tryParse(waterBox.get(key, defaultValue: 2000).toString()) ??
        2000;
  }

  double calculateProgress({
    required double startWeight,
    required double currentWeight,
    required double targetWeight,
  }) {
    if (startWeight <= 0 || targetWeight <= 0 || currentWeight <= 0) return 0;
    if (startWeight == targetWeight) return 1;

    double progress;

    if (targetWeight < startWeight) {
      progress = (startWeight - currentWeight) / (startWeight - targetWeight);
    } else {
      progress = (currentWeight - startWeight) / (targetWeight - startWeight);
    }

    return progress.clamp(0.0, 1.0).toDouble();
  }

  bool isOffTrack({
    required double startWeight,
    required double currentWeight,
    required double targetWeight,
  }) {
    if (startWeight <= 0 || targetWeight <= 0 || currentWeight <= 0) {
      return false;
    }

    if (targetWeight < startWeight) {
      return currentWeight > startWeight;
    }

    return currentWeight < startWeight;
  }

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return "Good morning";
    if (hour < 18) return "Good afternoon";
    return "Good evening";
  }

  String getProgressMessage({
    required double startWeight,
    required double currentWeight,
    required double targetWeight,
    required double progress,
  }) {
    if (startWeight <= 0 || targetWeight <= 0 || currentWeight <= 0) {
      return "Complete your profile and add daily data to track your goal.";
    }

    if (progress >= 1) {
      return "Amazing! You reached your target weight.";
    }

    if (targetWeight < startWeight) {
      if (currentWeight < startWeight) {
        return "You are moving in the right direction. Keep going.";
      }

      if (currentWeight > startWeight) {
        return "Your weight is above your starting point, so progress stays at 0%. Log your next entries and focus on getting back below your start weight.";
      }

      return "Progress starts once your current weight goes below your starting weight.";
    }

    if (currentWeight > startWeight) {
      return "You are moving in the right direction. Keep building.";
    }

    if (currentWeight < startWeight) {
      return "Your weight is below your starting point, so progress stays at 0%. Log your next entries and focus on getting back above your start weight.";
    }

    return "Progress starts once your current weight goes above your starting weight.";
  }

  @override
  Widget build(BuildContext context) {
    final firstName = user?["firstName"]?.toString() ?? "there";

    final double profileWeight =
        user == null ? 0.0 : parseDouble(user!["weight"]);

    final double initialWeight =
        user == null ? 0.0 : parseDouble(user!["initialWeight"]);

    final double startWeight = initialWeight > 0 ? initialWeight : profileWeight;

    final double targetWeight =
        user == null ? 0.0 : parseDouble(user!["targetWeight"]);

    final double currentWeight =
        lastEntry == null ? profileWeight : parseDouble(lastEntry!["weight"]);

    final double currentWaist =
        lastEntry == null ? 0.0 : parseDouble(lastEntry!["waist"]);

    final double calories =
        lastEntry == null ? 0.0 : parseDouble(lastEntry!["totalCalories"]);

    final int todayWater = getTodayWater();
    final int waterGoal = getWaterGoal();

    final double targetProgress = calculateProgress(
      startWeight: startWeight,
      currentWeight: currentWeight,
      targetWeight: targetWeight,
    );

    final bool offTrack = isOffTrack(
      startWeight: startWeight,
      currentWeight: currentWeight,
      targetWeight: targetWeight,
    );

    final double waterProgress =
        waterGoal <= 0 ? 0.0 : (todayWater / waterGoal).clamp(0.0, 1.0);

    final double caloriesProgress = (calories / 2000).clamp(0.0, 1.0);

    final int progressPercent = (targetProgress * 100).round();
    final double remainingKg = (currentWeight - targetWeight).abs().toDouble();

    final String progressMessage = getProgressMessage(
      startWeight: startWeight,
      currentWeight: currentWeight,
      targetWeight: targetWeight,
      progress: targetProgress,
    );

    return ValueListenableBuilder(
      valueListenable: Hive.box('waterBox').listenable(),
      builder: (context, box, child) {
        return Scaffold(
          backgroundColor: navy,
          appBar: AppBar(title: const Text("FitJourney")),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${getGreeting()}, $firstName",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your daily health overview",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  _HeroOverviewCard(
                    goal: displayGoalMode(goalMode),
                    currentWeight: currentWeight,
                    targetWeight: targetWeight,
                    remainingKg: remainingKg,
                    progress: targetProgress,
                    progressPercent: progressPercent,
                    message: progressMessage,
                    offTrack: offTrack,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _OverviewRingCard(
                          title: "Calories",
                          value:
                              calories == 0 ? "--" : calories.round().toString(),
                          subtitle: "kcal today",
                          progress: caloriesProgress,
                          icon: Icons.local_fire_department_rounded,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _OverviewRingCard(
                          title: "Water",
                          value: "$todayWater",
                          subtitle: "of $waterGoal ml",
                          progress: waterProgress,
                          icon: Icons.water_drop_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: "Weight",
                          value: currentWeight == 0
                              ? "--"
                              : "${currentWeight.toStringAsFixed(1)} kg",
                          icon: Icons.monitor_weight_rounded,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _StatCard(
                          title: "Waist",
                          value: currentWaist == 0
                              ? "--"
                              : "${currentWaist.toStringAsFixed(1)} cm",
                          icon: Icons.straighten_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardNavy,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: green.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.insights_rounded,
                            color: green,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            lastEntry == null
                                ? "Add your first daily entry to unlock your personalized overview."
                                : "You logged ${calories.round()} kcal today. Keep tracking your meals, hydration and body progress.",
                            style: const TextStyle(
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
      },
    );
  }
}

class _HeroOverviewCard extends StatelessWidget {
  final String goal;
  final double currentWeight;
  final double targetWeight;
  final double remainingKg;
  final double progress;
  final int progressPercent;
  final String message;
  final bool offTrack;

  const _HeroOverviewCard({
    required this.goal,
    required this.currentWeight,
    required this.targetWeight,
    required this.remainingKg,
    required this.progress,
    required this.progressPercent,
    required this.message,
    required this.offTrack,
  });

  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);
  static const orange = Color(0xFFF97316);
  static const navyText = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final badgeColor = offTrack ? orange : green;
    final badgeText = offTrack ? "0%" : "$progressPercent%";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardNavy,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                offTrack ? Icons.warning_amber_rounded : Icons.flag_rounded,
                color: badgeColor,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  goal,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: navyText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (offTrack) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: orange.withOpacity(0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: orange.withOpacity(0.5)),
              ),
              child: const Text(
                "Needs attention: progress is paused until your weight moves back toward your target.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 14,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _MiniInfo(
                  label: "Current",
                  value: currentWeight == 0
                      ? "--"
                      : "${currentWeight.toStringAsFixed(1)} kg",
                  textAlign: TextAlign.left,
                ),
              ),
              Expanded(
                child: _MiniInfo(
                  label: "Target",
                  value: targetWeight == 0
                      ? "--"
                      : "${targetWeight.toStringAsFixed(1)} kg",
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: _MiniInfo(
                  label: "Left",
                  value: currentWeight == 0 || targetWeight == 0
                      ? "--"
                      : "${remainingKg.toStringAsFixed(1)} kg",
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewRingCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final double progress;
  final IconData icon;

  const _OverviewRingCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.progress,
    required this.icon,
  });

  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardNavy,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(green),
                  ),
                ),
                Icon(icon, color: green, size: 30),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            "$subtitle • $percent%",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  final TextAlign textAlign;

  const _MiniInfo({
    required this.label,
    required this.value,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: textAlign == TextAlign.left
          ? CrossAxisAlignment.start
          : textAlign == TextAlign.center
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          textAlign: textAlign,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: textAlign,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ProgressPage extends StatelessWidget {
  const _ProgressPage();

  static const navy = Color(0xFF0B1120);
  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(title: const Text("Progress")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Track your progress",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Weight, waist, calories, meals, nutrition and water tracking.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              _ProgressCard(
                title: "Weight Tracker",
                subtitle: "View your weight trend and latest changes.",
                icon: Icons.monitor_weight_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KgTrackerPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _ProgressCard(
                title: "Waist Tracker",
                subtitle: "Track your waist measurements over time.",
                icon: Icons.straighten_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WaistTrackerPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _ProgressCard(
                title: "Calories",
                subtitle: "See your latest calorie split by meal.",
                icon: Icons.local_fire_department_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CaloriesPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _ProgressCard(
                title: "Meal Suggestions",
                subtitle: "Find healthy meal ideas by ingredient.",
                icon: Icons.restaurant_menu_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MealSuggestionsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _ProgressCard(
                title: "Nutrition Search",
                subtitle: "Search nutrition facts for foods.",
                icon: Icons.manage_search_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NutritionPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _ProgressCard(
                title: "Water Tracker",
                subtitle: "Track your daily hydration goal.",
                icon: Icons.water_drop_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WaterTrackerPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ProgressCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cardNavy,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: green.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: green, size: 31),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? green : Colors.white54, size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? green : Colors.white54,
                fontSize: 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
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
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: green, size: 30),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}