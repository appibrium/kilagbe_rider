import 'package:stackfood_multivendor_driver/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_card.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_snackbar_widget.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/controllers/my_account_controller.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/widgets/payment_method_bottom_sheet_widget.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/widgets/wallet_attention_alert_widget.dart';
import 'package:stackfood_multivendor_driver/feature/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor_driver/feature/profile/controllers/profile_controller.dart';
import 'package:stackfood_multivendor_driver/helper/price_converter_helper.dart';
import 'package:stackfood_multivendor_driver/helper/route_helper.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:stackfood_multivendor_driver/util/images.dart';
import 'package:stackfood_multivendor_driver/util/styles.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_app_bar_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {

  @override
  void initState() {
    super.initState();

    Get.find<ProfileController>().getProfile();
    Get.find<MyAccountController>().getWalletPaymentList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: 'my_account'.tr,
        isBackButtonExist: false,
      ),

      body: GetBuilder<MyAccountController>(builder: (myAccountController) {
        return GetBuilder<ProfileController>(builder: (profileController) {
          return (profileController.profileModel != null && myAccountController.transactions != null) ? RefreshIndicator(
            onRefresh: () async {
              await profileController.getProfile();
              await myAccountController.getWalletPaymentList();
            },
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Column(children: [

                Expanded(
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(children: [
                      Container(
                        width: context.width, height: 129,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          color: Color(0xff222324).withValues(alpha: 0.9),
                          image: const DecorationImage(
                            image: AssetImage(Images.cashInHandBg),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                Row(
                                  children: [
                                    Image.asset(Images.walletIcon, width: 40, height: 40),
                                    const SizedBox(width: Dimensions.paddingSizeSmall),
                                    Text('payable_amount'.tr, style: robotoMedium.copyWith(color: Colors.white)),
                                  ],
                                ),
                                const SizedBox(height: Dimensions.paddingSizeDefault),

                                Text(PriceConverter.convertPrice(profileController.profileModel!.payableBalance), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge, color: Colors.white)),
                              ]),
                            ),

                            Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                              profileController.profileModel!.adjustable! ? InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return GetBuilder<MyAccountController>(builder: (myAccountController) {
                                        return AlertDialog(
                                          title: Center(child: Text('cash_adjustment'.tr)),
                                          content: Text('cash_adjustment_description'.tr, textAlign: TextAlign.center),
                                          actions: [

                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Row(children: [

                                                Expanded(
                                                  child: CustomButtonWidget(
                                                    onPressed: () => Get.back(),
                                                    backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.5),
                                                    buttonText: 'cancel'.tr,
                                                  ),
                                                ),
                                                const SizedBox(width: Dimensions.paddingSizeExtraLarge),

                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () {
                                                      myAccountController.makeWalletAdjustment();
                                                    },
                                                    child: Container(
                                                      height: 45,
                                                      alignment: Alignment.center,
                                                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                                        color: Theme.of(context).primaryColor,
                                                      ),
                                                      child: !myAccountController.isLoading ? Text('ok'.tr, style: robotoBold.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeLarge),)
                                                          : const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)),
                                                    ),
                                                  ),
                                                ),

                                              ]),
                                            ),

                                          ],
                                        );
                                      });
                                    }
                                  );
                                },
                                child: Container(
                                  width: 115,
                                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  child: Text('adjust_payments'.tr, textAlign: TextAlign.center, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).cardColor)),
                                ),
                              ) : const SizedBox(),
                              SizedBox(height: profileController.profileModel!.adjustable! ? Dimensions.paddingSizeLarge : 0),

                              InkWell(
                                onTap: () {
                                  if(Get.find<SplashController>().configModel!.activePaymentMethodList!.isEmpty || !Get.find<SplashController>().configModel!.digitalPayment!){
                                    showCustomSnackBar('currently_there_are_no_payment_options_available_please_contact_admin_regarding_any_payment_process_or_queries'.tr);
                                  }else if(Get.find<SplashController>().configModel!.minAmountToPayDm! > profileController.profileModel!.payableBalance!){
                                    showCustomSnackBar('${'you_do_not_have_sufficient_balance_to_pay_the_minimum_payable_balance_is'.tr} ${PriceConverter.convertPrice(Get.find<SplashController>().configModel!.minAmountToPayDm)}');
                                  }else{
                                    showCustomBottomSheet(child: const PaymentMethodBottomSheetWidget());
                                  }
                                },
                                child: Container(
                                  width: profileController.profileModel!.adjustable! ? 115 : null,
                                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                    color: profileController.profileModel!.showPayNowButton! ? Theme.of(context).primaryColor : Theme.of(context).hintColor.withValues(alpha: 0.8),
                                  ),
                                  child: Text('pay_now'.tr, textAlign: TextAlign.center, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).cardColor)),
                                ),
                              ),

                            ]),
                          ]),
                        ),

                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      Row(children: [

                        Expanded(
                          child: CustomCard(
                            isBorder: false,
                            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                              Text(
                                PriceConverter.convertPrice(profileController.profileModel!.cashInHands),
                                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeSmall),

                              Text('cash_in_hand'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
                            ]),
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeDefault),

                        Expanded(
                          child: CustomCard(
                            isBorder: false,
                            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                              Text(
                                PriceConverter.convertPrice(profileController.profileModel!.totalWithdrawn),
                                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeSmall),

                              Text('total_withdrawn'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
                            ]),
                          ),
                        ),

                      ]),
                      const SizedBox(height:Dimensions.paddingSizeSmall),

                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('transaction_history'.tr, style: robotoMedium),

                        InkWell(
                          onTap: () => Get.toNamed(RouteHelper.getTransactionHistoryRoute()),
                          child: Padding(
                            padding:  const EdgeInsets.fromLTRB(10, 10, 0, 10),
                            child: Text('view_all'.tr, style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor, decoration: TextDecoration.underline,
                              decorationColor: Theme.of(context).primaryColor,
                            )),
                          ),
                        ),
                      ]),

                      myAccountController.transactions!.isNotEmpty ? ListView.builder(
                        itemCount: myAccountController.transactions!.length > 25 ? 25 : myAccountController.transactions!.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return Column(children: [

                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
                              child: Row(children: [
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(PriceConverter.convertPrice(myAccountController.transactions![index].amount), style: robotoBold, textDirection: TextDirection.ltr),
                                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                                    Text('${'paid_via'.tr} ${myAccountController.transactions![index].method?.replaceAll('_', ' ').capitalize??''}', style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor,
                                    )),
                                  ]),
                                ),
                                Text(myAccountController.transactions![index].paymentTime.toString(),
                                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                                ),
                              ]),
                            ),

                            index == (myAccountController.transactions!.length > 25 ? 25 : myAccountController.transactions!.length) - 1 ? const SizedBox() : const Divider(height: 1),
                          ]);
                        },
                      ) : Padding(padding: const EdgeInsets.only(top: 250), child: Text('no_transaction_found'.tr)),

                    ]),

                  ),
                ),

                (profileController.profileModel!.overFlowWarning! || profileController.profileModel!.overFlowBlockWarning!)
                    ? WalletAttentionAlertWidget(isOverFlowBlockWarning: profileController.profileModel!.overFlowBlockWarning!) : const SizedBox(),

              ]),
            ),
          ) : const Center(child: CircularProgressIndicator());
        });
      }),
    );
  }
}