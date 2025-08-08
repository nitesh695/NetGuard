import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/Auth/controllers/auth.controller.dart';
import '../utils/storage_manager.dart';
import 'api.dart';


Future<void> init() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  Get.lazyPut(() => sharedPreferences);
  Get.lazyPut(() => StorageManager(sharedPreferences));
  Get.lazyPut(() => ApiClient(sharedPreferences: Get.find()));
  Get.lazyPut(() => AuthController(storageManager: Get.find(),apiClient: Get.find()));




}
