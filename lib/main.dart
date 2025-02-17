import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lotto_simul/pages/start_page.dart';
import 'package:lotto_simul/pages/play_page.dart';
import 'package:lotto_simul/controllers/lotto_ticket_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Lotto Simulator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const StartPage()),
        GetPage(name: '/ticket', page: () => const PlayPage()),
      ],
      initialBinding: BindingsBuilder(() {
        Get.put(LottoTicketController());
      }),
    );
  }
}
