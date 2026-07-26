import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_confirmation_bottom_sheet.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_snackbar_widget.dart';
import 'package:stackfood_multivendor_driver/feature/home/widgets/shift_dialogue_widget.dart';
import 'package:stackfood_multivendor_driver/feature/order/controllers/order_controller.dart';
import 'package:stackfood_multivendor_driver/feature/profile/controllers/profile_controller.dart';
import 'package:stackfood_multivendor_driver/feature/profile/widgets/permission_dialog_widget.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:stackfood_multivendor_driver/util/styles.dart';

class OnlineStatusWidget extends StatelessWidget {
  const OnlineStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController) {
      return GetBuilder<OrderController>(builder: (orderController) {
        if (profileController.profileModel == null || orderController.currentOrderList == null) {
          return const SizedBox();
        }

        bool isActive = profileController.profileModel!.active == 1;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
          child: Row(mainAxisSize: MainAxisSize.min, children: [

            Text(
              isActive ? 'online'.tr : 'offline'.tr,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: isActive ? Colors.green : Theme.of(context).disabledColor),
            ),
            const SizedBox(width: 4),

            Transform.scale(
              scale: 0.75,
              child: Switch(
                value: isActive,
                activeThumbColor: Colors.green,
                onChanged: (_) => _onTap(profileController, orderController, isActive),
              ),
            ),

          ]),
        );
      });
    });
  }

  void _onTap(ProfileController profileController, OrderController orderController, bool isActive) async {
    if (isActive && orderController.currentOrderList!.isNotEmpty) {
      showCustomSnackBar('you_can_not_go_offline_now'.tr);
      return;
    }

    if (isActive) {
      showCustomBottomSheet(
        child: CustomConfirmationBottomSheet(
          title: 'offline'.tr,
          description: 'are_you_sure_to_offline'.tr,
          onConfirm: () {
            if (Get.isSnackbarOpen) {
              Get.closeCurrentSnackbar();
            }
            profileController.updateActiveStatus(isUpdate: true);
          },
        ),
      );
    } else {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever
          || (GetPlatform.isIOS ? false : permission == LocationPermission.whileInUse)) {
        _checkPermission(() {
          if (profileController.shifts != null && profileController.shifts!.isNotEmpty) {
            Get.dialog(const ShiftDialogueWidget());
          } else {
            profileController.updateActiveStatus();
          }
        });
      } else {
        if (profileController.shifts != null && profileController.shifts!.isNotEmpty) {
          Get.dialog(const ShiftDialogueWidget());
        } else {
          profileController.updateActiveStatus();
        }
      }
    }
  }

  void _checkPermission(Function callback) async {
    LocationPermission permission = await Geolocator.requestPermission();
    permission = await Geolocator.checkPermission();

    while (Get.isDialogOpen == true) {
      Get.back();
    }

    if (permission == LocationPermission.denied) {
      Get.dialog(PermissionDialogWidget(description: 'you_denied'.tr, onOkPressed: () async {
        Get.back();
        final perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.deniedForever) await Geolocator.openAppSettings();
        Future.delayed(const Duration(seconds: 3), () {
          if (GetPlatform.isAndroid) _checkPermission(callback);
        });
      }));
    } else if (permission == LocationPermission.deniedForever || (GetPlatform.isIOS ? false : permission == LocationPermission.whileInUse)) {
      Get.dialog(PermissionDialogWidget(description: permission == LocationPermission.whileInUse ? 'you_denied'.tr : 'you_denied_forever'.tr, onOkPressed: () async {
        Get.back();
        await Geolocator.openAppSettings();
        Future.delayed(const Duration(seconds: 3), () {
          if (GetPlatform.isAndroid) _checkPermission(callback);
        });
      }));
    } else {
      callback();
    }
  }
}
