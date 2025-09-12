import 'package:ecg_cad_detector/res/colors/app_colors.dart';
import 'package:ecg_cad_detector/res/texts/app_texts.dart';
import 'package:flutter/material.dart';

Widget LogOutButton({

  final double height = 60,
  final  String title = 'title',
  final  String text = 'text',
  IconData? icon,

}){

  return Container(
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 4,
          offset: Offset(2, 2),
        ),
      ],
    ),
    child: Center(
      child: Text(AppTexts.logOut,style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),),
    )
  );
}