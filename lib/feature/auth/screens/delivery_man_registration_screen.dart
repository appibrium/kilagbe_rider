import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_asset_image_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_card.dart';
import 'package:stackfood_multivendor_driver/feature/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor_driver/feature/auth/controllers/address_controller.dart';
import 'package:stackfood_multivendor_driver/feature/language/controllers/localization_controller.dart';
import 'package:stackfood_multivendor_driver/feature/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor_driver/feature/auth/widgets/additional_data_section_widget.dart';
import 'package:stackfood_multivendor_driver/feature/forgot_password/widgets/pass_view_widget.dart';
import 'package:stackfood_multivendor_driver/helper/custom_validator.dart';
import 'package:stackfood_multivendor_driver/helper/route_helper.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:stackfood_multivendor_driver/util/images.dart';
import 'package:stackfood_multivendor_driver/util/styles.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_button_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_dropdown_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_text_field_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_snackbar_widget.dart';
import 'package:stackfood_multivendor_driver/common/models/config_model.dart';
import 'package:stackfood_multivendor_driver/feature/auth/domain/models/delivery_man_body_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class DeliveryManRegistrationScreen extends StatefulWidget {
  const DeliveryManRegistrationScreen({super.key});

  @override
  State<DeliveryManRegistrationScreen> createState() => _DeliveryManRegistrationScreenState();
}

class _DeliveryManRegistrationScreenState extends State<DeliveryManRegistrationScreen> {

  final TextEditingController _fNameController = TextEditingController();
  final TextEditingController _lNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _identityNumberController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _fNameNode = FocusNode();
  final FocusNode _lNameNode = FocusNode();
  final FocusNode _emailNode = FocusNode();
  final FocusNode _phoneNode = FocusNode();
  final FocusNode _passwordNode = FocusNode();
  final FocusNode _confirmPasswordNode = FocusNode();
  final FocusNode _identityNumberNode = FocusNode();

