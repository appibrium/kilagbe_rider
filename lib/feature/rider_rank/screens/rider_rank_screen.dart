import 'package:stackfood_multivendor_driver/common/widgets/custom_app_bar_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_image_widget.dart';
import 'package:stackfood_multivendor_driver/feature/rider_rank/controllers/rider_rank_controller.dart';
import 'package:stackfood_multivendor_driver/feature/rider_rank/domain/models/rider_rank_model.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:stackfood_multivendor_driver/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RiderRankScreen extends StatefulWidget {
  const RiderRankScreen({super.key});

  @override
  State<RiderRankScreen> createState() => _RiderRankScreenState();
}

class _RiderRankScreenState extends State<RiderRankScreen> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<RiderRankController>().getRiderRank();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'my_rank'.tr, isBackButtonExist: true),

      body: GetBuilder<RiderRankController>(builder: (riderRankController) {
        if (riderRankController.isLoading && riderRankController.riderRankModel == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final RiderRankModel? rank = riderRankController.riderRankModel;
        if (rank == null) {
          return Center(child: Text('failed_to_load_data'.tr, style: robotoRegular));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Current tier hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                color: const Color(0xffEEF3FE), borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Column(children: [
                if (rank.currentTier?.badge != null)
                  CustomImageWidget(image: rank.currentTier!.badge!, height: 70, width: 70, fit: BoxFit.contain)
                else
                  Icon(Icons.emoji_events, size: 60, color: Theme.of(context).disabledColor),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text('your_current_rank'.tr, style: robotoRegular.copyWith(color: Colors.black)),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text(
                  rank.currentTier?.name ?? 'unranked'.tr,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge, color: Colors.black),
                ),
              ]),
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            // Progress toward next tier
            if (rank.nextTier != null) ...[
              Text('${'progress_toward'.tr} ${rank.nextTier!.name}', style: robotoMedium),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              _ProgressRow(
                label: 'completed_orders_this_month'.tr,
                current: rank.thisMonthOrderCount ?? 0,
                target: rank.nextTier!.monthlyOrderTarget ?? 0,
              ),
              _ProgressRow(
                label: '${'fast_deliveries_this_month'.tr} (< ${rank.fastDeliveryMinutes ?? 30} ${'min'.tr})',
                current: rank.thisMonthFastDeliveryCount ?? 0,
                target: rank.nextTier!.monthlyFastDeliveryTarget ?? 0,
              ),
              _ProgressRow(
                label: 'lifetime_ratings_received'.tr,
                current: rank.lifetimeRatingCount ?? 0,
                target: rank.nextTier!.ratingCountTarget ?? 0,
              ),
            ] else if (rank.allTiers != null && rank.allTiers!.isNotEmpty) ...[
              Text('you_have_reached_the_highest_rank'.tr, style: robotoMedium),
            ],

            const SizedBox(height: Dimensions.paddingSizeDefault),

            // Tier ladder
            Text('all_ranks'.tr, style: robotoMedium),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            if (rank.allTiers != null)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rank.allTiers!.length,
                itemBuilder: (context, index) {
                  final RiderRankTierModel tier = rank.allTiers![index];
                  final bool unlocked = (rank.currentTier?.sequence ?? 0) >= (tier.sequence ?? 0);

                  return Container(
                    margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      border: Border.all(color: Theme.of(context).disabledColor.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(unlocked ? Icons.emoji_events : Icons.lock_outline, color: unlocked ? Theme.of(context).primaryColor : Theme.of(context).disabledColor),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(child: Text(tier.name ?? '', style: robotoMedium)),
                      Text(
                        '${tier.monthlyOrderTarget}/${'mo'.tr}  •  ${tier.monthlyFastDeliveryTarget} ${'fast'.tr}  •  ${tier.ratingCountTarget} ${'ratings'.tr}',
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                      ),
                    ]),
                  );
                },
              ),
          ]),
        );
      }),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  const _ProgressRow({required this.label, required this.current, required this.target});

  @override
  Widget build(BuildContext context) {
    final double progress = target > 0 ? (current / target).clamp(0, 1).toDouble() : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(label, style: robotoRegular)),
          Text('$current / $target', style: robotoMedium),
        ]),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: LinearProgressIndicator(
            value: progress, minHeight: 8,
            backgroundColor: Theme.of(context).disabledColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      ]),
    );
  }
}
