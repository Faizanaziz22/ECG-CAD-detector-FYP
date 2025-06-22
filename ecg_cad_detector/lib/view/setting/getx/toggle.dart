import 'package:get/get.dart';

class SwitchController extends GetxController {
  var isSwitched = false.obs;

  void toggleSwitch(bool value) {
    isSwitched.value = value;
  }
}
