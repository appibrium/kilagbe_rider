import 'package:stackfood_multivendor_driver/feature/rider_rank/domain/models/rider_rank_model.dart';

abstract class RiderRankServiceInterface {
  Future<RiderRankModel?> getRiderRank();
}
