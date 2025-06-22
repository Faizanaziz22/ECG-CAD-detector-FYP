import 'package:ecg_cad_detector/view/home/widgets/detail_container.dart';
import 'package:ecg_cad_detector/view/home/widgets/live_feed_container.dart';
import 'package:ecg_cad_detector/view/home/widgets/summary_container.dart';
import 'package:flutter/material.dart';

import '../../models/fake_models/detail_models.dart';
import '../../models/fake_models/summary_container.dart';
import '../../res/colors/app_colors.dart';
import '../../res/images/app_images.dart';
import '../../res/texts/app_texts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SummaryIems items = SummaryIems();
  final DetailsIems detailsIems = DetailsIems();

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
              const SizedBox(
                height: 50,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.lightBlue2,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(15, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 40,
                      ),
                      Row(
                        children: [
                          Image.asset(
                            AppImages.ecgHeart,
                            height: 35,
                            width: 35,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          const Text(
                            AppTexts.cadDetector,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        AppTexts.goodMorning,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      const Text(
                        AppTexts.todaySummary,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          itemCount: items.Items.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: SummaryContainer(
                                  title: items.Items[index].text,
                                  number: items.Items[index].number,
                                  image: items.Items[index].image),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      LiveFeedContainer(),
                      const SizedBox(
                        height: 15,
                      ),
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          itemCount: detailsIems.Items.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: DetailContainer(
                                  title: detailsIems.Items[index].text,
                                  icon: detailsIems.Items[index].icon),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      )
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
