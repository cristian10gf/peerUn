import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall call) async => Directory.systemTemp.path,
  );
  Get.testMode = true;
  Get.reset();
}
