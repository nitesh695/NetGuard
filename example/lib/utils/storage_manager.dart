import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class StorageManager  extends GetxService{

  late SharedPreferences prefs;
  StorageManager(this.prefs);

  clearSharedPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }


  setToken(String stringValue) async {
   writeStringData('token', stringValue);
  }

  setRefToken(String stringValue) async {
    writeStringData('ref_token', stringValue);
  }



  Future<String> getToken() async {
    String val = await getStringData('token');
    return val;
  }

  Future<String> getRefToken() async {
    String val = await getStringData('ref_token');
    return val;
  }





  writeStringData(String key, String value) async {
    await prefs.setString(key, value);
  }

  Future<String> getStringData(String key) async {

    String? bindValue = prefs.getString(key);
    return bindValue ?? '';
  }

}
