import 'package:example/screens/Auth/controllers/auth.controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _onButtonPressed(BuildContext context) async{

    Future.wait([
      Get.find<AuthController>().testApi(),
      Get.find<AuthController>().testApi1(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _onButtonPressed(context),
          child: const Text('Click Me'),
        ),
      ),
    );
  }
}
