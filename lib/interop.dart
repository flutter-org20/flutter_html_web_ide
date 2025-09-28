// Use the modern, built-in JS interop library
import 'dart:js_interop';

// --- Callback Type Definitions for your Dart code ---
typedef ContentChangedCallback = void Function(String content);
typedef WebOutputCallback = void Function(String message);

// --- Monaco Interop Bindings ---

@JS('monacoInterop.init')
external JSPromise _initMonaco(
  String containerId,
  String initialCode,
  String theme,
  double fontSize,
  JSFunction onContentChanged, [
  String language = 'html',
]);

// Public wrapper that handles the Dart-to-JS function conversion for you
Future<void> initMonaco(
  String containerId,
  String initialCode,
  String theme,
  double fontSize,
  ContentChangedCallback onContentChanged, [
  String language = 'html',
]) async {
  try {
    // Add a check to ensure monacoInterop is available
    if (!_isMonacoInteropAvailable()) {
      throw Exception(
        'monacoInterop is not available. Make sure interop.js is loaded.',
      );
    }

    await _initMonaco(
      containerId,
      initialCode,
      theme,
      fontSize,
      onContentChanged.toJS,
      language,
    ).toDart;
  } catch (e) {
    print('Error initializing Monaco Editor: $e');
    rethrow;
  }
}

@JS('monacoInterop')
external JSObject? _monacoInteropObject;

bool _isMonacoInteropAvailable() {
  return _monacoInteropObject != null;
}

@JS('monacoInterop.getValue')
external JSString _getMonacoValue(String containerId);
String getMonacoValue(String containerId) =>
    _getMonacoValue(containerId).toDart;

@JS('monacoInterop.setValue')
external void setMonacoValue(String containerId, String content);

@JS('monacoInterop.updateOptions')
external void updateMonacoOptions(
  String containerId,
  String theme,
  double fontSize,
);

@JS('monacoInterop.formatDocument')
external void formatMonacoDocument(String containerId);

@JS('monacoInterop.selectAll')
external void selectAllInMonaco(String containerId);

@JS('monacoInterop.insertText')
external void insertMonacoText(String containerId, String text);

@JS('monacoInterop.copySelection')
external void copyMonacoSelection(String containerId);

// --- Pyodide Interop Bindings ---

@JS('pyodideInterop.init')
external JSPromise _initPyodide(JSFunction onOutput);

// Public wrapper that handles the Promise and function conversion
Future<String> initPyodide(WebOutputCallback onOutput) {
  return _initPyodide(
    onOutput.toJS,
  ).toDart.then((value) => (value as JSString).toDart);
}

@JS('pyodideInterop.runCode')
external JSPromise _runPyodideCode(String code);

// Public wrapper that handles the Promise and converts nullable results
Future<String?> runPyodideCode(String code) {
  return _runPyodideCode(code).toDart.then((value) {
    return (value as JSString?)?.toDart;
  });
}

@JS('monacoInterop.setLanguage')
external void _setMonacoLanguage(String containerId, String language);

void setMonacoLanguage(String containerId, String language) {
  _setMonacoLanguage(containerId, language);
}

@JS('destroyMonacoEditor')
external void _destroyMonacoEditor(String elementId);

Future<void> destroyEditor(String elementId) async {
  try {
    _destroyMonacoEditor(elementId);
  } catch (e) {
    print('Failed to destroy editor $elementId: $e');
  }
}

@JS('insertTextAtCursor')
external void _insertTextAtCursor(String editorId, String text);

@JS('deleteCharacterBeforeCursor')
external void _deleteCharacterBeforeCursor(String editorId);

Future<void> insertTextAtCursor(String editorId, String text) async {
  try {
    _insertTextAtCursor(editorId, text);
  } catch (e) {
    print('Failed to insert text in editor $editorId: $e');
  }
}

Future<void> deleteCharacterBeforeCursor(String editorId) async {
  try {
    _deleteCharacterBeforeCursor(editorId);
  } catch (e) {
    print('Failed to delete character in editor $editorId: $e');
  }
}

// Alias for setMonacoValue to match the undo/redo functionality
Future<void> setEditorContent(String editorId, String content) async {
  try {
    setMonacoValue(editorId, content);
  } catch (e) {
    print('Failed to set editor content for $editorId: $e');
  }
}

@JS('moveCursor')
external void _moveCursor(String editorId, String direction);

Future<void> moveCursor(String editorId, String direction) async {
  try {
    _moveCursor(editorId, direction);
  } catch (e) {
    print('Failed to move cursor in editor $editorId: $e');
  }
}

// Prettify code function (using existing formatDocument)
Future<void> prettifyCode(String editorId) async {
  try {
    formatMonacoDocument(editorId);
  } catch (e) {
    print('Failed to prettify code in editor $editorId: $e');
  }
}

// Autocomplete functions - these will be implemented in JS
@JS('monacoInterop.setAutocomplete')
external void _setAutocomplete(String editorId, bool enabled);

@JS('monacoInterop.triggerAutocomplete')
external void _triggerAutocomplete(String editorId);

Future<void> setAutocomplete(String editorId, bool enabled) async {
  try {
    _setAutocomplete(editorId, enabled);
  } catch (e) {
    print('Failed to set autocomplete in editor $editorId: $e');
  }
}

Future<void> triggerAutocomplete(String editorId) async {
  try {
    _triggerAutocomplete(editorId);
  } catch (e) {
    print('Failed to trigger autocomplete in editor $editorId: $e');
  }
}
