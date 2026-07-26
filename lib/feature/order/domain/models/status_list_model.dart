class StatusListModel{
  final String statusTitle;
  final String status;
  StatusListModel({required this.statusTitle, required this.status});

  static List<StatusListModel> getRunningOrderStatusList(){
    return [
      // Simplified flow: a rider only ever has orders waiting to be picked up
      // or already picked up. The server folds confirmed/processing/handover
      // into "accepted" so older orders remain reachable here.
      StatusListModel(statusTitle: 'all', status: 'all'),
      StatusListModel(statusTitle: 'accepted', status: 'accepted'),
      StatusListModel(statusTitle: 'picked_up', status: 'picked_up'),
    ];
  }

  static List<StatusListModel> getMyOrderStatusList(){
    return [
      StatusListModel(statusTitle: 'all', status: 'all'),
      StatusListModel(statusTitle: 'delivered', status: 'delivered'),
      StatusListModel(statusTitle: 'canceled', status: 'canceled'),
      StatusListModel(statusTitle: 'refund_requested', status: 'refund_requested'),
      StatusListModel(statusTitle: 'refunded', status: 'refunded'),
      StatusListModel(statusTitle: 'refund_request_canceled', status: 'refund_request_canceled'),
    ];
  }

}