import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:icalnotifier/main.dart';
import 'sign_in_with_google.dart';

void flow() async {
  await signInWithGoogle();
  // await sendToken(token);
  await FirebaseMessaging.instance
      .subscribeToTopic("salles")
      .then((value) => logger.d("Sub completed"));
}