  String? _countryDialCode;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;
    if(Get.find<AuthController>().showPassView){
      Get.find<AuthController>().showHidePass(isUpdate: false);
    }
    Get.find<AuthController>().pickDmImageForRegistration(false, true);
    Get.find<AuthController>().setIdentityTypeIndex(Get.find<AuthController>().identityTypeList[0], false);
    Get.find<AuthController>().setDMTypeIndex(-1, false);
    Get.find<AddressController>().getZoneList();
    Get.find<AuthController>().getVehicleList();
    Get.find<AuthController>().dmStatusChange(0.4, isUpdate: false);
    Get.find<AuthController>().setJoinUsPageData(isUpdate: false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async{
        if(Get.find<AuthController>().dmStatus != 0.4 && !didPop) {
          Get.find<AuthController>().dmStatusChange(0.4);
        }else{
          Future.delayed(const Duration(milliseconds: 0), () {
            Get.offAllNamed(RouteHelper.getSignInRoute());
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'delivery_man_registration'.tr,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge!.color),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: Theme.of(context).textTheme.bodyLarge!.color,
            onPressed: () async {
              if(Get.find<AuthController>().dmStatus != 0.4){
                Get.find<AuthController>().dmStatusChange(0.4);
              }else{
                Get.back();
              }
            },
          ),
          backgroundColor: Theme.of(context).cardColor,
          surfaceTintColor: Theme.of(context).cardColor,
          shadowColor: Theme.of(context).disabledColor.withValues(alpha: 0.5),
          elevation: 2,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 5, left: 5, right: 5),
              height: 4,
              child: Row(spacing: Dimensions.paddingSizeSmall, children: [
                Expanded(
                  child: Container(
                    height: 4,
                    color: Get.find<AuthController>().dmStatus == 0.4 ? Theme.of(context).primaryColor.withValues(alpha: 0.5) : Theme.of(context).primaryColor,
                  ),
                ),

                Expanded(
                  child: Container(
                    height: 4,
                    color: Get.find<AuthController>().dmStatus != 0.4 ? Theme.of(context).primaryColor.withValues(alpha: 0.5) :  Get.find<AuthController>().dmStatus != 0.4 ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.5),
                  ),
                ),
              ]),
            ),
          ),
        ),

        body: GetBuilder<AuthController>(builder: (authController) {
          return GetBuilder<AddressController>(builder: (addressController) {

            List<int> zoneIndexList = [];
            List<DropdownItem<int>> zoneList = [];
            List<DropdownItem<int>> vehicleList = [];
            List<DropdownItem<int>> dmTypeList = [];
            List<DropdownItem<int>> identityTypeList = [];

            for(int index = 0; index < authController.dmTypeList.length; index++) {
              dmTypeList.add(DropdownItem<int>(value: index, child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${authController.dmTypeList[index]?.tr}'),
              )));
            }

            for(int index=0; index<authController.identityTypeList.length; index++) {
              identityTypeList.add(DropdownItem<int>(value: index, child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(authController.identityTypeList[index].tr),
              )));
            }

            if(addressController.zoneList != null) {
              for(int index=0; index<addressController.zoneList!.length; index++) {
                zoneIndexList.add(index);
              }
            }

            if(addressController.zoneList != null) {
              for(int index=0; index<addressController.zoneList!.length; index++) {
                zoneIndexList.add(index);
                zoneList.add(DropdownItem<int>(value: index, child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('${addressController.zoneList![index].name}'),
                )));
              }
            }

            if(authController.vehicles != null){
              for(int index=0; index<authController.vehicles!.length; index++) {
                vehicleList.add(DropdownItem<int>(value: index + 1, child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('${authController.vehicles![index].type}'),
                )));
              }
            }

            return Column(children: [
              Expanded(child: SingleChildScrollView(
                padding:  EdgeInsets.all(Dimensions.paddingSizeDefault),
                physics: const BouncingScrollPhysics(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  Visibility(
                    visible: authController.dmStatus == 0.4,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      Text('basic_information'.tr, style: robotoBold),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      CustomCard(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Column(children: [
                          CustomTextFieldWidget(
                            labelText: 'first_name'.tr,
                            hintText: 'ex_jhon'.tr,
                            isRequired: true,
                            controller: _fNameController,
                            capitalization: TextCapitalization.words,
                            inputType: TextInputType.name,
                            focusNode: _fNameNode,
                            nextFocus: _lNameNode,
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                          CustomTextFieldWidget(
                            labelText: 'last_name'.tr,
                            hintText: 'ex_doe'.tr,
                            isRequired: true,
                            controller: _lNameController,
                            capitalization: TextCapitalization.words,
                            inputType: TextInputType.name,
                            focusNode: _lNameNode,
                            nextFocus: _phoneNode,
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                          CustomTextFieldWidget(
                            labelText: 'phone'.tr,
                            hintText: 'xxx-xxx-xxxxx'.tr,
                            isRequired: true,
                            controller: _phoneController,
                            focusNode: _phoneNode,
                            nextFocus: _emailNode,
                            inputType: TextInputType.phone,
                            isPhone: true,
                            onCountryChanged: (CountryCode countryCode) {
                              _countryDialCode = countryCode.dialCode;
                            },
                            countryDialCode: _countryDialCode != null ? CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code
                                : Get.find<LocalizationController>().locale.countryCode,
                          ),
                        ]),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      Text('account_information'.tr, style: robotoBold),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      CustomCard(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Column(children: [
                          CustomTextFieldWidget(
                            labelText: 'email'.tr,
                            hintText: 'enter_email'.tr,
                            isRequired: true,
                            controller: _emailController,
                            focusNode: _emailNode,
                            nextFocus: _passwordNode,
                            inputType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                          CustomTextFieldWidget(
                            labelText: 'password'.tr,
                            hintText: 'eight_characters'.tr,
                            isRequired: true,
                            controller: _passwordController,
                            focusNode: _passwordNode,
                            nextFocus: _confirmPasswordNode,
                            inputType: TextInputType.visiblePassword,
                            isPassword: true,
                            onChanged: (value){
                              if(value != null && value.isNotEmpty){
                                if(!authController.showPassView){
                                  authController.showHidePass();
                                }
                                authController.validPassCheck(value);
                              }else{
                                if(authController.showPassView){
                                  authController.showHidePass();
                                }
                              }
                            },
                          ),

                          authController.showPassView ? const Align(alignment: Alignment.centerLeft, child: PassViewWidget()) : const SizedBox(),
                          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                          CustomTextFieldWidget(
                            labelText: 'confirm_password'.tr,
                            hintText: 're_enter_your_password'.tr,
                            isRequired: true,
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordNode,
                            inputAction: TextInputAction.done,
                            inputType: TextInputType.visiblePassword,
                            isPassword: true,
                          ),
                        ]),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      CustomCard(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: 'profile_picture'.tr,
                                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color),
                              ),
                              TextSpan(
                                text: '*',
                                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Colors.red),
                              ),
                            ]),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                          Text('image_format_and_ratio_for_profile'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
                          const SizedBox(height: Dimensions.paddingSizeLarge),

                          Align(alignment: Alignment.center, child: Stack(children: [

                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                child: authController.pickedImage != null ? GetPlatform.isWeb ? Image.network(
                                  authController.pickedImage!.path, width: 120, height: 120, fit: BoxFit.cover,
                                ) : Image.file(
                                  File(authController.pickedImage!.path), width: 120, height: 120, fit: BoxFit.cover,
                                ) : SizedBox(
                                  width: 120, height: 120,
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                                    CustomAssetImageWidget(image: Images.pictureIcon, height: 30, width: 30, color: Theme.of(context).disabledColor),
                                    const SizedBox(height: Dimensions.paddingSizeSmall),

                                    Text(
                                      'click_to_add'.tr,
                                      style: robotoMedium.copyWith(color: Colors.blue, fontSize: Dimensions.fontSizeSmall), textAlign: TextAlign.center,
                                    ),

                                  ]),
                                ),
                              ),
                            ),

                            Positioned(
                              bottom: 0, right: 0, top: 0, left: 0,
                              child: InkWell(
                                onTap: () => authController.pickDmImageForRegistration(true, false),
                                child: DottedBorder(
                                  options: RoundedRectDottedBorderOptions(
                                    color: Theme.of(context).disabledColor,
                                    strokeWidth: 1,
                                    strokeCap: StrokeCap.butt,
                                    dashPattern: const [5, 5],
                                    padding: const EdgeInsets.all(0),
                                    radius: const Radius.circular(Dimensions.radiusDefault),
                                  ),
                                  child: const SizedBox(width: 120, height: 120),
                                ),
                              ),
                            ),

                          ])),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                        ]),
                      ),

                    ]),
                  ),

                  Visibility(
                    visible: authController.dmStatus != 0.4,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      Text('setup'.tr, style: robotoBold),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      CustomCard(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Column(children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              color: Theme.of(context).cardColor,
                              border: Border.all(color: Theme.of(context).disabledColor),
                            ),
                            child: CustomDropdown<int>(
                              onChange: (int? value, int index) {
                                authController.setDMTypeIndex(index, true);
                              },
                              dropdownButtonStyle: DropdownButtonStyle(
                                height: 50,
                                padding: const EdgeInsets.symmetric(
                                  vertical: Dimensions.paddingSizeExtraSmall,
                                  horizontal: Dimensions.paddingSizeExtraSmall,
                                ),
                                primaryColor: Theme.of(context).textTheme.bodyLarge!.color,
                              ),
                              dropdownStyle: DropdownStyle(
                                elevation: 10,
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                              ),
                              items: dmTypeList,
                              child: Padding(
                                padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                                child: authController.dmTypeIndex == -1 ? Row(
                                  children: [
                                    Text(
                                      'select_delivery_type'.tr,
                                      style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
                                    ),

                                    Text(
                                      '*',
                                      style: robotoRegular.copyWith(color: Colors.red),
                                    ),
                                  ],
                                ) : Text(
                                  authController.dmTypeList[authController.dmTypeIndex]!.tr,
                                  style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                          addressController.zoneList != null ? Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              color: Theme.of(context).cardColor,
                              border: Border.all(color: Theme.of(context).disabledColor),
                            ),
                            child: CustomDropdown<int>(
                              onChange: (int? value, int index) {
                                addressController.setZoneIndex(value);
                              },
                              dropdownButtonStyle: DropdownButtonStyle(
                                height: 50,
                                padding: EdgeInsets.zero,
                                primaryColor: Theme.of(context).textTheme.bodyLarge!.color,
                              ),
                              dropdownStyle: DropdownStyle(
                                elevation: 10,
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                              ),
                              items: zoneList,
                              child: Padding(
                                padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                                child: Text('${addressController.zoneList![0].name}'),
                              ),
                            ),
                          ) : const Center(child: CircularProgressIndicator()),
                          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                          authController.vehicleIds != null ? Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              color: Theme.of(context).cardColor,
                              border: Border.all(color: Theme.of(context).disabledColor),
                            ),
                            child: CustomDropdown<int>(
                              onChange: (int? value, int index) {
                                authController.setVehicleIndex(value, true);
                              },
                              dropdownButtonStyle: DropdownButtonStyle(
                                height: 50,
                                padding: const EdgeInsets.symmetric(
                                  vertical: Dimensions.paddingSizeExtraSmall,
                                  horizontal: Dimensions.paddingSizeExtraSmall,
                                ),
                                primaryColor: Theme.of(context).textTheme.bodyLarge!.color,
                              ),
                              dropdownStyle: DropdownStyle(
                                elevation: 10,
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                              ),
                              items: vehicleList,
                              child: Padding(
                                padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                                child: authController.vehicleIndex == 0 || authController.vehicleIndex! >= authController.vehicles!.length ? Row(
                                  children: [
                                    Text(
                                      'select_vehicle'.tr,
                                      style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
                                    ),

                                    Text(
                                      '*',
                                      style: robotoRegular.copyWith(color: Colors.red),
                                    ),
                                  ],
                                ) : Text(
                                  authController.vehicles![authController.vehicleIndex!].type!.tr,
                                  style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
                                ),
                              ),
                            ),
                          ) : const CircularProgressIndicator(),
                        ]),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      Text('identity_information'.tr, style: robotoBold),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      CustomCard(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Column(children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              color: Theme.of(context).cardColor,
                              border: Border.all(color: Theme.of(context).disabledColor),
                            ),
                            child: CustomDropdown<int>(
                              onChange: (int? value, int index) {
                                authController.setIdentityTypeIndex(authController.identityTypeList[index], true);
                              },
                              dropdownButtonStyle: DropdownButtonStyle(
                                height: 50,
                                padding: const EdgeInsets.symmetric(
                                  vertical: Dimensions.paddingSizeExtraSmall,
                                  horizontal: Dimensions.paddingSizeExtraSmall,
                                ),
                                primaryColor: Theme.of(context).textTheme.bodyLarge!.color,
                              ),
                              dropdownStyle: DropdownStyle(
                                elevation: 10,
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                              ),
                              items: identityTypeList,
                              child: Padding(
                                padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                                child: Text(authController.identityTypeList[0].tr),
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                          CustomTextFieldWidget(
                            hintText: authController.identityTypeIndex == 0 ? 'Ex: XXXXX-XXXXXXX-X'
                                : authController.identityTypeIndex == 1 ? 'L-XXX-XXX-XXX-XXX.' : 'XXX-XXXXX',
                            labelText: 'identity_number'.tr,
                            controller: _identityNumberController,
                            focusNode: _identityNumberNode,
                            inputAction: TextInputAction.done,
                            isRequired: true,
                          ),
                        ]),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      CustomCard(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: 'identity_image'.tr,
                                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color),
                              ),
                              TextSpan(
                                text: '*',
                                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Colors.red),
                              ),
                            ]),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                          Text('image_format_and_ratio_for_profile'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
                          const SizedBox(height: Dimensions.paddingSizeLarge),

                          Center(
                            child: SizedBox(
                              width: 130,
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1, mainAxisExtent: 130,
                                  mainAxisSpacing: 10, crossAxisSpacing: 10,
                                ),
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: authController.pickedIdentities.length + 1,
                                itemBuilder: (context, index) {

                                  XFile? file = index == authController.pickedIdentities.length ? null : authController.pickedIdentities[index];

                                  if(index == authController.pickedIdentities.length) {
                                    return InkWell(
                                      onTap: () {
                                        if((authController.pickedIdentities.length) < 6) {
                                          authController.pickDmImageForRegistration(false, false);
                                        }else {
                                          showCustomSnackBar('maximum_image_limit_is_6'.tr);
                                        }
                                      },
                                      child: DottedBorder(
                                        options: RoundedRectDottedBorderOptions(
                                          radius: const Radius.circular(Dimensions.radiusDefault),
                                          dashPattern: const [8, 4],
                                          strokeWidth: 1,
                                          color: Get.isDarkMode ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE5E5E5),
                                        ),
                                        child: Container(
                                          height: 130, width: 130,
                                          decoration: BoxDecoration(
                                            color: Get.isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFAFAFA),
                                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                          ),
                                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                                            CustomAssetImageWidget(image: Images.pictureIcon, height: 40, width: 40, color: Get.isDarkMode ? Colors.grey : null),
                                            const SizedBox(height: Dimensions.paddingSizeDefault),

                                            RichText(
                                              textAlign: TextAlign.center,
                                              text: TextSpan(children: [
                                                TextSpan(text: 'click_to_upload'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.blue)),
                                              ]),
                                            ),

                                          ]),
                                        ),
                                      ),
                                    );
                                  }
                                  return DottedBorder(
                                    options: RoundedRectDottedBorderOptions(
                                      radius: const Radius.circular(Dimensions.radiusDefault),
                                      dashPattern: const [8, 5],
                                      strokeWidth: 1,
                                      color: const Color(0xFFE5E5E5),
                                    ),
                                    child: SizedBox(
                                      width: 130,
                                      child: Stack(children: [

                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                          child: GetPlatform.isWeb ? Image.network(
                                            file!.path, height: 130, width: 130, fit: BoxFit.cover,
                                          ) : Image.file(
                                            File(file!.path), height: 130, width: 130, fit: BoxFit.cover,
                                          ),
                                        ),

                                        Positioned(
                                          right: 0, top: 0,
                                          child: InkWell(
                                            onTap: () {
                                              authController.removeIdentityImage(index);
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                                              child: Icon(Icons.delete_forever, color: Colors.red),
                                            ),
                                          ),
                                        ),

                                      ]),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                        ]),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                      Text('additional_data'.tr, style: robotoBold),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      AdditionalDataSectionWidget(authController: authController, scrollController: _scrollController),

                    ]),
                  ),

                ]),
              )),

              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                ),
                child: CustomButtonWidget(
                  isLoading: authController.isLoading,
                  buttonText: authController.dmStatus == 0.4 ? 'next'.tr : 'submit'.tr,
                  onPressed: () => _addDeliveryMan(authController, addressController),
                ),
              ),

            ]);
          });
        }),
      ),
    );
  }

  void _addDeliveryMan(AuthController authController, AddressController addressController) async {
    String fName = _fNameController.text.trim();
    String lName = _lNameController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();
    String identityNumber = _identityNumberController.text.trim();

    bool customFieldEmpty = false;

    Map<String, dynamic> additionalData = {};
    List<FilePickerResult> additionalDocuments = [];
    List<String> additionalDocumentsInputType = [];

    if(authController.dmStatus != 0.4) {
      for (Data data in authController.dataList!) {
        bool isTextField = data.fieldType == 'text' || data.fieldType == 'number' || data.fieldType == 'email' || data.fieldType == 'phone';
        bool isDate = data.fieldType == 'date';
        bool isCheckBox = data.fieldType == 'check_box';
        bool isFile = data.fieldType == 'file';
        int index = authController.dataList!.indexOf(data);
        bool isRequired = data.isRequired == 1;

        if(isTextField) {
          if(authController.additionalList![index].text != '') {
            additionalData.addAll({data.inputData! : authController.additionalList![index].text});
          } else {
            if(isRequired) {
              customFieldEmpty = true;
              showCustomSnackBar('${data.placeholderData} ${'can_not_be_empty'.tr}');
              break;
            }
          }
        } else if(isDate) {
          if(authController.additionalList![index] != null) {
            additionalData.addAll({data.inputData! : authController.additionalList![index]});
          } else {
            if(isRequired) {
              customFieldEmpty = true;
              showCustomSnackBar('${data.placeholderData} ${'can_not_be_empty'.tr}');
              break;
            }
          }
        } else if(isCheckBox) {
          List<String> checkData = [];
          bool noNeedToGoElse = false;
          for(var e in authController.additionalList![index]) {
            if(e != 0) {
              checkData.add(e);
              customFieldEmpty = false;
              noNeedToGoElse = true;
            } else if(!noNeedToGoElse) {
              customFieldEmpty = true;
            }
          }
          if(customFieldEmpty && isRequired) {
            showCustomSnackBar( '${'please_set_data_in'.tr} ${authController.camelToSentence(authController.dataList![index].inputData!)} ${'field'.tr}');
            break;
          } else {
            additionalData.addAll({data.inputData! : checkData});
          }

        } else if(isFile) {
          if(authController.additionalList![index].length == 0 && isRequired) {
            customFieldEmpty = true;
            showCustomSnackBar('${'please_add'.tr} ${authController.camelToSentence(authController.dataList![index].inputData!)}');
            break;
          } else {
            authController.additionalList![index].forEach((file) {
              additionalDocuments.add(file);
              additionalDocumentsInputType.add(authController.dataList![index].inputData!);
            });
          }
        }
      }
    }

    String numberWithCountryCode = _countryDialCode!+phone;
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if(authController.dmStatus == 0.4) {
      if(fName.isEmpty) {
        showCustomSnackBar('enter_delivery_man_first_name'.tr);
      }else if(lName.isEmpty) {
        showCustomSnackBar('enter_delivery_man_last_name'.tr);
      }else if(phone.isEmpty) {
        showCustomSnackBar('enter_delivery_man_phone_number'.tr);
      }else if(!phoneValid.isValid) {
        showCustomSnackBar('enter_a_valid_phone_number'.tr);
      }else if(email.isEmpty) {
        showCustomSnackBar('enter_delivery_man_email_address'.tr);
      }else if(!GetUtils.isEmail(email)) {
        showCustomSnackBar('enter_a_valid_email_address'.tr);
      }else if(password.isEmpty) {
        showCustomSnackBar('enter_password_for_delivery_man'.tr);
      }else if(password.length < 6) {
        showCustomSnackBar('password_should_be'.tr);
      }else if(password != confirmPass) {
        showCustomSnackBar('password_does_not_match'.tr);
      } else if(authController.pickedImage == null) {
        showCustomSnackBar('upload_delivery_man_image'.tr);
      }else{
        authController.dmStatusChange(0.8);
      }
    } else {
      if(authController.dmTypeIndex == -1) {
        showCustomSnackBar('please_select_delivery_type'.tr);
      }else if(authController.vehicleIndex!-1 == -1) {
        showCustomSnackBar('please_select_vehicle_for_the_deliveryman'.tr);
      }else if(identityNumber.isEmpty) {
        showCustomSnackBar('enter_delivery_man_identity_number'.tr);
      }else if(authController.pickedIdentities.isEmpty) {
        showCustomSnackBar('please_add_your_identity_image'.tr);
      }else if(customFieldEmpty) {
        debugPrint('Not provide addition data');
      }else {

        Map<String, String> data = {};

        data.addAll(DeliveryManBodyModel(
          fName: fName, lName: lName, password: password, phone: numberWithCountryCode, email: email,
          identityNumber: identityNumber, identityType: authController.identityTypeList[authController.identityTypeIndex],
          earning: authController.dmTypeIndex == 0 ? '1' : '0', zoneId: addressController.zoneList![addressController.selectedZoneIndex!].id.toString(),
          vehicleId: authController.vehicles![authController.vehicleIndex! - 1].id.toString(),
        ).toJson());

        data.addAll({
          'additional_data': jsonEncode(additionalData),
        });

        authController.registerDeliveryMan(data, additionalDocuments, additionalDocumentsInputType);

      }
    }
  }

}