import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_app_bar_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_image_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_snackbar_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_text_field_widget.dart';
import 'package:stackfood_multivendor_driver/feature/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor_driver/feature/profile/controllers/profile_controller.dart';
import 'package:stackfood_multivendor_driver/feature/profile/domain/models/profile_model.dart';
import 'package:stackfood_multivendor_driver/feature/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UpdateProfileScreen extends StatefulWidget {
  final ProfileModel profileModel;
  const UpdateProfileScreen({super.key, required this.profileModel});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  String? _countryDialCode;
  String? _countryCode;

  @override
  void initState() {
    super.initState();

    _countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;
    _countryCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code;
    _splitPhone(Get.find<ProfileController>().profileModel!.phone!);

    _firstNameController.text = widget.profileModel.fName ?? '';
    _lastNameController.text = widget.profileModel.lName ?? '';
    _emailController.text = widget.profileModel.email ?? '';
    Get.find<ProfileController>().initData();
  }

  void _splitPhone(String? phone) async {
    try {
      if (phone != null && phone.isNotEmpty) {
        PhoneNumber phoneNumber = PhoneNumber.parse(phone);
        _countryDialCode = '+${phoneNumber.countryCode}';
        _countryCode = phoneNumber.isoCode.name;
        _phoneController.text = phoneNumber.international.substring(_countryDialCode!.length);
      }
    } catch (e) {
      debugPrint('Phone Number Parse Error: $e');
    }
    setState(() {});
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'edit_profile'.tr),

      body: GetBuilder<ProfileController>(builder: (profileController) {
        return Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(children: [

            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [
                  SizedBox(height: 30),

                  Center(child: Stack(children: [

                    ClipOval(child: profileController.pickedFile != null ? GetPlatform.isWeb ? Image.network(
                      profileController.pickedFile!.path, width: 100, height: 100, fit: BoxFit.cover) : Image.file(
                      File(profileController.pickedFile!.path), width: 100, height: 100, fit: BoxFit.cover) : CustomImageWidget(
                      image: '${profileController.profileModel!.imageFullUrl}',
                      height: 100, width: 100, fit: BoxFit.cover,
                    )),

                    Positioned(
                      bottom: 0, right: 0, top: 0, left: 0,
                      child: InkWell(
                        onTap: () => profileController.pickImage(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle,
                            border: Border.all(width: 1, color: Theme.of(context).cardColor),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              border: Border.all(width: 2, color: Colors.white),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ])),
                  SizedBox(height: Dimensions.paddingSizeOverLarge),

                  CustomTextFieldWidget(
                    hintText: 'first_name'.tr,
                    labelText: 'first_name'.tr,
                    controller: _firstNameController,
                    focusNode: _firstNameFocus,
                    nextFocus: _lastNameFocus,
                    inputType: TextInputType.name,
                    capitalization: TextCapitalization.words,
                    isRequired: true,
                    prefixIcon: Icons.person,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeOverLarge),

                  CustomTextFieldWidget(
                    hintText: 'last_name'.tr,
                    labelText: 'last_name'.tr,
                    controller: _lastNameController,
                    focusNode: _lastNameFocus,
                    nextFocus: _emailFocus,
                    inputType: TextInputType.name,
                    capitalization: TextCapitalization.words,
                    isRequired: true,
                    prefixIcon: Icons.person,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeOverLarge),

                  CustomTextFieldWidget(
                    hintText: 'email'.tr,
                    labelText: 'email'.tr,
                    controller: _emailController,
                    focusNode: _emailFocus,
                    nextFocus: _phoneFocus,
                    inputType: TextInputType.emailAddress,
                    isRequired: true,
                    prefixIcon: Icons.email,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeOverLarge),

                  CustomTextFieldWidget(
                    hintText: 'xxx-xxx-xxxxx'.tr,
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    inputType: TextInputType.phone,
                    inputAction: TextInputAction.done,
                    isPhone: true,
                    onCountryChanged: (CountryCode countryCode) {
                      _countryDialCode = countryCode.dialCode;
                    },
                    countryDialCode: _countryCode,
                    labelText: 'phone'.tr,
                    isRequired: true,
                    isEnabled: false,
                  ),

                ]),
              ),
            ),

            CustomButtonWidget(
              isLoading: profileController.isLoading,
              buttonText: 'update_profile'.tr,
              onPressed: () => _updateProfile(profileController),
            ),

          ]),
        );
      }),
    );
  }

  void _updateProfile(ProfileController profileController) async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String email = _emailController.text.trim();
    String phoneNumber = _phoneController.text.trim();
    if (profileController.profileModel!.fName == firstName &&
        profileController.profileModel!.lName == lastName && profileController.profileModel!.phone == phoneNumber &&
        profileController.profileModel!.email == _emailController.text && profileController.pickedFile == null) {
      showCustomSnackBar('change_something_to_update'.tr);
    }else if (firstName.isEmpty) {
      showCustomSnackBar('enter_your_first_name'.tr);
    }else if (lastName.isEmpty) {
      showCustomSnackBar('enter_your_last_name'.tr);
    }else if (email.isEmpty) {
      showCustomSnackBar('enter_email_address'.tr);
    }else if (!GetUtils.isEmail(email)) {
      showCustomSnackBar('enter_a_valid_email_address'.tr);
    }else if (phoneNumber.isEmpty) {
      showCustomSnackBar('enter_phone_number'.tr);
    }else if (phoneNumber.length < 6) {
      showCustomSnackBar('enter_a_valid_phone_number'.tr);
    } else {
      ProfileModel updatedUser = ProfileModel(fName: firstName, lName: lastName, email: email, phone: phoneNumber);
      await profileController.updateUserInfo(updatedUser, Get.find<AuthController>().getUserToken());
    }
  }

}