// FastImagePreview.dart
import 'package:flutter/material.dart';

class FastImagePreview extends StatelessWidget {
  final String url;

  const FastImagePreview({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      // यदि URL खाली है तो एक डमी लोडिंग कंटेनर दिखाएँ
      return Container(
        width: 95,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.white70),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        width: 95,
        height: 120,
        fit: BoxFit.cover,
        // लोडिंग को तेज़ करने के लिए कैशिंग का उपयोग करता है
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          
          // जब तक इमेज लोड न हो जाए तब तक एक हल्का कंटेनर दिखाएँ
          return Container(
            width: 95,
            height: 120,
            color: Colors.black26,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // यदि कोई त्रुटि हो तो
          return Container(
            width: 95,
            height: 120,
            color: Colors.red.shade900,
            child: const Center(child: Icon(Icons.broken_image, color: Colors.white)),
          );
        },
      ),
    );
  }
}