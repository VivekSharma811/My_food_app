import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../global/global.dart';
import '../home/home_screen.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/error_dialog.dart';
import '../widgets/loading_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  validate() {
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      loginUser();
    } else {
      showDialog(
          context: context,
          builder: (c) {
            return const ErrorDialog(
                message: "Please enter Email and Password");
          });
    }
  }

  loginUser() async {
    showDialog(
        context: context,
        builder: (c) {
          return const LoadingDialog(message: "Authenticating");
        });

    User? currentUser;

    await firebaseAuth
        .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim())
        .then((auth) {
      currentUser = auth.user!;
    }).catchError((error) {
      Navigator.pop(context);
      showDialog(
          context: context,
          builder: (c) {
            return ErrorDialog(message: error.message.toString());
          });
    });

    if (currentUser != null) {
      fetchUserDetails(currentUser!).then((value) {
        Navigator.pop(context);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (c) => const HomeScreen()));
      }).catchError((error) {
        Navigator.pop(context);
        showDialog(
            context: context,
            builder: (c) {
              return ErrorDialog(message: error.message.toString());
            });
      });
    }
  }

  Future<void> fetchUserDetails(User currentUser) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .get()
        .then((snapshot) async {
          if(snapshot.exists) {
            await sharedPreferences!.setString("userUID", currentUser.uid);
            await sharedPreferences!
                .setString("userName", snapshot.data()!["userName"]);
            await sharedPreferences!.setString(
                "userProfilePicture",
                snapshot.data()!["userProfilePicture"]);
            await sharedPreferences!
                .setString("userEmail", emailController.text.trim());
          } else {
            firebaseAuth.signOut();
            throw Exception("You are not Authorised");
          }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Image.asset(
                "images/login.png",
                height: 270,
              ),
            ),
          ),
          Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    data: Icons.email,
                    controller: emailController,
                    hint: "Email",
                    isSecure: false,
                  ),
                  CustomTextField(
                    data: Icons.lock,
                    controller: passwordController,
                    hint: "Password",
                    isSecure: true,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      validate();
                    },
                    style: ElevatedButton.styleFrom(
                        primary: Colors.purple,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 20)),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ))
        ],
      ),
    );
  }
}
