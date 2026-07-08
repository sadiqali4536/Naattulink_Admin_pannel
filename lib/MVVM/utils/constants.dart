import 'package:flutter/material.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';


var myDefultBackround = AppColors.mainscreen;

var myAppBar = AppBar(
 backgroundColor: const Color.fromARGB(255, 255, 254, 254),
);

var myDrower = Drawer(
 backgroundColor: AppColors.mainscreen,
      child: Column(
        children: [
          DrawerHeader(
            child: Image.asset("")),
          const ListTile(
            leading: Icon(Icons.dashboard),
            title: Text("DASHBOARD"),
          )
        ],
      ),
);
var myslideDrawer = SliderDrawer(
   slider: Container(color: Colors.black45,),
    child: Container(color: Colors.green,));

  // colors
  class AppColors{
    static const Color gradient1 = Color.fromRGBO(88, 142, 12, 1);
    static const Color gradient2 = Color.fromRGBO(53, 120, 1, 1);
    static const Color border= Color.fromRGBO(133, 130, 130, 1);
    static const Color textcolor1 = Color.fromRGBO(173, 181, 188, 1);
    static const Color black= Color.fromRGBO(0, 0, 0, 1);
    static const Color yellow= Color.fromRGBO(247, 198, 4, 1);
    static const Color red= Color.fromRGBO(243, 41, 41, 1);
    static const Color blue= Color.fromRGBO(33, 154, 223, 1);
    static const Color green= Color.fromRGBO(51, 167, 41, 1);
    static const Color mainscreen= Color.fromRGBO(238, 237, 237, 1); 
    static const Color drawer= Color.fromRGBO(255, 255, 255, 1);
    
  }
  