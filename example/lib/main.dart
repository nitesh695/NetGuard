import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'example-1/screens/Auth/login_screen.dart';
import 'example-1/screens/dashboard/dashboard_screen.dart';
import 'example-1/service/api.dart';
import 'example-1/service/di_container.dart' as di;
import 'example-1/utils/routes_list.dart';
import 'example-1/utils/storage_manager.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(MyApp()); ///Or  runApp(const NetGuardExampleApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    // TODO: implement initState
    getToken();
    Get.find<ApiClient>().init();
    super.initState();
  }

  String token = '';
  void getToken()async{
    token =  await Get.find<StorageManager>().getToken();
    print("token is ....$token");
  }

  @override
  Widget build(BuildContext context){
    return GetMaterialApp(
      title: "NetGuard Demo",
      debugShowCheckedModeBanner: false,
      navigatorKey: Get.key,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
      ),
      onGenerateRoute: generateRoute,
      home: token.isEmpty ? const LoginPage() : DashboardPage(),
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 500),
      builder: (context, child) {
        return MediaQuery(data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling), child: child!);
      },
    );
  }
}
