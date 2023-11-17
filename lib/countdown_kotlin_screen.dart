import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

class CountdownKotlinPage extends StatefulWidget {
  final DateTime birthdate;

  CountdownKotlinPage({super.key, required this.birthdate});

  @override
  _BirthdayCountdownState createState() => _BirthdayCountdownState();
}

class ParsedTime {
  final int days;
  final int hours;
  final int minutes;
  final int seconds;

  ParsedTime(
      {required this.days,
      required this.hours,
      required this.minutes,
      required this.seconds});
}

class _BirthdayCountdownState extends State<CountdownKotlinPage>
    with WidgetsBindingObserver {
  late ParsedTime currentTime;
  bool isCurrentTimeInitialized = false;
  final streamEventChannel =
      const EventChannel('com.chidumennamdi/stream_channel');
  final startCountdownChannel =
      const MethodChannel("com.chidumennamdi/countdown");

  ParsedTime parseMillisToTime(int millis) {
    // Calculate days, hours, minutes, and seconds
    int seconds = (millis / 1000).floor();
    int minutes = (seconds / 60).floor();
    int hours = (minutes / 60).floor();
    int days = (hours / 24).floor();

    // Calculate remaining hours, minutes, and seconds
    int remainingHours = hours % 24;
    int remainingMinutes = minutes % 60;
    int remainingSeconds = seconds % 60;

    // Create and return an instance of ParsedTime
    return ParsedTime(
      days: days,
      hours: remainingHours,
      minutes: remainingMinutes,
      seconds: remainingSeconds,
    );
  }

  void initKotlin() {
    try {
      streamEventChannel.receiveBroadcastStream().listen((dynamic data) {
        ParsedTime parsedTime = parseMillisToTime(int.parse(data));

        setState(() {
          currentTime = parsedTime;
          isCurrentTimeInitialized = true;
        });
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void initState() {
    initKotlin();
    startCountdownChannel.invokeMethod(
        'startCountdown', getFormattedDateFromDatetime());

    WidgetsBinding.instance?.addObserver(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: Container(),
          backgroundColor: Colors.black,
          centerTitle: true, // Center the title
          title: const Text(
            "Birthday Countdown",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: "AlfaSlabOne-Regular",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                _showConfirmationDialog(context);
              },
              child: const Text(
                "Reset",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: "AlfaSlabOne-Regular",
                ),
              ),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [checkTimeElapsed()])),
          ],
        ));
  }

  Widget checkTimeElapsed() {
    if (!isCurrentTimeInitialized) {
      return const CircularProgressIndicator();
    }

    int days = currentTime.days;
    int hours = currentTime.hours;
    int mins = currentTime.minutes;
    int secs = currentTime.seconds;

    int elapsed = days + hours + mins + secs;

    return elapsed <= 0
        ? Center(
            child: Column(children: [
            const Text(
              "🎉🎉🎉",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 50,
                color: Colors.white,
              ),
            ),
            const Text(
              "Hooray!!, It's your birthday.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 50,
                  color: Colors.white,
                  fontFamily: "AlfaSlabOne-Regular"),
            ),
            const SizedBox(
              height: 30,
            ),
            ElevatedButton(
                // style: const ButtonStyle(
                //     backgroundColor: Colors.white),
                onPressed: () {
                  _showConfirmationDialog(context);
                },
                child: const Text(
                  "Restart",
                  style: TextStyle(
                      color: Colors.black, fontFamily: "AlfaSlabOne-Regular"),
                ))
          ]))
        : displayTime(currentTime);
  }

  Widget displayTime(ParsedTime _currentTime) {
    int days = _currentTime.days;
    int hours = _currentTime.hours;
    int mins = _currentTime.minutes;
    int secs = _currentTime.seconds;

    return Table(
      children: [
        _buildTimeTableRow(days, "DAYS"),
        _buildTimeTableRow(hours, "HOURS"),
        _buildTimeTableRow(mins, "MINS"),
        _buildTimeTableRow(secs, "SECS"),
      ],
    );
  }

  TableRow _buildTimeTableRow(int timeValue, String unit) {
    return TableRow(children: [
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.bottom, // Align bottom
        child: Padding(
          padding: const EdgeInsets.only(right: 8.0), // Add space between cells
          child: Text(
            '$timeValue',
            style: const TextStyle(
                fontSize: 80,
                color: Colors.white,
                decoration: TextDecoration.none,
                fontFamily: "AlfaSlabOne-Regular"),
            textAlign: TextAlign.end,
          ),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.bottom, // Align bottom
        child: Padding(
            padding:
                const EdgeInsets.only(bottom: 20.0), // Add space between cells
            child: Text(
              unit,
              style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                  fontFamily: "AlfaSlabOne-Regular"),
            )),
      ),
    ]);
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Reset'),
          content: const Text('Are you sure you want to reset?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () async {
                final SharedPreferences prefs =
                    await SharedPreferences.getInstance();
                await prefs.remove('_birthday');

                startCountdownChannel.invokeMethod("stopCountdown");

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const MyHomePage(),
                  ),
                );
              },
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void reStart() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('_birthday');

    startCountdownChannel.invokeMethod("stopCountdown");

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MyHomePage(),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  String getFormattedDateFromDatetime() {
    DateTime birthdate = widget.birthdate;
    String formattedDate =
        '${birthdate.year}-${birthdate.month}-${birthdate.day}';
    return formattedDate;
  }

  void startBackgroundServiceAndCountdown() {
    String formattedDate = getFormattedDateFromDatetime();

    MethodChannel backgroundServiceChannel =
        const MethodChannel('com.chidumennamdi/background_service');
    MethodChannel startCountdownChannel =
        const MethodChannel('com.example/start_countdown');

    backgroundServiceChannel
        .invokeMethod('startBackgroundService')
        .then((value) {
      startCountdownChannel.invokeMethod('startCountdown', formattedDate);
      initKotlin(); // Assuming initKotlin is a function you want to call after starting the background service and countdown.
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App has resumed, re-establish communication with the background service.
      // Call your method to reconnect or resend necessary data.
      startBackgroundServiceAndCountdown();
    }
  }
}
