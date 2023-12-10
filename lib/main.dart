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

  @override
  void initState() {
    super.initState();
    _minsPerKmController.addListener(_updateRunTime);
    _kmController.addListener(_updateRunTime);
  }

  void _convertEnergy(String input, bool isKjToCal) {
    if (input.isNotEmpty) {
      double value = double.tryParse(input) ?? 0;
      if (isKjToCal) {
        // Convert kilojoules to calories (1 kJ = 0.239005736 calories)
        _calController.text = (value * 0.239005736).toStringAsFixed(2);
      } else {
        // Convert calories to kilojoules (1 calorie = 4.184 kilojoules)
        _kjController.text = (value * 4.184).toStringAsFixed(2);
      }
    } else {
      if (isKjToCal) {
        _calController.clear();
      } else {
        _kjController.clear();
      }
    }
  }

  void _convertPace(String input, bool isMinsPerKm) {
    if (input.isNotEmpty) {
      final parts = input.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]);
        final seconds = int.tryParse(parts[1]);
        if (minutes != null && seconds != null) {
          final totalMinutes = minutes + (seconds / 60);
          if (isMinsPerKm) {
            // Convert min/km to min/mi
            final convertedValue = totalMinutes * 1.60934;
            _minsPerMiController.text = _formatPace(convertedValue);
          } else {
            // Convert min/mile to min/km
            final convertedValue = totalMinutes / 1.60934;
            _minsPerKmController.text = _formatPace(convertedValue);
          }
        }
      }
    } else {
      if (isMinsPerKm) {
        _minsPerMiController.clear();
      } else {
        _minsPerKmController.clear();
      }
    }
  }

  String _formatPace(double value) {
    final int minutes = value.floor();
    final int seconds = ((value - minutes) * 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _convertDistance(String input, bool isKmToMiles) {
    if (input.isNotEmpty) {
      double value = double.tryParse(input) ?? 0;
      if (isKmToMiles) {
        _miController.text = (value * 0.621371).toStringAsFixed(2);
      } else {
        _kmController.text = (value * 1.60934).toStringAsFixed(2);
      }
    } else {
      if (isKmToMiles) {
        _miController.clear();
      } else {
        _kmController.clear();
      }
    }
  }

  String _calculateRunTime() {
    String formattedTime = '';
    try {
      double paceInMinsPerKm = _getPaceInMinutes(_minsPerKmController.text);
      double distanceInKm = double.tryParse(_kmController.text) ?? 0;

      double totalTimeInMins = paceInMinsPerKm * distanceInKm;

      int hrs = totalTimeInMins ~/ 60;
      int mins = (totalTimeInMins % 60).floor();
      int secs = ((totalTimeInMins - totalTimeInMins.toInt()) * 60).toInt();

      formattedTime =
          '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } catch (e) {
      // Handle parsing error or leave formattedTime as empty
    }

    return formattedTime;
  }

  double _getPaceInMinutes(String pace) {
    var parts = pace.split(':');
    if (parts.length == 2) {
      int mins = int.tryParse(parts[0]) ?? 0;
      int secs = int.tryParse(parts[1]) ?? 0;
      return mins + (secs / 60);
    }
    return 0;
  }

  void _updateRunTime() {
    setState(() {
      // This will trigger a rebuild of the widget
    });
  }

  String get runTime {
    if (_minsPerKmController.text.isEmpty ||
        _minsPerKmController.text == '00:00' ||
        _kmController.text.isEmpty) {
      return '';
    }
    return _calculateRunTime();
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
                      onChanged: (value) => _convertPace(value, true),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _minsPerMiController,
                      decoration: const InputDecoration(labelText: 'Min/mi'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [TimeInputFormatter()],
                      onChanged: (value) => _convertPace(value, false),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                      ],
                      onChanged: (value) => _convertDistance(value, true),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _miController,
                      decoration: const InputDecoration(labelText: 'Miles'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                      ],
                      onChanged: (value) => _convertDistance(value, false),
                    ),
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
