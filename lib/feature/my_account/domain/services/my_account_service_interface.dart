abstract class MyAccountServiceInterface {
  Future<dynamic> makeCollectCashPayment(double amount, String paymentGatewayName);
  Future<dynamic> makeWalletAdjustment();
  Future<dynamic> getWalletPaymentList();
}