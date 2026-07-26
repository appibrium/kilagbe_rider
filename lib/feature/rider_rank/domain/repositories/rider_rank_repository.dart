import 'package:stackfood_multivendor_driver/api/api_client.dart';
import 'package:stackfood_multivendor_driver/feature/rider_rank/domain/models/rider_rank_model.dart';
import 'package:stackfood_multivendor_driver/feature/rider_rank/domain/repositories/rider_rank_repository_interface.dart';
import 'package:stackfood_multivendor_driver/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiderRankRepository implements RiderRankRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  RiderRankRepository({required this.apiClient, required this.sharedPreferences});

  @override
  Future<RiderRankModel?> getRiderRank() async {
    RiderRankModel? riderRankModel;
    Response response = await apiClient.getData('${AppConstants.riderRankUri}?token=${_getUserToken()}');
    if(response.statusCode == 200) {
      riderRankModel = RiderRankModel.fromJson(response.body);
    }
    return riderRankModel;
  }

  String _getUserToken() {
    return sharedPreferences.getString(AppConstants.token) ?? "";
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future get(int id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body) {
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    throw UnimplementedError();
  }

  @override
  Future getList() {
    throw UnimplementedError();
  }
}
