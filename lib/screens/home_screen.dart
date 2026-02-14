import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'semester_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int totalYears = 4;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  // ================= LOAD YEARS =================
  Future<void> _loadYears() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalYears = prefs.getInt('course_years') ?? 4;
      isLoading = false;
    });
  }

  // ================= CHANGE YEARS (TOP-RIGHT) =================
  Future<void> _changeYearsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    int tempYears = totalYears;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Change Course Duration',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: DropdownButton<int>(
          value: tempYears,
          isExpanded: true,
          items: [3, 4, 5, 6].map((year) {
            return DropdownMenuItem(
              value: year,
              child: Text('$year Years'),
            );
          }).toList(),
          onChanged: (value) {
            tempYears = value!;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await prefs.setInt('course_years', tempYears);
              setState(() => totalYears = tempYears);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar),
            tooltip: 'Change course years',
            onPressed: _changeYearsDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: totalYears,
              itemBuilder: (context, index) {
                final yearNumber = index + 1;
                final sem1 = (yearNumber - 1) * 2 + 1;
                final sem2 = sem1 + 1;

                return YearCard(
                  year: yearNumber,
                  semesters: [sem1, sem2],
                );
              },
            ),
    );
  }
}

// ================= YEAR CARD =================
class YearCard extends StatefulWidget {
  final int year;
  final List<int> semesters;

  const YearCard({
    super.key,
    required this.year,
    required this.semesters,
  });

  @override
  State<YearCard> createState() => _YearCardState();
}

class _YearCardState extends State<YearCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          ListTile(
            title: Text(
              'Year ${widget.year}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () {
              setState(() => expanded = !expanded);
            },
          ),
          if (expanded)
            Column(
              children: widget.semesters.map((sem) {
                return SemesterCard(semester: sem);
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ================= SEMESTER CARD =================
class SemesterCard extends StatelessWidget {
  final int semester;

  const SemesterCard({
    super.key,
    required this.semester,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.school),
        title: Text('Semester $semester'),
        subtitle: const Text('Result • Backlogs • Achievements'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SemesterDetailsScreen(semester: semester),
            ),
          );
        },
      ),
    );
  }
}
