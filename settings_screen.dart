
import 'package:eat_smart/navigation_screens/settings_nav/about_us_screen.dart';
import 'package:eat_smart/navigation_screens/settings_nav/survey_questions_after.dart';
import 'package:eat_smart/registration/Preferences_logged_in/login_screen.dart';
import 'package:eat_smart/navigation_screens/settings_nav/meal_planner_creation.dart';
import 'package:eat_smart/registration/Preferences_logged_in/budget_logged.dart';
import 'package:eat_smart/registration/Preferences_logged_in/recipes_logged.dart';
import 'package:eat_smart/registration/Preferences_logged_in/serving_count_logged.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  final int userId;

  const SettingsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userName = '';

  @override
  void initState() {
    super.initState();
    fetchUserName();
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

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: const Text(
          'Settings',
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
                    title: Text('Settings',style: TextStyle(fontFamily: 'MyFontText',),),
                    content: Text('In the setting page you can alter any account preferences, answer the survey after a weeks initial use of the app, as well as learn about the app.',style: TextStyle(fontFamily: 'MyFontText',),),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Hey, $userName :)',
              style: TextStyle(
                fontSize: 20.0, 
                fontWeight: FontWeight.bold,
                fontFamily: 'MyFontText',
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    'I want to change my meal choices',
                    style: TextStyle(fontSize: 16.0,fontFamily: 'MyFontText'), 
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MealPlannerCreation(userId: widget.userId)),
                    );
                  },
                ),
                ListTile(
                  title: Text(
                    'Change servings amount',
                    style: TextStyle(fontSize: 16.0,fontFamily: 'MyFontText'), 
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ServingLoggedCount(userId: widget.userId)),
                    );
                  },
                ),
                ListTile(
                  title: Text(
                    'Change Meal Restrictions',
                    style: TextStyle(fontSize: 16.0,fontFamily: 'MyFontText'), 
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RecipesLogged(userId: widget.userId)),
                    );
                  },
                ),
                ListTile(
                  title: Text(
                    'Change Budget',
                    style: TextStyle(fontSize: 16.0,fontFamily: 'MyFontText'),  
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BudgetLoggedScreen(userId: widget.userId)),
                    );
                  },
                ),
                ListTile(
                  title: Text(
                    'Survey Questions',
                    style: TextStyle(fontSize: 16.0,fontFamily: 'MyFontText'), 
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SurveyQuestionsAfterScreen(userId: widget.userId)),
                    );
                  },
                ),
                ListTile(
                  title: Text(
                    'About eat smart',
                    style: TextStyle(fontSize: 16.0,fontFamily: 'MyFontText'), 
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AboutUsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20), 
                  border: Border.all(color: Colors.black, width: 1), 
                ),
                child: MaterialButton(
                  onPressed: _logout,
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontFamily: 'MyFontText',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
