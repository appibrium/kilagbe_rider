import 'package:stackfood_multivendor_driver/feature/order/controllers/order_controller.dart';
import 'package:stackfood_multivendor_driver/feature/order/domain/models/status_list_model.dart';
import 'package:stackfood_multivendor_driver/feature/order/widgets/history_order_widget.dart';
import 'package:stackfood_multivendor_driver/feature/order/widgets/order_button_widget.dart';
import 'package:stackfood_multivendor_driver/feature/order/widgets/order_list_shimmer.dart';
import 'package:stackfood_multivendor_driver/helper/custom_print_helper.dart';
import 'package:stackfood_multivendor_driver/helper/date_converter_helper.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackfood_multivendor_driver/util/styles.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  static const int _runningOrdersTab = 0;
  static const int _orderHistoryTab = 1;

  final ScrollController _scrollController = ScrollController();
  int _selectedTab = _runningOrdersTab;

  OrderController get _orderController => Get.find<OrderController>();

  @override
  void initState() {
    super.initState();
    _initializeOrders();
    _setupPaginationListener();
  }

  void _initializeOrders() {
    _orderController.setSelectedRunningOrderStatusIndex(0, 'all', isUpdate: false);
    _orderController.getCurrentOrders(status: 'all');
    _orderController.getCompletedOrders(offset: 1, status: 'all', isUpdate: false);
  }

  void _setupPaginationListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent
          && Get.find<OrderController>().completedOrderList != null && !Get.find<OrderController>().paginate) {
        int pageSize = (Get.find<OrderController>().pageSize! / 10).ceil();
        if (Get.find<OrderController>().offset < pageSize) {
          Get.find<OrderController>().setOffset(Get.find<OrderController>().offset+1);
          customPrint('end of the page');
          Get.find<OrderController>().showBottomLoader();
          Get.find<OrderController>().getCompletedOrders(offset: Get.find<OrderController>().offset, status: Get.find<OrderController>().selectedMyOrderStatus!);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _selectedTab == _runningOrdersTab ? _buildRunningOrdersTab() : _buildOrderHistoryTab(),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'my_orders'.tr,
        style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeLarge,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge!.color,
        ),
      ),
      automaticallyImplyLeading: false,
      centerTitle: true,
      backgroundColor: Theme.of(context).cardColor,
      surfaceTintColor: Theme.of(context).cardColor,
      shadowColor: Theme.of(context).disabledColor.withValues(alpha: 0.5),
      elevation: 2,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(35),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: _buildTabButtons(context),
        ),
      ),
    );
  }

  Widget _buildTabButtons(BuildContext context) {
    return Row(
      children: [
        _buildTabButton(
          context: context,
          label: 'running_orders'.tr,
          tabIndex: _runningOrdersTab,
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        _buildTabButton(
          context: context,
          label: 'order_history'.tr,
          tabIndex: _orderHistoryTab,
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required String label,
    required int tabIndex,
  }) {
    final isSelected = _selectedTab == tabIndex;

    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: () => setState(() => _selectedTab = tabIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeLarge,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.5),
        ),
        child: Text(
          label,
          style: robotoMedium.copyWith(
            color: isSelected ? Theme.of(context).cardColor : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRunningOrdersTab() {
    return GetBuilder<OrderController>(
      builder: (orderController) {
        final statusList = StatusListModel.getRunningOrderStatusList();

        return Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            children: [
              _buildStatusFilters(statusList, orderController),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Expanded(
                child: _buildOrderList(
                  orderList: orderController.currentOrderList,
                  onRefresh: () => orderController.getCurrentOrders(
                    status: orderController.selectedRunningOrderStatus!,
                  ),
                  buildOrders: () => _buildGroupedOrders(
                    orders: orderController.currentOrderList!,
                    isRunning: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderHistoryTab() {
    return GetBuilder<OrderController>(
      builder: (orderController) {
        final statusList = StatusListModel.getMyOrderStatusList();

        return Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            children: [
              _buildStatusFilters(statusList, orderController, fromMyOrder: true),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Expanded(
                child: _buildOrderList(
                  orderList: orderController.completedOrderList,
                  scrollController: _scrollController,
                  onRefresh: () => orderController.getCompletedOrders(
                    offset: 1,
                    status: orderController.selectedMyOrderStatus!,
                  ),
                  buildOrders: () => [
                    ..._buildGroupedOrders(
                      orders: orderController.completedOrderList!,
                      isRunning: false,
                    ),
                    if (orderController.paginate) _buildPaginationLoader(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusFilters(
      List<StatusListModel> statusList,
      OrderController orderController, {
        bool fromMyOrder = false,
      }) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: statusList.length,
        itemBuilder: (context, index) {
          return OrderButtonWidget(
            statusListModel: statusList[index],
            index: index,
            orderController: orderController,
            fromMyOrder: fromMyOrder,
          );
        },
      ),
    );
  }

  Widget _buildOrderList({
    required List? orderList,
    ScrollController? scrollController,
    required Future<void> Function() onRefresh,
    required List<Widget> Function() buildOrders,
  }) {
    if (orderList == null) {
      return const OrderListShimmer();
    }

    if (orderList.isEmpty) {
      return Center(child: Text('no_order_found'.tr));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: buildOrders(),
        ),
      ),
    );
  }

  Widget _buildPaginationLoader() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: CircularProgressIndicator(),
      ),
    );
  }

  List<Widget> _buildGroupedOrders({
    required List orders,
    required bool isRunning,
  }) {
    final groupedOrders = _groupOrdersByDate(orders, isRunning);
    final widgets = <Widget>[];

    groupedOrders.forEach((dateLabel, ordersList) {
      widgets.add(_buildDateLabel(dateLabel));

      for (int i = 0; i < ordersList.length; i++) {
        widgets.add(
          HistoryOrderWidget(
            orderModel: ordersList[i],
            isRunning: isRunning,
            index: i,
          ),
        );
      }
    });

    return widgets;
  }

  Map<String, List> _groupOrdersByDate(List orders, bool isRunning) {
    final grouped = <String, List>{};
    final now = DateTime.now();

    for (var order in orders) {
      final createdDate = DateTime.tryParse(isRunning ? order.updatedAt : order.createdAt) ?? now;
      final dateLabel = _getDateLabel(createdDate, now);
      grouped.putIfAbsent(dateLabel, () => []).add(order);
    }

    return grouped;
  }

  String _getDateLabel(DateTime orderDate, DateTime now) {
    if (_isSameDate(orderDate, now)) {
      return 'Today';
    }

    if (_isSameDate(orderDate, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }

    return DateConverter.estimatedDate(orderDate);
  }

  Widget _buildDateLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        label,
        style: robotoRegular.copyWith(
          color: Theme.of(Get.context!).hintColor,
        ),
      ),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}