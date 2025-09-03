import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:management_event/authwrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  kIsWeb
      ? await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDUeHxnX-B8qB9WdJNxedfN7zot-VAtacI",
          authDomain: "sky-lab-edc2e.firebaseapp.com",
          projectId: "sky-lab-edc2e",
          storageBucket: "sky-lab-edc2e.appspot.com",
          messagingSenderId: "723045892957",
          appId: "1:723045892957:web:ac9ce2c5c32d637b219eb4",
        ),
      )
      : await Firebase.initializeApp();
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Auth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
