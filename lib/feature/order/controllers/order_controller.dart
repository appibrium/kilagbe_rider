import 'package:stackfood_multivendor_driver/common/models/response_model.dart';
import 'package:stackfood_multivendor_driver/feature/order/domain/services/order_service_interface.dart';
import 'package:stackfood_multivendor_driver/feature/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor_driver/api/api_client.dart';
import 'package:stackfood_multivendor_driver/feature/order/domain/models/update_status_body.dart';
import 'package:stackfood_multivendor_driver/feature/order/domain/models/ignore_model.dart';
import 'package:stackfood_multivendor_driver/feature/order/domain/models/order_cancellation_body_model.dart';
import 'package:stackfood_multivendor_driver/feature/order/domain/models/order_details_model.dart';
import 'package:stackfood_multivendor_driver/feature/order/domain/models/order_model.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_snackbar_widget.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class OrderController extends GetxController implements GetxService {
  final OrderServiceInterface orderServiceInterface;
  OrderController({required this.orderServiceInterface});

  List<OrderModel>? _allOrderList;
  List<OrderModel>? get allOrderList => _allOrderList;

  List<OrderModel>? _currentOrderList;
  List<OrderModel>? get currentOrderList => _currentOrderList;

  List<int>? _currentOrderCountList;
  List<int>? get currentOrderCountList => _currentOrderCountList;

  List<OrderModel>? _deliveredOrderList;
  List<OrderModel>? get deliveredOrderList => _deliveredOrderList;

  List<OrderModel>? _completedOrderList;
  List<OrderModel>? get completedOrderList => _completedOrderList;

  List<int>? _completedOrderCountList;
  List<int>? get completedOrderCountList => _completedOrderCountList;

  List<OrderModel>? _latestOrderList;
  List<OrderModel>? get latestOrderList => _latestOrderList;

  List<OrderDetailsModel>? _orderDetailsModel;
  List<OrderDetailsModel>? get orderDetailsModel => _orderDetailsModel;

  /// Id of the order [_orderModel] / [_orderDetailsModel] currently belong to.
  /// Every detail fetch is tagged with it so a response that arrives late (or
  /// for a different order) can never overwrite the order being viewed.
  int? _activeOrderId;
  int? get activeOrderId => _activeOrderId;

  /// Kept apart from [_orderDetailsModel] on purpose: the incoming request
  /// popup loads its own order while the rider may be looking at another one.
  List<OrderDetailsModel>? _requestOrderDetailsModel;
  List<OrderDetailsModel>? get requestOrderDetailsModel => _requestOrderDetailsModel;
  int? _requestOrderId;

  double get storeWillGet => ((_orderDetailsModel != null && _orderDetailsModel!.isNotEmpty) ? _orderDetailsModel![0].storeWillGet : null) ?? _orderModel?.storeWillGet ?? 0;

  List<IgnoreModel> _ignoredRequests = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Position _position = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1, altitudeAccuracy: 1, headingAccuracy: 1);
  Position get position => _position;

  Placemark _placeMark = const Placemark(name: 'Unknown', subAdministrativeArea: 'Location', isoCountryCode: 'Found');
  Placemark get placeMark => _placeMark;

  String _otp = '';
  String get otp => _otp;

  String get address => '${_placeMark.name} ${_placeMark.subAdministrativeArea} ${_placeMark.isoCountryCode}';

  bool _paginate = false;
  bool get paginate => _paginate;

  int? _pageSize;
  int? get pageSize => _pageSize;

  List<int> _offsetList = [];
  int _offset = 1;
  int get offset => _offset;

  OrderModel? _orderModel;
  OrderModel? get orderModel => _orderModel;

  List<CancellationData>? _orderCancelReasons;
  List<CancellationData>? get orderCancelReasons => _orderCancelReasons;

  String? _cancelReason = '';
  String? get cancelReason => _cancelReason;

  bool _showDeliveryImageField = false;
  bool get showDeliveryImageField => _showDeliveryImageField;

  List<XFile> _pickedPrescriptions = [];
  List<XFile> get pickedPrescriptions => _pickedPrescriptions;

  int? _selectedRunningOrderStatusIndex;
  int? get selectedRunningOrderStatusIndex => _selectedRunningOrderStatusIndex;

  String? _selectedRunningOrderStatus = 'all';
  String? get selectedRunningOrderStatus => _selectedRunningOrderStatus;

  int? _selectedMyOrderStatusIndex;
  int? get selectedMyOrderStatusIndex => _selectedMyOrderStatusIndex;

  String? _selectedMyOrderStatus = 'all';
  String? get selectedMyOrderStatus => _selectedMyOrderStatus;

  void setSelectedRunningOrderStatusIndex(int? index, String? status, {bool isUpdate = true}) {
    _selectedRunningOrderStatusIndex = index;
    _selectedRunningOrderStatus = status;
    if(isUpdate) update();
  }

  void setSelectedMyOrderStatusIndex(int? index, String? status) {
    _selectedMyOrderStatusIndex = index;
    _selectedMyOrderStatus = status;
    update();
  }

  void changeDeliveryImageStatus({bool isUpdate = true}){
    _showDeliveryImageField = !_showDeliveryImageField;
    if(isUpdate) {
      update();
    }
  }

  void pickPrescriptionImage({required bool isRemove, required bool isCamera}) async {
    if(isRemove) {
      _pickedPrescriptions = [];
    }else {
      XFile? xFile = await ImagePicker().pickImage(source: isCamera ? ImageSource.camera : ImageSource.gallery, imageQuality: 50);
      if(xFile != null) {
        _pickedPrescriptions.add(xFile);
        if(Get.isDialogOpen!){
          Get.back();
        }
      }
      update();
    }
  }

  void removePrescriptionImage(int index) {
    _pickedPrescriptions.removeAt(index);
    update();
  }

  void setOrderCancelReason(String? reason){
    _cancelReason = reason;
    update();
  }

  Future<void> getOrderCancelReasons()async {
    List<CancellationData>? orderCancelReasons = await orderServiceInterface.getCancelReasons();
    if (orderCancelReasons != null) {
      _orderCancelReasons = [];
      _orderCancelReasons!.addAll(orderCancelReasons);
    }
    update();
  }

  Future<void> getAllOrders() async {
    List<OrderModel>? allOrderList = await orderServiceInterface.getAllOrders();
    if(allOrderList != null) {
      _allOrderList = [];
      _allOrderList!.addAll(allOrderList);
      _deliveredOrderList = orderServiceInterface.sortDeliveredOrderList(_allOrderList!);
    }
    update();
  }

  Future<void> getCompletedOrders({required int offset, bool isUpdate = true, required String status}) async {
    if(offset == 1) {
      _offsetList = [];
      _offset = 1;
      _completedOrderList = null;
      if(isUpdate) {
        update();
      }
    }
    if (!_offsetList.contains(offset)) {
      _offsetList.add(offset);
      PaginatedOrderModel? paginatedOrderModel = await orderServiceInterface.getCompletedOrderList(offset, status: status);
      if (paginatedOrderModel != null) {
        if (offset == 1) {
          _completedOrderList = [];
        }
        _completedOrderList!.addAll(paginatedOrderModel.orders!);
        _completedOrderCountList = [
          paginatedOrderModel.orderCount?.all ?? 0,
          paginatedOrderModel.orderCount?.delivered ?? 0,
          paginatedOrderModel.orderCount?.canceled ?? 0,
          paginatedOrderModel.orderCount?.refundRequested ?? 0,
          paginatedOrderModel.orderCount?.refunded ?? 0,
          paginatedOrderModel.orderCount?.refundRequestCanceled ?? 0,
        ];
        _pageSize = paginatedOrderModel.totalSize;
        _paginate = false;
        update();
      }
    } else {
      if(_paginate) {
        _paginate = false;
        update();
      }
    }
  }

  void showBottomLoader() {
    _paginate = true;
    update();
  }

  void setOffset(int offset) {
    _offset = offset;
  }

  Future<void> getCurrentOrders({required String status, bool isDataClear = true}) async {
    if(isDataClear){
      _currentOrderList = null;
    }
    PaginatedOrderModel? paginatedOrderModel = await orderServiceInterface.getCurrentOrders(status: status);
    if(paginatedOrderModel != null) {
      _currentOrderList = [];
      _currentOrderList!.addAll(paginatedOrderModel.orders!);
      // Index order must stay in step with StatusListModel.getRunningOrderStatusList().
      // "accepted" folds in the legacy store-driven states so orders placed
      // before the flow was simplified still show up under the same tab.
      _currentOrderCountList = [
        paginatedOrderModel.orderCount?.all ?? 0,
        (paginatedOrderModel.orderCount?.pending ?? 0) + (paginatedOrderModel.orderCount?.accepted ?? 0)
            + (paginatedOrderModel.orderCount?.confirmed ?? 0) + (paginatedOrderModel.orderCount?.processing ?? 0)
            + (paginatedOrderModel.orderCount?.handover ?? 0),
        paginatedOrderModel.orderCount?.pickedUp ?? 0,
      ];
    }
    update();
  }

  /// Points the controller at [orderId] and drops whatever belonged to the
  /// previously opened order, so a screen never renders a mix of two orders.
  ///
  /// Deliberately does not call update(): it runs from initState, where a
  /// synchronous rebuild would throw "setState() called during build". The
  /// fetches that follow it repaint once their data lands.
  void setActiveOrder(int? orderId) {
    if(_activeOrderId != orderId) {
      _activeOrderId = orderId;
      _orderModel = null;
      _orderDetailsModel = null;
    }
  }

  Future<void> getOrderWithId(int? orderId) async {
    setActiveOrder(orderId);
    OrderModel? orderModel = await orderServiceInterface.getOrderWithId(orderId);
    if(_activeOrderId != orderId) {
      return;
    }
    if(orderModel != null) {
      _orderModel = orderModel;
    }
    update();
  }

  Future<void> getLatestOrders() async {
    List<OrderModel>? latestOrderList = await orderServiceInterface.getLatestOrders();
    if(latestOrderList != null) {
      _latestOrderList = [];
      List<int?> ignoredIdList = orderServiceInterface.prepareIgnoreIdList(_ignoredRequests);
      _latestOrderList!.addAll(orderServiceInterface.processLatestOrders(latestOrderList, ignoredIdList));
    }
    update();
  }

  /// Performs the status change only. Navigation is left to the caller so a
  /// swipe on the details screen no longer pops the screen out from under it.
  Future<bool> updateOrderStatus(int? orderId, String status, {String? reason}) async {
    if(_isLoading) {
      return false;
    }
    _isLoading = true;
    update();
    List<MultipartBody> multiParts = orderServiceInterface.prepareOrderProofImages(_pickedPrescriptions);
    UpdateStatusBody updateStatusBody = UpdateStatusBody(
      orderId: orderId, status: status,
      otp: status == 'delivered' ? _otp : null, reason: reason,
    );
    ResponseModel responseModel = await orderServiceInterface.updateOrderStatus(updateStatusBody, multiParts);
    _isLoading = false;
    update();
    if(responseModel.isSuccess) {
      if(orderId == _activeOrderId) {
        await getOrderWithId(orderId);
      }
      await getCurrentOrders(status: _selectedRunningOrderStatus ?? 'all', isDataClear: false);
      showCustomSnackBar(responseModel.message, isError: false);
    }else {
      showCustomSnackBar(responseModel.message, isError: true);
    }
    return responseModel.isSuccess;
  }

  Future<void> getOrderDetails(int? orderID) async {
    setActiveOrder(orderID);
    _orderDetailsModel = null;
    List<OrderDetailsModel>? orderDetailsModel = await orderServiceInterface.getOrderDetails(orderID);
    if(_activeOrderId != orderID) {
      return;
    }
    if(orderDetailsModel != null) {
      _orderDetailsModel = [];
      _orderDetailsModel!.addAll(orderDetailsModel);
    }
    update();
  }

  /// Used by the incoming request popup. Writes to its own field so it can
  /// never replace the item list of the order already open on screen.
  Future<void> getRequestOrderDetails(int? orderID) async {
    // Same reason as setActiveOrder: this is kicked off from initState.
    _requestOrderId = orderID;
    _requestOrderDetailsModel = null;
    List<OrderDetailsModel>? orderDetailsModel = await orderServiceInterface.getOrderDetails(orderID);
    if(_requestOrderId != orderID) {
      return;
    }
    if(orderDetailsModel != null) {
      _requestOrderDetailsModel = [];
      _requestOrderDetailsModel!.addAll(orderDetailsModel);
    }
    update();
  }

  Future<bool> acceptOrder(int? orderID, OrderModel orderModel) async {
    if(_isLoading) {
      return false;
    }
    _isLoading = true;
    update();
    ResponseModel responseModel = await orderServiceInterface.acceptOrder(orderID);
    _isLoading = false;
    if(responseModel.isSuccess) {
      // Match on id, never on list position: the request list is refreshed on a
      // timer, so an index captured at build time can point at another order.
      _latestOrderList?.removeWhere((order) => order.id == orderID);
      _currentOrderList ??= [];
      if(!_currentOrderList!.any((order) => order.id == orderID)) {
        _currentOrderList!.add(orderModel);
      }
    }else {
      showCustomSnackBar(responseModel.message, isError: true);
    }
    update();
    return responseModel.isSuccess;
  }

  void getIgnoreList() {
    _ignoredRequests = [];
    _ignoredRequests.addAll(orderServiceInterface.getIgnoreList());
  }

  void ignoreOrder(int? orderId) {
    if(orderId == null) {
      return;
    }
    _ignoredRequests.add(IgnoreModel(id: orderId, time: DateTime.now()));
    _latestOrderList?.removeWhere((order) => order.id == orderId);
    orderServiceInterface.setIgnoreList(_ignoredRequests);
    update();
  }

  void removeFromIgnoreList() {
    List<IgnoreModel> tempList = [];
    tempList.addAll(_ignoredRequests);
    for(int index=0; index<tempList.length; index++) {
      if(Get.find<SplashController>().currentTime.difference(tempList[index].time!).inMinutes > 10) {
        tempList.removeAt(index);
      }
    }
    _ignoredRequests = [];
    _ignoredRequests.addAll(tempList);
    orderServiceInterface.setIgnoreList(_ignoredRequests);
  }

  Future<void> getCurrentLocation() async {
    Position currentPosition = await Geolocator.getCurrentPosition();
    if(!GetPlatform.isWeb) {
      try {
        List<Placemark> placeMarks = await placemarkFromCoordinates(currentPosition.latitude, currentPosition.longitude);
        _placeMark = placeMarks.first;
      }catch(_) {}
    }
    _position = currentPosition;
    update();
  }

  void setOtp(String otp) {
    _otp = otp;
    if(otp != '') {
      update();
    }
  }

}