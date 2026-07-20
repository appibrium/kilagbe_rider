import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_button_widget.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:stackfood_multivendor_driver/util/images.dart';
import 'package:stackfood_multivendor_driver/util/styles.dart';

class NotFoundOrderBottomSheet extends StatelessWidget {
  const NotFoundOrderBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusExtraLarge), topRight: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        Container(
          height: 5, width: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
        ),

        Align(
          alignment: Alignment.topRight,
          child: InkWell(
            onTap: () {
              Get.back();
            },
            child: Icon(Icons.close, color: Theme.of(context).disabledColor),
          ),
        ),

        Image.asset(
          Images.warning, height: 60, width: 60,
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Text(
            'this_order_is_no_longer_assign_to_you'.tr,
            style: robotoRegular.copyWith(color: Theme.of(context).hintColor), textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 30),

        SizedBox(
          width: 100,
          child: CustomButtonWidget(
            onPressed: () {
              Get.back();
            },
            buttonText: 'got_it'.tr,
            backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.5),
            fontColor: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
      ]),

    );
  }
}
