import 'package:flutter/material.dart';
import '../constants/routes_constants.dart';
import '../screens/Auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';



Route<dynamic> generateRoute(RouteSettings settings) {
if(settings != null){
  switch(settings.name){
    case RouteConstants.loginScreen :
      return MaterialPageRoute(
          builder: (context) => const LoginPage());
      case RouteConstants.dashboardScreen :
      return MaterialPageRoute(
          builder: (context) => const DashboardPage());



    default :
      return MaterialPageRoute(
          builder: (context) => const SizedBox());
  }
}else{
return MaterialPageRoute(
    builder: (context) => const SizedBox());
}
}