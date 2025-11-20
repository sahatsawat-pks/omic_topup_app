class ImageHelper {
  /// Get the asset path for a product image based on product name or photo path
  /// Prioritizes database path attribute over name matching
  static String getProductImagePath(String? productPhotoPath, String productName) {
    // If photo path is provided from database, use it directly
    if (productPhotoPath != null && productPhotoPath.isNotEmpty) {
      // Remove any leading slashes or path prefixes
      String cleanPath = productPhotoPath.trim();
      
      // If it's already a full asset path, return as-is
      if (cleanPath.startsWith('assets/')) {
        return cleanPath;
      }
      
      // Remove common prefixes like /img/products/, /images/, etc.
      cleanPath = cleanPath.replaceAll(RegExp(r'^/?(img/products/|images/products/|products/)'), '');
      
      // Build the full asset path
      return 'assets/images/products/$cleanPath';
    }
    
    // Fallback: try to match by name if no path in database
    final name = productName.toLowerCase();
    
    if (name.contains('free fire') || name.contains('freefire')) {
      return 'assets/images/products/freefire.png';
    } else if (name.contains('genshin')) {
      return 'assets/images/products/genshin.png';
    } else if (name.contains('league') || name.contains('lol')) {
      return 'assets/images/products/lol.png';
    } else if (name.contains('pokemon')) {
      return 'assets/images/products/pokemonunite.png';
    } else if (name.contains('pubg') && name.contains('mobile')) {
      return 'assets/images/products/pubgm.png';
    } else if (name.contains('pubg')) {
      return 'assets/images/products/pubg.png';
    } else if (name.contains('roblox')) {
      return 'assets/images/products/roblox.png';
    } else if (name.contains('rov') || name.contains('arena')) {
      return 'assets/images/products/rov.png';
    } else if (name.contains('star rail')) {
      return 'assets/images/products/starrail.png';
    } else if (name.contains('valorant')) {
      return 'assets/images/products/valorant.png';
    }
    
    // Default placeholder
    return 'assets/images/placeholder.png';
  }
  
  /// Get app icon path
  static const String appIcon = 'assets/icons/icon.png';
}
