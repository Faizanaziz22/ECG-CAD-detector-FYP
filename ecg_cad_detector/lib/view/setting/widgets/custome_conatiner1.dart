import 'package:ecg_cad_detector/res/colors/app_colors.dart';
import 'package:ecg_cad_detector/res/texts/app_texts.dart';
import 'package:flutter/material.dart';

Widget CustomeContainer1({

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
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icon,color: AppColors.darkBlue,),
          SizedBox(width: 13,),
          Text(title,style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),),
          Spacer(),
          Text(text,style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
              color: Colors.grey
          ),),
          SizedBox(width: 5,),
          Icon(Icons.arrow_forward_ios_rounded,size: 14,color: Colors.grey,)
        ],
      ),
    ),
  );
}