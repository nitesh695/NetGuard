import 'package:get/get.dart';
import '../../../constants/routes_constants.dart';
import '../../../service/api.dart';
import '../../../utils/route.dart';
import '../../../utils/storage_manager.dart';


class AuthController extends GetxController implements GetxService{
  ApiClient apiClient;
  StorageManager storageManager;
  AuthController({ required this.apiClient,required this.storageManager});

Future<void> login(String username,String password)async{
  try{
    Map<String,String> body = {
      "email" : username,
      "password": password
    };

    final response = await apiClient.post("/api/v1/login",data: body);
    print("login response.....${response.data}");
    if(response.statusCode == 200){
      String accessToken = response.data['data']['_token']['access_token'] ?? '';
      String refToken = response.data['data']['_token']['refresh_token'] ?? '';
      storageManager.setToken(accessToken);
      storageManager.setRefToken(refToken);
      apiClient.updateHeader(accessToken, refToken);
      letsGoto.pushReplacementNamed(RouteConstants.dashboardScreen);
    }else{
      showSnackbar(response.data['message']);
    }

  }catch(e){
    print("login error.....$e");
  }
}


Future<void> testApi()async{
  try{

    final response = await apiClient.get('/api/v1/address/countries',useCache: false);
    print("response of test....11${response.data}");

    if(response.statusCode == 200){
      showSnackbar("data fetched");
    }

  }catch(e){
    print("test api error......$e");
  }
}

  Future<void> testApi1()async{
    try{

      final response = await apiClient.get('/api/v1/address/states/1');
      print("response of test....${response.data}");

      if(response.statusCode == 200){
        showSnackbar("data fetched...1111");
      }

    }catch(e){
      print("test api error......$e");
    }
  }



void showSnackbar(String message){
  Get.showSnackbar(
  GetSnackBar(
  title: '',
  message: '$message',
  duration: const Duration(seconds: 3),
  ),
  );

}


}