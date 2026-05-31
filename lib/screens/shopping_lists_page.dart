import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ShoppingListsPage extends StatefulWidget {
  const ShoppingListsPage({super.key});

  @override
  State<ShoppingListsPage> createState() => _ShoppingListsPageState();
}

class _ShoppingListsPageState extends State<ShoppingListsPage> {
  static const navy = Color(0xFF0B1120);
  static const cardNavy = Color(0xFF1E293B);
  static const green = Color(0xFF4ADE80);
  static const navyText = Color(0xFF0F172A);

  final listNameController = TextEditingController();
  final itemController = TextEditingController();

  String? get currentUserEmail {
    final settingsBox = Hive.box('settingsBox');
    return settingsBox.get("currentUserEmail");
  }

  List<Map<String, dynamic>> getUserLists() {
    final box = Hive.box('shoppingListsBox');
    final email = currentUserEmail;

    if (email == null) return [];

    final lists = box.values
        .where((list) => list["userEmail"] == email)
        .map((list) => Map<String, dynamic>.from(list))
        .toList();

    lists.sort((a, b) {
      final dateA = DateTime.parse(a["createdAt"]);
      final dateB = DateTime.parse(b["createdAt"]);
      return dateB.compareTo(dateA);
    });

    return lists;
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

  bool isValidText(String value) {
    final text = value.trim();

    if (text.isEmpty) return false;
    if (text.length < 2) return false;
    if (text.length > 40) return false;

    return true;
  }

  Future<void> addList() async {
    final name = listNameController.text.trim();

    if (currentUserEmail == null) {
      showMessage("User not found.");
      return;
    }

    if (!isValidText(name)) {
      showMessage("List name must have between 2 and 40 characters.");
      return;
    }

    final box = Hive.box('shoppingListsBox');

    final exists = getUserLists().any(
      (list) => list["name"].toString().toLowerCase() == name.toLowerCase(),
    );

    if (exists) {
      showMessage("A list with this name already exists.");
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final newList = {
      "id": id,
      "userEmail": currentUserEmail,
      "name": name,
      "items": [],
      "createdAt": DateTime.now().toIso8601String(),
    };

    await box.put(id, newList);
    listNameController.clear();

    if (mounted) {
      Navigator.pop(context);
      setState(() {});
      showMessage("Shopping list created.");
    }
  }

  Future<void> addItem(String listId) async {
    final name = itemController.text.trim();

    if (!isValidText(name)) {
      showMessage("Item name must have between 2 and 40 characters.");
      return;
    }

    final box = Hive.box('shoppingListsBox');
    final listData = box.get(listId);

    if (listData == null) {
      showMessage("Shopping list not found.");
      return;
    }

    final list = Map<String, dynamic>.from(listData);
    final items = (list["items"] as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final exists = items.any(
      (item) => item["name"].toString().toLowerCase() == name.toLowerCase(),
    );

    if (exists) {
      showMessage("This item already exists in the list.");
      return;
    }

    items.add({
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "name": name,
      "bought": false,
      "createdAt": DateTime.now().toIso8601String(),
    });

    list["items"] = items;

    await box.put(listId, list);
    itemController.clear();

    if (mounted) {
      Navigator.pop(context);
      setState(() {});
      showMessage("Item added.");
    }
  }

  Future<void> toggleItem(String listId, String itemId, bool value) async {
    final box = Hive.box('shoppingListsBox');
    final listData = box.get(listId);

    if (listData == null) return;

    final list = Map<String, dynamic>.from(listData);
    final items = (list["items"] as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final index = items.indexWhere((item) => item["id"] == itemId);

    if (index == -1) return;

    items[index]["bought"] = value;
    list["items"] = items;

    await box.put(listId, list);
    setState(() {});
  }

  Future<void> deleteItem(String listId, String itemId) async {
    final box = Hive.box('shoppingListsBox');
    final listData = box.get(listId);

    if (listData == null) return;

    final list = Map<String, dynamic>.from(listData);
    final items = (list["items"] as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    items.removeWhere((item) => item["id"] == itemId);
    list["items"] = items;

    await box.put(listId, list);
    setState(() {});
  }

  Future<void> deleteList(String listId) async {
    final box = Hive.box('shoppingListsBox');
    await box.delete(listId);
    setState(() {});
    showMessage("Shopping list deleted.");
  }

  void openAddListDialog() {
    listNameController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          title: const Text(
            "New Shopping List",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: listNameController,
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => addList(),
            decoration: InputDecoration(
              filled: true,
              fillColor: navy,
              labelText: "List name",
              hintText: "Ex: Weekly groceries",
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.shopping_bag, color: green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: addList,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: navyText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Create",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void openAddItemDialog(String listId) {
    itemController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          title: const Text(
            "Add Item",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: itemController,
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => addItem(listId),
            decoration: InputDecoration(
              filled: true,
              fillColor: navy,
              labelText: "Item name",
              hintText: "Ex: Chicken breast",
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.add_shopping_cart, color: green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => addItem(listId),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: navyText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Add",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    listNameController.dispose();
    itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lists = getUserLists();

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        title: const Text("Shopping Lists"),
      ),
      body: SafeArea(
        child: lists.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: cardNavy,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: green.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            color: green,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "No lists yet",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Create a shopping list and add the ingredients you need.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: openAddListDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: navyText,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "Create List",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                itemCount: lists.length,
                itemBuilder: (context, index) {
                  final list = lists[index];
                  final listId = list["id"];
                  final items = (list["items"] as List)
                      .map((item) => Map<String, dynamic>.from(item))
                      .toList();

                  final boughtCount =
                      items.where((item) => item["bought"] == true).length;

                  final progress =
                      items.isEmpty ? 0.0 : boughtCount / items.length;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardNavy,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: green.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.shopping_bag_rounded,
                                color: green,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    list["name"],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "$boughtCount / ${items.length} completed",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => openAddItemDialog(listId),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: green,
                              ),
                            ),
                            IconButton(
                              onPressed: () => deleteList(listId),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 9,
                            backgroundColor: Colors.white12,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(green),
                          ),
                        ),
                        if (items.isEmpty) ...[
                          const SizedBox(height: 18),
                          const Text(
                            "This list is empty.",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 15,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 14),
                          ...items.map((item) {
                            final bought = item["bought"] == true;

                            return Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: navy,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: bought,
                                    onChanged: (value) {
                                      toggleItem(
                                        listId,
                                        item["id"],
                                        value ?? false,
                                      );
                                    },
                                    activeColor: green,
                                    checkColor: navyText,
                                    side: const BorderSide(
                                      color: Colors.white54,
                                      width: 1.5,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item["name"],
                                      style: TextStyle(
                                        color: bought
                                            ? Colors.white38
                                            : Colors.white,
                                        fontSize: 16,
                                        decoration: bought
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      deleteItem(listId, item["id"]);
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white54,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "shopping_lists_add_fab",
        onPressed: openAddListDialog,
        backgroundColor: green,
        foregroundColor: navyText,
        child: const Icon(Icons.add),
      ),
    );
  }
}