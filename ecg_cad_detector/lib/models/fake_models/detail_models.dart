

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../res/texts/app_texts.dart';

class DetailModels {
  final IconData icon;
  final String text;


  DetailModels({
    required this.icon,
    required this.text,

  });
}

class DetailsIems{

  List<DetailModels> Items =[
    DetailModels(
        text: AppTexts.uploadReport,
        icon: Icons.upload_file,

    ),
    DetailModels(
        text: 'View Reports',
        icon: Icons.search,

    ),
    DetailModels(
        text: 'Add patients',
        icon: Icons.add_box_rounded,

    ),

  ];
}