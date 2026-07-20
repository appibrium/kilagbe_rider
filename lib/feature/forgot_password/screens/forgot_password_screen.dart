import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_asset_image_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_snackbar_widget.dart';
import 'package:stackfood_multivendor_driver/feature/forgot_password/controllers/forgot_password_controller.dart';
import 'package:stackfood_multivendor_driver/feature/language/controllers/localization_controller.dart';
import 'package:stackfood_multivendor_driver/feature/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor_driver/helper/custom_validator.dart';
import 'package:stackfood_multivendor_driver/helper/route_helper.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:stackfood_multivendor_driver/util/images.dart';
import 'package:stackfood_multivendor_driver/util/styles.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_app_bar_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_button_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {

  String? _countryDialCode;
  final TextEditingController _numberController = TextEditingController();
  final FocusNode _numberFocus = FocusNode();
  bool isPhone = false;

  @override
  void initState() {
    super.initState();
    isPhone = (Get.find<SplashController>().configModel!.isSmsActive! || Get.find<SplashController>().configModel!.firebaseOtpVerification!);
    _countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_numberFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CustomAppBarWidget(title: 'forgot_password'.tr),

      body: isPhone ? SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeOverLarge, vertical: Dimensions.paddingSizeLarge),
        child: Column(children: [

          CustomAssetImageWidget(image: Images.forgot, height: 220),

          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 30),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(children: [
                TextSpan(
                  text: 'please_enter_your_registered'.tr,
                  style: robotoRegular.copyWith( color: Theme.of(context).hintColor),
                ),

                TextSpan(
                  text: ' ${'mobile_number'.tr} ',
                  style: robotoBold.copyWith( color: Theme.of(context).hintColor),
                ),

                TextSpan(
                  text: 'so_we_can_recover_your_password'.tr,
                  style: robotoRegular.copyWith( color: Theme.of(context).hintColor),
                ),
              ]),
            )
          ),

          CustomTextFieldWidget(
            labelText: 'phone'.tr,
            hintText: 'xxx-xxx-xxxxx'.tr,
            controller: _numberController,
            focusNode: _numberFocus,
            inputType: TextInputType.phone,
            inputAction: TextInputAction.done,
            isPhone: true,
            onCountryChanged: (CountryCode countryCode) {
              _countryDialCode = countryCode.dialCode;
            },
            countryDialCode: _countryDialCode != null ? CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code
            : Get.find<LocalizationController>().locale.countryCode,
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          GetBuilder<ForgotPasswordController>(builder: (forgotPasswordController) {
            return CustomButtonWidget(
              isLoading: forgotPasswordController.isLoading,
              buttonText: 'verify'.tr,
              onPressed: () => _forgetPass(_countryDialCode!),
            );
          }),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeOverLarge),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(children: [
                TextSpan(
                  text: 'if_you_have_any_queries_feel_free_to_contact_with_our'.tr,
                  style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
                ),
                TextSpan(
                  text: ' ${'help_and_support'.tr} ',
                  style: robotoBold.copyWith(color: Theme.of(context).primaryColor),
                  recognizer: TapGestureRecognizer()..onTap = () => Get.toNamed(RouteHelper.getSupportRoute()),
                ),
              ]),
            ),
          ),

        ]),
      ) : Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

          const CustomAssetImageWidget(image: Images.forgot, height: 220),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
            child: Text('sorry_something_went_wrong'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge), textAlign: TextAlign.center),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
            child: Text(
              'please_try_again_after_some_time_or_contact_with_our_support_team'.tr,
              style: robotoRegular.copyWith(color: Theme.of(context).hintColor), textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeOverLarge),

          CustomButtonWidget(
            buttonText: 'help_and_support'.tr,
            onPressed: () {
              Get.toNamed(RouteHelper.getSupportRoute());
            }
          ),

        ]),
      ),

    );
  }


  void _forgetPass(String countryCode) async {
    String phone = _numberController.text.trim();

    String numberWithCountryCode = countryCode+phone;
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if (phone.isEmpty) {
      showCustomSnackBar('enter_phone_number'.tr);
    }else if (!phoneValid.isValid) {
      showCustomSnackBar('invalid_phone_number'.tr);
    }else {
      Get.find<ForgotPasswordController>().forgotPassword(numberWithCountryCode).then((status) async {
        if (status.isSuccess) {
          if(Get.find<SplashController>().configModel!.firebaseOtpVerification!) {
            Get.find<ForgotPasswordController>().firebaseVerifyPhoneNumber(numberWithCountryCode);
          } else {
            Get.toNamed(RouteHelper.getVerificationRoute(numberWithCountryCode));
          }
        }else {
          showCustomSnackBar(status.message);
        }
      });
    }
  }
  
}