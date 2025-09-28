import 'package:http/http.dart' as http;
import '../models/api_response.dart';

class PollinationsServices {
  static const String baseUrl = 'https://text.pollinations.ai';

  static Future<PollinationsResponse> generateText(String prompt) async {
    if (prompt.trim().isEmpty) {
      return PollinationsResponse.error('Prompt cannot be empty');
    }
    try {
      final encodedPrompt = Uri.encodeComponent(prompt);
      final url = Uri.parse('$baseUrl/$encodedPrompt');

      final response = await http
          .get(
            url,
            headers: {'Accept': 'text/plain', 'User-Agent': 'Flutter-Web-App'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Pollinations API returns plain text, not JSON
        final responseText = response.body.trim();
        if (responseText.isNotEmpty) {
          return PollinationsResponse(text: responseText);
        } else {
          return PollinationsResponse.error('Empty response from API');
        }
      } else {
        return PollinationsResponse.error(
          'API Error: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return PollinationsResponse.error('Network Error: ${e.toString()}');
    }
  }

  /// Generate multiple different code samples for the same prompt
  /// Each sample will have slight variations to ensure diversity
  static Future<List<PollinationsResponse>> generateMultipleSamples({
    required String prompt,
    int count = 4,
  }) async {
    if (prompt.trim().isEmpty) {
      return [PollinationsResponse.error('Prompt cannot be empty')];
    }

    final List<Future<PollinationsResponse>> futures = [];
    final variations = _createPromptVariations(prompt, count);

    for (int i = 0; i < count; i++) {
      final variationPrompt = variations[i];
      futures.add(generateText(variationPrompt));

      // Add small delay between requests to avoid overwhelming the API
      if (i < count - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    try {
      final results = await Future.wait(futures);
      return results;
    } catch (e) {
      // If batch request fails, return error responses
      return List.generate(
        count,
        (_) =>
            PollinationsResponse.error('Batch request failed: ${e.toString()}'),
      );
    }
  }

  /// Create variations of the same prompt to get diverse responses
  static List<String> _createPromptVariations(String basePrompt, int count) {
    final variations = <String>[];

    // Add the original prompt
    variations.add(
      'Using $basePrompt, create a simple HTML webpage with CSS styling. Keep it clean, under 50 lines total, and return only raw HTML code with embedded CSS in <style> tags. Do not use markdown/backticks or external dependencies.',
    );

    if (count > 1) {
      // Add variations with different approaches
      variations.add(
        'Create an interactive webpage for $basePrompt using HTML, CSS, and JavaScript. Keep it simple, under 80 lines total, with inline CSS and JS. Return only raw HTML code with embedded styles and scripts. No markdown or comments.',
      );
    }

    if (count > 2) {
      // Add variation asking for alternative implementation
      variations.add(
        'Build a modern webpage for $basePrompt using HTML5, CSS3, and vanilla JavaScript. Keep it responsive and under 100 lines total. Return only raw HTML with embedded CSS and JS. No markdown or external libraries.',
      );
    }

    if (count > 3) {
      // Add variation asking for optimized version
      variations.add(
        'Create a beginner-friendly webpage demonstrating $basePrompt. Use semantic HTML, basic CSS flexbox/grid, and simple JavaScript. Keep under 80 lines total. Output only plain HTML code with embedded styles and scripts.',
      );
    }

    if (count > 4) {
      // Add variations with more specific requests
      final additionalVariations = [
        'Design a single-page application for $basePrompt using HTML, CSS animations, and interactive JavaScript. Keep it visually appealing, under 120 lines total, with no external dependencies.',
        '$basePrompt. Make it mobile-responsive with CSS media queries.',
        '$basePrompt. Add hover effects and smooth transitions.',
        '$basePrompt. Use CSS Grid or Flexbox for layout.',
        '$basePrompt. Include form validation with JavaScript.',
      ];

      for (int i = 4; i < count && i - 4 < additionalVariations.length; i++) {
        variations.add(additionalVariations[i - 4]);
      }
    }

    // Fill remaining slots with the original prompt if needed
    while (variations.length < count) {
      variations.add(
        '$basePrompt. Version ${variations.length + 1} - Create with HTML/CSS/JS.',
      );
    }

    return variations.take(count).toList();
  }
}
