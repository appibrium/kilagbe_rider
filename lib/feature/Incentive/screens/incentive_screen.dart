import 'package:stackfood_multivendor_driver/common/widgets/details_custom_card.dart';
import 'package:stackfood_multivendor_driver/feature/profile/controllers/profile_controller.dart';
import 'package:stackfood_multivendor_driver/helper/price_converter_helper.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:stackfood_multivendor_driver/util/styles.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_app_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IncentiveScreen extends StatefulWidget {
  const IncentiveScreen({super.key});

  @override
  State<IncentiveScreen> createState() => _IncentiveScreenState();
}

class _IncentiveScreenState extends State<IncentiveScreen> {

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CustomAppBarWidget(title: 'incentive'.tr),

      body: GetBuilder<ProfileController>(builder: (profileController) {

        for (var incentive in profileController.profileModel!.incentiveList!) {
          if(incentive.earning! < profileController.profileModel!.todaysEarning!){
            selectedIndex = profileController.profileModel!.incentiveList!.indexOf(incentive);
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Container(
              height: 130, width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xffEEF3FE), borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('you_have_total_incentive'.tr, textAlign: TextAlign.center, style: robotoRegular.copyWith(color: Colors.black)),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Text(
                    PriceConverter.convertPrice(profileController.profileModel!.totalIncentiveEarning),
                    textAlign: TextAlign.center, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge, color: Colors.black),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
              child: Text('current_incentive_offers'.tr, style: robotoMedium),
            ),

            profileController.profileModel!.incentiveList!.isNotEmpty ? ListView.builder(
              shrinkWrap: true,
              itemCount: profileController.profileModel!.incentiveList!.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: DetailsCustomCard(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                    child: Column(children: [

                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                        Text('earning'.tr, style: robotoRegular),

                        Text('incentive'.tr, style: robotoRegular),

                      ]),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                        Text(PriceConverter.convertPrice(profileController.profileModel!.incentiveList![index].earning), style: robotoMedium),

                        Text(PriceConverter.convertPrice(profileController.profileModel!.incentiveList![index].incentive), style: robotoMedium),

                      ]),

                    ]),
                  ),
                );
              },
            ) : Text('no_offer_available'.tr, style: robotoBold),

          ]),
        );
      }),
    );
  }
}