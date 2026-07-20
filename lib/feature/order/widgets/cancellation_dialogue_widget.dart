import 'package:stackfood_multivendor_driver/feature/order/controllers/order_controller.dart';
import 'package:stackfood_multivendor_driver/feature/profile/controllers/profile_controller.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:stackfood_multivendor_driver/util/styles.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_button_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CancellationDialogueWidget extends StatefulWidget {
  final int? orderId;
  const CancellationDialogueWidget({super.key, required this.orderId});

  @override
  State<CancellationDialogueWidget> createState() => _CancellationDialogueWidgetState();
}

class _CancellationDialogueWidgetState extends State<CancellationDialogueWidget> {

  @override
  void initState() {
    super.initState();
    Get.find<OrderController>().getOrderCancelReasons();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      insetPadding: const EdgeInsets.all(30),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: GetBuilder<OrderController>(builder: (orderController) {
        return SizedBox(
          width: 500,
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => Get.back(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.cancel_outlined, size: 25, color: Theme.of(context).disabledColor),
                ),
              ),
            ),

            Text('select_cancellation_reasons'.tr, style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),

            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

                  orderController.orderCancelReasons != null ? orderController.orderCancelReasons!.isNotEmpty ? Flexible(
                    child: ListView.builder(
                      itemCount: orderController.orderCancelReasons!.length,
                      shrinkWrap: true,
                      padding: EdgeInsets.only(top: Dimensions.paddingSizeLarge, bottom: Dimensions.paddingSizeSmall),
                      itemBuilder: (context, index){
                        return Container(
                          margin: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                          padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            boxShadow: orderController.orderCancelReasons![index].reason == orderController.cancelReason ? [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)] : [],
                            border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
                          ),
                          child: InkWell(
                            onTap: (){
                              orderController.setOrderCancelReason(orderController.orderCancelReasons![index].reason);
                            },
                            child: Row(
                              children: [
                                Icon(orderController.orderCancelReasons![index].reason == orderController.cancelReason ? Icons.radio_button_checked : Icons.radio_button_off, color: Theme.of(context).primaryColor, size: 18),
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                Flexible(child: Text(orderController.orderCancelReasons![index].reason!, style: robotoRegular, maxLines: 3, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ) : SizedBox() : const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault), child: CircularProgressIndicator())),
                ]),
              ),
            ),
            SizedBox(height: Dimensions.paddingSizeSmall),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
              child: !orderController.isLoading ? Row(children: [
                Expanded(child: CustomButtonWidget(
                  buttonText: 'cancel'.tr, backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                  fontColor: Theme.of(context).textTheme.bodyLarge?.color,
                  onPressed: () => Get.back(),
                )),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Expanded(child: CustomButtonWidget(
                  buttonText: 'submit'.tr,
                  onPressed: (){
                    if(orderController.cancelReason != '' && orderController.cancelReason != null){

                      orderController.updateOrderStatus(widget.orderId, 'canceled', back: true, reason: orderController.cancelReason).then((success) {
                        if(success) {
                          Get.find<ProfileController>().getProfile();
                          Get.find<OrderController>().getCurrentOrders(status: Get.find<OrderController>().selectedRunningOrderStatus!);
                        }
                      });

                    }else{
                      if(Get.isDialogOpen!){
                        Get.back();
                      }

                      showCustomSnackBar('you_did_not_select_select_any_reason'.tr);

                    }
                  },
                )),
              ]) : const Center(child: CircularProgressIndicator()),
            ),
          ]),
        );
      }),
    );
  }
}