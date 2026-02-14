import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseSetupScreen extends StatefulWidget {
  const CourseSetupScreen({super.key});

  @override
  State<CourseSetupScreen> createState() => _CourseSetupScreenState();
}

class _CourseSetupScreenState extends State<CourseSetupScreen> {
  int selectedYears = 4;

  Future<void> _saveAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('course_years', selectedYears);
    await prefs.setBool('is_setup_done', true);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Setup')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How many years is your course?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            DropdownButton<int>(
              value: selectedYears,
              isExpanded: true,
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
                onPressed: _saveAndContinue,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
