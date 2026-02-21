import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mighty_fitness/controllers/google_sign_in_controller/google_sign_in_controller.dart';


class GoogleLoginScreen extends StatelessWidget {
  GoogleLoginScreen({super.key});

  final GoogleAuthController controller =
      Get.put(GoogleAuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center,
                    size: 80, color: Colors.redAccent),
                const SizedBox(height: 20),
                Text(
                  "Welcome to Mighty Fitness",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Train smarter. Live stronger.",
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),
                controller.isLoading.value
                    ? const CircularProgressIndicator(
                        color: Colors.redAccent,
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Image.asset(
                          "assets/google.png",
                          height: 24,
                        ),
                        label: const Text("Continue with Google"),
                        onPressed: controller.loginWithGoogle,
                      ),

                const SizedBox(height: 20),

                Text(
                  "By continuing, you agree to our Terms & Privacy Policy",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
