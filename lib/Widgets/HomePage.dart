import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height - 60,
      child: Column(
        children: <Widget>[
          Image.asset(
            'assets/images/charizard.webp',
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height - 60,
          ),
        ],
      ),
    );
  }
}
