
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class GotSomeSpareScreen extends StatefulWidget {
  @override
  _GotSomeSpareScreenState createState() => _GotSomeSpareScreenState();
}

class _GotSomeSpareScreenState extends State<GotSomeSpareScreen> {
  late Future<List<Product>> futureProducts;
  TextEditingController searchController = TextEditingController();
  String filter = "";
  List<String> selectedProductIds = [];
  bool isFetchingRecipes = false;

  @override
  void initState() {
    super.initState();
    futureProducts = fetchProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void applyFilter(String query) {
    setState(() {
      filter = query.toLowerCase();
    });
  }

  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse('https://ysjcs.net/~sam.drinkwater/EatSmart/got_some_spare.php'));
    if (response.statusCode == 200) {
      List<dynamic> productsJson = json.decode(response.body);
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  void fetchCommonRecipes(List<String> selectedProductIds) async {
  setState(() {
    isFetchingRecipes = true; // Set fetching state to true
  });

  Map<String, int> recipeIdCount = {};

  // Iterate over selectedProductIds to fetch each product and update recipeIdCount
  for (String productId in selectedProductIds) {
    Product product = await fetchProduct(productId); 
    for (String recipeId in product.recipeIds) {
      if (recipeIdCount.containsKey(recipeId)) {
        recipeIdCount[recipeId] = recipeIdCount[recipeId]! + 1;
      } else {
        recipeIdCount[recipeId] = 1;
      }
    }
  }

  // Sort recipe IDs based on their match count in descending order
  List<MapEntry<String, int>> sortedRecipeIdEntries = recipeIdCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  List<String> sortedRecipeIds = sortedRecipeIdEntries.map((entry) => entry.key).toList();

  // Fetch recipes based on the sorted list of recipe IDs
  List<Recipe> fetchedRecipes = await fetchRecipes(sortedRecipeIds, selectedProductIds);

  // Ensure the fetched recipes are in the order of sortedRecipeIds
  List<Recipe> sortedRecipes = sortedRecipeIds
    .map((id) => fetchedRecipes.firstWhere((recipe) => recipe.recipeId.toString() == id))
    .whereType<Recipe>()
    .toList();

  setState(() {
    isFetchingRecipes = false;
  });

  // Navigate to the screen that displays the sorted recipes
  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => Scaffold(
      appBar: AppBar(
        title: const Text(
          'Our Common Recipes',
          style: TextStyle(fontFamily: 'MyFontLogo', fontSize: 30, color: Colors.black,),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(
                      'Our Common Recipes',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'MyFontText',
                      ),
                    ),
                    content: Text(
                      'In here we can see all the matched recipes. The matched recipes are sorted so the recipes with the most selected recipes are displayed at the top. The selected products inside each recipe are also displayed.',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'MyFontText',
                      ),
                    ),
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
      body: ListView.builder(
        itemCount: sortedRecipes.length,
        itemBuilder: (context, index) {
          return RecipeCard(recipe: sortedRecipes[index], selectedProductIds: selectedProductIds);
        },
      ),
    ),
  ),
);
  }


  Future<Product> fetchProduct(String productId) async {
    final response = await http.get(
      Uri.parse('https://ysjcs.net/~sam.drinkwater/EatSmart/got_some_spare.php'),
    );

    if (response.statusCode == 200) {
      List<dynamic> productsJson = json.decode(response.body);
      // Find the product with the matching productId
      var productJson = productsJson.firstWhere((product) => product['product_id'] == productId);
      return Product.fromJson(productJson);
    } else {
      throw Exception('Failed to load product');
    }
  }

  Future<List<Recipe>> fetchRecipes(List<String> recipeIds, List<String> selectedProductIds) async {
    List<Recipe> recipes = [];

    String recipeIdsString = recipeIds.join(',');

    final response = await http.post(
      Uri.parse('https://ysjcs.net/~sam.drinkwater/EatSmart/grab_all_recipes.php'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'recipeIds': recipeIdsString},
    );

    if (response.statusCode == 200) {
      List<dynamic> responseData = json.decode(response.body);
      responseData.forEach((recipeJson) {
        List<Map<String, dynamic>> recipeDetails = [];
        recipeJson['recipe_details'].forEach((detail) {
          recipeDetails.add({
            'product_id': detail['product_id'],
            'product_name': detail['product_name'],
            'product_img': detail['product_img'],
            'n_ingredients': detail['n_ingredients'],
            'product_measurement': detail['product_measurement'],
          });
        });

        Recipe recipe = Recipe(
          recipeId: int.parse(recipeJson['recipe_id']),
          recipeName: recipeJson['recipe_name'],
          recipeKcal: int.parse(recipeJson['recipe_kcal']),
          instructions: recipeJson['instructions'],
          recipeImg: recipeJson['recipe_img'],
          mealType: recipeJson['meal_type'],
          recipeDetails: recipeDetails,
        );

        recipes.add(recipe);
      });
    } else {
      throw Exception('Failed to load recipes');
    }
    return recipes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Got Some Spare',
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
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text(
                      'Got Some Spare',
                      style: TextStyle(fontFamily: 'MyFontText'),
                    ),
                    content: const Text(
                      'This is Got Some Spare. If you have any products you want to finish, select as many products you need to use. Tap the "Get Common Recipes" button and view all recipes that include 1 or multiple of the selected products.',
                      style: TextStyle(fontFamily: 'MyFontText'),
                    ),
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
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                suffixIcon: const Icon(Icons.search),
                hintStyle: const TextStyle(fontSize: 16, fontFamily: 'MyFontText'),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal.shade700),
                ),
              ),
              onChanged: applyFilter,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (BuildContext context, index) {
                      Product product = snapshot.data![index];
                      if (filter.isEmpty ||
                          product.productName.toLowerCase().contains(filter)) {
                        bool isSelected = selectedProductIds.contains(product.productId);
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedProductIds.remove(product.productId);
                                } else {
                                  selectedProductIds.add(product.productId);
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(8.0),
                                color: isSelected ? Colors.teal[900] : Colors.white,
                              ),
                              child: ListTile(
                                leading: ClipOval(
                                  child: Image.network(
                                    product.productImg,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.error);
                                    },
                                  ),
                                ),
                                title: Text(
                                  product.productName,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontFamily: 'MyFontText',
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Container();
                      }
                    },
                  );
                } else {
                  return const Center(child: Text("No products found"));
                }
              },
            ),
          ),
          ElevatedButton(
            onPressed: isFetchingRecipes ? null : () => fetchCommonRecipes(selectedProductIds),
            style: ElevatedButton.styleFrom(
              primary: Colors.teal[900],
              onPrimary: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            ),
            child: isFetchingRecipes
                ? const CircularProgressIndicator()
                : const Text(
                    'Get Common Recipes',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'MyFontText',
                    ),
                  ),
          ),
          const SizedBox(height: 10.0)
        ],
      ),
    );
  }
}

