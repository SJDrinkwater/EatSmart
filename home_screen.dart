import 'package:eat_smart/navigation_screens/settings_nav/meal_planner_creation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final int userId;

  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Recipe> recipes = [];
  DateTime selectedDate = DateTime.now(); // Start with today's date
  String userName = '';

  @override
  void initState() {
    super.initState();
    fetchUserName();
    fetchRecipes();
  }

  Future<void> fetchUserName() async {
    final Uri url = Uri.parse('https://ysjcs.net/~sam.drinkwater/EatSmart/get_user_name.php?user_id=${widget.userId}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          userName = jsonData['first_name'];
        });
      } else {
        throw Exception('Failed to load user name');
      }
    } catch (e) {
      print('Error fetching user name: $e');
      throw Exception('Failed to load user name');
    }
  }

  Future<void> fetchRecipes() async {
    final Uri url = Uri.parse('https://ysjcs.net/~sam.drinkwater/EatSmart/display_users_recipes.php?user_id=${widget.userId}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          recipes = jsonData.map((json) => Recipe.fromJson(json)).toList();
        });
      } else {
        print('Response Body: ${response.body}');
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      throw Exception('Failed to load recipes');
    }
  }

  Map<String, List<Recipe>> groupRecipesByDate() {
    Map<String, List<Recipe>> groupedRecipes = {};
    for (var recipe in recipes) {
      DateTime date = DateTime.parse(recipe.chosenTimestamp);
      String dateString = DateFormat('yyyy-MM-dd').format(date);
      if (!groupedRecipes.containsKey(dateString)) {
        groupedRecipes[dateString] = [];
      }
      groupedRecipes[dateString]!.add(recipe);
    }
    return groupedRecipes;
  }

  Widget buildRecipeCard(BuildContext context, Recipe recipe) {
    return GestureDetector(
      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailsScreenHome(recipe: recipe),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.all(16.0),
        elevation: 8.0, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0), 
        ),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
              child: Image.network(recipe.recipeImg, height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
            SizedBox(height: 8.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.recipeName,
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, fontFamily: 'MyFontText'), 
                  ),
                  SizedBox(height: 4.0),
                  Text('Kcal: ${recipe.recipeKcal}', style: TextStyle(fontSize: 18.0,  fontFamily: 'MyFontText'),), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool hasRecipesForDate(DateTime date) {
    String dateString = DateFormat('yyyy-MM-dd').format(date);
    Map<String, List<Recipe>> groupedRecipes = groupRecipesByDate();
    return groupedRecipes.containsKey(dateString);
  }

  void changeDate(int daysToAdd) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: daysToAdd));
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Recipe>> groupedRecipes = groupRecipesByDate();
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime endOfWeek = today.add(Duration(days: DateTime.daysPerWeek - today.weekday));
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);

    // Format the selectedDateString based on comparison
    String selectedDateString;
    if (selectedDate.compareTo(today) == 0) {
      selectedDateString = "Today";
    } else if (selectedDate.compareTo(tomorrow) == 0) {
      selectedDateString = "Tomorrow";
    } else {
      selectedDateString = DateFormat('EEEE').format(selectedDate);
    }

    List<Recipe> recipesForSelectedDate = groupedRecipes[DateFormat('yyyy-MM-dd').format(selectedDate)] ?? [];

    // Check if all recipes for the current week are completed
    bool allRecipesCompleted = groupedRecipes.entries.every((entry) {
      DateTime date = DateTime.parse(entry.key);
      return date.isBefore(endOfWeek) || date.isAtSameMomentAs(endOfWeek);
    });

    // Display the "Create New Weekly Meal Plan" button if all recipes are completed
    Widget planButton = allRecipesCompleted && !hasRecipesForDate(selectedDate)
  ? Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: () {
            // Navigate to MealPlannerCreation screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MealPlannerCreation(userId: widget.userId)),
            );
          },
          style: ElevatedButton.styleFrom(
            primary: Colors.white,
            onPrimary: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
            side: BorderSide(color: Colors.black),
          ),
          child: Text(
            "Looks like you've finished your meal plan!\nClick on me to create a new one.",
            style: TextStyle(
              fontFamily: 'MyFontText',
              fontSize: 18.0,
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    )
  : SizedBox();

    List<Recipe> breakfastRecipes = [];
    List<Recipe> lunchRecipes = [];
    List<Recipe> dinnerRecipes = [];

    // Group recipes by meal type
    for (var recipe in recipesForSelectedDate) {
      if (recipe.mealType == 'Breakfast') {
        breakfastRecipes.add(recipe);
      } else if (recipe.mealType == 'Lunch') {
        lunchRecipes.add(recipe);
      } else if (recipe.mealType == 'Dinner') {
        dinnerRecipes.add(recipe);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Eat Smart',
          style: TextStyle(
            fontFamily: 'MyFontLogo',
            fontSize: 30,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white, 
        automaticallyImplyLeading: false, 
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Home Screen',style: TextStyle(fontFamily: 'MyFontText',),),
                    content: Text('In this screen we are displaying all recipes for the week, swipe right or left to view your recipes.',style: TextStyle(fontFamily: 'MyFontText',),),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Close', style: TextStyle(color: Colors.teal[900], fontWeight: FontWeight.bold, fontFamily: 'MyFontText'))
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          DateSelectionWidget(
            selectedDateString: selectedDateString,
            changeDate: changeDate,
            hasRecipesForDate: hasRecipesForDate,
            selectedDate: selectedDate,
          ),
          Expanded(
            child: ListView(
              children: [
                if (breakfastRecipes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Breakfast',
                      style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, fontFamily: 'MyFontText'),
                    ),
                  ),
                ...breakfastRecipes.map((recipe) => buildRecipeCard(context, recipe)).toList(),
                if (lunchRecipes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Lunch',
                      style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, fontFamily: 'MyFontText'),
                    ),
                  ),
                ...lunchRecipes.map((recipe) => buildRecipeCard(context, recipe)).toList(),
                if (dinnerRecipes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Dinner',
                      style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, fontFamily: 'MyFontText'),
                    ),
                  ),
                ...dinnerRecipes.map((recipe) => buildRecipeCard(context, recipe)).toList(),
                SizedBox(height: 16.0),
                planButton, 
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DateSelectionWidget extends StatelessWidget {
  final String selectedDateString;
  final Function(int) changeDate;
  final bool Function(DateTime) hasRecipesForDate;
  final DateTime selectedDate;

  DateSelectionWidget({
    required this.selectedDateString,
    required this.changeDate,
    required this.hasRecipesForDate,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Detect swipe gesture to the right
        if (details.primaryVelocity! > 0 && hasRecipesForDate(selectedDate.subtract(Duration(days: 1)))) {
          changeDate(-1);
        }
        // Detect swipe gesture to the left
        else if (details.primaryVelocity! < 0 && hasRecipesForDate(selectedDate.add(Duration(days: 1)))) {
          changeDate(1);
        }
      },
      child: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: hasRecipesForDate(selectedDate.subtract(Duration(days: 1))) ? () => changeDate(-1) : null,
            ),
            Text(
              selectedDateString,
              style: TextStyle(fontSize: 20, fontFamily: 'MyFontText', fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios),
              onPressed: hasRecipesForDate(selectedDate.add(Duration(days: 1))) ? () => changeDate(1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class Recipe {
  final int recipeId;
  final String recipeName;
  final int recipeKcal;
  final String instructions;
  final String recipeImg;
  final String mealType;
  final List<Map<String, dynamic>> recipeDetails;
  final String chosenTimestamp;

  Recipe({
    required this.recipeId,
    required this.recipeName,
    required this.recipeKcal,
    required this.instructions,
    required this.recipeImg,
    required this.mealType,
    required this.recipeDetails,
    required this.chosenTimestamp,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      recipeId: json['recipe_id'],
      recipeName: json['recipe_name'],
      recipeKcal: json['recipe_kcal'],
      instructions: json['instructions'],
      recipeImg: json['recipe_img'],
      mealType: json['meal_type'],
      recipeDetails: List<Map<String, dynamic>>.from(json['recipe_details']),
      chosenTimestamp: json['chosen_timestamp'],
    );
  }
}

class RecipeDetailsScreenHome extends StatelessWidget {
  final Recipe recipe;

  RecipeDetailsScreenHome({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Detect swipe gesture to the right
        if (details.primaryVelocity! > 0) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            recipe.recipeName,
            style: TextStyle(
              fontFamily: 'MyFontLogo',
              fontSize: 30,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white, 
          automaticallyImplyLeading: false, 
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.help_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('The Menu',style: TextStyle(fontFamily: 'MyFontText',),),
                      content: const Text('Here we can view the recipes ingredients and instructions ',style: TextStyle(fontFamily: 'MyFontText',),),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                          'Close',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.teal[900],
                            fontFamily: 'MyFontText',
                          ),
                        ),      
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2.0),
                    ),
                    child: CircleAvatar(
                      radius: 100, 
                      backgroundImage: NetworkImage(recipe.recipeImg),
                    ),
                  ),
                ),            
                SizedBox(height: 16.0),
                Text(
                  'Products(per person):',
                  style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, fontFamily: 'MyFontText'),
                ),
                ...recipe.recipeDetails.map((detail) {
                  return ListTile(
                    title: Text(detail['product_name'],style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, fontFamily: 'MyFontText')),
                    subtitle: Text('${detail['n_ingredients']} ${detail['product_measurement']}',style: TextStyle(fontSize: 18.0, fontFamily: 'MyFontText')),
                  );
                }).toList(),
                SizedBox(height: 16.0),
                Text(
                  'Instructions:',
                  style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, fontFamily: 'MyFontText'),
                ),
                SizedBox(height: 8.0),
                Text(
                  recipe.instructions,style: TextStyle(fontSize: 18.0, fontFamily: 'MyFontText')
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
