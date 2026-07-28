import 'dart:async';
import 'dart:io';
import 'package:stackfood_multivendor_driver/common/widgets/custom_asset_image_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_card.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_tool_tip_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/details_custom_card.dart';
import 'package:stackfood_multivendor_driver/feature/language/controllers/localization_controller.dart';
import 'package:stackfood_multivendor_driver/feature/notification/controllers/notification_controller.dart';
import 'package:stackfood_multivendor_driver/feature/order/controllers/order_controller.dart';
import 'package:stackfood_multivendor_driver/feature/order/widgets/divider_widget.dart';
import 'package:stackfood_multivendor_driver/feature/order/widgets/order_details_shimmer.dart';
import 'package:stackfood_multivendor_driver/feature/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor_driver/feature/notification/domain/models/notification_body_model.dart';
import 'package:stackfood_multivendor_driver/feature/chat/domain/models/conversation_model.dart';
import 'package:stackfood_multivendor_driver/feature/order/domain/models/order_details_model.dart';
import 'package:stackfood_multivendor_driver/feature/order/domain/models/order_model.dart';
import 'package:stackfood_multivendor_driver/feature/order/widgets/camera_button_sheet_widget.dart';
import 'package:stackfood_multivendor_driver/feature/order/widgets/cancellation_dialogue_widget.dart';
import 'package:stackfood_multivendor_driver/feature/order/widgets/collect_money_delivery_sheet_widget.dart';
import 'package:stackfood_multivendor_driver/feature/order/widgets/dialogue_image_widget.dart';
import 'package:stackfood_multivendor_driver/feature/order/widgets/info_card_widget.dart';
import 'package:stackfood_multivendor_driver/feature/order/widgets/order_product_widget.dart';
import 'package:stackfood_multivendor_driver/feature/order/widgets/slider_button_widget.dart';
import 'package:stackfood_multivendor_driver/feature/order/widgets/verify_delivery_sheet_widget.dart';
import 'package:stackfood_multivendor_driver/feature/profile/controllers/profile_controller.dart';
import 'package:stackfood_multivendor_driver/helper/date_converter_helper.dart';
import 'package:stackfood_multivendor_driver/helper/price_converter_helper.dart';
import 'package:stackfood_multivendor_driver/helper/responsive_helper.dart';
import 'package:stackfood_multivendor_driver/helper/route_helper.dart';
import 'package:stackfood_multivendor_driver/helper/string_extensions.dart';
import 'package:stackfood_multivendor_driver/util/color_resources.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:stackfood_multivendor_driver/util/images.dart';
import 'package:stackfood_multivendor_driver/util/styles.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_button_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_image_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int? orderId;
  final bool? isRunningOrder;
  final int? orderIndex;
  final bool fromNotification;
  final String? orderStatus;
  const OrderDetailsScreen({super.key, required this.orderId, required this.isRunningOrder, required this.orderIndex, this.fromNotification = false, this.orderStatus});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {

  Timer? _timer;
  int? orderPosition;

  /// Screen-local copies. The controller holds a single order at a time, so a
  /// second details screen (or an incoming request) would otherwise repaint
  /// this one with another order's items and quantities.
  OrderModel? _order;
  List<OrderDetailsModel>? _details;
  bool _wasCurrentRoute = true;

  bool get _isCurrentRoute => mounted && (ModalRoute.of(context)?.isCurrent ?? true);

  void _startApiCalling(){
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if(!_isCurrentRoute) {
        _wasCurrentRoute = false;
        return;
      }
      if(!_wasCurrentRoute) {
        // Came back from a pushed screen: another order may have taken over
        // the controller, so reload this one in full.
        _wasCurrentRoute = true;
        _loadData();
        return;
      }
      Get.find<OrderController>().getOrderWithId(widget.orderId);
      // Items are refreshed too: an order can be edited (quantity changed, item
      // added or removed) while the rider has this screen open, and fetching
      // only the order header would leave the old quantities on screen.
      Get.find<OrderController>().getOrderDetails(widget.orderId);
    });
  }

  Future<void> _loadData() async {
    Get.find<OrderController>().pickPrescriptionImage(isRemove: true, isCamera: false);
    if(Get.find<OrderController>().showDeliveryImageField){
      Get.find<OrderController>().changeDeliveryImageStatus(isUpdate: false);
    }
    Get.find<OrderController>().setActiveOrder(widget.orderId);
    if(widget.orderIndex == null){
      await Get.find<OrderController>().getCurrentOrders(status: Get.find<OrderController>().selectedRunningOrderStatus ?? 'all', isDataClear: false);
      final List<OrderModel> currentOrders = Get.find<OrderController>().currentOrderList ?? [];
      for(int index=0; index<currentOrders.length; index++) {
        if(currentOrders[index].id == widget.orderId){
          orderPosition = index;
          break;
        }
      }
    }
    Get.find<OrderController>().getOrderWithId(widget.orderId);
    Get.find<OrderController>().getOrderDetails(widget.orderId);
  }

  @override
  void initState() {
    super.initState();

    orderPosition = widget.orderIndex;

    _loadData();
    _startApiCalling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// A partial payment whose remaining half is still due in cash. Guarded on
  /// length because `payments` is not always the two-entry list assumed here.
  bool _isPartialCod(OrderModel order) => order.paymentMethod == 'partial_payment'
      && (order.payments?.length ?? 0) > 1 && order.payments![1].paymentMethod == 'cash_on_delivery';

  bool _isCod(OrderModel order) => order.paymentMethod == 'cash_on_delivery' || _isPartialCod(order);

  double? _dueAmount(OrderModel order) => (order.paymentMethod == 'partial_payment' && (order.payments?.length ?? 0) > 1)
      ? order.payments![1].amount?.toDouble() : order.orderAmount;

  void _openCollectMoneySheet(OrderModel order, {required bool isDismissible}) {
    Get.bottomSheet(
      CollectMoneyDeliverySheetWidget(
        orderID: order.id, verify: Get.find<SplashController>().configModel!.orderDeliveryVerification,
        orderAmount: _dueAmount(order), cod: _isCod(order),
      ),
      isScrollControlled: true, isDismissible: isDismissible,
    );
  }

  void _startDeliveryFlow(OrderModel order) {
    final bool verify = Get.find<SplashController>().configModel!.orderDeliveryVerification ?? false;

    if(verify) {
      Get.find<NotificationController>().sendDeliveredNotification(order.id);

      Get.bottomSheet(VerifyDeliverySheetWidget(
        orderID: order.id, verify: true,
        orderAmount: _dueAmount(order), cod: _isCod(order),
      ), isScrollControlled: true).then((isSuccess) {
        // isSuccess is null when the sheet is dismissed by dragging.
        if(isSuccess == true && _isCod(order)) {
          _openCollectMoneySheet(order, isDismissible: false);
        }
      });
    } else {
      _openCollectMoneySheet(order, isDismissible: true);
    }
  }

  void _onDeliverSwipe(OrderModel order) {
    final configModel = Get.find<SplashController>().configModel!;

    if((configModel.orderDeliveryVerification ?? false) || _isCod(order)) {
      Get.find<OrderController>().changeDeliveryImageStatus();
      if(configModel.dmPictureUploadStatus ?? false) {
        showCustomBottomSheet(child: DialogImageWidget());
      } else {
        _startDeliveryFlow(order);
      }
    } else {
      Get.find<OrderController>().updateOrderStatus(order.id, 'delivered').then((success) {
        if(success) {
          Get.find<ProfileController>().getProfile();
          Get.offAllNamed(RouteHelper.getInitialRoute());
        }
      });
    }
  }

  void _onPickUpSwipe(OrderModel order) {
    if(Get.find<ProfileController>().profileModel?.active != 1) {
      showCustomSnackBar('make_yourself_online_first'.tr);
      return;
    }
    // Deliberately stays on this screen: the controller refreshes the order and
    // the slider flips over to "swipe to deliver".
    Get.find<OrderController>().updateOrderStatus(order.id, 'picked_up').then((success) {
      if(success) {
        Get.find<ProfileController>().getProfile();
      }
    });
  }
  @override
  Widget build(BuildContext context) {

    bool? cancelPermission = Get.find<SplashController>().configModel!.canceledByDeliveryman;

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if(widget.fromNotification) {
          Get.offAllNamed(RouteHelper.getInitialRoute());
        }else {
          return;
        }
      },
      child: GetBuilder<OrderController>(builder: (orderController) {
        return Scaffold(
          appBar: AppBar(
            title: Column(children: [
              Text(
                '${'order'.tr} #${widget.orderId}',
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge!.color),
              ),

              Text(
                // Reads the screen-local copy, not the controller, so the title
                // can never show a status belonging to a different order.
                '${'order_is'.tr} ${_order?.orderStatus?.tr ?? ''}',
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
              ),
            ]),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              color: Theme.of(context).textTheme.bodyLarge!.color,
              onPressed: (){
                if(widget.fromNotification) {
                  Get.offAllNamed(RouteHelper.getInitialRoute());
                } else {
                  Get.back();
                }
              },
            ),
            backgroundColor: Theme.of(context).cardColor,
            surfaceTintColor: Theme.of(context).cardColor,
            shadowColor: Theme.of(context).hintColor.withValues(alpha: 0.5),
            elevation: 2,
          ),

          body: Padding(
            padding: const EdgeInsets.all(0),
            child: GetBuilder<OrderController>(builder: (orderController) {

              // Only adopt controller data that actually belongs to this order.
              if(orderController.activeOrderId == widget.orderId) {
                if(orderController.orderModel != null) {
                  _order = orderController.orderModel;
                }
                if(orderController.orderDetailsModel != null) {
                  _details = orderController.orderDetailsModel;
                }
              }

              OrderModel? controllerOrderModel = _order;

              late bool showBottomView;
              late bool showSlider;
              bool showDeliveryConfirmImage = orderController.showDeliveryImageField && (Get.find<SplashController>().configModel!.dmPictureUploadStatus ?? false);

              double? deliveryCharge = 0;
              double itemsPrice = 0;
              double? discount = 0;
              double? couponDiscount = 0;
              double? dmTips = 0;
              double? tax = 0;
              bool? taxIncluded = false;
              double addOns = 0;
              double additionalCharge = 0;
              double extraPackagingAmount = 0;
              double referrerBonusAmount = 0;
              OrderModel? order = controllerOrderModel;

              if(order != null && _details != null ) {

                if(order.orderType == 'delivery') {
                  deliveryCharge = order.deliveryCharge;
                  dmTips = order.dmTips;
                }
                discount = order.restaurantDiscountAmount ?? 0;
                tax = order.totalTaxAmount ?? 0;
                taxIncluded = order.taxStatus ?? false;
                couponDiscount = order.couponDiscountAmount ?? 0;
                additionalCharge = order.additionalCharge ?? 0;
                extraPackagingAmount = order.extraPackagingAmount ?? 0;
                referrerBonusAmount = order.referrerBonusAmount ?? 0;
                for(OrderDetailsModel orderDetails in _details!) {
                  for(AddOn addOn in orderDetails.addOns ?? []) {
                    addOns = addOns + ((addOn.price ?? 0) * (addOn.quantity ?? 0));
                  }
                  itemsPrice = itemsPrice + ((orderDetails.price ?? 0) * (orderDetails.quantity ?? 0));
                }
              }
              deliveryCharge ??= 0;
              dmTips ??= 0;
              //double subTotal = itemsPrice + addOns;
              double total = itemsPrice + addOns - discount + (taxIncluded ? 0 : tax) + deliveryCharge - couponDiscount + dmTips + additionalCharge + extraPackagingAmount - referrerBonusAmount;

              // Simplified flow: once the rider has the order it is theirs to
              // pick up. confirmed/processing/handover are kept only so orders
              // created under the old store-driven flow still finish normally.
              bool readyForPickUp = controllerOrderModel != null && (controllerOrderModel.orderStatus == 'accepted'
                  || controllerOrderModel.orderStatus == 'confirmed' || controllerOrderModel.orderStatus == 'processing'
                  || controllerOrderModel.orderStatus == 'handover');
              bool pickedUp = controllerOrderModel?.orderStatus == 'picked_up';

              if(controllerOrderModel != null){
                showBottomView = readyForPickUp || pickedUp;
                showSlider = readyForPickUp || pickedUp;
              }

              return (_details != null && controllerOrderModel != null && order != null) ? Column(children: [

                Expanded(child: SingleChildScrollView(
                  child: Column(children: [

                    DateConverter.isBeforeTime(controllerOrderModel.scheduleAt) ? (controllerOrderModel.orderStatus != 'handover' && controllerOrderModel.orderStatus != 'delivered'
                    && controllerOrderModel.orderStatus != 'failed' && controllerOrderModel.orderStatus != 'canceled' && controllerOrderModel.orderStatus != 'refund_requested' && controllerOrderModel.orderStatus != 'our_for_delivery'
                    && controllerOrderModel.orderStatus != 'refunded' && controllerOrderModel.orderStatus != 'refund_request_canceled') ? Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                      child: Row(children: [
                        CustomAssetImageWidget(
                          image: Images.cooking,
                          height: 60, width: 60, fit: BoxFit.contain,
                        ),
                        const SizedBox(width: Dimensions.paddingSizeLarge),

                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('food_need_to_deliver_within'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor)),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(
                              DateConverter.differenceInMinute(controllerOrderModel.restaurantDeliveryTime, controllerOrderModel.createdAt, controllerOrderModel.processingTime, controllerOrderModel.scheduleAt) < 5 ? '1 - 5'
                              : '${DateConverter.differenceInMinute(controllerOrderModel.restaurantDeliveryTime, controllerOrderModel.createdAt, controllerOrderModel.processingTime, controllerOrderModel.scheduleAt)-5} '
                              '- ${DateConverter.differenceInMinute(controllerOrderModel.restaurantDeliveryTime, controllerOrderModel.createdAt, controllerOrderModel.processingTime, controllerOrderModel.scheduleAt)}',
                              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                            Text('min'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor)),
                          ]),
                        ]),
                      ]),
                    ) : const SizedBox() : const SizedBox(),

                    controllerOrderModel.bringChangeAmount != null && controllerOrderModel.bringChangeAmount! > 0 ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      decoration: BoxDecoration(
                        color: const Color(0XFF009AF1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(text: 'please_bring'.tr, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
                          TextSpan(text: ' ${PriceConverter.convertPrice(controllerOrderModel.bringChangeAmount)}', style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
                          TextSpan(text: ' ${'in_change_for_the_customer_when_making_the_delivery'.tr}', style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        ]),
                      ),
                    ) : const SizedBox(),
                    DividerWidget(height: controllerOrderModel.bringChangeAmount != null && controllerOrderModel.bringChangeAmount! > 0 ? Dimensions.paddingSizeSmall : 0),

                    InfoCardWidget(
                      title: 'customer_contact_details'.tr, addressModel: controllerOrderModel.deliveryAddress, isDelivery: true,
                      image: controllerOrderModel.customer != null ? '${controllerOrderModel.customer!.imageFullUrl}' : '',
                      name: controllerOrderModel.deliveryAddress?.contactPersonName, phone: controllerOrderModel.deliveryAddress?.contactPersonNumber,
                      latitude: controllerOrderModel.deliveryAddress?.latitude, longitude: controllerOrderModel.deliveryAddress?.longitude,
                      showButton: (controllerOrderModel.orderStatus != 'delivered' && controllerOrderModel.orderStatus != 'failed' && controllerOrderModel.orderStatus != 'canceled'),
                      orderModel: controllerOrderModel,
                      messageOnTap: () async {
                        if(controllerOrderModel.customer != null){
                          _timer?.cancel();
                          await Get.toNamed(RouteHelper.getChatRoute(
                            notificationBody: NotificationBodyModel(
                              orderId: controllerOrderModel.id, customerId: controllerOrderModel.customer!.id,
                            ),
                            user: User(
                              id: controllerOrderModel.customer!.id, fName: controllerOrderModel.customer!.fName,
                              lName: controllerOrderModel.customer!.lName, imageFullUrl: controllerOrderModel.customer!.imageFullUrl,
                            ),
                          ));
                          _startApiCalling();
                        }else{
                          showCustomSnackBar('customer_not_found'.tr);
                        }
                      },
                    ),
                    DividerWidget(),

                    InfoCardWidget(
                      isRestaurant: true,
                      title: 'restaurant_details'.tr, addressModel: DeliveryAddress(address: controllerOrderModel.restaurantAddress),
                      image: '${controllerOrderModel.restaurantLogoFullUrl}',
                      name: controllerOrderModel.restaurantName, phone: controllerOrderModel.restaurantPhone,
                      latitude: controllerOrderModel.restaurantLat, longitude: controllerOrderModel.restaurantLng,
                      showButton: (controllerOrderModel.orderStatus != 'delivered' && controllerOrderModel.orderStatus != 'failed' && controllerOrderModel.orderStatus != 'canceled'),
                      orderModel: controllerOrderModel,
                      messageOnTap: () async {
                        if(controllerOrderModel.restaurantModel != 'commission' && controllerOrderModel.chatPermission == 0){
                          showCustomSnackBar('restaurant_have_no_chat_permission'.tr);
                        }else{
                          _timer?.cancel();
                          await Get.toNamed(RouteHelper.getChatRoute(
                            notificationBody: NotificationBodyModel(
                              orderId: controllerOrderModel.id, vendorId: controllerOrderModel.vendorId,
                            ),
                            user: User(
                              id: controllerOrderModel.vendorId, fName: controllerOrderModel.restaurantName,
                              imageFullUrl: controllerOrderModel.restaurantLogoFullUrl,
                            ),
                          ));
                          _startApiCalling();
                        }
                      },
                    ),
                    DividerWidget(),

                    DetailsCustomCard(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      borderRadius: Dimensions.radiusSmall,
                      isBorder: false,
                      child: Column(children: [

                        Row(children: [

                          Text('item_info'.tr,  style: robotoBold),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                          Text(
                            '(${_details!.length})',
                            style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
                          ),

                        ]),
                        SizedBox(height: Dimensions.paddingSizeSmall),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _details!.length,
                          itemBuilder: (context, index) {
                            return OrderProductWidgetWidget(order: controllerOrderModel, orderDetails: _details![index], showDivider: index != _details!.length - 1);
                          },
                        ),

                      ]),
                    ),
                    DividerWidget(),

                    (controllerOrderModel.cutlery != null) ? DetailsCustomCard(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      borderRadius: Dimensions.radiusSmall,
                      isBorder: false,
                      child: Row(children: [

                        Text('${'cutlery'.tr}: ', style: robotoBold),
                        const Expanded(child: SizedBox()),

                        Text(
                          controllerOrderModel.cutlery! ? 'yes'.tr : 'no'.tr,
                          style: robotoRegular,
                        ),

                      ]),
                    ) : const SizedBox(),
                    DividerWidget(height: (controllerOrderModel.cutlery != null) ? Dimensions.paddingSizeSmall : 0),

                    controllerOrderModel.unavailableItemNote != null && controllerOrderModel.unavailableItemNote!.isNotEmpty ? DetailsCustomCard(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      borderRadius: Dimensions.radiusSmall,
                      isBorder: false,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        Text('unavailable_item_note'.tr, style: robotoBold),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraLarge),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall + 2),
                            color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                          ),
                          child: Text(
                            controllerOrderModel.unavailableItemNote!.tr,
                            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                          ),
                        ),

                      ]),
                    ): const SizedBox(),
                    DividerWidget(height: controllerOrderModel.unavailableItemNote != null && controllerOrderModel.unavailableItemNote!.isNotEmpty ? Dimensions.paddingSizeSmall : 0),

                    controllerOrderModel.deliveryInstruction != null && controllerOrderModel.deliveryInstruction!.isNotEmpty ? DetailsCustomCard(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      borderRadius: Dimensions.radiusSmall,
                      isBorder: false,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        Text('delivery_instruction'.tr, style: robotoBold),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraLarge),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall + 2),
                            color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                          ),
                          child: Text(
                            controllerOrderModel.deliveryInstruction!.tr,
                            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                          ),
                        ),

                      ]),
                    ): const SizedBox(),
                    DividerWidget(height: controllerOrderModel.deliveryInstruction != null && controllerOrderModel.deliveryInstruction!.isNotEmpty ? Dimensions.paddingSizeSmall : 0),

                    (controllerOrderModel.orderNote != null && controllerOrderModel.orderNote!.isNotEmpty) ? DetailsCustomCard(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      borderRadius: Dimensions.radiusSmall,
                      isBorder: false,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        Text('additional_note'.tr, style: robotoBold),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraLarge),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall + 2),
                            color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                          ),
                          child: Text(
                            controllerOrderModel.orderNote!.tr,
                            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                          ),
                        ),

                      ]),
                    ) : const SizedBox(),
                    DividerWidget(height: (controllerOrderModel.orderNote  != null && controllerOrderModel.orderNote!.isNotEmpty) ? Dimensions.paddingSizeSmall : 0),

                    (controllerOrderModel.orderStatus == 'delivered' && controllerOrderModel.orderProofFullUrl != null && controllerOrderModel.orderProofFullUrl!.isNotEmpty) ? DetailsCustomCard(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      borderRadius: Dimensions.radiusSmall,
                      isBorder: false,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        Text('order_proof'.tr, style: robotoBold),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            childAspectRatio: 1.5,
                            crossAxisCount: ResponsiveHelper.isTab(context) ? 5 : 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 5,
                          ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controllerOrderModel.orderProofFullUrl!.length,
                          itemBuilder: (BuildContext context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () => openDialog(context, controllerOrderModel.orderProofFullUrl![index]),
                                child: Center(child: ClipRRect(
                                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                  child: CustomImageWidget(
                                    image: controllerOrderModel.orderProofFullUrl![index],
                                    width: 100, height: 100,
                                  ),
                                )),
                              ),
                            );
                          },
                        ),

                      ]),
                    ) : const SizedBox(),
                    DividerWidget(height: (controllerOrderModel.orderStatus == 'delivered' && controllerOrderModel.orderProofFullUrl != null && controllerOrderModel.orderProofFullUrl!.isNotEmpty) ? Dimensions.paddingSizeSmall : 0),

                    DetailsCustomCard(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      borderRadius: Dimensions.radiusSmall,
                      isBorder: false,
                      child: Column(children: [

                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('payment_method'.tr, style: robotoBold),

                          Text(
                            controllerOrderModel.paymentStatus!.toTitleCase(),
                            style: robotoRegular.copyWith(
                              color: controllerOrderModel.paymentStatus == 'paid' ? ColorResources.green : controllerOrderModel.paymentStatus == 'unpaid' ? ColorResources.red : Theme.of(context).primaryColor,
                            ),
                          ),
                        ]),
                        Divider(height: 30, color: Theme.of(context).hintColor.withValues(alpha: 0.3)),

                        controllerOrderModel.paymentMethod == 'cash_on_delivery' ? Row(children: [
                          CustomAssetImageWidget(image: Images.cashIcon, height: 25, width: 25),
                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          Text('cash'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
                        ]) : (controllerOrderModel.paymentMethod == 'wallet' || order.paymentMethod == 'partial_payment') ? Row(children: [
                          CustomAssetImageWidget(image: Images.partialPayIcon, height: 25, width: 25),
                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          Text(controllerOrderModel.paymentMethod == 'wallet' ? 'wallet_payment'.tr : 'partial_payment'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
                        ]) : Row(children: [
                          CustomAssetImageWidget(image: Images.cashIcon, height: 25, width: 25),
                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          Text('digital_payment'.tr, style: robotoRegular),
                        ]),
                      ]),
                    ),
                    DividerWidget(),

                    DetailsCustomCard(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      borderRadius: Dimensions.radiusSmall,
                      isBorder: false,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('billing_info'.tr, style: robotoBold),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        Row(children: [
                          Text('subtotal'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),

                          taxIncluded ? Text(' ${'vat_tax_inc'.tr}', style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor,
                          )) : const SizedBox(),
                          const Expanded(child: SizedBox()),

                          Text(PriceConverter.convertPrice(total - dmTips), style: robotoMedium, textDirection: TextDirection.ltr),
                        ]),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('delivery_man_tips'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
                          Text('(+) ${PriceConverter.convertPrice(dmTips)}', style: robotoMedium.copyWith(color: Theme.of(context).primaryColor), textDirection: TextDirection.ltr),
                        ]),
                        Divider(height: 25, color: Theme.of(context).hintColor.withValues(alpha: 0.3)),

                        order.orderType != 'parcel' ? Column(children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('store_will_get'.tr, style: robotoRegular.copyWith(color: ColorResources.green)),
                            Text(
                              PriceConverter.convertPrice(orderController.orderModel?.storeWillGet ?? orderController.storeWillGet),
                              style: robotoMedium.copyWith(color: ColorResources.green, fontWeight: FontWeight.bold),
                              textDirection: TextDirection.ltr,
                            ),
                          ]),
                          Divider(height: 25, color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
                        ]) : const SizedBox(),

                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('total_amount'.tr, style: robotoMedium.copyWith(color: order.paymentMethod == 'partial_payment' ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).primaryColor)),
                          Text(
                            PriceConverter.convertPrice(total), textDirection: TextDirection.ltr,
                            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: order.paymentMethod == 'partial_payment' ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).primaryColor),
                          ),
                        ]),

                        order.paymentMethod == 'partial_payment' ? Column(children: [

                          const SizedBox(height: Dimensions.paddingSizeSmall),

                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('paid_amount_via_wallet'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),

                            Text(
                              PriceConverter.convertPrice(order.payments![0].amount),
                              style: robotoMedium,
                            ),
                          ]),
                          Divider(height: 25, color: Theme.of(context).hintColor.withValues(alpha: 0.3)),

                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('${order.payments![1].paymentStatus == 'paid' ? 'paid_by'.tr : 'due_amount'.tr} (${order.payments?[1].paymentMethod?.toString().replaceAll('_', ' ')})', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor)),
                            Text(
                              PriceConverter.convertPrice(order.payments![1].amount),
                              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
                            ),
                          ]),
                        ]) : const SizedBox(),
                      ]),
                    ),
                    controllerOrderModel.orderStatus != 'delivered' ? DividerWidget(height: Dimensions.paddingSizeDefault) : const SizedBox(),

                  ]),
                )),

                showDeliveryConfirmImage && controllerOrderModel.orderStatus != 'delivered' ? CustomCard(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  isBorder: false,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    Row(children: [
                      Text('completed_after_delivery_picture'.tr, style: robotoBold),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      CustomToolTip(
                        message: 'completed_after_delivery_picture'.tr,
                        child: const Icon(Icons.info_outline, size: 20),
                      ),
                    ]),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Container(
                      height: 80,
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      decoration: BoxDecoration(
                        color: Theme.of(context).hintColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: orderController.pickedPrescriptions.length+1,
                        itemBuilder: (context, index) {

                          XFile? file = index == orderController.pickedPrescriptions.length ? null : orderController.pickedPrescriptions[index];

                          if(index < 5 && index == orderController.pickedPrescriptions.length) {
                            return InkWell(
                              onTap: () {
                                Get.bottomSheet(const CameraButtonSheetWidget());
                              },
                              child: Container(
                                height: 60, width: 60, alignment: Alignment.center, decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              ),
                                child:  Icon(Icons.camera_alt_sharp, color: Theme.of(context).primaryColor, size: 32),
                              ),
                            );
                          }

                          return file != null ? Container(
                            margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            ),
                            child: Stack(children: [

                              ClipRRect(
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                child: GetPlatform.isWeb ? Image.network(
                                  file.path, width: 60, height: 60, fit: BoxFit.cover,
                                ) : Image.file(
                                  File(file.path), width: 60, height: 60, fit: BoxFit.cover,
                                ),
                              ),

                            ]),
                          ) : const SizedBox();
                        },
                      ),
                    ),

                  ]),
                ) : const SizedBox(),

                SafeArea(
                  child: showDeliveryConfirmImage && controllerOrderModel.orderStatus != 'delivered' ? Container(
                    color: Theme.of(context).cardColor,
                    padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeDefault),
                    child: CustomButtonWidget(
                      buttonText: 'complete_delivery'.tr,
                      onPressed: () => _startDeliveryFlow(order),
                    ),
                  ) : (showBottomView && showSlider) ? CustomCard(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    isBorder: false,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      Row(children: [
                        CustomAssetImageWidget(image: Images.amountIcon, height: 20, width: 20),
                        const SizedBox(width: 5),

                       Text('amount_collect_from_customer'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                        Spacer(),


                        Text(
                          PriceConverter.convertPrice(_isPartialCod(order) ? order.payments![1].amount : order.paymentMethod == 'cash_on_delivery' ? total : 0),
                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
                        ),

                      ]),

                      order.paymentMethod == 'cash_on_delivery' ? SizedBox() : (order.paymentMethod == 'partial_payment' && !_isPartialCod(order)) ? Padding(
                        padding: const EdgeInsets.only(left: 23),
                        child: Text('already_paid'.tr, style: robotoBold.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall)),
                      ) : const SizedBox(),
                      SizedBox(height: Dimensions.paddingSizeSmall),

                      // Cancelling is only offered before pick up, matching the
                      // backend rule that an order can no longer be dropped once
                      // the rider has collected it.
                      (readyForPickUp && (cancelPermission ?? false)) ? Padding(
                        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                        child: TextButton(
                          onPressed: (){
                            orderController.setOrderCancelReason('');
                            Get.dialog(CancellationDialogueWidget(orderId: widget.orderId));
                          },
                          style: TextButton.styleFrom(
                            minimumSize: const Size(1170, 40), padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                              side: BorderSide(width: 1, color: Theme.of(context).textTheme.bodyLarge!.color!),
                            ),
                          ),
                          child: Text('cancel'.tr, textAlign: TextAlign.center, style: robotoRegular.copyWith(
                            color: Theme.of(context).textTheme.titleSmall!.color,
                            fontSize: Dimensions.fontSizeLarge,
                          )),
                        ),
                      ) : const SizedBox(),

                      SliderButtonWidget(
                        action: () {
                          if(pickedUp) {
                            _onDeliverSwipe(order);
                          }else if(readyForPickUp) {
                            _onPickUpSwipe(order);
                          }
                        },
                        label: Text(
                          pickedUp ? 'swipe_to_deliver_order'.tr : 'swipe_to_pick_up_order'.tr,
                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
                        ),
                        dismissThresholds: 0.5, dismissible: false, shimmer: true,
                        width: 1170, height: 50, buttonSize: 50, radius: 10,
                        icon: Center(child: Icon(
                          Get.find<LocalizationController>().isLtr ? Icons.double_arrow_sharp : Icons.keyboard_double_arrow_left_sharp,
                          color: ColorResources.white, size: 20.0,
                        )),
                        isLtr: Get.find<LocalizationController>().isLtr,
                        boxShadow: const BoxShadow(blurRadius: 0),
                        buttonColor: Theme.of(context).primaryColor,
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        baseColor: Theme.of(context).primaryColor,
                      ),
                    ]),
                  ) : const SizedBox(),
                ),

              ]) : OrderDetailsShimmer();
            }),
          ),
        );
      }),
    );
  }

  void openDialog(BuildContext context, String imageUrl) => showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
        child: Stack(children: [

          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            child: PhotoView(
              tightMode: true,
              imageProvider: NetworkImage(imageUrl),
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
            ),
          ),

          Positioned(top: 0, right: 0, child: IconButton(
            splashRadius: 5,
            onPressed: () => Get.back(),
            icon: Icon(Icons.cancel, color: Theme.of(context).colorScheme.error),
          )),

        ]),
      );
    },
  );
}