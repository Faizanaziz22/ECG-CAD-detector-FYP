import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../res/colors/app_colors.dart';
import '../getx/toggle.dart';

Widget CustomeContainer2({

  final double height = 60,
  IconData? icon,
  final String title = 'title'

}){
  final SwitchController controller = Get.put(SwitchController());

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
          Obx(
                () => CupertinoSwitch(
              value: controller.isSwitched.value,
              onChanged: controller.toggleSwitch,
                  activeColor: AppColors.darkBlue,

            ),
          ),
        ],
      ),
    ),
  );
}