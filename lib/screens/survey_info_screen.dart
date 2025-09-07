import 'package:flutter/material.dart';

class SurveyInfoScreen extends StatefulWidget {
  const SurveyInfoScreen({super.key});

  @override
  State<SurveyInfoScreen> createState() => _SurveyInfoScreenState();
}

class _SurveyInfoScreenState extends State<SurveyInfoScreen> {
  final _searchController = TextEditingController();
  String? selectedSurvey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('सर्वे जानकारी / Survey Info'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'सर्वे नंबर खोजें',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Search Survey Number',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'सर्वे नंबर दर्ज करें / Enter Survey Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      selectedSurvey = null;
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  selectedSurvey = value.isNotEmpty ? value : null;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedSurvey != null ? () {
                Navigator.pushNamed(context, '/mangalvedhe_map');
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'खोजें / Search',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 30),
            if (selectedSurvey != null) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'सर्वे नंबर: $selectedSurvey',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'गांव: मंगलवेढे',
                        style: TextStyle(fontSize: 16),
                      ),
                      const Text(
                        'Village: Mangalvedhe',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'तहसील: मंगलवेढे',
                        style: TextStyle(fontSize: 16),
                      ),
                      const Text(
                        'Tehsil: Mangalvedhe',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'जिला: सोलापुर',
                        style: TextStyle(fontSize: 16),
                      ),
                      const Text(
                        'District: Solapur',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/mangalvedhe_map');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B4513),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('मानचित्र में देखें / View on Map'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
