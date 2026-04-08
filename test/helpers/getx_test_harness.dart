import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget buildGetxTestApp({
  required Widget home,
  List<GetPage<dynamic>> extraRoutes = const <GetPage<dynamic>>[],
}) {
  return GetMaterialApp(
    initialRoute: '/',
    getPages: <GetPage<dynamic>>[
      GetPage<dynamic>(name: '/', page: () => home),
      ...extraRoutes,
    ],
  );
}

void resetGetxTestState() {
  Get.testMode = true;
  Get.reset();
}
