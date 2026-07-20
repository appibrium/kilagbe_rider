import 'package:stackfood_multivendor_driver/common/widgets/custom_card.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:stackfood_multivendor_driver/util/styles.dart';
import 'package:flutter/material.dart';

class ProfileCardWidget extends StatelessWidget {
  final String title;
  final String data;
  const ProfileCardWidget({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: CustomCard(
      isBorder: false,
      padding: EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

        Text(data, style: robotoBold.copyWith(
          fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).primaryColor,
        )),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        Text(title, style: robotoRegular.copyWith(
          fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
        )),

      ]),
    ));
  }
}