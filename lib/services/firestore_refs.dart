import 'package:cloud_firestore/cloud_firestore.dart';

final db = FirebaseFirestore.instance;

CollectionReference<Map<String, dynamic>> usersCol() => db.collection('users');
CollectionReference<Map<String, dynamic>> eventsCol() => db.collection('events');
CollectionReference<Map<String, dynamic>> locationsCol() => db.collection('locations');
CollectionReference<Map<String, dynamic>> baCol() => db.collection('ba');
CollectionReference<Map<String, dynamic>> evidenceCol() => db.collection('evidence');
CollectionReference<Map<String, dynamic>> reimburseCol() => db.collection('reimburse');
