import 'package:ecg_cad_detector/res/colors/app_colors.dart';
import 'package:ecg_cad_detector/res/images/app_images.dart';
import 'package:flutter/material.dart';

Widget SummaryContainer(
    {final String image = 'image',
    final double height = 100,
    final double width = 90,
    final String title = 'title',
    final String number = 'number'}) {
  return Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: AppColors.white,
         borderRadius: BorderRadius.circular(20),
        boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.2),
    blurRadius: 4,
    offset: Offset(2, 2),
  ),
  ],
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          AppImages.scope,
          height: 30,

        ),
        Text(
          number,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,),
        ),
      ],
    ),
  );
}
