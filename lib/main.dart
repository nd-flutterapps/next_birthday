import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'countdown_kotlin_screen.dart';
import 'countdown_screen.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget render() {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return render();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  final String title = 'My Next Birthday';

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController dateController = TextEditingController();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _birthday;
  final MethodChannel platform =
      const MethodChannel('com.example/background_service');

  final startCountdownChannel =
      const MethodChannel("com.example/start_countdown");

  @override
  void initState() {
    super.initState();

    // startBackgroundService();
    // print("Flutter: startBackgroundService");
    //
    // eventChannel.receiveBroadcastStream().listen((dynamic data) {
    //   print("In Flutter: ");
    //   print(data);
    // });

    startBackgroundService().then((_) {
      print("Flutter: startBackgroundService");
    });

    _birthday = _prefs.then((SharedPreferences prefs) {
      return prefs.getString('_birthday') ?? "";
    });
  }

  startBackgroundService() async {
    await platform.invokeMethod('startBackgroundService');

    return true;
  }

  void start() async {
    // try {
    //   streamEventChannel.receiveBroadcastStream().listen((dynamic data) {
    //     print("In Flutter: ");
    //     print(data);
    //   });
    //   startCountdownChannel.invokeMethod("startCountdown", "09/12/2023");
    // } catch (e) {
    //   print("Error: $e");
    // }
    // return;

    if (dateController.text.isEmpty) {
      return;
    }

    startCountdownChannel.invokeMethod("startCountdown", dateController.text);

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CountdownKotlinPage(
              birthdate: DateTime.parse(dateController.text))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: _birthday,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return const CircularProgressIndicator();
            case ConnectionState.active:
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                String? value = snapshot.data;
                if (value!.isEmpty) {
                  return Scaffold(
                      appBar: AppBar(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        centerTitle: true, // Center the title
                        leading: Container(), // Remove any leading widget
                        title: Text(
                          widget.title,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      body: Center(
                        child: Container(
                          color: Colors.black,
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              TextField(
                                  style: const TextStyle(color: Colors.white),
                                  controller:
                                      dateController, //editing controller of this TextField
                                  decoration: const InputDecoration(
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.white),
                                      ),
                                      iconColor: Colors.white,
                                      icon: Icon(Icons
                                          .calendar_today), //icon of text field
                                      labelText:
                                          "Enter Birthday Date", //label text of field
                                      labelStyle:
                                          TextStyle(color: Colors.white),
                                      hintStyle:
                                          TextStyle(color: Colors.white)),
                                  readOnly:
                                      true, // when true user cannot edit text
                                  onTap: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            DateTime.now(), //get today's date
                                        firstDate: DateTime(
                                            2000), //DateTime.now() - not to allow to choose before today.
                                        lastDate: DateTime(2101));

                                    if (pickedDate != null) {
                                      print(
                                          pickedDate); //get the picked date in the format => 2022-07-04 00:00:00.000
                                      String formattedDate =
                                          DateFormat('yyyy-MM-dd').format(
                                              pickedDate); // format date in required form here we use yyyy-MM-dd that means time is removed
                                      print(
                                          formattedDate); //formatted date output using intl package =>  2022-07-04
                                      //You can format date as per your need

                                      final SharedPreferences prefs =
                                          await _prefs;

                                      prefs.setString(
                                          '_birthday', formattedDate);

                                      setState(() {
                                        dateController.text =
                                            formattedDate; //set foratted date to TextField value.
                                      });
                                    } else {
                                      print("Date is not selected");
                                    } //when click we have to show the datepicker
                                  }),
                              const SizedBox(
                                height: 9,
                              ),
                              TextButton(
                                  style: ButtonStyle(
                                    foregroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.black),
                                  ),
                                  onPressed: () {
                                    start();
                                  },
                                  child: const Text(
                                    'Start',
                                    style: TextStyle(color: Colors.white),
                                  ))
                            ],
                          ),
                        ),
                      ) // This trailing comma makes auto-formatting nicer for build methods.
                      );
                }

                return CountdownPage(birthdate: DateTime.parse(value!));
              }
          }
        });
  }
}

// I/System.out( 3686): startBackgroundService
// I/System.out( 3686): onStartCommand
// I/System.out( 3686): initializeMethodChannel
// I/System.out( 3686): Kotlin: initializing EventChannel
// I/System.out( 3686): initializeEventChannel
// I/flutter ( 3686): Flutter: startBackgroundService

// The error message that you are encountering, kotlin.UninitializedPropertyAccessException: lateinit property eventSink has not been initialized, is indicating that the eventSink property is being accessed before it has been initialized. This can happen when you try to send an event to the Flutter side before the EventChannel has established a communication link with the Flutter frontend.
//
// In the provided code, eventSink is a lateinit property that is only initialized when the onListen method of your EventChannel.StreamHandler is called. This method is called when the Flutter side starts listening to the EventChannel. The error suggests that you are trying to use eventSink in other parts of your service, such as the sendEventToFlutter method, before onListen has been called.
//
// To fix this issue, you should check that eventSink has been initialized (is not null) before using it:
//
// private fun sendEventToFlutter(message: String) {
// if (this::eventSink.isInitialized) {
// eventSink.success(message)
// }
// }
// Additionally, make sure you are not calling sendEventToFlutter from anywhere before the onListen method of your EventChannel.StreamHandler has been called. Your startCountdown method should not attempt to send an event to Flutter until eventSink is guaranteed to have been initialized.
//
// Furthermore, it seems like you've commented out the initializeMethodChannel invocation in onStartCommand, and handleMethodCallFromFlutter is currently kick-starting the countdown process. Depending on the interactions with your service, ensure that the sequence of method invocations allows for proper initialization of eventSink before its use.
//
// Lastly, it's not clear why initializeMethodChannel is setting up a new MethodChannel with a new instance of FlutterEngine. This would not be normal practice, and if the intention was to set up a method channel to handle calls from Flutter, you should be using the same BinaryMessenger that was provided by the MainActivity.sharedFlutterEngine?.dartExecutor.binaryMessenger. You should probably revisit this part of your implementation, as it seems to be part of logic establishing the channels for communication.
//
// Make sure you correct these issues and then test your app to ensure the EventChannel is properly establishing a connection before attempting to send messages to Flutter.
