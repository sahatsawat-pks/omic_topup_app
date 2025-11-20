import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../config/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../utils/image_helper.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OMiC Games'),
        actions: [
          if (authProvider.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.of(context).pushNamed('/user/profile'),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () => productProvider.loadProducts(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Hero Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                color: AppTheme.accentColor,
                child: Column(
                  children: [
                    Image.asset(
                      ImageHelper.appIcon,
                      width: 60,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.sports_esports, size: 60, color: Colors.white);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome to OMiC Games',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Your game top-up destination',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              
              // Products
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Popular Games',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    if (productProvider.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading products from database...'),
                            ],
                          ),
                        ),
                      )
                    else if (productProvider.error != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, size: 60, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Error: ${productProvider.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => productProvider.loadProducts(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (productProvider.products.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              const Icon(Icons.inbox, size: 60, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'No products available',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Please check database connection',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pushNamed('/debug'),
                                child: const Text('Run Database Tests'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
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
                              onTap: () => Navigator.of(context).pushNamed(
                                '/product/${product.productId}',
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
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
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      product.productName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
