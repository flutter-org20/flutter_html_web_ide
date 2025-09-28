import 'package:http/http.dart' as http;
import '../models/api_response.dart';

class PollinationsServices {
  static const String baseUrl = 'https://text.pollinations.ai';

  /// Test connection to the Pollinations API
  static Future<bool> testConnection() async {
    try {
      print('Testing connection to: $baseUrl');

      // Use a simple test prompt instead of hitting the base URL
      final response = await _generateTextRaw('test');

      print('Connection test response: ${response.success}');

      if (response.success) {
        print(
          'Connection test successful! Response: ${response.text.substring(0, response.text.length > 50 ? 50 : response.text.length)}...',
        );
        return true;
      } else {
        print('Connection test failed: ${response.error}');
        return false;
      }
    } catch (e) {
      print('Connection test failed with error: $e');
      return false;
    }
  }

  /// Generate text with raw prompt (internal method)
  static Future<PollinationsResponse> _generateTextRaw(String prompt) async {
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
        final responseText = response.body.trim();
        if (responseText.isNotEmpty) {
          return PollinationsResponse(text: responseText);
        } else {
          return PollinationsResponse.error('Empty response from API');
        }
      } else {
        final errorMsg =
            'API Error: ${response.statusCode} - ${response.reasonPhrase}';
        return PollinationsResponse.error(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Network Error: ${e.toString()}';
      return PollinationsResponse.error(errorMsg);
    }
  }

  static Future<PollinationsResponse> generateText(String prompt) async {
    if (prompt.trim().isEmpty) {
      return PollinationsResponse.error('Prompt cannot be empty');
    }
    try {
      // Use _createPromptVariations to get a well-formatted prompt
      final variations = _createPromptVariations(prompt, 1);
      final formattedPrompt = variations.first;

      final encodedPrompt = Uri.encodeComponent(formattedPrompt);
      final url = Uri.parse('$baseUrl/$encodedPrompt');

      print('Making request to: $url');

      final response = await http
          .get(
            url,
            headers: {'Accept': 'text/plain', 'User-Agent': 'Flutter-Web-App'},
          )
          .timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Response headers: ${response.headers}');
      }

      if (response.statusCode == 200) {
        // Pollinations API returns plain text, not JSON
        final responseText = response.body.trim();
        print('Response text length: ${responseText.length}');
        if (responseText.isNotEmpty) {
          return PollinationsResponse(text: responseText);
        } else {
          return PollinationsResponse.error('Empty response from API');
        }
      } else {
        final errorMsg =
            'API Error: ${response.statusCode} - ${response.reasonPhrase}';
        print(errorMsg);
        return PollinationsResponse.error(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Network Error: ${e.toString()}';
      print('Generate text error: $errorMsg');
      return PollinationsResponse.error(errorMsg);
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
      futures.add(_generateTextRaw(variationPrompt));

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
      'Using $basePrompt, generate a single, simple HTML webpage with embedded CSS and JS in <style> tags. Keep it under 50 lines. Return **only one HTML block**, with proper indentation and line breaks. Do not include explanations, options, comments, markdown, or any text before or after the code. Do not include multiple versions. Output only valid HTML code.',
    );

    if (count > 1) {
      // Add variations with different approaches
      variations.add(
        'Create a single, interactive webpage for $basePrompt using HTML, CSS, and JavaScript. Keep it simple, under 80 lines total, with inline CSS and JS. Return only raw HTML code with embedded <style> and <script> tags, with proper indentation and line breaks. Do not include explanations, comments, multiple versions, markdown, or any text before or after the code. Output only valid HTML.',
      );
    }

    if (count > 2) {
      // Add variation asking for alternative implementation
      variations.add(
        'Build a single, modern webpage for $basePrompt using HTML5, CSS3, and vanilla JavaScript. Keep it responsive and under 100 lines total, with inline CSS in <style> and JS in <script> tags. Return only raw HTML code with proper indentation and line breaks. Do not include explanations, comments, multiple versions, markdown, or any text before or after the code. Do not use external libraries. Output only valid HTML.',
      );
    }

    if (count > 3) {
      // Add variation asking for optimized version
      variations.add(
        'Create a single, beginner-friendly webpage demonstrating $basePrompt using semantic HTML, basic CSS flexbox or grid, and simple JavaScript. Keep it under 80 lines total, with inline <style> and <script> tags. Return only raw, valid HTML code with proper indentation and line breaks. Do not include explanations, comments, multiple versions, markdown, or any text before or after the code. Output only working HTML.',
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
