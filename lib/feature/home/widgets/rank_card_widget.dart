import 'package:stackfood_multivendor_driver/common/widgets/custom_image_widget.dart';
import 'package:stackfood_multivendor_driver/feature/rider_rank/controllers/rider_rank_controller.dart';
import 'package:stackfood_multivendor_driver/helper/route_helper.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:stackfood_multivendor_driver/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RankCardWidget extends StatelessWidget {
  const RankCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RiderRankController>(builder: (riderRankController) {
      final rank = riderRankController.riderRankModel;

      String? progressLabel;
      if (rank?.nextTier != null) {
        final target = rank!.nextTier!.monthlyOrderTarget ?? 0;
        final current = rank.thisMonthOrderCount ?? 0;
        progressLabel = '$current/$target ${'orders_to'.tr} ${rank.nextTier!.name}';
      } else if (rank?.currentTier != null) {
        progressLabel = 'you_have_reached_the_highest_rank'.tr;
      }

      return InkWell(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        onTap: () => Get.toNamed(RouteHelper.getRiderRankRoute()),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: const Color(0xffEEF3FE),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Row(children: [

            rank?.currentTier?.badge != null ? CustomImageWidget(
              image: rank!.currentTier!.badge!, height: 45, width: 45, fit: BoxFit.contain,
            ) : Icon(Icons.emoji_events, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(width: Dimensions.paddingSizeDefault),

            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('your_current_rank'.tr, style: robotoRegular.copyWith(color: Colors.black54, fontSize: Dimensions.fontSizeSmall)),
                const SizedBox(height: 2),
                Text(
                  rank?.currentTier?.name ?? 'unranked'.tr,
                  style: robotoBold.copyWith(color: Colors.black, fontSize: Dimensions.fontSizeLarge),
                ),
                if (progressLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    progressLabel, style: robotoRegular.copyWith(color: Colors.black54, fontSize: Dimensions.fontSizeExtraSmall),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ]),
            ),

            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),

          ]),
        ),
      );
    });
  }
}
