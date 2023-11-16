import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

class CountdownPage extends StatefulWidget {
  final DateTime birthdate;

  CountdownPage({super.key, required this.birthdate});

  @override
  _BirthdayCountdownState createState() => _BirthdayCountdownState();
}

class _BirthdayCountdownState extends State<CountdownPage> {
  late Duration _timeRemaining;

  @override
  void initState() {
    super.initState();
    calculateTimeRemaining();
  }

  void calculateTimeRemaining() {
    final today = DateTime.now();
    DateTime nextBirthday =
        DateTime(today.year, widget.birthdate.month, widget.birthdate.day);

    if (nextBirthday.isBefore(today)) {
      // Birthday has already occurred this year, calculate for next year
      nextBirthday = nextBirthday.add(const Duration(days: 365));
    }

    _timeRemaining = nextBirthday.difference(today);

    // Update the countdown every second
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining.inSeconds <= 0) {
        timer.cancel();
        // Handle the case when the countdown is complete
      } else {
        setState(() {
          _timeRemaining = _timeRemaining - const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int days = _timeRemaining.inDays;
    int hours = _timeRemaining.inHours.remainder(24);
    int mins = _timeRemaining.inMinutes.remainder(60);
    int secs = _timeRemaining.inSeconds.remainder(60);

    int elasped = 0; //days + hours + mins + secs;

    // MaterialStateProperty<Color?>? yt = MaterialStateProperty();

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
                  fontSize: 25,
                  fontFamily: "Roboto",
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
                    children: [
                  elasped == 0
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
                            ),
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
                                style: TextStyle(color: Colors.black),
                              ))
                        ]))
                      : Table(
                          children: [
                            _buildTimeTableRow(_timeRemaining.inDays, "DAYS"),
                            _buildTimeTableRow(
                                _timeRemaining.inHours.remainder(24), "HOURS"),
                            _buildTimeTableRow(
                                _timeRemaining.inMinutes.remainder(60), "MINS"),
                            _buildTimeTableRow(
                                _timeRemaining.inSeconds.remainder(60), "SECS"),
                          ],
                        ),
                ])),
          ],
        ));
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
            ),
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
              ),
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

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MyHomePage(),
      ),
    );
  }
}
