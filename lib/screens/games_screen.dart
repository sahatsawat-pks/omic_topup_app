import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../config/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../utils/image_helper.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: GameSearchDelegate(productProvider),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('All', null),
                _buildCategoryChip('Action', 'CATG01'),
                _buildCategoryChip('RPG', 'CATG02'),
                _buildCategoryChip('Strategy', 'CATG03'),
              ],
            ),
          ),
          
          // Products Grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => productProvider.loadProducts(),
              child: productProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : productProvider.products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.games, size: 80, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'No games available',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => productProvider.loadProducts(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: productProvider.products.length,
                          itemBuilder: (context, index) {
                            final product = productProvider.products[index];
                            final imagePath = ImageHelper.getProductImagePath(
                              product.productPhotoPath,
                              product.productName,
                            );

                            return Card(
                              elevation: 2,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    '/product/${product.productId}',
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Image.asset(
                                        imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.videogame_asset,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.productName,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const Spacer(),
                                            Row(
                                              children: [
                                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                                const SizedBox(width: 4),
                                                Text(
                                                  product.productRating.toStringAsFixed(1),
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  '฿${product.productPrice.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.accentColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? categoryId) {
    final isSelected = _selectedCategory == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = categoryId;
          });
          Provider.of<ProductProvider>(context, listen: false)
              .filterByCategory(categoryId);
        },
        selectedColor: AppTheme.accentColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
        ),
      ),
    );
  }
}

class GameSearchDelegate extends SearchDelegate<String> {
  final ProductProvider productProvider;

  GameSearchDelegate(this.productProvider);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    productProvider.searchProducts(query);
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    productProvider.searchProducts(query);
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final products = productProvider.products;

    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No games found'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final imagePath = ImageHelper.getProductImagePath(
          product.productPhotoPath,
          product.productName,
        );

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imagePath,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[300],
                  child: const Icon(Icons.videogame_asset, size: 25),
                );
              },
            ),
          ),
          title: Text(product.productName),
          subtitle: Text('฿${product.productPrice.toStringAsFixed(0)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text(product.productRating.toStringAsFixed(1)),
            ],
          ),
          onTap: () {
            Navigator.of(context).pushNamed('/product/${product.productId}');
          },
        );
      },
    );
  }
}
