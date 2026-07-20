import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_app_bar_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_confirmation_bottom_sheet.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_image_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_snackbar_widget.dart';
import 'package:stackfood_multivendor_driver/feature/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor_driver/feature/home/widgets/shift_dialogue_widget.dart';
import 'package:stackfood_multivendor_driver/feature/order/controllers/order_controller.dart';
import 'package:stackfood_multivendor_driver/feature/profile/controllers/profile_controller.dart';
import 'package:stackfood_multivendor_driver/feature/profile/widgets/permission_dialog_widget.dart';
import 'package:stackfood_multivendor_driver/feature/profile/widgets/profile_button_widget.dart';
import 'package:stackfood_multivendor_driver/feature/profile/widgets/profile_card_widget.dart';
import 'package:stackfood_multivendor_driver/feature/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor_driver/helper/date_converter_helper.dart';
import 'package:stackfood_multivendor_driver/helper/route_helper.dart';
import 'package:stackfood_multivendor_driver/util/app_constants.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:stackfood_multivendor_driver/util/images.dart';
import 'package:stackfood_multivendor_driver/util/styles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'my_profile'.tr, isBackButtonExist: false),

      body: GetBuilder<ProfileController>(builder: (profileController) {
        return profileController.profileModel == null ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
          padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(children: [

            Container(
              padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraLarge, horizontal: Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                image: DecorationImage(
                  colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.dstATop),
                  image: AssetImage(
                    Images.profileBg,
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Row(children: [

                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).cardColor),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: CustomImageWidget(
                      image: profileController.profileModel?.imageFullUrl ?? '',
                      height: 80, width: 80,
                    ),
                  ),
                ),
                SizedBox(width: Dimensions.paddingSizeLarge),

                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      '${profileController.profileModel?.fName} ${profileController.profileModel?.lName}',
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge + 1, color: Theme.of(context).cardColor),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Dimensions.paddingSizeExtraSmall),

                    Text(
                      profileController.profileModel?.phone ?? '',
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).cardColor),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),

              ]),
            ),
            SizedBox(height: Dimensions.paddingSizeLarge),

            profileController.profileModel!.shiftName != null ? Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
              child: RichText(text: TextSpan(children: [
                TextSpan(text: '${'shift'.tr}: ', style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeSmall)),
                TextSpan(text: ' ${profileController.profileModel!.shiftName}', style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
                TextSpan(text: ' (${DateConverter.onlyTimeShow(profileController.profileModel!.shiftStartTime!)} - ${DateConverter.onlyTimeShow(profileController.profileModel!.shiftEndTime!)})',
                    style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
              ])),
            ) : const SizedBox(),

            Row(children: [

              ProfileCardWidget(title: 'total_order'.tr, data: profileController.profileModel?.orderCount.toString() ?? '0'),
              const SizedBox(width: Dimensions.paddingSizeDefault),

              ProfileCardWidget(title: 'complete_delivery'.tr, data: profileController.profileModel?.totalDelivery.toString() ?? '0'),

            ]),
            SizedBox(height: Dimensions.paddingSizeLarge),

            GetBuilder<OrderController>(builder: (orderController) {
              return (profileController.profileModel != null && orderController.currentOrderList != null) ? ProfileButtonWidget(
                icon: Icons.online_prediction,
                title: 'online_status'.tr,
                isButtonActive: profileController.profileModel!.active == 1,
                onTap: () async {
                  bool isActive = profileController.profileModel!.active == 1;

                  if(isActive && orderController.currentOrderList!.isNotEmpty) {
                    showCustomSnackBar('you_can_not_go_offline_now'.tr);
                  }else {
                    if(isActive) {
                      showCustomBottomSheet(
                        child: CustomConfirmationBottomSheet(
                          title: 'offline'.tr,
                          description: 'are_you_sure_to_offline'.tr,
                          onConfirm: () {
                            if(Get.isSnackbarOpen) {
                              Get.closeCurrentSnackbar();
                            }
                            profileController.updateActiveStatus(isUpdate: true);
                          },
                        ),
                      );
                    }else {
                      LocationPermission permission = await Geolocator.checkPermission();
                      if(permission == LocationPermission.denied || permission == LocationPermission.deniedForever
                          || (GetPlatform.isIOS ? false : permission == LocationPermission.whileInUse)) {

                        _checkPermission(() {
                          if(profileController.shifts != null && profileController.shifts!.isNotEmpty) {
                            Get.dialog(const ShiftDialogueWidget());
                          }else{
                            profileController.updateActiveStatus();
                          }
                        });
                      }else {
                        if(profileController.shifts != null && profileController.shifts!.isNotEmpty) {
                          Get.dialog(const ShiftDialogueWidget());
                        }else{
                          profileController.updateActiveStatus();
                        }
                      }
                    }
                  }
                },
              ) : const SizedBox();
            }),
            SizedBox(height: Dimensions.paddingSizeSmall),

            ProfileButtonWidget(icon: CupertinoIcons.pencil_circle, title: 'edit_profile'.tr, onTap: () {
              Get.toNamed(RouteHelper.getUpdateProfileRoute(profileModel: profileController.profileModel!));
            }),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            ProfileButtonWidget(icon: Icons.settings, title: 'settings'.tr, onTap: () {
              Get.toNamed(RouteHelper.getSettingsRoute());
            }),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            ProfileButtonWidget(icon: Icons.lock, title: 'change_password'.tr, onTap: () {
              Get.toNamed(RouteHelper.getResetPasswordRoute('', '', 'password-change'));
            }),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            ProfileButtonWidget(icon: Icons.chat_outlined, title: 'conversation'.tr, onTap: () {
              Get.toNamed(RouteHelper.getConversationListRoute());
            }),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            (profileController.profileModel != null && profileController.profileModel!.earnings == 1) ? Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: ProfileButtonWidget(icon: Icons.wallet, title: 'wallet'.tr, onTap: () {
                Get.toNamed(RouteHelper.getMyAccountRoute());
              }),
            ) : const SizedBox(),

            (profileController.profileModel!.type != 'restaurant_wise' && profileController.profileModel!.earnings != 0) ? ProfileButtonWidget(icon: Icons.local_offer_rounded, title: 'incentive_offers'.tr, onTap: () {
              Get.toNamed(RouteHelper.getIncentiveRoute());
            }) : const SizedBox(),
            SizedBox(height: (profileController.profileModel!.type != 'restaurant_wise' && profileController.profileModel!.earnings != 0) ? Dimensions.paddingSizeSmall : 0),

            if(Get.find<SplashController>().configModel!.disbursementType == 'automated' && profileController.profileModel!.type != 'restaurant_wise' && profileController.profileModel!.earnings != 0)
              Column(children: [

                Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                  child: ProfileButtonWidget(icon: Icons.payments, title: 'disbursement'.tr, onTap: () {
                    Get.toNamed(RouteHelper.getDisbursementRoute());
                  }),
                ),

                ProfileButtonWidget(icon: Icons.money, title: 'disbursement_methods'.tr, onTap: () {
                  Get.toNamed(RouteHelper.getWithdrawMethodRoute());
                }),
                const SizedBox(height: Dimensions.paddingSizeSmall),

              ]),

            ProfileButtonWidget(icon: Icons.list, title: 'terms_condition'.tr, onTap: () {
              Get.toNamed(RouteHelper.getTermsRoute());
            }),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            ProfileButtonWidget(icon: Icons.privacy_tip, title: 'privacy_policy'.tr, onTap: () {
              Get.toNamed(RouteHelper.getPrivacyRoute());
            }),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            ProfileButtonWidget(
              icon: CupertinoIcons.delete, title: 'delete_account'.tr,
              onTap: () {
                showCustomBottomSheet(
                  child: CustomConfirmationBottomSheet(
                    cancelButtonText: 'no'.tr, confirmButtonText: 'yes'.tr,
                    title: 'are_you_sure_to_delete_account'.tr,
                    description: 'it_will_remove_your_all_information'.tr,
                    onConfirm: () {
                      profileController.removeDriver();
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            ProfileButtonWidget(icon: Icons.logout, title: 'logout'.tr, onTap: () {
              showCustomBottomSheet(
                child: CustomConfirmationBottomSheet(
                  cancelButtonText: 'no'.tr, confirmButtonText: 'yes'.tr,
                  title: 'logout'.tr,
                  description: 'are_you_sure_to_logout'.tr,
                  onConfirm: () {
                    Get.find<AuthController>().clearSharedData();
                    profileController.stopLocationRecord();
                    Get.offAllNamed(RouteHelper.getSignInRoute());
                  },
                ),
              );
            }),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${'version'.tr}:', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall)),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),

              Text(AppConstants.appVersion.toString(), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall)),
            ]),

          ]),
        );
      }),
    );
  }

  void _checkPermission(Function callback) async {
    LocationPermission permission = await Geolocator.requestPermission();
    permission = await Geolocator.checkPermission();

    while(Get.isDialogOpen == true) {
      Get.back();
    }

    if(permission == LocationPermission.denied/* || (GetPlatform.isIOS ? false : permission == LocationPermission.whileInUse)*/) {
      Get.dialog(PermissionDialogWidget(description: 'you_denied'.tr, onOkPressed: () async {
        Get.back();
        final perm = await Geolocator.requestPermission();
        if(perm == LocationPermission.deniedForever) await Geolocator.openAppSettings();
        Future.delayed(Duration(seconds: 3), () {
          if(GetPlatform.isAndroid) _checkPermission(callback);
        });
      }));
    }else if(permission == LocationPermission.deniedForever || (GetPlatform.isIOS ? false : permission == LocationPermission.whileInUse)) {
      Get.dialog(PermissionDialogWidget(description:  permission == LocationPermission.whileInUse ? 'you_denied'.tr : 'you_denied_forever'.tr, onOkPressed: () async {
        Get.back();
        await Geolocator.openAppSettings();
        Future.delayed(Duration(seconds: 3), () {
          if(GetPlatform.isAndroid) _checkPermission(callback);
        });
      }));
    }else {
      callback();
    }
  }

}