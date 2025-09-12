import 'package:ecg_cad_detector/res/colors/app_colors.dart';
import 'package:ecg_cad_detector/res/images/app_images.dart';
import 'package:ecg_cad_detector/res/texts/app_texts.dart';
import 'package:flutter/material.dart';

Widget LiveFeedContainer(
    {final String image = 'image',
      final double height = 150,
    }) {
  return Container(
    height: height,
    width: double.infinity,
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
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              AppTexts.liveFeed,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600,),
            ),
          ),

          Spacer(),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.lightBlue2,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Center(child: Text(AppTexts.startAnalysis,style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold),)),
          )
        ],
      ),
    ),
  );
}
