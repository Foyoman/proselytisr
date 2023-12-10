import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class TimeInputFormatter extends TextInputFormatter {
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
  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _miController = TextEditingController();

  double _calories = 0;
  double _kilojoules = 0;
  double _paceInSecsPerKm = 0;
  double _paceInSecsPerMi = 0;
  double _distanceInKm = 0;
  double _distanceInMi = 0;

  @override
  void initState() {
    super.initState();
    _minsPerKmController.addListener(_updateRunTime);
    _kmController.addListener(_updateRunTime);
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
    double totalSeconds = _getPaceInSeconds(input);
    if (isMinsPerKm) {
      _paceInSecsPerKm = totalSeconds;
      _paceInSecsPerMi = _paceInSecsPerKm * 1.60934; // Convert min/km to min/mi
      _minsPerMiController.text = _formatPace(_paceInSecsPerMi);
    } else {
      _paceInSecsPerMi = totalSeconds;
      _paceInSecsPerKm = _paceInSecsPerMi / 1.60934; // Convert min/mi to min/km
      _minsPerKmController.text = _formatPace(_paceInSecsPerKm);
    }
    setState(() {}); // Trigger a rebuild
  }

  String _formatPace(double value) {
    final int minutes = (value / 60).floor();
    final int seconds = (value % 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _convertDistance(String input, bool isKmToMiles) {
    if (input.isNotEmpty) {
      if (isKmToMiles) {
        _distanceInKm = double.tryParse(input) ?? 0;
        _distanceInMi = _distanceInKm * 0.621371;
        _miController.text = _distanceInMi.toStringAsFixed(2);
      } else {
        _distanceInMi = double.tryParse(input) ?? 0;
        _distanceInKm = _distanceInMi / 0.621371;
        _kmController.text = _distanceInKm.toStringAsFixed(2);
      }
    } else {
      if (isKmToMiles) {
        _miController.clear();
      } else {
        _kmController.clear();
      }
    }
  }

  double _getPaceInSeconds(String pace) {
    var parts = pace.split(':');
    if (parts.length == 2) {
      int mins = int.tryParse(parts[0]) ?? 0;
      int secs = int.tryParse(parts[1]) ?? 0;
      return (mins * 60 + secs).toDouble();
    }
    return 0;
  }

  void _updateRunTime() {
    setState(() {
      // This will trigger a rebuild of the widget
    });
  }

  String get runTime {
    if (_minsPerKmController.text.isNotEmpty &&
        _minsPerKmController.text != '00:00' &&
        _kmController.text.isNotEmpty &&
        _kmController.text != '0') {
      double totalTimeInSecs = _paceInSecsPerKm * _distanceInKm;

      int hrs = (totalTimeInSecs / 3600).floor();
      int mins = ((totalTimeInSecs % 3600) / 60).floor();
      int secs = totalTimeInSecs.round() % 60;

      return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
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
                margin: const EdgeInsets.only(top: 40, bottom: 40),
                child: Column(
                  children: <Widget>[
                    Text('Energy',
                        style: Theme.of(context).textTheme.titleMedium),
                    TextField(
                      controller: _kjController,
                      decoration:
                          const InputDecoration(labelText: 'Kilojoules'),
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
                      decoration: const InputDecoration(labelText: 'Calories'),
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
              Container(
                  width: 200,
                  margin: const EdgeInsets.only(bottom: 40),
                  child: Column(children: <Widget>[
                    Text('Pace',
                        style: Theme.of(context).textTheme.titleMedium),
                    TextField(
                      controller: _minsPerKmController,
                      decoration: const InputDecoration(labelText: 'Min/km'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [TimeInputFormatter()],
                      onChanged: (value) {
                        _convertPace(value, true);
                        setState(() {}); // This triggers a rebuild
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _minsPerMiController,
                      decoration: const InputDecoration(labelText: 'Min/mi'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [TimeInputFormatter()],
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
                    TextField(
                        controller: _kmController,
                        decoration:
                            const InputDecoration(labelText: 'Kilometres'),
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
                        decoration: const InputDecoration(labelText: 'Miles'),
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
              if (runTime.isNotEmpty) ...[
                RichText(
                    text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: <TextSpan>[
                      const TextSpan(text: 'Time to run at pace: '),
                      TextSpan(
                        text: runTime,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      )
                    ]))
              ],
              const SizedBox(height: 400)
            ]))));
  }

  @override
  void dispose() {
    _minsPerKmController.dispose();
    _minsPerMiController.dispose();
    super.dispose();
  }
}
