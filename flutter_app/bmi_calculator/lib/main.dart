import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BMICalculator(),
    );
  }
}

class BMICalculator extends StatefulWidget {
  @override
  _BMICalculatorState createState() => _BMICalculatorState();
}

class _BMICalculatorState extends State<BMICalculator> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _result;

  Future<void> _calculateBMI() async {
    final name = _nameController.text;
    final age = int.tryParse(_ageController.text);
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (name.isEmpty || age == null || height == null || weight == null) {
      setState(() {
        _result = "Please fill all fields correctly.";
      });
      return;
    }

    final response = await http.post(
      Uri.parse("http://10.0.2.2:5000/calculate"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "age": age,
        "height": height,
        "weight": weight,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _result = "BMI: ${data['bmi']}. ${data['message']}";
      });
    } else {
      setState(() {
        _result = "Error: ${response.body}";
      });
    }
  }

  Future<void> _showRecords() async {
    final response = await http.get(Uri.parse("http://10.0.2.2:5000/records"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("BMI Records"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (_, index) {
                final record = data[index];
                return ListTile(
                  title: Text("${record['name']} (Age: ${record['age']})"),
                  subtitle: Text(
                      "Height: ${record['height']}m, Weight: ${record['weight']}kg, BMI: ${record['bmi']}"),
                );
              },
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BMI Calculator"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(labelText: "Age"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _heightController,
              decoration: InputDecoration(labelText: "Height (m)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _weightController,
              decoration: InputDecoration(labelText: "Weight (kg)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculateBMI,
              child: const Text("Calculate BMI"),
            ),
            ElevatedButton(
              onPressed: _showRecords,
              child: const Text("Show Records"),
            ),
            const SizedBox(height: 16),
            if (_result != null) Text(_result!),
          ],
        ),
      ),
    );
  }
}
