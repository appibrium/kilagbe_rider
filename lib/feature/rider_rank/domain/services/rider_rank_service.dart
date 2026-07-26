import 'package:stackfood_multivendor_driver/feature/rider_rank/domain/models/rider_rank_model.dart';
import 'package:stackfood_multivendor_driver/feature/rider_rank/domain/repositories/rider_rank_repository_interface.dart';
import 'package:stackfood_multivendor_driver/feature/rider_rank/domain/services/rider_rank_service_interface.dart';

class RiderRankService implements RiderRankServiceInterface {
  final RiderRankRepositoryInterface riderRankRepositoryInterface;
  RiderRankService({required this.riderRankRepositoryInterface});

  @override
  Future<RiderRankModel?> getRiderRank() async {
    return await riderRankRepositoryInterface.getRiderRank();
  }
}
