import 'package:flutter/material.dart';
import 'package:swiftclean_admin/MVVM/utils/constants.dart';
import 'package:swiftclean_admin/MVVM/utils/my_box.dart';
import 'package:swiftclean_admin/MVVM/utils/my_title.dart';

class TabletScaffold extends StatefulWidget {
  const TabletScaffold({super.key});

  @override
  State<TabletScaffold> createState() => _TabletScaffoldState();
}

class _TabletScaffoldState extends State<TabletScaffold> {
  @override
  Widget build(BuildContext context) {
     return Scaffold(
       appBar: myAppBar,
      backgroundColor: myDefultBackround,
      drawer: myDrower,
      body: Column(
        children: [
        // 4 box on the top
        AspectRatio(
          aspectRatio: 4,
          child: SizedBox(
            width: double.infinity,
            child: GridView.builder(
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4), 
              itemBuilder: (context, index){
                return const MyBox();
              }
              ),
          ),
        ),

        //title below here
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index){
              return const MyTitle();
            }) )
        ],
      ),
    );
  }
}