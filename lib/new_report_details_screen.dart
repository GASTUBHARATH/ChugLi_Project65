import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'report_data_service.dart';
import 'report_submitted_screen.dart';

class NewReportDetailsScreen extends StatefulWidget {
  final String issueType;
  final Map<String, dynamic>? room;

  const NewReportDetailsScreen({super.key, required this.issueType, this.room});

  @override
  State<NewReportDetailsScreen> createState() => _NewReportDetailsScreenState();
}

class _NewReportDetailsScreenState extends State<NewReportDetailsScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _simulatedScreenshots = [];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _addSimulatedScreenshot() {
    if (_simulatedScreenshots.length < 3) {
      setState(() {
        _simulatedScreenshots.add('dummy_path_${Random().nextInt(1000)}.jpg');
      });
      HapticFeedback.lightImpact();
    }
  }

  void _removeScreenshot(int index) {
    setState(() {
      _simulatedScreenshots.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  void _submitReport() {
    final report = {
      'reportId': 'rpt_${DateTime.now().millisecondsSinceEpoch}',
      'issueType': widget.issueType,
      'description': _descriptionController.text.trim(),
      'screenshots': List<String>.from(_simulatedScreenshots),
      'status': 'Pending',
      'submittedAt': DateTime.now(),
      'submittedBy': 'Anonymous User',
      'roomId': widget.room?['id'],
      'roomTitle': widget.room?['title'],
      'category': widget.room?['category'],
      'rejectionReason': null,
    };

    ReportDataService.instance.addReport(report);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ReportSubmittedScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Report',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step 2 of 3',
                style: TextStyle(color: Color(0xFF6C47FF), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'Additional Details',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 24),
              ),
              SizedBox(height: 24),
              
              Text(
                'Describe what happened',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLength: 500,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Please provide as much context as possible...',
                  hintStyle: TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: Colors.white,
                  counterStyle: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
              SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Optional Screenshots',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  Text(
                    '${_simulatedScreenshots.length}/3',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  if (_simulatedScreenshots.length < 3)
                    GestureDetector(
                      onTap: _addSimulatedScreenshot,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C47FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF6C47FF).withOpacity(0.3), width: 2, style: BorderStyle.solid),
                        ),
                        child: Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF6C47FF), size: 32),
                      ),
                    ),
                  SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _simulatedScreenshots.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                margin: EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(16),
                                  image: const DecorationImage(
                                    image: NetworkImage('https://via.placeholder.com/150'), // Dummy placeholder
                                    fit: BoxFit.cover,
                                  )
                                ),
                              ),
                              Positioned(
                                top: -8,
                                right: 4,
                                child: IconButton(
                                  icon: Icon(Icons.cancel_rounded, color: Colors.redAccent),
                                  onPressed: () => _removeScreenshot(index),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C47FF),
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFF6C47FF).withOpacity(0.5),
                  ),
                  child: Text(
                    'Submit Report',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
