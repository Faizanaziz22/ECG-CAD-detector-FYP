import 'package:ecg_cad_detector/models/fake_models/report_details.dart';
import 'package:ecg_cad_detector/view/report/widgets/details_continer2.dart';
import 'package:ecg_cad_detector/view/report/widgets/report_container.dart';
import 'package:ecg_cad_detector/view/report/widgets/search_container.dart';
import 'package:flutter/material.dart';
import '../../models/fake_models/report_model2.dart';
import '../../res/colors/app_colors.dart';
import '../../res/images/app_images.dart';
import '../../res/texts/app_texts.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportItems reportItems = ReportItems();
  final ReportItems2 reportItems2 = ReportItems2();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        AppTexts.hereAreReports,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          itemCount: reportItems.Items.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: DetailContainer2(
                                  title: reportItems.Items[index].text,
                                  number: reportItems.Items[index].number,
                                  image: reportItems.Items[index].image),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      SearchContainer(),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        'Recent Reports',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        height: 170,
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
                        child: ListView.builder(
                          itemCount: reportItems2.Items.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 10),
                              child:  ReportContainer(
                                name: reportItems2.Items[index].name,
                                date: reportItems2.Items[index].date,
                                result: reportItems2.Items[index].report,
                              )
                            );
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
    );
  }
}
