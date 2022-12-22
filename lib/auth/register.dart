import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as storage;
import 'package:shared_preferences/shared_preferences.dart';

import '../global/global.dart';
import '../home/home_screen.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/error_dialog.dart';
import '../widgets/loading_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  XFile? imageXFile;
  final ImagePicker _picker = ImagePicker();

  String userImageUrl = "";

  Future<void> _getImage() async {
    imageXFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      imageXFile;
    });
  }

  Future<void> validate() async {
    if (imageXFile == null) {
      showDialog(
          context: context,
          builder: (c) {
            return const ErrorDialog(message: "Please select Profile Picture");
          });
    } else {
      if (passwordController.text == confirmPasswordController.text &&
          confirmPasswordController.text.isNotEmpty) {
        // Upload Image
        showDialog(
            context: context,
            builder: (c) {
              return const LoadingDialog(message: "Registering");
            });

        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        storage.Reference reference = storage.FirebaseStorage.instance
            .ref()
            .child("users")
            .child("profilePicture")
            .child(fileName);
        storage.UploadTask uploadTask =
            reference.putFile(File(imageXFile!.path));
        storage.TaskSnapshot taskSnapshot =
            await uploadTask.whenComplete(() => {});
        await taskSnapshot.ref.getDownloadURL().then((url) {
          userImageUrl = url;

          // Create User
          signUpAndAuthenticateUser();
        });
      } else {
        showDialog(
            context: context,
            builder: (c) {
              return const ErrorDialog(message: "Password do not match");
            });
      }
    }
  }

  void signUpAndAuthenticateUser() async {
    User? currentUser;

    await firebaseAuth
        .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim())
        .then((auth) => {currentUser = auth.user})
        .catchError((error) {
      Navigator.pop(context);
      showDialog(
          context: context,
          builder: (c) {
            return ErrorDialog(message: error.message.toString());
          });
    });

    if (currentUser != null) {
      addUserToDB(currentUser!).then((value) {
        Navigator.pop(context);

        // Navigate to Home page
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (c) => const HomeScreen()));
      });
    }
  }

  Future addUserToDB(User currentUser) async {
    FirebaseFirestore.instance.collection("users").doc(currentUser.uid).set({
      "userUID": currentUser.uid,
      "userEmail": currentUser.email,
      "userName": nameController.text.trim(),
      "userProfilePicture": userImageUrl,
      "status": "approved",
    });

    // Save data locally
    sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences!.setString("userUID", currentUser.uid);
    await sharedPreferences!.setString("userName", nameController.text.trim());
    await sharedPreferences!.setString("userProfilePicture", userImageUrl);
    await sharedPreferences!.setString("userEmail", currentUser.email.toString());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(
            height: 10,
          ),
          InkWell(
            onTap: () => _getImage(),
            child: CircleAvatar(
              radius: MediaQuery.of(context).size.width * 0.2,
              backgroundColor: Colors.white,
              backgroundImage:
                  imageXFile == null ? null : FileImage(File(imageXFile!.path)),
              child: imageXFile == null
                  ? Icon(
                      Icons.add_photo_alternate,
                      size: MediaQuery.of(context).size.width * 0.2,
                      color: Colors.grey,
                    )
                  : null,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  data: Icons.person,
                  controller: nameController,
                  hint: "Name",
                  isSecure: false,
                ),
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
                CustomTextField(
                  data: Icons.lock,
                  controller: confirmPasswordController,
                  hint: "Confirm Password",
                  isSecure: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              validate();
            },
            style: ElevatedButton.styleFrom(
                primary: Colors.purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20)),
            child: const Text(
              "Sign Up",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(
            height: 30,
          )
        ],
      ),
    );
  }
}
