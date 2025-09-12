

import '../../res/images/app_images.dart';
import '../../res/texts/app_texts.dart';

class ReportDetails {

  final String image;
  final String text;
  final String number;

  ReportDetails({ required this.image, required this.text,required this.number});
}

class ReportItems{

  List<ReportDetails> Items =[
    ReportDetails(
        text: 'Total Reports',
        image: AppImages.scope,
        number: '20'
    ),
    ReportDetails(
        text: 'CAD Diagnoses',
        image: AppImages.ecgHeart,
        number: '20'
    ),
    ReportDetails(
        text: 'Need Follow-up',
        image: AppImages.scope,
        number: '20'
    ),
    ReportDetails(
        text: 'Confirmed Cases',
        image: AppImages.scope,
        number: '20'
    ),

  ];
}