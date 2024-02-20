import 'dart:async';
import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:icalnotifier/animated_border.dart';
import 'package:icalnotifier/send_token.dart';
import 'package:icalnotifier/show_notification.dart';
import 'package:icalnotifier/flow.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:fuzzy/fuzzy.dart';

FirebaseAuth auth = FirebaseAuth.instance;
Logger logger = Logger();
List<String> names = ['Sofyan', 'Alois', 'Youssef', 'Hadrien'];
String name = 'Temporaire';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initAndroid =
      AndroidInitializationSettings("app_icon");
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
    _backgroundHandler(message);
  });
  runApp(const Notifier());
}

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  String msg = message.data.values.firstOrNull + 'est en ' + message.data.values.lastOrNull;

  showNotification(
      'viens fumer', msg, name);
  logger.i(message.data.toString());
}

class Notifier extends StatelessWidget {
  const Notifier({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'ICal'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? fcmToken = '';
  bool logged = false || FirebaseAuth.instance.currentUser != null;
  
  final TextEditingController _textEditingController =  TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      init();
    });
    FirebaseMessaging.instance.onTokenRefresh
        .listen((fcmToken) => sendToken(fcmToken))
        .onError((err) {
      if (kDebugMode) {
        print(err);
      }
    });
  }

  void init() async {
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
      init();
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      showSettingsDialog();
    }

    setState(() {
        name = logged ? FirebaseAuth.instance.currentUser!.displayName ?? 'Ajouter' : 'Temporaire';
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: Column(
                    children: [
                      const AnimatedBorder(),
                      Text(
                          "Status: ${logged ? "Connected" : "Disconnected"}"),
                      Text("Name: $name"),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: TextField(
                          controller: _textEditingController,
                          decoration: const InputDecoration(
                            labelText: "Name",
                            hintText: "Enter one of the 4 names"
                          ),
                        ),
                      ),
                      TextButton(onPressed: () async {
                        String tname = _textEditingController.text;
                        final fuse = Fuzzy(names);
                        final result = fuse.search(tname);
                        
                        if (logged) { await FirebaseAuth.instance.currentUser!.updateDisplayName(result[0].item); }
                        setState(() {
                          name = logged ? FirebaseAuth.instance.currentUser!.displayName! : result[0].item;
                        });
                      }, child: const Text('Submit Name'))
                    ],
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
                  flow();
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
