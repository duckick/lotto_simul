import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lotto_ticket_controller.dart';
import 'play_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: PlayPage(),
    );
  }
}
