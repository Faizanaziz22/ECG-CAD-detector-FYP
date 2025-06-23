import 'package:ecg_cad_detector/view/patient/widgets/patient_container.dart';
import 'package:flutter/material.dart';

import '../../res/colors/app_colors.dart';
import '../../res/images/app_images.dart';
import '../../res/texts/app_texts.dart';

class PatientScreen extends StatefulWidget {
  const PatientScreen({super.key});

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
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
                height: 30,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
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
                        AppTexts.goodMorning,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(
                        height: 2,
                      ),
                      Text(
                        AppTexts.hereArePatient,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      SizedBox(
                        height: 300,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: AlwaysScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 1.0,
                          ),
                          padding: EdgeInsets.all(8.0),
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            return PatientContainer(
                                name: AppTexts.amandaWilliams,
                                age: AppTexts.age,
                                date: AppTexts.date);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
                    ),
                  ),
          )),
      floatingActionButton: FloatingActionButton(
          onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }
}
