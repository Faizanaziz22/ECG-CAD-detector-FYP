import 'package:flutter/material.dart';

import '../../../res/colors/app_colors.dart';

Widget SearchContainer({

  final double height = 60,
}){
  return Container(
    height:height ,
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(15),
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
          Container(
            height: 35,
            width: 140,
            decoration: BoxDecoration(
              color: AppColors.lightGrey.withOpacity(0.45),
              borderRadius: BorderRadius.circular(30),
            ),

            child: TextFormField(
              decoration: InputDecoration(
                hintText: 'Search',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search,size: 19,color: Colors.grey,)
              ),
            ),
          ),
          Spacer(),
          Container(
            height: 30,
            width: 70,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            child: Center(child: Text('Date Range')),
          ),
          SizedBox(width: 5,),
          Container(
            height: 30,
            width: 45,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            child: Center(child: Text('Filter')),
          ),
        ],
      ),
    ),
  );
}