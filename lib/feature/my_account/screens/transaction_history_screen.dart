import 'package:stackfood_multivendor_driver/feature/my_account/controllers/my_account_controller.dart';
import 'package:stackfood_multivendor_driver/helper/price_converter_helper.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:stackfood_multivendor_driver/util/styles.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_app_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {

  @override
  void initState() {
    super.initState();
    
    Get.find<MyAccountController>().getWalletPaymentList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'transaction_history'.tr),

      body: GetBuilder<MyAccountController>(builder: (myAccountController) {
        return myAccountController.transactions != null ? myAccountController.transactions!.isNotEmpty ? ListView.builder(
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
          itemCount: myAccountController.transactions!.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Column(children: [

              Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
                child: Row(children: [

                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      Text(PriceConverter.convertPrice(myAccountController.transactions![index].amount), style: robotoBold),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                      Text(
                        '${'paid_via'.tr} ${myAccountController.transactions![index].method?.replaceAll('_', ' ').capitalize??''}',
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
                      ),

                    ]),
                  ),

                  Text(
                    myAccountController.transactions![index].paymentTime.toString(),
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                  ),

                ]),
              ),

              index == myAccountController.transactions!.length - 1 ? const SizedBox() : const Divider(height: 1),

            ]);
          },
        ) : Center(child: Text('no_transaction_found'.tr)) : const Center(child: CircularProgressIndicator());
      }),
    );
  }
}