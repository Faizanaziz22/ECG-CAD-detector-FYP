import 'package:ecg_cad_detector/view/setting/widgets/custome_conatiner1.dart';
import 'package:ecg_cad_detector/view/setting/widgets/custome_container2.dart';
import 'package:ecg_cad_detector/view/setting/widgets/logout_button.dart';
import 'package:flutter/material.dart';

import '../../res/colors/app_colors.dart';
import '../../res/images/app_images.dart';
import '../../res/texts/app_texts.dart';
import '../auth/widgets/login_button.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue2,
      body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Column(
            children: [
              SizedBox(
                height: 45,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.lightBlue2,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: Offset(15, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            
                      Row(
                        children: [
                          Image.asset(
                            AppImages.ecgHeart,
                            height: 35,
                            width: 35,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            AppTexts.cadDetector,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Text(
                        AppTexts.setting,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      CustomeContainer1(
                        icon: Icons.person,
                        title: AppTexts.account,
                        text: AppTexts.email
                      ),
                      SizedBox(height: 15,),
                      CustomeContainer2(
                        icon: Icons.notifications,
                        title: AppTexts.notification
                      ),
                      SizedBox(height: 15,),
                      CustomeContainer2(
                          icon: Icons.dark_mode,
                          title: AppTexts.darkMode
                      ),
                      SizedBox(height: 15,),
                      CustomeContainer1(
                          icon: Icons.language,
                          title: AppTexts.language,
                          text: 'English'
                      ),
                      SizedBox(height: 15,),
                      LogOutButton(),
            
                    ],
                  ),
                ),
              )
            ],
                    ),
                  ),
          )),
    );
  }
}
