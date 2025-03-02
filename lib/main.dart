import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lotto_simul/pages/start_page.dart';
import 'package:lotto_simul/pages/main_page.dart';
import 'package:lotto_simul/pages/stats_page.dart';
import 'package:lotto_simul/controllers/lotto_ticket_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
        GetPage(name: '/main', page: () => const MainPage()),
        GetPage(name: '/stats', page: () => const StatsPage()),
      ],

      // 한국어 지원을 위한 로컬라이제이션 설정
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),

      initialBinding: BindingsBuilder(() {
        Get.put(LottoTicketController());
      }),
    );
  }
}
