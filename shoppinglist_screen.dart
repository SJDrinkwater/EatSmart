import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String supermarketCount;
  final String measurement;
  final String totalIngredients;
  final String availability;
  bool isRemoved;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.supermarketCount,
    required this.measurement,
    required this.totalIngredients,
    required this.availability,
    this.isRemoved = false,
  });
}

class ShoppingListScreen extends StatefulWidget {
  final int userId;

  const ShoppingListScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  late Future<List<List<Product>>> futureUserProducts;

  @override
  void initState() {
    super.initState();
    futureUserProducts = fetchUserProducts(widget.userId);
  }

  Future<List<List<Product>>> fetchUserProducts(int userId) async {
    final displayProductsUrl = 'https://ysjcs.net/~sam.drinkwater/EatSmart/view_products.php?user_id=$userId';
    final response = await http.get(Uri.parse(displayProductsUrl));

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);

      List<dynamic> userProductsJson = responseData['UserProducts'];
      List<Product> userProducts = userProductsJson.map((productData) => Product(
        id: productData['product_id'],
        name: productData['product_name'],
        price: (double.tryParse(productData['product_price']) ?? 0.0) * (double.tryParse(productData['availability_calc'].toString()) ?? 1.0),
        imageUrl: productData['product_img'],
        supermarketCount: productData['n_supermarket'],
        measurement: productData['product_measurement'] ?? 'N/A',
        totalIngredients: productData['total_n_ingredients'].toString(),
        availability: productData['availability_calc'].toString(),
      )).toList();

      List<dynamic> userProductsExtraJson = responseData['UserProductsExtra'];
      List<Product> userProductsExtra = userProductsExtraJson.map((productData) => Product(
        id: productData['product_id'],
        name: productData['product_name'],
        price: (double.tryParse(productData['product_price']) ?? 0.0) * (double.tryParse(productData['availability_calc'].toString()) ?? 1.0),
        imageUrl: productData['product_img'],
        supermarketCount: productData['n_supermarket'],
        measurement: productData['product_measurement'] ?? 'N/A',
        totalIngredients: productData['total_n_ingredients'].toString(),
        availability: productData['availability_calc'].toString(),
      )).toList();

      List<dynamic> userUnwantedProductsJson = responseData['UserUnwantedProducts'];
      List<Product> userUnwantedProducts = userUnwantedProductsJson.map((productData) => Product(
        id: productData['product_id'],
        name: productData['product_name'],
        price: (double.tryParse(productData['product_price']) ?? 0.0) * (double.tryParse(productData['availability_calc'].toString()) ?? 1.0),
        imageUrl: productData['product_img'],
        supermarketCount: productData['n_supermarket'],
        measurement: productData['product_measurement'] ?? 'N/A',
        totalIngredients: productData['total_n_ingredients'].toString(),
        availability: productData['availability_calc'].toString(),
      )).toList();

      return [userProducts, userProductsExtra, userUnwantedProducts];
    } else {
      throw Exception('Failed to load user products');
    }
  }

  void markProductAsRemoved(Product product) async {
    // Show confirmation dialog
    bool confirmRemove = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Removal',style: TextStyle(fontFamily: 'MyFontText')),
          content: Text('Are you sure you want to remove this product?',style: TextStyle(fontFamily: 'MyFontText')),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.teal[900],
                            fontFamily: 'MyFontText',
                          ),),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Remove',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.red[900],
                            fontFamily: 'MyFontText',
                          ),),
            ),
          ],
        );
      },
    );

    // Check user's confirmation
    if (confirmRemove) {
      final response = await http.post(
        Uri.parse('https://ysjcs.net/~sam.drinkwater/EatSmart/remove_product.php'),
        body: {
          'user_id': widget.userId.toString(), 
          'product_id': product.id,
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['success']) {
          setState(() {
            product.isRemoved = true;
          });
          futureUserProducts = fetchUserProducts(widget.userId);
        } else {
          print(responseBody['message']);
        }
      } else {
        print('Failed to remove product from the database');
      }
    }
  }

  double calculateTotalPrice(List<Product> products) {
    return products.fold(0, (total, current) => total + (current.isRemoved ? 0 : current.price));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Shopping List',
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
                    title: Text('Shopping List',style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'MyFontText',
                    ),),
                    content: Text('Welcome to Shopping List. In here your list is split into two parts. Fresh ingredients of which has a usual shelf life of around 5 days. Then extra products, these are typical around your kitchen products, or products with a long shelf life.\n\n *These products are extracted from the Tescos supermarket, other supermarkets may differ',style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'MyFontText',
                    ),),
                    
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Close',style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.teal[900],
                          fontFamily: 'MyFontText',
                        ),),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<List<Product>>>(
        future: futureUserProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            List<List<Product>> userProductsLists = snapshot.data!;
            List<Product> userProducts = userProductsLists[0];
            List<Product> userProductsExtra = userProductsLists[1];
            List<Product> userUnwantedProducts = userProductsLists[2];
            double totalFreshProductsPrice = calculateTotalPrice(userProducts);
            double totalExtraProductsPrice = calculateTotalPrice(userProductsExtra);
            double totalUnwantedProductsPrice = calculateTotalPrice(userUnwantedProducts);

            return ListView(
              children: [
                _buildSection('Fresh Products', userProducts, totalFreshProductsPrice),
                _buildSection('Extra Products', userProductsExtra, totalExtraProductsPrice),
                _buildSection('Unwanted Products', userUnwantedProducts, totalUnwantedProductsPrice), // New section
              ],
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Product> products, double totalPrice) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
            fontFamily: 'MyFontText',
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          'Total Price: £${totalPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.green,
            fontFamily: 'MyFontText',
          ),
        ),
      ),
      SizedBox(
        height: 8.0,
      ),
      ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          Product product = products[index];
          return Container(
            margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Card(
              elevation: 0,
              child: ListTile(
                title: Text(
                  '${product.name}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'MyFontText'),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expected Price: £${product.price.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.black, fontFamily: 'MyFontText'),
                    ),
                    
                    Text(
                      'We are using a total of: ${product.totalIngredients} ${product.measurement}',
                      style: TextStyle(color: Colors.black, fontFamily: 'MyFontText'),
                    ),
                  ],
                ),
                leading: Image.network(
                  product.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/logo.png', width: 80, height: 80),
                ),
                trailing: IconButton(
                  icon: product.isRemoved
                      ? Icon(
                          Icons.remove_shopping_cart,
                          color: Colors.red,
                        )
                      : Icon(Icons.shopping_cart),
                  onPressed: () {
                    markProductAsRemoved(product);
                  },
                ), 
              ), 
            ),
          );      
        },  
      ),     
    ],
  );
}
}
