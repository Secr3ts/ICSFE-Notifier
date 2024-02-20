import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:icalnotifier/main.dart';

sendToken(String token) async {
  DatabaseReference ref = FirebaseDatabase.instance.ref("tokens/");

  if (auth.currentUser != null) {
    String name = FirebaseAuth.instance.currentUser!.email!
        .split('@')[0]
        .replaceAll('-_.', '');
    await ref.update({name: token});
  }
}