class Product {
  final String productId;
  final String productName;
  final String productImg;
  final List<String> recipeIds;

  Product({
    required this.productId,
    required this.productName,
    required this.productImg,
    required this.recipeIds,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var recipeIdsRaw = json['recipe_ids'] ?? '';
    List<String> recipeIds = recipeIdsRaw.isNotEmpty ? recipeIdsRaw.split(',') : [];
    return Product(
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      productImg: json['product_img'] ?? 'assets/images/logo.png',
      recipeIds: recipeIds,
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final List<String> selectedProductIds;

  RecipeCard({required this.recipe, required this.selectedProductIds});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Detect swipe gesture to the right
        if (details.primaryVelocity! > 0) {
          Navigator.of(context).pop();
        }
      },
      child: _buildRecipeCard(context),
    );
  }

  Widget _buildRecipeCard(BuildContext context) {
    
    List<Map<String, dynamic>> matchingProductsDetails = recipe.recipeDetails.where((detail) {
      return selectedProductIds.contains(detail['product_id'].toString());
    }).toList();

    if (matchingProductsDetails.isNotEmpty) {
      return Card(
        elevation: 4,
        margin: const EdgeInsets.all(8),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: const BorderSide(color: Colors.black),
        ),
        child: InkWell(
          onTap: () {
            // Navigate to RecipeDetailsScreen when tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeDetailsScreen(recipe: recipe),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    recipe.recipeImg,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/logo.png',
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  recipe.recipeName,
                  style: const TextStyle(
                      fontSize: 18.0, fontWeight: FontWeight.bold, fontFamily: 'MyFontText'),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Kcal: ${recipe.recipeKcal}',
                  style: const TextStyle(fontSize: 16.0, color: Colors.black, fontFamily: 'MyFontText'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Matching Products:',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, fontFamily: 'MyFontText'),
                ),
                ...matchingProductsDetails.map((detail) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      ClipOval(
                        child: Image.network(
                          detail['product_img'] ?? 'assets/images/logo.png', 
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error), 
                        ),
                      ),

                      const SizedBox(width: 10), 
                      Expanded(
                        child: Text(
                          "${detail['product_name']} ",
                          style: const TextStyle(fontSize: 16.0, fontFamily: 'MyFontText'),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}


class RecipeDetailsScreen extends StatelessWidget {
  final Recipe recipe;

  RecipeDetailsScreen({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            recipe.recipeName,
            style: const TextStyle(
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
              icon: const Icon(Icons.help_outline),
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
            padding: const EdgeInsets.all(16.0),
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
                const SizedBox(height: 16.0),
                const Text(
                  'Products(per person):',
                  style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, fontFamily: 'MyFontText'),
                ),
                ...recipe.recipeDetails.map((detail) {
                  return ListTile(
                    title: Text(detail['product_name'],style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, fontFamily: 'MyFontText')),
                    subtitle: Text('${detail['n_ingredients']} ${detail['product_measurement']}',style: const TextStyle(fontSize: 18.0, fontFamily: 'MyFontText')),
                  );
                }).toList(),
                const SizedBox(height: 16.0),
                const Text(
                  'Instructions:',
                  style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, fontFamily: 'MyFontText'),
                ),
                const SizedBox(height: 8.0),
                Text(
                  recipe.instructions,style: const TextStyle(fontSize: 18.0, fontFamily: 'MyFontText')
                ),
              ],
            ),
          ),
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

  Recipe({
    required this.recipeId,
    required this.recipeName,
    required this.recipeKcal,
    required this.instructions,
    required this.recipeImg,
    required this.mealType,
    required this.recipeDetails,
  });

  // New method to get product image by ID
  String getProductImageById(String productId) {
    print("Getting image for product ID: $productId");
    var product = recipeDetails.firstWhere(
      (detail) => detail['product_id'].toString() == productId,
      orElse: () => {'product_img': ''},
    );
    print("Found image URL: ${product['product_img']}");
    return product['product_img'] ?? 'assets/images/logo.png';
  }


}
