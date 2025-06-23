import 'package:ecg_cad_detector/res/colors/app_colors.dart';
import 'package:ecg_cad_detector/res/texts/app_texts.dart';
import 'package:flutter/material.dart';

Widget PatientContainer({

  final double height = 110,
  final double width = 130,
  final  String name = 'name',
  final  String age = 'age',
  final  String date = 'date',
}){

  return Container(
    height: height,
    width: width,
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
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
          Text(age,style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold),),
          Text(date,style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold),),
          Row(
            children: [
              Text(AppTexts.ecgAnalysis,style: TextStyle(fontSize: 10,fontWeight: FontWeight.bold),),
              Spacer(),
              Container(
                height: 17,
                width: 50,
                decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text('Normal',style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10
                  ),),
                ),
              )

            ],
          )
        ],
      ),
    ),
  );
}