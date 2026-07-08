import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swiftclean_admin/MVVM/Responsive/responsive_layput.dart';
import 'package:swiftclean_admin/MVVM/view/Dashboard/desktop_scaffold.dart';
import 'package:swiftclean_admin/MVVM/view/Dashboard/mobile_scaffold.dart';
import 'package:swiftclean_admin/MVVM/view/Dashboard/tablet_scaffold.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  String? adminEmail = "swiftcleanaccount@gmail.com";
  final passController = TextEditingController();

  bool isLoading = false;
  bool _isObscureCurrent = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        if (screenWidth >= 1024) {
          // Desktop layout
          return _buildDesktopUI(screenWidth, screenHeight);
        } else {
          // Mobile & tablet layout
          return _buildCompactLoginUI(screenWidth, screenHeight);
        }
      },
    );
  }

  Widget _buildDesktopUI(double screenWidth, double screenHeight) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(248, 248, 248, 1),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * .1,
          vertical: screenHeight * .055,
        ),
        child: Row(
          children: [
            // Left section with avatar and logo
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            "assets/icon/avathar_backround.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: EdgeInsets.only(top: screenHeight * 0.07),
                            height: screenHeight * 0.22,
                            width: screenWidth * 0.18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.white,
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Image.asset("assets/icon/logo.png")),
                                const Positioned(
                                  bottom: 12,
                                  left: 60,
                                  child: Row(
                                    children: [
                                      Text(
                                        "SWIFT",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 25,
                                          color: Color.fromARGB(255, 27, 131, 31),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        "CLEAN",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 25,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                           child: Image.asset("assets/icon/cleaning_avathar.png",scale: 1.6,),
                           )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Right section with login form
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  height: screenHeight,
                  decoration: const BoxDecoration(
                    boxShadow: [BoxShadow(blurRadius: 1.5, color: Colors.grey)],
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Welcome Back!",
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Email field
                      Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(20),
                        child: TextFormField(
                          readOnly: true,
                          initialValue: adminEmail,
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            hintText: " Email",
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 202, 202, 202),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password field
                      Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(20),
                        child: TextFormField(
                          controller: passController,
                          obscureText: _isObscureCurrent,
                          decoration: InputDecoration(
                          suffixIcon: IconButton(
                           icon: Icon(
                          _isObscureCurrent ? Icons.visibility_off : Icons.visibility,
                         ),
                          onPressed: () {
                           setState(() {
                             _isObscureCurrent = !_isObscureCurrent;
                               });
                              },
                            ),
                            fillColor: Colors.white,
                            filled: true,
                            hintText: " Password",
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 202, 202, 202),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Forget Password",
                            style: TextStyle(
                              fontSize: 18,
                              color: Color.fromARGB(255, 24, 128, 27),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Login button
                      Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(15),
                        child: InkWell(
                          onTap: _handleLogin,
                          child: Container(
                            height: 46,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: const Color.fromARGB(255, 24, 128, 27),
                            ),
                            child: const Center(
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLoginUI(double screenWidth, double screenHeight) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(248, 248, 248, 1),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 4)],
              ),
              width: screenWidth * 0.9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome Back!",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    readOnly: true,
                    initialValue: adminEmail,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Email",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Forget Password?",
                        style: TextStyle(
                          color: Color.fromARGB(255, 24, 128, 27),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 24, 128, 27),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isLoading == true
                                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                  : const Text(
                      "Login",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

 void _handleLogin() async {
   setState(() {
      isLoading = true;
    });

    try {    
      final currentUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: adminEmail.toString(),
        password: passController.text.trim(),
      );

      if (currentUser.user != null) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const ResponsiveLayout(
              mobileScaffold: MobileScaffold(),
              tabletScaffold: TabletScaffold(),
              desktopScaffold: DesktopScaffold(),
            ),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Authentication failed.");
    } catch (e) {
      _showError("Something went wrong. Please try again.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
