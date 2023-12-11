import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MinsSecsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Only allow numeric characters and limit the length to 4
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 4) {
      digits = digits.substring(digits.length - 4);
    }

    // Format the string with leading zeros and a colon
    while (digits.length < 4) {
      digits = '0$digits';
    }

    String formattedText =
        '${digits.substring(0, 2)}:${digits.substring(2, 4)}';

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class HrsMinsSecsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 6) {
      digits = digits.substring(digits.length - 6);
    }

    while (digits.length < 6) {
      digits = '0$digits';
    }

    String formattedText =
        '${digits.substring(0, 2)}:${digits.substring(2, 4)}:${digits.substring(4, 6)}';

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    String themePreference = prefs.getString('themeMode') ?? 'system';
    setState(() {
      if (themePreference == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (themePreference == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
    });
  }

  Future<void> _saveThemePreference(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', themeMode);
  }

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
        _saveThemePreference('light');
      } else {
        _themeMode = ThemeMode.dark;
        _saveThemePreference('dark');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'proselytr',
      // Choose the theme based on the state
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: MyHomePage(
        title: 'proselytr',
        toggleTheme: _toggleTheme,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.toggleTheme});

  final String title;
  final VoidCallback toggleTheme;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _minsPerKmController = TextEditingController(text: '00:00');
  final _minsPerMiController = TextEditingController(text: '00:00');
  final _kjController = TextEditingController();
  final _calController = TextEditingController();
  final _kmController = TextEditingController();
  final _miController = TextEditingController();
  final _runTimeController = TextEditingController(text: '00:00:00');

  double _calories = 0;
  double _kilojoules = 0;
  double _paceInSecsPerKm = 0;
  double _paceInSecsPerMi = 0;
  double _distanceInKm = 0;
  double _distanceInMi = 0;
  double _runTimeInSecs = 0;

  @override
  void initState() {
    super.initState();
    _minsPerKmController.addListener(_updateState);
    _kmController.addListener(_updateState);
    _runTimeController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  void _convertEnergy(String input, bool isKjToCal) {
    setState(() {
      double value = double.tryParse(input) ?? 0;
      if (isKjToCal) {
        _kilojoules = value;
        _calories = _kilojoules * 0.239005736; // Convert kilojoules to calories
        _calController.text = _calories.toStringAsFixed(2);
      } else {
        _calories = value;
        _kilojoules = _calories / 0.239005736; // Convert calories to kilojoules
        _kjController.text = _kilojoules.toStringAsFixed(2);
      }
    });
  }

  void _convertPace(String input, bool isMinsPerKm) {
    double paceInSecs = _getPaceInSecs(input);

    if (isMinsPerKm) {
      _paceInSecsPerKm = paceInSecs;
      _paceInSecsPerMi = _paceInSecsPerKm * 1.60934;
      _minsPerMiController.text = _formatPace(_paceInSecsPerMi);
    } else {
      _paceInSecsPerMi = paceInSecs;
      _paceInSecsPerKm = _paceInSecsPerMi / 1.60934;
      _minsPerKmController.text = _formatPace(_paceInSecsPerKm);
    }

    _runTimeInSecs = _paceInSecsPerKm * _distanceInKm;
    _runTimeController.text = _formatRunTime(_runTimeInSecs);

    setState(() {});
  }

  double _getPaceInSecs(String pace) {
    var parts = pace.split(':');
    if (parts.length == 2) {
      int mins = int.tryParse(parts[0]) ?? 0;
      int secs = int.tryParse(parts[1]) ?? 0;
      return (mins * 60 + secs).toDouble();
    }
    return 0;
  }

  String _formatPace(double paceInSecs) {
    final int mins = (paceInSecs / 60).floor();
    final int secs = (paceInSecs % 60).round();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _convertDistance(String input, bool isKmToMiles) {
    if (input.isNotEmpty) {
      if (isKmToMiles) {
        _distanceInKm = double.tryParse(input) ?? 0;
        _distanceInMi = _distanceInKm * 0.621371;
        _miController.text = _distanceInMi.toStringAsFixed(4);
      } else {
        _distanceInMi = double.tryParse(input) ?? 0;
        _distanceInKm = _distanceInMi / 0.621371;
        _kmController.text = _distanceInKm.toStringAsFixed(4);
      }
    } else {
      _distanceInKm = 0;
      _distanceInMi = 0;
      _kmController.clear();
      _miController.clear();
    }

    _runTimeInSecs = _paceInSecsPerKm * _distanceInKm;
    _runTimeController.text = _formatRunTime(_runTimeInSecs);
  }

  void _calculatePaceByRunTimeDistance(String input) {
    double runTimeInSecs = _getRunTimeInSecs(input);

    _paceInSecsPerKm = runTimeInSecs / _distanceInKm;
    _paceInSecsPerMi = runTimeInSecs / _distanceInMi;
    _minsPerKmController.text = _formatPace(_paceInSecsPerKm);
    _minsPerMiController.text = _formatPace(_paceInSecsPerMi);
  }

  double _getRunTimeInSecs(String runTime) {
    var parts = runTime.split(':');
    if (parts.length == 3) {
      int hrs = int.tryParse(parts[0]) ?? 0;
      int mins = int.tryParse(parts[1]) ?? 0;
      int secs = int.tryParse(parts[2]) ?? 0;
      return (hrs * 3600 + mins * 60 + secs).toDouble();
    }
    return 0;
  }

  String _formatRunTime(double runTimeInSecs) {
    final int hrs = (runTimeInSecs / 3600).floor();
    final int mins = (runTimeInSecs % 3600 / 60).floor();
    final int secs = (runTimeInSecs % 60).round();

    return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.title),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.transparent
                : const Color.fromRGBO(255, 255, 255, 0),
            elevation: 0,
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.brightness_6),
                onPressed: widget.toggleTheme,
              )
            ]),
        body: SingleChildScrollView(
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
              Container(
                width: 200,
                margin: const EdgeInsets.only(top: 40, bottom: 20),
                child: Column(
                  children: <Widget>[
                    Text('Energy',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _kjController,
                      decoration: const InputDecoration(
                          labelText: 'Kilojoules',
                          border: OutlineInputBorder()),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                      ],
                      onChanged: (value) => _convertEnergy(value, true),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _calController,
                      decoration: const InputDecoration(
                          labelText: 'Calories', border: OutlineInputBorder()),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                      ],
                      onChanged: (value) => _convertEnergy(value, false),
                    ),
                  ],
                ),
              ),
              Divider(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white24
                    : Colors.black26,
                height: 20,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),
              Container(
                  width: 200,
                  margin: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Column(children: <Widget>[
                    Text('Pace',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _minsPerKmController,
                      decoration: const InputDecoration(
                          labelText: 'Min/km', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [MinsSecsInputFormatter()],
                      onChanged: (value) {
                        _convertPace(value, true);
                        setState(() {}); // This triggers a rebuild
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _minsPerMiController,
                      decoration: const InputDecoration(
                          labelText: 'Min/mi', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [MinsSecsInputFormatter()],
                      onChanged: (value) {
                        _convertPace(value, false);
                        setState(() {}); // This triggers a rebuild
                      },
                    )
                  ])),
              Container(
                  width: 200,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Column(children: <Widget>[
                    Text('Distance',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                        controller: _kmController,
                        decoration: const InputDecoration(
                            labelText: 'Kilometres',
                            border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'))
                        ],
                        onChanged: (value) {
                          _convertDistance(value, true);
                          setState(() {});
                        }),
                    const SizedBox(height: 20),
                    TextField(
                        controller: _miController,
                        decoration: const InputDecoration(
                            labelText: 'Miles', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'))
                        ],
                        onChanged: (value) {
                          _convertDistance(value, false);
                          setState(() {});
                        }),
                  ])),
              // if (runTime.isNotEmpty) ...[
              //   RichText(
              //       text: TextSpan(
              //           style: Theme.of(context).textTheme.bodyMedium,
              //           children: <TextSpan>[
              //         const TextSpan(text: 'Time to run at pace: '),
              //         TextSpan(
              //           text: runTime,
              //           style: const TextStyle(fontWeight: FontWeight.w600),
              //         )
              //       ]))
              // ],
              // const SizedBox(height: 200)
              Container(
                  width: 200,
                  margin: const EdgeInsets.only(bottom: 240),
                  child: Column(children: <Widget>[
                    Text('Time',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                        enabled: _distanceInKm > 0 || _distanceInMi > 0,
                        controller: _runTimeController,
                        decoration: const InputDecoration(
                            labelText: 'Time to run at pace',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        inputFormatters: [HrsMinsSecsInputFormatter()],
                        onChanged: (value) {
                          _calculatePaceByRunTimeDistance(value);
                          setState(() {});
                        }),
                  ]))
            ]))));
  }

  @override
  void dispose() {
    _minsPerKmController.dispose();
    _minsPerMiController.dispose();
    super.dispose();
  }
}
