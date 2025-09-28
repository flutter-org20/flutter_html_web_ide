import 'dart:html' as html;
import 'dart:convert';
import '../models/prompt_history.dart';

class PromptHistoryService {
  static const String _storageKey = 'web_ide_prompt_history';
  static const int _maxHistoryItems = 100;

  /// Save a prompt to history with generated responses
  static Future<void> savePrompt({
    required String prompt,
    required List<String> responses,
  }) async {
    try {
      final history = await getHistory();
      final newItem = PromptHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        prompt: prompt,
        timestamp: DateTime.now(),
        responses: responses,
      );

      // Remove duplicate prompts (same prompt text)
      history.removeWhere(
        (item) =>
            item.prompt.trim().toLowerCase() == prompt.trim().toLowerCase(),
      );

      // Add new item to the beginning
      history.insert(0, newItem);

      // Keep only the most recent items
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      await _saveToStorage(history);
    } catch (e) {
      print('Error saving prompt to history: $e');
    }
  }

  /// Get all prompts from history, sorted by most recent first
  static Future<List<PromptHistoryItem>> getHistory() async {
    try {
      final storage = html.window.localStorage;
      final historyJson = storage[_storageKey];

      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }

      final List<dynamic> historyList = jsonDecode(historyJson);
      return historyList
          .map((item) => PromptHistoryItem.fromJson(item))
          .toList();
    } catch (e) {
      print('Error loading prompt history: $e');
      return [];
    }
  }

  /// Delete a specific prompt from history by ID
  static Future<bool> deletePrompt(String id) async {
    try {
      final history = await getHistory();
      final initialLength = history.length;

      history.removeWhere((item) => item.id == id);

      if (history.length != initialLength) {
        await _saveToStorage(history);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting prompt from history: $e');
      return false;
    }
  }

  /// Clear all history
  static Future<void> clearHistory() async {
    try {
      html.window.localStorage.remove(_storageKey);
    } catch (e) {
      print('Error clearing prompt history: $e');
    }
  }

  /// Search history by prompt text
  static Future<List<PromptHistoryItem>> searchHistory(String query) async {
    try {
      final history = await getHistory();
      if (query.trim().isEmpty) return history;

      final lowerQuery = query.toLowerCase();
      return history
          .where((item) => item.prompt.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      print('Error searching prompt history: $e');
      return [];
    }
  }

  /// Get history statistics
  static Future<Map<String, int>> getHistoryStats() async {
    try {
      final history = await getHistory();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastWeek = today.subtract(const Duration(days: 7));
      final lastMonth = today.subtract(const Duration(days: 30));

      return {
        'total': history.length,
        'today': history.where((item) => item.timestamp.isAfter(today)).length,
        'lastWeek':
            history.where((item) => item.timestamp.isAfter(lastWeek)).length,
        'lastMonth':
            history.where((item) => item.timestamp.isAfter(lastMonth)).length,
      };
    } catch (e) {
      print('Error getting history stats: $e');
      return {'total': 0, 'today': 0, 'lastWeek': 0, 'lastMonth': 0};
    }
  }

  /// Private method to save history to localStorage
  static Future<void> _saveToStorage(List<PromptHistoryItem> history) async {
    try {
      final storage = html.window.localStorage;
      final historyJson = jsonEncode(
        history.map((item) => item.toJson()).toList(),
      );
      storage[_storageKey] = historyJson;
    } catch (e) {
      print('Error saving to localStorage: $e');
      rethrow;
    }
  }
}
