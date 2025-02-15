import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureCardList extends StatelessWidget {
  const FeatureCardList({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> features = const [
    {
      "icon": Icons.edit,
      "iconColor": Colors.red,
      "title": "Edit PDF",
      "description": "Edit texts, images, and pages in PDF files."
    },
    {
      "icon": Icons.translate,
      "iconColor": Colors.purple,
      "title": "AI Parallel Translate",
      "description":
          "Experience bilingual reading side-by-side with Parallel Translate now!"
    },
    {
      "icon": Icons.picture_as_pdf,
      "iconColor": Colors.purple,
      "title": "PDF Conversion",
      "description":
          "Try faster PDF conversion with enhanced layout, content, and editing."
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: features
                .map((feature) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: FeatureCard(
                        icon: feature["icon"],
                        iconColor: feature["iconColor"],
                        title: feature["title"],
                        description: feature["description"],
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
