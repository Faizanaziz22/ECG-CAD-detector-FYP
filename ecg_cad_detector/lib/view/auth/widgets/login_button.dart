import 'package:ecg_cad_detector/res/colors/app_colors.dart';
import 'package:flutter/material.dart';

Widget LoginButton({
  final String text = 'Text',
  final double height = 55,
  //final double width = ,
}) {
  return Container(
    height: height,
    decoration: BoxDecoration(
      color: AppColors.darkBlue,
      borderRadius: BorderRadius.circular(50),
    ),
    child: Center(
      child: Text(
        text,
        style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.white),
      ),
    ),
  );
}
