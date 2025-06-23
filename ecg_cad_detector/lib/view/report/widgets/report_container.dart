import 'package:flutter/material.dart';
import '../../../res/colors/app_colors.dart';

Widget ReportContainer({

  final String name = 'Name',
  final String date = 'date',
  final String result = 'result',
}){

  return Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(name,style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700
          ),),
          Text(date),
          Text(result),

        ],
      ),
      SizedBox(height: 5,),
      Container(
        height: 1,
        color: AppColors.lightGrey,
      )
    ],
  );
}