import 'package:equatable/equatable.dart';

import 'product.dart';

class ProductDetail extends Equatable {
  const ProductDetail({
    required this.product,
    this.images = const [],
    this.dynamicValues = const {},
    this.fieldConfig = const {},
  });

  final Product product;
  final List<String> images;
  final Map<String, dynamic> dynamicValues;
  final Map<String, dynamic> fieldConfig;

  @override
  List<Object?> get props => [product, images, dynamicValues, fieldConfig];
}
