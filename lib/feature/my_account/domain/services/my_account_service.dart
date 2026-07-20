import 'package:stackfood_multivendor_driver/common/models/response_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/models/wallet_payment_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/repositories/my_account_repository_interface.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/services/my_account_service_interface.dart';

class MyAccountService implements MyAccountServiceInterface {
  final MyAccountRepositoryInterface myAccountRepositoryInterface;
  MyAccountService({required this.myAccountRepositoryInterface});

  @override
  Future<ResponseModel> makeCollectCashPayment(double amount, String paymentGatewayName) async {
    return await myAccountRepositoryInterface.makeCollectCashPayment(amount, paymentGatewayName);
  }

  @override
  Future<ResponseModel> makeWalletAdjustment() async {
    return await myAccountRepositoryInterface.makeWalletAdjustment();
  }

  @override
  Future<List<Transactions>?> getWalletPaymentList() async {
    return await myAccountRepositoryInterface.getList();
  }

}