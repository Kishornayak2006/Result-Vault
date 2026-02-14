import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class YearSelectionScreen extends StatefulWidget {
  const YearSelectionScreen({super.key});

  @override
  State<YearSelectionScreen> createState() => _YearSelectionScreenState();
}

class _YearSelectionScreenState extends State<YearSelectionScreen> {
  int selectedYears = 4;

  Future<void> _saveYearsAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('course_years', selectedYears);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            const Text(
              'How many years is your course?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            DropdownButtonFormField<int>(
              value: selectedYears,
              decoration: const InputDecoration(
                labelText: 'Course duration',
                border: OutlineInputBorder(),
              ),
              items: [3, 4, 5, 6].map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text('$year Years'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedYears = value!);
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveYearsAndContinue,
                child: const Text('Continue'),
              ),
            ),

            const SizedBox(height: 24),

            // 👇 FOOTER TEXT
            const Center(
              child: Text(
                'Developed by Kishu',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
