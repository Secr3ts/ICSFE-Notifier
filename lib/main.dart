import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';

FirebaseAuth auth = FirebaseAuth.instance;
Logger logger = Logger();

void flow(String token) async {
  await _signInWithGoogle();
  // await sendToken(token);
  await FirebaseMessaging.instance
      .subscribeToTopic("salles")
      .then((value) => logger.d("Sub completed"));
}

void showNotification(String head, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails('69', 'icalmabite',
          channelDescription: 'tounsgay',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');

  const DarwinNotificationDetails iosPlatform = DarwinNotificationDetails();
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iosPlatform);

  await FlutterLocalNotificationsPlugin().show(
    0,
    head,
    body,
    platformChannelSpecifics,
    payload: 'item x',
  );
}

sendToken(String token) async {
  DatabaseReference ref = FirebaseDatabase.instance.ref("tokens/");

  if (auth.currentUser != null) {
    String name = FirebaseAuth.instance.currentUser!.email!
        .split('@')[0]
        .replaceAll('-_.', '');
    await ref.update({name: token});
  }
}

Future<UserCredential> _signInWithGoogle() async {
  // Trigger the authentication flow
  final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

  // Obtain the auth details from the request
  final GoogleSignInAuthentication? googleAuth =
      await googleUser?.authentication;

  // Create a new credential
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth?.accessToken,
    idToken: googleAuth?.idToken,
  );

  // Once signed in, return the UserCredential
  return await FirebaseAuth.instance.signInWithCredential(credential);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initIos = DarwinInitializationSettings();
  const InitializationSettings inits =
      InitializationSettings(android: initAndroid, iOS: initIos);
  await FlutterLocalNotificationsPlugin().initialize(inits);

  await Firebase.initializeApp(
    // name: 'App',
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    // You can also use a `ReCaptchaEnterpriseProvider` provider instance as an
    // argument for `webProvider`
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    // Default provider for Android is the Play Integrity provider. You can use the "AndroidProvider" enum to choose
    // your preferred provider. Choose from:
    // 1. Debug provider
    // 2. Safety Net provider
    // 3. Play Integrity provider
    androidProvider: AndroidProvider.debug,
    // Default provider for iOS/macOS is the Device Check provider. You can use the "AppleProvider" enum to choose
    // your preferred provider. Choose from:
    // 1. Debug provider
    // 2. Device Check provider
    // 3. App Attest provider
    // 4. App Attest provider with fallback to Device Check provider (App Attest provider is only available on iOS 14.0+, macOS 14.0+)
    appleProvider: AppleProvider.appAttest,
  );
  FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    showNotification("ok", message.data.values.firstOrNull);
  });
  runApp(const Notifier());
}

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  showNotification("!", message.data.values.firstOrNull);
  if (kDebugMode) {
    print(message.data);
    print("bite");
  }
}

class Notifier extends StatelessWidget {
  const Notifier({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICal',
      theme: ThemeData(
        // This is the theme of your application.
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'ICal'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? fcmToken = '';
  bool logged = false || FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getToken();
    });
    FirebaseMessaging.instance.onTokenRefresh
        .listen((fcmToken) => sendToken(fcmToken))
        .onError((err) {
      if (kDebugMode) {
        print(err);
      }
    });
  }

  void getToken() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.denied) {
      getToken();
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      showSettingsDialog();
    }

    final token = await FirebaseMessaging.instance.getToken();
    setState(() {
      fcmToken = token;
    });
  }

  Future<dynamic> showSettingsDialog() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Application Settings'),
          content: const Text(
              'Please enable the required permissions in the application settings.'),
          actions: [
            TextButton(
              child: const Text('Quit'),
              onPressed: () {
                exit(0);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Colors.teal.shade200,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
          leading: logged ? const Icon(Icons.check) : const Icon(Icons.error)),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Stack(
          children: <Widget>[
            const Column(
              // Column is also a layout widget. It takes a list of children and
              // arranges them vertically. By default, it sizes itself to fit its
              // children horizontally, and tries to be as tall as its parent.
              //
              // Column has various properties to control how it sizes itself and
              // how it positions its children. Here we use mainAxisAlignment to
              // center the children vertically; the main axis here is the vertical
              // axis because Columns are vertical (the cross axis would be
              // horizontal).
              //
              // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
              // action in the IDE, or press "p" in the console), to see the
              // wireframe for each widget.
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: Text(
                    "ICal Notifier",
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Visibility(
                visible: logged,
                child: TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      setState(
                        () {
                          logged = !logged;
                        },
                      );
                    },
                    child: const Text("Sign Out")),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: Visibility(
          visible: !logged,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                "Hit to receive notifications",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Padding(padding: EdgeInsets.all(2)),
              FloatingActionButton(
                backgroundColor: Colors.blueGrey,
                child: const Icon(Icons.share),
                onPressed: () {
                  flow(fcmToken!);
                  setState(() {
                    logged = !logged;
                  });
                },
              ),
            ],
          )),
    );
  }
}
