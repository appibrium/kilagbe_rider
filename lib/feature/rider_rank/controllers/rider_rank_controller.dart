import 'package:get/get.dart';
import 'package:stackfood_multivendor_driver/feature/rider_rank/domain/models/rider_rank_model.dart';
import 'package:stackfood_multivendor_driver/feature/rider_rank/domain/services/rider_rank_service_interface.dart';

class RiderRankController extends GetxController implements GetxService {
  final RiderRankServiceInterface riderRankServiceInterface;
  RiderRankController({required this.riderRankServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  RiderRankModel? _riderRankModel;
  RiderRankModel? get riderRankModel => _riderRankModel;

  Future<void> getRiderRank() async {
    _isLoading = true;
    update();

    RiderRankModel? riderRankModel = await riderRankServiceInterface.getRiderRank();
    if (riderRankModel != null) {
      _riderRankModel = riderRankModel;
    }

    _isLoading = false;
    update();
  }
}
