import 'package:ecg_cad_detector/res/colors/app_colors.dart';
import 'package:ecg_cad_detector/res/images/app_images.dart';
import 'package:ecg_cad_detector/res/texts/app_texts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../navigation_bar.dart';
import '../getx/checkbox.dart';
import '../sign_up/sign_up _screen.dart';
import '../widgets/custome_textfield.dart';
import '../widgets/login_button.dart.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final CheckboxController controller = Get.put(CheckboxController());
  final box = GetStorage();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _handleLogin() {
    String email = emailController.text.trim();
    String password = passwordController.text;

    // Simple validation (you can enhance this with real authentication logic)
    if (email == 'user@example.com' && password == '1234') {
      box.write('isLoggedIn', true);
      Get.offAll(() => CustomUserNavBar());
    } else {
      Get.snackbar(
        'Login Failed',
        'Incorrect email or password.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue2,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(AppImages.ecgHeart, height: 35, width: 35),
                    const SizedBox(width: 10),
                    Text(
                      AppTexts.cadDetector,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(AppTexts.emailUserName),
                        const SizedBox(height: 3),
                        CustomeTextField(
                          hint: AppTexts.enterEmail,
                          controller: emailController,
                          icon: false,  // Explicitly passing false
                        ),
                        const SizedBox(height: 10),
                        Text(AppTexts.password),
                        const SizedBox(height: 3),
                        CustomeTextField(
                          hint: AppTexts.enterPassword,
                          icon: true,
                          isPassword: true,
                          controller: passwordController,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Obx(() => Transform.scale(
                              scale: 0.8,
                              child: Checkbox(
                                activeColor: AppColors.darkBlue,
                                value: controller.isChecked.value,
                                onChanged: (value) =>
                                controller.isChecked.value = value!,
                              ),
                            )),
                            const Text(
                              AppTexts.rememberMe,
                              style: TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _handleLogin,
                          child: LoginButton(text: AppTexts.login),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          AppTexts.forget,
                          style: TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppTexts.newHere,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.lightBlue,
                              ),
                            ),
                            const SizedBox(width: 3),
                            GestureDetector(
                              onTap: () {
                               Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SignUpScreen()),
                              );
                              },
                              child: Text(
                                AppTexts.register,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: const Color.fromARGB(255, 63, 85, 91),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
