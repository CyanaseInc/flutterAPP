import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class LinkPreviewService {
  static Future<Map<String, String>?> getLinkPreview(String url) async {
    try {
      if (!url.startsWith('http')) {
        url = 'https://$url';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final document = html_parser.parse(response.body);
      final metaTags = document.getElementsByTagName('meta');

      String? title, description, image;

      for (var meta in metaTags) {
        final property = meta.attributes['property'];
        final content = meta.attributes['content'];
        if (property == null || content == null) continue;

        if (property == 'og:title') {
          title = content;
        } else if (property == 'og:description') {
          description = content;
        } else if (property == 'og:image') {
          image = content;
        }
      }

      title ??= document.querySelector('title')?.text;
      description ??= document.querySelector('meta[name="description"]')?.attributes['content'];

      return {
        'title': title ?? url,
        'description': description ?? 'No description available',
        'image': image ?? '',
        'url': url,
      };
    } catch (e) {
      print('Error fetching link preview: $e');
      return null;
    }
  }
}