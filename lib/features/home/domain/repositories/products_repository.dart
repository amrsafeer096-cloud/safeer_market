import '../entities/product.dart';

abstract class ProductsRepository {
  Future<List<Product>> fetchProducts();

  /// Up to [limit] in-stock products in random order.
  Future<List<Product>> fetchRandomProducts({required int limit});

  /// In-stock products on offer. [maxRows] caps how many discounted rows are read
  /// (the home row needs a handful); null reads them all for «عرض الكل».
  Future<List<Product>> fetchOfferProducts({int? maxRows});

  /// In-stock products created after [since], newest first.
  Future<List<Product>> fetchNewProducts({required DateTime since});

  /// Every product, in stock or not, that still needs a photo: `image_url`
  /// missing or not a valid link, or (where the database can tell) a Storage
  /// link whose file doesn't exist. In stock first, then by name.
  Future<List<Product>> fetchProductsWithoutImage();
}
