import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chugli_project65/features/reports/new_report_details_screen.dart';

class NewReportIssueScreen extends StatefulWidget {
  final Map<String, dynamic>? room;
  const NewReportIssueScreen({super.key, this.room});

  @override
  State<NewReportIssueScreen> createState() => _NewReportIssueScreenState();
}

class _NewReportIssueScreenState extends State<NewReportIssueScreen> {
  String? _selectedIssue;

  final List<String> _issueTypes = [
    'Spam Content',
    'Abuse / Harassment',
    'Hate Speech',
    'Misinformation',
    'Fake Room',
    'App Bug',
    'Other'
  ];

  void _onNext() {
    if (_selectedIssue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an issue type to continue.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewReportDetailsScreen(
          issueType: _selectedIssue!,
          room: widget.room,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Report',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 20),
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
                'Step 1 of 3',
                style: TextStyle(color: Color(0xFF6C47FF), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              if (widget.room != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Reporting Room: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                          Expanded(child: Text('${widget.room!['title']}', style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Category: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                          Text('${widget.room!['category']}', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 8),
              Text(
                'What is the issue?',
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 24),
              ),
              SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _issueTypes.length,
                  itemBuilder: (context, index) {
                    final issue = _issueTypes[index];
                    final isSelected = _selectedIssue == issue;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedIssue = issue);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF6C47FF) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF6C47FF).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                          border: Border.all(
                            color: isSelected ? Colors.transparent : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              issue,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: Colors.white)
                            else
                              Icon(Icons.circle_outlined, color: Colors.grey)
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C47FF),
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFF6C47FF).withValues(alpha: 0.5),
                  ),
                  child: Text(
                    'Next',
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
