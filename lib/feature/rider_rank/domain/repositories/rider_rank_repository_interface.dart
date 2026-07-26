import 'package:stackfood_multivendor_driver/feature/rider_rank/domain/models/rider_rank_model.dart';
import 'package:stackfood_multivendor_driver/interface/repository_interface.dart';

abstract class RiderRankRepositoryInterface implements RepositoryInterface {
  Future<RiderRankModel?> getRiderRank();
}
