import 'package:ecg_cad_detector/res/colors/app_colors.dart';
import 'package:flutter/material.dart';

Widget DetailContainer({
  IconData? icon,
  double height = 70,
  double width = 100,
  String title = 'title',
}) {
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
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Expanded(child: SizedBox()),
          Icon(icon,size: 20,),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,

              ),
            ),
          ),
        ],
      ),
    )

  );
}
