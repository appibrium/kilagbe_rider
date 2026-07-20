import 'package:cached_network_image/cached_network_image.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_asset_image_widget.dart';
import 'package:stackfood_multivendor_driver/util/images.dart';
import 'package:flutter/cupertino.dart';

class CustomImageWidget extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final String? placeholder;
  const CustomImageWidget({super.key, required this.image, this.height, this.width, this.fit = BoxFit.cover, this.placeholder});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: image, height: height, width: width, fit: fit,
      placeholder: (context, url) => CustomAssetImageWidget(image: placeholder ?? Images.placeholder, height: height, width: width, fit: fit),
      errorWidget: (context, url, error) => CustomAssetImageWidget(image: placeholder ?? Images.placeholder, height: height, width: width, fit: fit),
    );
  }
}