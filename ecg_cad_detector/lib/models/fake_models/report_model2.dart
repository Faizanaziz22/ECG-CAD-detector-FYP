

import '../../res/images/app_images.dart';
import '../../res/texts/app_texts.dart';

class ReportModel2 {

  final String name;
  final String date;
  final String report;

  ReportModel2({ required this.name, required this.date,required this.report});
}

class ReportItems2{

  List<ReportModel2> Items =[
    ReportModel2(
        name: 'Name',
        date: 'Date',
        report: 'Report'
    ),
    ReportModel2(
        name: 'William',
        date: AppTexts.date,
        report: 'normal'
    ),
    ReportModel2(
        name: 'William',
        date: AppTexts.date,
        report: 'normal'
    ),
    ReportModel2(
        name: 'William',
        date: AppTexts.date,
        report: 'normal'
    ),
    ReportModel2(
        name: 'William',
        date: AppTexts.date,
        report: 'normal'
    ),

  ];
}