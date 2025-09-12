

import '../../res/images/app_images.dart';
import '../../res/texts/app_texts.dart';

class SummaryModel {

  final String image;
  final String text;
  final String number;

  SummaryModel({ required this.image, required this.text,required this.number});
}

class SummaryIems{

  List<SummaryModel> Items =[
    SummaryModel(
        text: AppTexts.totalPatients,
        image: AppImages.scope,
        number: '20'
    ),
    SummaryModel(
        text: AppTexts.ecgAnalysis,
        image: AppImages.ecgHeart,
        number: '20'
    ),
    SummaryModel(
        text: AppTexts.detectiveAbnormal,
        image: AppImages.scope,
        number: '20'
    ),

  ];
}