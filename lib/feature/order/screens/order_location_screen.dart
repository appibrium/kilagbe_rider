import 'dart:math';
import 'dart:ui';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:stackfood_multivendor_driver/common/controllers/theme_controller.dart';
import 'package:stackfood_multivendor_driver/feature/order/controllers/order_controller.dart';
import 'package:stackfood_multivendor_driver/feature/order/domain/models/order_model.dart';
import 'package:stackfood_multivendor_driver/feature/order/widgets/location_card_widget.dart';
import 'package:stackfood_multivendor_driver/feature/profile/controllers/profile_controller.dart';
import 'package:stackfood_multivendor_driver/util/images.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_app_bar_widget.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderLocationScreen extends StatefulWidget {
  final OrderModel orderModel;
  final OrderController orderController;
  final int index;
  final Function onTap;
  const OrderLocationScreen({super.key, required this.orderModel, required this.orderController, required this.index, required this.onTap});

  @override
  State<OrderLocationScreen> createState() => _OrderLocationScreenState();
}

class _OrderLocationScreenState extends State<OrderLocationScreen> {

  GoogleMapController? _controller;
  final Set<Marker> _markers = HashSet<Marker>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CustomAppBarWidget(title: 'order_location'.tr),

      body: Stack(children: [

        GoogleMap(
          initialCameraPosition: CameraPosition(target: LatLng(
            double.parse(widget.orderModel.deliveryAddress?.latitude??'0'), double.parse(widget.orderModel.deliveryAddress?.longitude??'0'),
          ), zoom: 16),
          minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
          zoomControlsEnabled: false,
          markers: _markers,
          style: Get.isDarkMode ? Get.find<ThemeController>().darkMap : Get.find<ThemeController>().lightMap,
          onMapCreated: (GoogleMapController controller) {
            _controller = controller;
            _setMarker(widget.orderModel);
          },
        ),

        Positioned(
          bottom: 0, left: 0, right: 0,
          child: LocationCardWidget(
            orderModel: widget.orderModel, orderController: widget.orderController,
            onTap: widget.onTap, index: widget.index,
          ),
        ),

      ]),
    );
  }

  void _setMarker(OrderModel orderModel) async {
    try {
      Uint8List restaurantImageData = await _convertAssetToUnit8List(Images.restaurantMarker, width: 100);
      Uint8List deliveryBoyImageData = await _convertAssetToUnit8List(Images.yourMarker, width: 100);
      Uint8List destinationImageData = await _convertAssetToUnit8List(Images.customerMarker, width: 100);

      double deliveryLat = double.parse(orderModel.deliveryAddress?.latitude ?? '0');
      double deliveryLng = double.parse(orderModel.deliveryAddress?.longitude ?? '0');
      double restaurantLat = double.parse(orderModel.restaurantLat ?? '0');
      double restaurantLng = double.parse(orderModel.restaurantLng ?? '0');
      double? deliveryManLat = Get.find<ProfileController>().recordLocationBody?.latitude;
      double? deliveryManLng = Get.find<ProfileController>().recordLocationBody?.longitude;

      // Clear previous markers
      _markers.clear();

      // Collect valid locations for bounds calculation
      List<LatLng> validLocations = [];

      // Add destination marker (delivery address)
      if (orderModel.deliveryAddress != null && deliveryLat != 0 && deliveryLng != 0) {
        LatLng deliveryLocation = LatLng(deliveryLat, deliveryLng);
        validLocations.add(deliveryLocation);
        _markers.add(Marker(
          markerId: const MarkerId('destination'),
          position: deliveryLocation,
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: orderModel.deliveryAddress?.address,
          ),
          icon: BitmapDescriptor.bytes(destinationImageData, height: 40, width: 40),
        ));
      }

      // Add restaurant marker
      if (orderModel.restaurantLat != null && orderModel.restaurantLng != null && restaurantLat != 0 && restaurantLng != 0) {
        LatLng restaurantLocation = LatLng(restaurantLat, restaurantLng);
        validLocations.add(restaurantLocation);
        _markers.add(Marker(
          markerId: const MarkerId('restaurant'),
          position: restaurantLocation,
          infoWindow: InfoWindow(
            title: orderModel.restaurantName,
            snippet: orderModel.restaurantAddress,
          ),
          icon: BitmapDescriptor.bytes(restaurantImageData, height: 40, width: 40),
        ));
      }

      // Add delivery boy marker
      if (deliveryManLat != null && deliveryManLng != null && deliveryManLat != 0 && deliveryManLng != 0) {
        LatLng deliveryManLocation = LatLng(deliveryManLat, deliveryManLng);
        validLocations.add(deliveryManLocation);
        _markers.add(Marker(
          markerId: const MarkerId('delivery_boy'),
          position: deliveryManLocation,
          infoWindow: InfoWindow(
            title: '${Get.find<ProfileController>().profileModel?.fName ?? ''} ${Get.find<ProfileController>().profileModel?.lName ?? ''}',
            snippet: Get.find<ProfileController>().recordLocationBody?.location,
          ),
          icon: BitmapDescriptor.bytes(deliveryBoyImageData, height: 40, width: 40),
        ));
      }

      // Calculate bounds only if we have valid locations
      if (validLocations.isNotEmpty && _controller != null) {
        if (validLocations.length == 1) {
          // If only one location, just center on it
          _controller!.animateCamera(
            CameraUpdate.newLatLngZoom(validLocations.first, 16),
          );
        } else {
          // Calculate bounds for multiple locations
          double minLat = validLocations.map((l) => l.latitude).reduce(min);
          double maxLat = validLocations.map((l) => l.latitude).reduce(max);
          double minLng = validLocations.map((l) => l.longitude).reduce(min);
          double maxLng = validLocations.map((l) => l.longitude).reduce(max);

          LatLngBounds bounds = LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          );

          if (kDebugMode) {
            print('Bounds: SW(${bounds.southwest}), NE(${bounds.northeast})');
          }

          // Animate to fit all markers with padding
          _controller!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting markers: $e');
      }
    }
    setState(() {});
  }

  Future<Uint8List> _convertAssetToUnit8List(String imagePath, {int width = 50}) async {
    ByteData data = await rootBundle.load(imagePath);
    Codec codec = await instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ImageByteFormat.png))!.buffer.asUint8List();
  }

}