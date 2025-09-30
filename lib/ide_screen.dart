import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html_web_ide/widgets/keyboard_toolbar.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'interop.dart' as interop;
import 'utils/code_history.dart';
import 'dart:math' as math;
import '../services/pollinations_services.dart';
import '../services/prompt_history_service.dart';
import '../widgets/prompt_history_widget.dart';
import '../models/prompt_history.dart';

enum KeyboardPosition { aboveEditor, betweenEditorOutput, belowOutput }

enum TabType { html, css, js }

class IDEScreen extends StatefulWidget {
  const IDEScreen({super.key});

  @override
  State<IDEScreen> createState() => _IDEScreenState();
}

class _IDEScreenState extends State<IDEScreen> {
  final Map<String, String> _editorOutputs = {};
  final bool _isLoading = false;
  final double _editorHeightRatio = 0.45;
  final double _fontSize = 14.0;
  final Map<String, String> _lastText = {};
  final Map<String, CodeHistory> _codeHistories = {};
  String _currentTheme = 'vs-dark';
  bool _preventHistoryUpdate = false;

  int numberOfStudents = 4;
  final List<String> _monacoElementIds = [
    'monaco-editor-container-1',
    'monaco-editor-container-2',
    'monaco-editor-container-3',
    'monaco-editor-container-4',
  ];

  // Tab system for HTML/CSS/JS

  final Map<String, TabType> _currentTabs = {}; // Current active tab per editor
  final Map<String, Map<TabType, String>> _tabContents =
      {}; // Content for each tab per editor
  final Map<String, Map<TabType, String>> _tabFileNames =
      {}; // Filenames for each tab per editor

  final List<String> _monacoDivIds = [
    'monaco-editor-div-1',
    'monaco-editor-div-2',
    'monaco-editor-div-3',
    'monaco-editor-div-4',
  ];
  bool _monacoInitialized = false;
  bool _editorsNeedReinitialization = false;

  final List<String> _availableThemes = ['vs-dark', 'vs-light', 'hc-black'];

  final Map<String, bool> _canUndoCache = {};
  final Map<String, bool> _canRedoCache = {};
  final Map<String, bool> _autocompleteEnabledCache = {};
  final Map<String, bool> _isPrettifyingCache = {};

  final Map<String, int> _editorRollNumbers = {};
  final Set<int> _usedRollNumbers = {};
  final math.Random _random = math.Random();

  // Keyboard positioning - now per editor
  final Map<String, KeyboardPosition?> _keyboardPositions = {};

  // Output expansion state - per editor
  final Map<String, bool> _outputExpanded = {};

  // Live preview management
  final Map<String, bool> _livePreviewEnabled = {};
  final Map<String, Timer?> _previewUpdateTimers = {};
  final List<String> _previewElementIds = [
    'html-preview-1',
    'html-preview-2',
    'html-preview-3',
    'html-preview-4',
  ];

  // UI layout reorganization - expandable preview with output toggle
  final Map<String, bool> _previewExpanded =
      {}; // Controls preview section expansion
  final Map<String, bool> _showOutputInPreview =
      {}; // Toggle between preview and output in bottom section

  // Prevent multiple simultaneous Monaco initialization attempts
  bool _isInitializingMonaco = false;

  // Input management
  final TextEditingController _promptController = TextEditingController();
  final FocusNode _promptFocus = FocusNode();

  // State management
  bool _isGenerating = false;
  String? _errorMessage;

  // History management
  bool _showHistoryPanel = false;

  // Editor selection for code generation
  int _selectedEditorIndex = 0;

  @override
  void initState() {
    super.initState();

    // Initialize state for each editor
    for (final id in _monacoDivIds) {
      _livePreviewEnabled[id] = true;
      _previewUpdateTimers[id] = null;
      _codeHistories[id] = CodeHistory();
      _lastText[id] = '';
      _editorOutputs[id] = '';
      _currentTabs[id] = TabType.html; // Default to HTML tab
      _tabContents[id] = {
        TabType.html: '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Web Page</title>
</head>
<body>
    <div class="container">
        <h1 id="main-title">Welcome to HTML Web IDE!</h1>
        <p class="description">Edit HTML, CSS, and JavaScript in the tabs above.</p>
        <button id="change-btn" class="btn">Click me!</button>
        <div id="output-area"></div>
    </div>
</body>
</html>''',

        TabType.css: '''/* CSS Styles for your webpage */
.container {
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
    font-family: 'Arial', sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
    color: white;
}

#main-title {
    text-align: center;
    color: #fff;
    font-size: 2.5em;
    margin-bottom: 20px;
    text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
}

.description {
    text-align: center;
    font-size: 1.2em;
    margin-bottom: 30px;
    opacity: 0.9;
}

.btn {
    display: block;
    margin: 20px auto;
    padding: 12px 24px;
    background: #ff6b6b;
    color: white;
    border: none;
    border-radius: 25px;
    font-size: 1.1em;
    cursor: pointer;
    transition: all 0.3s ease;
}

.btn:hover {
    background: #ff5252;
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(0,0,0,0.3);
}

#output-area {
    margin-top: 30px;
    padding: 20px;
    background: rgba(255,255,255,0.1);
    border-radius: 10px;
    text-align: center;
    min-height: 50px;
}''',

        TabType.js: '''// JavaScript for interactive functionality
console.log("🚀 HTML Web IDE is ready!");

// Wait for DOM to load
document.addEventListener('DOMContentLoaded', function() {
    const button = document.getElementById('change-btn');
    const title = document.getElementById('main-title');
    const outputArea = document.getElementById('output-area');
    
    let clickCount = 0;
    const colors = ['#ff6b6b', '#4ecdc4', '#45b7d1', '#96ceb4', '#feca57'];
    
    button.addEventListener('click', function() {
        clickCount++;
        
        // Change title text
        title.textContent = `You clicked ` + clickCount + ` times! 🎉`;
        
        // Change button color
        const randomColor = colors[Math.floor(Math.random() * colors.length)];
        button.style.backgroundColor = randomColor;
        
        // Add message to output area
        outputArea.innerHTML = `
            <h3>Button clicked ` + clickCount + ` times!</h3>
            <p>Try editing the code in different tabs to see live changes.</p>
            <small>Last clicked: ` + new Date().toLocaleTimeString() + `</small>
        `;
        
        console.log(`Button clicked ` + clickCount + ` times at ` + new Date() + ``);
    });
    
    // Add some dynamic content
    setTimeout(() => {
        outputArea.innerHTML = '<p>✨ Ready for interaction! Click the button above.</p>';
    }, 1000);
});''',
      };
      _tabFileNames[id] = {
        TabType.html: 'index.html',
        TabType.css: 'styles.css',
        TabType.js: 'script.js',
      };

      // Initialize undo/redo cache
      _updateUndoRedoCache(id);

      // Initialize autocomplete cache (enabled by default)
      _autocompleteEnabledCache[id] = true;
      _isPrettifyingCache[id] = false;

      // Initialize keyboard position for each editor
      _keyboardPositions[id] = KeyboardPosition.betweenEditorOutput;

      // Initialize output expansion state (collapsed by default)
      _outputExpanded[id] = false;

      // Initialize new UI layout states
      _previewExpanded[id] = false; // Preview section collapsed by default
      _showOutputInPreview[id] =
          false; // Show preview content by default (not output)

      _assignRollNumbers();
    }

    // Register DOM elements for all editors
    _registerDOMElements();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reduced delay since DOM elements are now always present
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _isInitializingMonaco = true;
        });
        _setupMonacoEditor();
      });
      // Python initialization removed - now using HTML/CSS/JS

      // Add visibility change listener to detect when user comes back to tab
      html.document.addEventListener('visibilitychange', (_) {
        if (!html.document.hidden!) {
          // Page became visible, check if editors need reinitialization
          // Add extra delay to ensure DOM is stable after page refresh
          Future.delayed(const Duration(milliseconds: 1000), () {
            // Only reinitialize if editors are actually missing or broken
            bool needsReinit = false;
            for (final id in _monacoDivIds) {
              final element = html.document.getElementById(id);
              if (element == null ||
                  (!element.hasAttribute('data-monaco-initialized') &&
                      element.children.isEmpty)) {
                needsReinit = true;
                print(
                  'Editor $id needs reinitialization after visibility change',
                );
                break;
              }
            }
            if (needsReinit) {
              _checkAndReinitializeEditors();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _promptFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Don't check if we're already initializing
    if (!_isInitializingMonaco) {
      // Check if we need to reinitialize editors when coming back to the screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndReinitializeEditors();
      });
    }
  }

  @override
  void didUpdateWidget(IDEScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Don't check if we're already initializing
    if (!_isInitializingMonaco) {
      // Also check when the widget updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndReinitializeEditors();
      });
    }
  }

  void _checkAndReinitializeEditors() {
    // Prevent multiple simultaneous checks
    if (_isInitializingMonaco) {
      print('Monaco initialization already in progress, skipping check...');
      return;
    }

    // Check if any of the Monaco editor DOM elements are missing or improperly initialized
    bool needsReinit = false;

    // Only check the editors that should be active based on numberOfStudents
    for (int i = 0; i < numberOfStudents; i++) {
      final id = _monacoDivIds[i];
      final element = html.document.getElementById(id);

      if (element == null) {
        needsReinit = true;
        print('Editor $id DOM element is missing');
        break;
      } else if (!element.hasAttribute('data-monaco-initialized') &&
          element.children.isEmpty) {
        needsReinit = true;
        print('Editor $id DOM element is empty and not initialized');
        break;
      }
    }

    if (needsReinit || _editorsNeedReinitialization) {
      print('Reinitializing Monaco editors from check...');
      _editorsNeedReinitialization = false;

      // Use a longer delay to ensure DOM is ready after widget rebuilds
      Future.delayed(const Duration(milliseconds: 1000), () async {
        if (!_isInitializingMonaco) {
          // Double-check flag
          setState(() {
            _monacoInitialized = false;
            _isInitializingMonaco = true;
          });
          _setupMonacoEditor();
        }
      });
    }
  }

  void _setupMonacoEditor() {
    print(
      '_setupMonacoEditor called - _isInitializingMonaco: $_isInitializingMonaco',
    );
    print('Starting Monaco editor setup...');

    const initialCode = '''<!-- Welcome to HTML Web IDE! -->
<!DOCTYPE html>
<html>
<head>
    <title>Welcome</title>
</head>
<body>
    <h1>Welcome to HTML Web IDE!</h1>
    <p>Switch between HTML, CSS, and JS tabs to build your web project.</p>
</body>
</html>''';

    print('Setting up Monaco editors...'); // Debug log

    // Reset initialization flag
    _monacoInitialized = false;

    // Initialize all editors sequentially to avoid conflicts
    _initializeEditorsSequentially(initialCode);
  }

  Future<void> _initializeEditorsSequentially(String defaultCode) async {
    // Wait longer for DOM elements to be ready (especially after widget rebuild)
    await Future.delayed(const Duration(milliseconds: 1000));

    print('Initializing $numberOfStudents editors sequentially...');

    for (int i = 0; i < numberOfStudents; i++) {
      final id = _monacoDivIds[i];
      final currentTab = _currentTabs[id] ?? TabType.html;

      // Get the content for the current tab, use saved content if available
      String initialCode = defaultCode;
      if (_tabContents[id] != null && _tabContents[id]![currentTab] != null) {
        initialCode = _tabContents[id]![currentTab]!;
      }

      // Update internal state
      _lastText[id] = initialCode;
      _codeHistories[id]?.addState(initialCode);

      final language = _getLanguageForTab(currentTab);

      print('Initializing editor $i: $id with language: $language');

      try {
        // Wait for DOM element to be available with more retries (especially after widget rebuild)
        var retries = 0;
        html.Element? element;

        while (retries < 50) {
          element = html.document.getElementById(id);
          if (element != null) {
            break;
          }
          await Future.delayed(const Duration(milliseconds: 200));
          retries++;
        }

        if (retries >= 50 || element == null) {
          print('DOM element $id not found after waiting ${retries * 200}ms');
          continue;
        }

        // Check if Monaco editor already exists for this element
        final hasMonacoInstance = element.hasAttribute(
          'data-monaco-initialized',
        );

        if (hasMonacoInstance) {
          print('Monaco editor already exists for $id, destroying first...');
          await interop.destroyEditor(id);
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Ensure the element is completely clean
        element.innerHtml = '';
        element.removeAttribute('data-monaco-initialized');
        print('DOM element found and cleared for $id, initializing...');

        // Initialize Monaco editor
        print('Initializing Monaco editor for $id with language: $language');
        await interop.initMonaco(
          id,
          initialCode,
          _currentTheme,
          _fontSize,
          (content) => _onContentChanged(content, id),
          language,
        );

        // Mark element as initialized
        element.setAttribute('data-monaco-initialized', 'true');
        print('Editor initialized: $id with language: $language');

        // Ensure content is properly set after initialization
        await Future.delayed(const Duration(milliseconds: 200));
        interop.setMonacoValue(id, initialCode);
        _lastText[id] = initialCode;

        // Update the tab content to ensure consistency
        if (_tabContents[id] != null) {
          _tabContents[id]![currentTab] = initialCode;
        }

        print(
          'Content set for editor $id: ${initialCode.substring(0, math.min(50, initialCode.length))}...',
        );

        // Delay between initializations to prevent conflicts
        await Future.delayed(const Duration(milliseconds: 400));
      } catch (error) {
        print('Error initializing editor $id: $error');
      }
    }

    if (mounted) {
      setState(() {
        _monacoInitialized = true;
        _isInitializingMonaco = false;
      });
    }

    print('Monaco editor setup completed for $numberOfStudents editors');

    // Ensure all tab contents are properly loaded
    await _refreshAllTabContents();

    // Trigger initial preview updates for all editors
    await Future.delayed(const Duration(milliseconds: 500));
    for (int i = 0; i < numberOfStudents; i++) {
      final id = _monacoDivIds[i];
      _updateLivePreview(id);
    }
  }

  String _getLanguageForTab(TabType tab) {
    switch (tab) {
      case TabType.html:
        return 'html';
      case TabType.css:
        return 'css';
      case TabType.js:
        return 'javascript';
    }
  }

  String _getFileExtensionForTab(TabType tab) {
    switch (tab) {
      case TabType.html:
        return '.html';
      case TabType.css:
        return '.css';
      case TabType.js:
        return '.js';
    }
  }

  String _getTabNameForTabType(TabType tab) {
    switch (tab) {
      case TabType.html:
        return 'html';
      case TabType.css:
        return 'css';
      case TabType.js:
        return 'js';
    }
  }

  void _switchTab(String editorId, TabType newTab) {
    if (_currentTabs[editorId] == newTab) return;

    // Save current content before switching
    final currentTab = _currentTabs[editorId];
    if (currentTab != null) {
      try {
        final currentContent = interop.getMonacoValue(editorId);
        _tabContents[editorId]?[currentTab] = currentContent;
      } catch (e) {
        print('Error saving current content: $e');
      }
    }

    // Switch to new tab
    setState(() {
      _currentTabs[editorId] = newTab;
    });

    // Load new tab content with a small delay to ensure Monaco is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      final newContent = _tabContents[editorId]?[newTab] ?? '';
      final language = _getLanguageForTab(newTab);

      try {
        interop.setMonacoLanguage(editorId, language);
        interop.setMonacoValue(editorId, newContent);
        _lastText[editorId] = newContent;

        // Trigger autocomplete to show new language-specific suggestions
        final isAutocompleteEnabled =
            _autocompleteEnabledCache[editorId] ?? true;
        if (isAutocompleteEnabled) {
          Future.delayed(const Duration(milliseconds: 200), () {
            interop.triggerAutocomplete(editorId);
          });
        }

        print(
          'Switched to $newTab tab for $editorId with content length: ${newContent.length}',
        );
      } catch (e) {
        print('Error switching tab: $e');
      }

      // Clear undo/redo history for clean switch
      _codeHistories[editorId]?.clear();
      _codeHistories[editorId]?.addState(newContent);
      _updateUndoRedoCache(editorId);

      // Update live preview with new tab content
      _updateLivePreview(editorId);
    });
  }

  void _updateLivePreview(String editorId) {
    // Cancel existing timer to debounce updates
    _previewUpdateTimers[editorId]?.cancel();

    // Set a new timer to update after user stops typing
    _previewUpdateTimers[editorId] = Timer(
      const Duration(milliseconds: 500),
      () {
        if (_livePreviewEnabled[editorId] == true) {
          _refreshPreviewContent(editorId);
        }
      },
    );
  }

  void _refreshPreviewContent(String editorId) {
    final htmlContent = _tabContents[editorId]?[TabType.html] ?? '';
    final cssContent = _tabContents[editorId]?[TabType.css] ?? '';
    final jsContent = _tabContents[editorId]?[TabType.js] ?? '';

    final completeHTML = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Live Preview</title>
    <style>
$cssContent
    </style>
</head>
<body>
$htmlContent
    <script>
try {
$jsContent
} catch(e) {
  console.error('JavaScript Error:', e);
  document.body.innerHTML += '<div style="color:red;padding:10px;background:#ffebee;margin:10px;border-radius:5px;"><strong>JavaScript Error:</strong> ' + e.message + '</div>';
}
    </script>
</body>
</html>
  ''';

    // Update the iframe content
    _injectHTMLToPreview(editorId, completeHTML);
  }

  void _injectHTMLToPreview(String editorId, String htmlContent) {
    // Get the index from editor ID
    final index = _monacoDivIds.indexOf(editorId);
    if (index >= 0 && index < _previewElementIds.length) {
      final previewId = _previewElementIds[index];

      // Use JavaScript interop to update iframe
      try {
        final iframe =
            html.document.getElementById(previewId) as html.IFrameElement?;
        if (iframe != null) {
          iframe.srcdoc = htmlContent;
        }
      } catch (e) {
        print('Error updating preview: $e');
      }
    }
  }

  Future<void> _saveCurrentEditorStates() async {
    print('Saving current editor states...');

    for (int i = 0; i < numberOfStudents; i++) {
      final id = _monacoDivIds[i];
      final currentTab = _currentTabs[id] ?? TabType.html;

      try {
        final element = html.document.getElementById(id);
        if (element != null &&
            element.hasAttribute('data-monaco-initialized')) {
          final currentContent = interop.getMonacoValue(id);

          // Save the current tab content
          if (_tabContents[id] != null) {
            _tabContents[id]![currentTab] = currentContent;
            print(
              'Saved content for editor $id, tab: $currentTab (${currentContent.length} chars)',
            );
          }
        }
      } catch (e) {
        print('Error saving content for editor $id: $e');
      }
    }
  }

  Future<void> _cleanupEditors() async {
    // Save current editor states before cleanup
    final Map<String, Map<TabType, String>> savedContents = {};

    for (int i = 0; i < 4; i++) {
      final id = _monacoDivIds[i];

      // Save current content from the Monaco editor if it exists
      try {
        final element = html.document.getElementById(id);
        if (element != null &&
            element.hasAttribute('data-monaco-initialized')) {
          final currentContent = interop.getMonacoValue(id);
          final currentTab = _currentTabs[id] ?? TabType.html;

          // Save the current tab content
          if (_tabContents[id] != null) {
            savedContents[id] = Map.from(_tabContents[id]!);
            savedContents[id]![currentTab] = currentContent;
          }
        }
      } catch (e) {
        print('Error saving content for $id: $e');
      }

      // Clean up all 4 editors to be safe
      try {
        await interop.destroyEditor(id);
        print('Destroyed Monaco editor: $id');

        // Also clear the DOM element and remove initialization marker to prevent duplication
        final element = html.document.getElementById(id);
        if (element != null) {
          element.innerHtml = '';
          element.removeAttribute('data-monaco-initialized');
          print('Cleared DOM element: $id');
        }
      } catch (error) {
        print('Error destroying editor $id: $error');
      }
    }

    // Restore saved contents
    for (final entry in savedContents.entries) {
      _tabContents[entry.key] = entry.value;
    }

    // Wait a bit to ensure cleanup is complete
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _reinitializeEditors() async {
    // Prevent multiple simultaneous reinitializations
    if (!_isInitializingMonaco) {
      print('Initialization flag not set, setting it now...');
      setState(() {
        _monacoInitialized = false;
        _isInitializingMonaco = true;
      });
    }

    print('Starting editor reinitialization...');

    try {
      // Clean up existing Monaco editors first
      await _cleanupEditors();

      // Let _setupMonacoEditor handle the initialization timing
      _setupMonacoEditor();
    } catch (e) {
      print('Error during editor reinitialization: $e');
      // Reset flag on error
      if (mounted) {
        setState(() {
          _isInitializingMonaco = false;
        });
      }
    }
  } // Track registered view factories to avoid re-registration

  static final Set<String> _registeredViewFactories = <String>{};

  Future<void> _registerDOMElements() async {
    print('Registering view factories...');

    // Register preview iframe views for all possible students
    for (var i = 0; i < 4; i++) {
      final previewId = _previewElementIds[i];

      // Skip if already registered
      if (_registeredViewFactories.contains(previewId)) {
        print(
          'Preview view factory $previewId already registered, skipping...',
        );
        continue;
      }

      try {
        ui_web.platformViewRegistry.registerViewFactory(
          previewId,
          (int viewId) =>
              html.IFrameElement()
                ..id = previewId
                ..style.width = '100%'
                ..style.height = '100%'
                ..style.border = 'none'
                ..srcdoc =
                    '<html><body><p>Preview will appear here...</p></body></html>',
        );
        _registeredViewFactories.add(previewId);
        print('Successfully registered preview view factory: $previewId');
      } catch (e) {
        print('Failed to register preview view factory $previewId: $e');
        // Mark as attempted to prevent repeated registration attempts
        _registeredViewFactories.add(previewId);
      }
    }

    // Register editor views for all possible students
    for (var i = 0; i < 4; i++) {
      final elementId = _monacoElementIds[i];
      final divId = _monacoDivIds[i];

      // Skip if already registered
      if (_registeredViewFactories.contains(elementId)) {
        print('Editor view factory $elementId already registered, skipping...');
        continue;
      }

      try {
        ui_web.platformViewRegistry.registerViewFactory(
          elementId,
          (int viewId) =>
              html.DivElement()
                ..id = divId
                ..style.width = '100%'
                ..style.height = '100%',
        );
        _registeredViewFactories.add(elementId);
        print(
          'Successfully registered editor view factory: $elementId with div $divId',
        );
      } catch (e) {
        print('Failed to register editor view factory $elementId: $e');
        // Mark as attempted to prevent repeated registration attempts
        _registeredViewFactories.add(elementId);
      }
    }
  }

  void _onContentChanged(String content, String editorId) {
    // Run in post-frame callback to avoid calling setState during a build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_preventHistoryUpdate && content != _lastText[editorId]) {
        final currentTab = _currentTabs[editorId];
        if (currentTab != null) {
          _tabContents[editorId]?[currentTab] = content;
        }

        _codeHistories[editorId]?.addState(content);
        _lastText[editorId] = content;

        _updateUndoRedoCache(editorId);

        _updateLivePreview(editorId);

        setState(() {}); // Update Undo/Redo button states
      }
    });
  }

  int _generateUniqueRollNumber() {
    if (_usedRollNumbers.length >= 40) {
      return _random.nextInt(40) + 1;
    }
    int rollNumber;
    do {
      rollNumber = _random.nextInt(40) + 1; // Random number from 1 to 40
    } while (_usedRollNumbers.contains(rollNumber));

    _usedRollNumbers.add(rollNumber);
    return rollNumber;
  }

  void _assignRollNumbers() {
    _usedRollNumbers.clear();
    _editorRollNumbers.clear();

    for (int i = 0; i < numberOfStudents; i++) {
      final editorId = _monacoDivIds[i];
      _editorRollNumbers[editorId] = _generateUniqueRollNumber();
    }
  }

  void _regenerateRollNumber(String editorId) {
    // Remove current roll number from used set
    final currentRoll = _editorRollNumbers[editorId];
    if (currentRoll != null) {
      _usedRollNumbers.remove(currentRoll);
    }

    // Generate new unique roll number
    final newRollNumber = _generateUniqueRollNumber();

    setState(() {
      _editorRollNumbers[editorId] = newRollNumber;
    });
  }

  void _undo(String editorId) {
    final history = _codeHistories[editorId];
    if (history?.canUndo() == true) {
      _preventHistoryUpdate = true;
      final previousState = history!.undo();
      if (previousState != null) {
        interop.setEditorContent(editorId, previousState);
        _lastText[editorId] = previousState;
      }

      // Immediately update cache for instant UI response
      _updateUndoRedoCache(editorId);
      setState(() {});

      _preventHistoryUpdate = false;
    }
  }

  void _redo(String editorId) {
    final history = _codeHistories[editorId];
    if (history?.canRedo() == true) {
      _preventHistoryUpdate = true;
      final nextState = history!.redo();
      if (nextState != null) {
        interop.setEditorContent(editorId, nextState);
        _lastText[editorId] = nextState;
      }

      // Immediately update cache for instant UI response
      _updateUndoRedoCache(editorId);
      setState(() {});

      _preventHistoryUpdate = false;
    }
  }

  void _clearOutput([String? editorId]) {
    if (editorId != null) {
      setState(() => _editorOutputs[editorId] = '');
    } else {
      // Clear all outputs if no specific editor is specified
      setState(() {
        for (final id in _monacoDivIds) {
          _editorOutputs[id] = '';
        }
      });
    }
  }

  void _updateMonacoSettings([String? editorId]) {
    if (editorId != null) {
      interop.updateMonacoOptions(editorId, _currentTheme, _fontSize);
    } else {
      for (final id in _monacoDivIds) {
        interop.updateMonacoOptions(id, _currentTheme, _fontSize);
      }
    }
  }

  void _updateUndoRedoCache(String editorId) {
    _canUndoCache[editorId] = _codeHistories[editorId]?.canUndo() ?? false;
    _canRedoCache[editorId] = _codeHistories[editorId]?.canRedo() ?? false;
  }

  void _prettifyCode(String editorId) {
    setState(() {
      _isPrettifyingCache[editorId] = true;
    });

    Future.delayed(Duration(milliseconds: 100), () {
      interop.formatMonacoDocument(editorId);
      setState(() {
        _isPrettifyingCache[editorId] = false;
      });
    });
  }

  void _toggleAutocomplete(String editorId) {
    final isEnabled = _autocompleteEnabledCache[editorId] ?? true;
    _autocompleteEnabledCache[editorId] = !isEnabled;

    // Set autocomplete state
    interop.setAutocomplete(editorId, !isEnabled);

    // If enabling autocomplete, trigger suggestions to demonstrate functionality
    if (!isEnabled) {
      // Small delay to ensure settings are applied first
      Future.delayed(Duration(milliseconds: 100), () {
        interop.triggerAutocomplete(editorId);
      });
    }

    setState(() {}); // Update UI
  }

  // void _clearEditor(String? editorId) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Clear Editor'),
  //         backgroundColor: Colors.grey[800],
  //         content: const Text(
  //           'Are you sure you want to clear all editor content? This action cannot be undone.',
  //           style: TextStyle(color: Colors.white),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: const Text('Cancel'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               // Clear all editors
  //               for (final id in _monacoDivIds) {
  //                 interop.setMonacoValue(id, '');
  //                 _lastText[id] = '';
  //                 _codeHistories[id]?.clear();
  //                 _codeHistories[id]?.addState('');
  //                 _currentFileNames[id] = 'untitled.py';
  //               }
  //               setState(() {});
  //               Navigator.of(context).pop();
  //               _showSnackBar('Editors cleared');
  //             },
  //             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //             child: const Text('Clear'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _changeTheme(String themeName) {
    setState(() {
      _currentTheme = themeName;
      _updateMonacoSettings();
    });
    _showSnackBar('Theme changed to $_currentTheme');
  }

  void _handleArrowUp(String editorId) {
    interop.moveCursor(editorId, 'up');
  }

  void _handleArrowDown(String editorId) {
    interop.moveCursor(editorId, 'down');
  }

  void _handleArrowLeft(String editorId) {
    interop.moveCursor(editorId, 'left');
  }

  void _handleArrowRight(String editorId) {
    interop.moveCursor(editorId, 'right');
  }

  void _saveCodeToFile([String? editorId]) {
    _showSaveDialog(editorId);
  }

  void _showSaveDialog([String? editorId]) {
    final id = editorId ?? _monacoDivIds[0];
    final currentTab = _currentTabs[id] ?? TabType.html;
    final currentFileName =
        _tabFileNames[id]?[currentTab] ??
        'untitled${_getFileExtensionForTab(currentTab)}';
    final TextEditingController fileNameController = TextEditingController(
      text: currentFileName,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Save ${currentTab.name.toUpperCase()} File'),
          backgroundColor: Colors.grey[800],
          content: TextField(
            controller: fileNameController,
            decoration: const InputDecoration(
              labelText: 'File name',
              hintText: 'Enter file name with extension',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String fileName = fileNameController.text.trim();
                if (fileName.isEmpty) {
                  fileName = 'untitled${_getFileExtensionForTab(currentTab)}';
                }
                if (!fileName.contains('.')) {
                  fileName += _getFileExtensionForTab(currentTab);
                }

                _downloadFile(fileName, interop.getMonacoValue(id));
                setState(() => _tabFileNames[id]![currentTab] = fileName);
                Navigator.of(context).pop();
                _showSnackBar('File saved as $fileName');
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _downloadFile(String fileName, String content) {
    final blob = html.Blob([content], 'text/plain');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  void _handleKeyPress(String key, String editorId) {
    // Insert the key at current cursor position
    interop.insertTextAtCursor(editorId, key);
  }

  void _handleBackspace(String editorId) {
    // Delete character before cursor
    interop.deleteCharacterBeforeCursor(editorId);
  }

  void _handleEnter(String editorId) {
    // Insert new line
    interop.insertTextAtCursor(editorId, '\n');
  }

  void _handleMenuSelection(String value, String editorId) {
    print('Menu selection: $value for editor: $editorId');
    print('Current position: ${_keyboardPositions[editorId]}');

    setState(() {
      switch (value) {
        case 'above':
          _keyboardPositions[editorId] = KeyboardPosition.aboveEditor;
          print('Setting position to: aboveEditor for $editorId');
          break;
        case 'between':
          _keyboardPositions[editorId] = KeyboardPosition.betweenEditorOutput;
          print('Setting position to: betweenEditorOutput for $editorId');
          break;
        case 'below':
          _keyboardPositions[editorId] = KeyboardPosition.belowOutput;
          print('Setting position to: belowOutput for $editorId');
          break;
      }
    });

    print('New position: ${_keyboardPositions[editorId]} for $editorId');
  }

  // New helper methods for expandable preview functionality
  void _togglePreviewExpansion(String editorId) {
    setState(() {
      final wasExpanded = _previewExpanded[editorId] ?? false;
      _previewExpanded[editorId] = !wasExpanded;

      // When expanding preview, hide keyboard. When collapsing, show keyboard
      if (!wasExpanded) {
        // Expanding - hide keyboard
        _keyboardPositions[editorId] = null;
      } else {
        // Collapsing - show keyboard between editor and preview
        _keyboardPositions[editorId] = KeyboardPosition.betweenEditorOutput;
      }
    });
  }

  void _toggleOutputInPreview(String editorId) {
    setState(() {
      _showOutputInPreview[editorId] =
          !(_showOutputInPreview[editorId] ?? false);
    });
  }

  // Calculate heights accounting for keyboard toolbar and preview expansion
  Map<String, double> _calculateDynamicHeights(
    BoxConstraints constraints,
    int editorIndex,
  ) {
    const double keyboardHeight =
        200.0; // Approximate height for keyboard toolbar
    const double headerHeight = 85.0; // Account for header + tabbar

    // Check if keyboard is visible for this editor
    bool keyboardVisible =
        _keyboardPositions[_monacoDivIds[editorIndex]] != null;

    // Check if preview is expanded
    bool previewExpanded =
        _previewExpanded[_monacoDivIds[editorIndex]] ?? false;

    double availableHeight = constraints.maxHeight;
    double usedHeight = headerHeight + (keyboardVisible ? keyboardHeight : 0);
    double remainingHeight = availableHeight - usedHeight;

    // Ensure minimum heights
    remainingHeight = remainingHeight.clamp(200.0, double.infinity);

    double editorHeight;
    double previewHeight;

    if (previewExpanded && !keyboardVisible) {
      // When preview is expanded and keyboard is hidden, give more space to preview
      editorHeight = remainingHeight * 0.4; // 40% for editor
      previewHeight = remainingHeight * 0.6 - 10; // 60% for expanded preview
    } else {
      // Normal layout
      editorHeight = remainingHeight * 0.7; // 70% of remaining height
      previewHeight =
          remainingHeight * 0.3 - 10; // 30% of remaining height minus padding
    }

    return {
      'editor': editorHeight,
      'preview': previewHeight,
      'remaining': remainingHeight,
    };
  }

  Future<void> _refreshAllTabContents() async {
    for (int i = 0; i < numberOfStudents; i++) {
      final id = _monacoDivIds[i];
      final currentTab = _currentTabs[id] ?? TabType.html;
      final content = _tabContents[id]?[currentTab] ?? '';

      try {
        interop.setMonacoValue(id, content);
        _lastText[id] = content;
        print('Refreshed content for editor $id, tab: $currentTab');
      } catch (error) {
        print('Error refreshing content for $id: $error');
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Widget _buildKeyboard(int editorIndex) {
    final currentTab = _currentTabs[_monacoDivIds[editorIndex]] ?? TabType.html;
    final currentTabName = _getTabNameForTabType(currentTab);

    return KeyboardToolbar(
      key: ValueKey('keyboard-${_monacoDivIds[editorIndex]}'),
      onKeyPress: (key) => _handleKeyPress(key, _monacoDivIds[editorIndex]),
      onBackspace: () => _handleBackspace(_monacoDivIds[editorIndex]),
      onEnter: () => _handleEnter(_monacoDivIds[editorIndex]),
      onUndo: () => _undo(_monacoDivIds[editorIndex]),
      onRedo: () => _redo(_monacoDivIds[editorIndex]),
      canUndo: _canUndoCache[_monacoDivIds[editorIndex]] ?? false,
      canRedo: _canRedoCache[_monacoDivIds[editorIndex]] ?? false,
      onArrowUp: () => _handleArrowUp(_monacoDivIds[editorIndex]),
      onArrowDown: () => _handleArrowDown(_monacoDivIds[editorIndex]),
      onArrowLeft: () => _handleArrowLeft(_monacoDivIds[editorIndex]),
      onArrowRight: () => _handleArrowRight(_monacoDivIds[editorIndex]),
      onPrettify: () => _prettifyCode(_monacoDivIds[editorIndex]),
      onToggleAutocomplete:
          () => _toggleAutocomplete(_monacoDivIds[editorIndex]),
      isAutocompleteEnabled:
          _autocompleteEnabledCache[_monacoDivIds[editorIndex]] ?? true,
      isPrettifying: _isPrettifyingCache[_monacoDivIds[editorIndex]] ?? false,
      onMenuSelection: _handleMenuSelection,
      editorId: _monacoDivIds[editorIndex],
      currentTab: currentTabName,
    );
  }

  Widget _buildPromptInputSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Text Generation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promptController,
                  focusNode: _promptFocus,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Enter your prompt here (e.g., "Create a responsive navbar with HTML and CSS")',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _generateTextFromPrompt(),
                  enabled: !_isGenerating,
                ),
              ),
              const SizedBox(width: 8),
              _buildEditorSelectionDropdown(),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showHistory,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.history, color: Colors.grey),
                tooltip: 'View prompt history',
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isGenerating ? null : _generateTextFromPrompt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isGenerating
                        ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Generating...'),
                          ],
                        )
                        : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 18),
                            SizedBox(width: 8),
                            Text('Generate'),
                          ],
                        ),
              ),
            ],
          ),
          if (_errorMessage != null) _buildErrorDisplay(),
        ],
      ),
    );
  }

  Widget _buildEditorSelectionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedEditorIndex,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          items: List.generate(numberOfStudents, (index) {
            return DropdownMenuItem<int>(
              value: index,
              child: Text(
                'Editor ${index + 1}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedEditorIndex = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Future<void> _generateTextFromPrompt() async {
    final prompt = _promptController.text.trim();

    // Validate input
    if (prompt.isEmpty) {
      _showErrorMessage('Please enter a prompt');
      return;
    }

    // Validate selected editor index
    if (_selectedEditorIndex >= numberOfStudents) {
      _showErrorMessage('Selected editor is not available');
      return;
    }

    // Update UI to show loading state
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      print('Generating text for prompt: $prompt');
      print('Target editor index: $_selectedEditorIndex');

      // Test connection first
      print('Testing API connection...');
      final isConnected = await PollinationsServices.testConnection();
      if (!isConnected) {
        setState(() {
          _errorMessage =
              'Unable to connect to AI service. This might be due to:\n'
              '• Network connectivity issues\n'
              '• CORS restrictions in web browser\n'
              '• AI service temporarily unavailable\n'
              'Please check browser console for details.';
          _isGenerating = false;
        });
        return;
      }
      print('Connection test passed');

      // Generate code for the selected editor only
      final response = await PollinationsServices.generateText(prompt);

      print('Response received - Success: ${response.success}');
      if (!response.success) {
        print('Error from API: ${response.error}');
      }

      if (response.success && response.text.isNotEmpty) {
        print('Generated text length: ${response.text.length}');

        // Set the generated code in the selected editor
        final editorId = _monacoDivIds[_selectedEditorIndex];
        final currentTab = _currentTabs[editorId] ?? TabType.html;

        print('Setting text in editor: $editorId, tab: $currentTab');

        interop.setMonacoValue(editorId, response.text);
        _lastText[editorId] = response.text;
        _codeHistories[editorId]?.clear();
        _codeHistories[editorId]?.addState(response.text);

        // Update tab content and filename to reflect the prompt
        _tabContents[editorId]![currentTab] = response.text;
        final extension = _getFileExtensionForTab(currentTab);
        final fileName =
            '${_sanitizeFilename(prompt)}_editor_${_selectedEditorIndex + 1}$extension';
        setState(() => _tabFileNames[editorId]![currentTab] = fileName);

        // Save to history with single response
        await PromptHistoryService.savePrompt(
          prompt: prompt,
          responses: [response.text],
        );

        setState(() {
          _isGenerating = false;
          _errorMessage = null;
        });

        // Clear the input after successful generation
        _promptController.clear();

        // Show success feedback
        _showSuccessMessage(
          'Code generated and loaded into Editor ${_selectedEditorIndex + 1}!',
        );
      } else {
        String errorMsg;
        if (!response.success && response.error != null) {
          if (response.error!.contains('Network Error')) {
            errorMsg =
                'Connection failed. Please check your internet connection and try again.';
          } else if (response.error!.contains('API Error')) {
            errorMsg =
                'AI service temporarily unavailable. Please try again in a few moments.';
          } else {
            errorMsg = 'AI Service Error: ${response.error}';
          }
        } else if (response.text.isEmpty) {
          errorMsg =
              'AI service returned empty response. Try rephrasing your prompt.';
        } else {
          errorMsg = 'Unknown error from AI service. Please try again.';
        }

        print('Setting error message: $errorMsg');
        setState(() {
          _errorMessage = errorMsg;
          _isGenerating = false;
        });
      }
    } catch (e) {
      print('Exception in _generateTextFromPrompt: $e');
      String userFriendlyError;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        userFriendlyError =
            'Connection timeout. Please check your internet connection and try again.';
      } else if (e.toString().contains('FormatException')) {
        userFriendlyError =
            'Invalid response format from AI service. Please try again.';
      } else {
        userFriendlyError =
            'Unexpected error occurred. Please try again or check your connection.';
      }

      setState(() {
        _errorMessage = userFriendlyError;
        _isGenerating = false;
      });
    }
  }

  // Helper method to sanitize filename
  String _sanitizeFilename(String prompt) {
    return prompt
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, math.min(20, prompt.length));
  }

  // Load a prompt from history
  void _loadPromptFromHistory(PromptHistoryItem item) {
    setState(() {
      _promptController.text = item.prompt;
      _showHistoryPanel = false;

      if (item.responses.isNotEmpty) {
        final responses = item.responses;
        final numberOfResponses = responses.length;

        for (int i = 0; i < numberOfStudents && i < numberOfResponses; i++) {
          final editorId = _monacoDivIds[i];
          final response = responses[i];

          interop.setEditorContent(editorId, response);
          _lastText[editorId] = response;
          _codeHistories[editorId]?.addState(response);
          _updateUndoRedoCache(editorId);
          setState(() {
            _editorOutputs[editorId] = '';
          });
        }

        // Fill remaining editors with the last available response (not the first)
        if (numberOfResponses > 0 && numberOfResponses < numberOfStudents) {
          final lastResponse = responses[numberOfResponses - 1];
          for (int i = numberOfResponses; i < numberOfStudents; i++) {
            final editorId = _monacoDivIds[i];
            interop.setEditorContent(editorId, lastResponse);
            _lastText[editorId] = lastResponse;
            _codeHistories[editorId]?.addState(lastResponse);
            _updateUndoRedoCache(editorId);
            setState(() {
              _editorOutputs[editorId] = '';
            });
          }
        }
      }
    });
    _promptFocus.requestFocus();
  }

  void _previewHTML(String editorId) {
    final htmlContent = _tabContents[editorId]?[TabType.html] ?? '';
    final cssContent = _tabContents[editorId]?[TabType.css] ?? '';
    final jsContent = _tabContents[editorId]?[TabType.js] ?? '';

    final completeHTML = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Preview</title>
    <style>
$cssContent
    </style>
</head>
<body>
$htmlContent
    <script>
$jsContent
    </script>
</body>
</html>
  ''';

    setState(() {
      _editorOutputs[editorId] = 'HTML Preview Generated';
    });

    // You can implement iframe preview or new window preview here
    _showHTMLPreviewDialog(completeHTML);
  }

  void _showHTMLPreviewDialog(String htmlContent) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('HTML Preview'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ClipRect(
                child: HtmlElementView(
                  viewType: 'html-preview',
                  onPlatformViewCreated: (id) {
                    // Inject HTML content into iframe
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _validateCode(String editorId, TabType tabType) {
    final content = _tabContents[editorId]?[tabType] ?? '';
    String validationResult = '';

    switch (tabType) {
      case TabType.html:
        validationResult = _validateHTML(content);
        break;
      case TabType.css:
        validationResult = _validateCSS(content);
        break;
      case TabType.js:
        validationResult = _validateJS(content);
        break;
    }

    setState(() {
      _editorOutputs[editorId] = validationResult;
    });
  }

  String _validateHTML(String html) {
    // Basic HTML validation
    if (html.trim().isEmpty) {
      return 'HTML is empty.';
    }

    // Check for basic HTML structure
    List<String> issues = [];
    if (!html.contains('<!DOCTYPE')) {
      issues.add('Missing DOCTYPE declaration');
    }
    if (!html.contains('<html')) {
      issues.add('Missing <html> tag');
    }
    if (!html.contains('<head')) {
      issues.add('Missing <head> section');
    }
    if (!html.contains('<body')) {
      issues.add('Missing <body> section');
    }

    if (issues.isEmpty) {
      return 'HTML structure looks good! ✅';
    } else {
      return 'HTML Issues Found:\n${issues.map((issue) => '• $issue').join('\n')}';
    }
  }

  String _validateCSS(String css) {
    // Basic CSS validation
    if (css.trim().isEmpty) {
      return 'CSS is empty.';
    }

    // Count braces to check for balance
    int openBraces = css.split('{').length - 1;
    int closeBraces = css.split('}').length - 1;

    if (openBraces != closeBraces) {
      return 'CSS Syntax Error: Unmatched braces ($openBraces opening, $closeBraces closing)';
    }

    return 'CSS syntax looks good! ✅';
  }

  String _validateJS(String js) {
    // Basic JavaScript validation
    if (js.trim().isEmpty) {
      return 'JavaScript is empty.';
    }

    // Count parentheses and braces for basic balance check
    int openParens = js.split('(').length - 1;
    int closeParens = js.split(')').length - 1;
    int openBraces = js.split('{').length - 1;
    int closeBraces = js.split('}').length - 1;

    List<String> issues = [];
    if (openParens != closeParens) {
      issues.add('Unmatched parentheses');
    }
    if (openBraces != closeBraces) {
      issues.add('Unmatched braces');
    }

    if (issues.isEmpty) {
      return 'JavaScript syntax looks good! ✅';
    } else {
      return 'JavaScript Issues Found:\n${issues.map((issue) => '• $issue').join('\n')}';
    }
  }

  // Show history panel
  void _showHistory() {
    setState(() {
      _showHistoryPanel = true;
    });
  }

  // Hide history panel
  void _hideHistory() {
    setState(() {
      _showHistoryPanel = false;
    });
  }

  // Helper method to show error messages
  void _showErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Add this method for error display
  Widget _buildErrorDisplay() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
            child: const Text('Dismiss', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building IDE with $numberOfStudents editors'); // Debug print
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'HTML Web IDE - $numberOfStudents Student${numberOfStudents == 1 ? '' : 's'}',
        ),
        backgroundColor: Colors.grey[900],
        actions: [
          PopupMenuButton<int>(
            onSelected: (value) async {
              print('Switching from $numberOfStudents to $value editors');

              // Save current state before changing
              await _saveCurrentEditorStates();

              // Immediately show loading state and cleanup editors to prevent flashing
              setState(() {
                _monacoInitialized = false;
                _isInitializingMonaco = true;
              });

              // Immediately cleanup existing editors to prevent visual glitch
              await _cleanupEditors();

              setState(() {
                numberOfStudents = value;
                // Reset selected editor index if it's out of range
                if (_selectedEditorIndex >= numberOfStudents) {
                  _selectedEditorIndex = 0;
                }
                // Mark that editors need reinitialization after widget rebuild
                _editorsNeedReinitialization = true;
              });

              _assignRollNumbers();

              // Wait for widget rebuild to complete, then reinitialize editors
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(const Duration(milliseconds: 500), () async {
                  await _reinitializeEditors();
                  print(
                    'Editor switch completed: $numberOfStudents editors active',
                  );
                });
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem<int>(
                    value: 0,
                    enabled: false,
                    child: Text(
                      'Number of Students',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const PopupMenuDivider(),
                  for (int i = 1; i <= 4; i++)
                    PopupMenuItem<int>(
                      value: i,
                      child: Row(
                        children: [
                          if (numberOfStudents == i)
                            const Icon(Icons.check, size: 16),
                          if (numberOfStudents == i) const SizedBox(width: 8),
                          Text('$i Student${i == 1 ? '' : 's'}'),
                        ],
                      ),
                    ),
                ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.palette),
            tooltip: 'Change Theme',
            onSelected: (value) {
              if (value != 'header') _changeTheme(value);
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem<String>(
                    value: 'header',
                    enabled: false,
                    child: Text(
                      'Editor Themes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const PopupMenuDivider(),
                  ..._availableThemes.map(
                    (theme) =>
                        PopupMenuItem<String>(value: theme, child: Text(theme)),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reinitialize Editors',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reinitializing editors...'),
                  duration: Duration(seconds: 2),
                ),
              );
              await _reinitializeEditors();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Editors reinitialized successfully!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save File',
            onPressed: _saveCodeToFile,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showHistory,
        backgroundColor: Colors.blue,
        tooltip: 'Show Prompt History',
        child: const Icon(Icons.history),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildPromptInputSection(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate responsive width for each editor
                    final availableWidth = constraints.maxWidth;
                    final margins =
                        (numberOfStudents - 1) * 8; // 4px margin on each side
                    final borders =
                        numberOfStudents * 4; // 2px border on each side
                    final editorWidth =
                        (availableWidth - margins - borders) / numberOfStudents;

                    // Minimum width to prevent editors from becoming too narrow
                    final minWidth = 300.0;
                    final useHorizontalScroll = editorWidth < minWidth;

                    // Calculate responsive width - always use horizontal scroll but with adaptive widths
                    final responsiveWidth =
                        useHorizontalScroll
                            ? minWidth
                            : (editorWidth - 8); // Account for margins

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < numberOfStudents; i++)
                              Container(
                                width: responsiveWidth,
                                height: constraints.maxHeight,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.5),
                                    width: 2,
                                  ), // More visible border
                                  borderRadius: BorderRadius.circular(8),
                                  color:
                                      Colors
                                          .grey[850], // Background color to make containers visible
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Column(
                                  key: ValueKey(
                                    'editor-column-${_monacoDivIds[i]}',
                                  ),
                                  children: [
                                    //Roll Number Header
                                    Container(
                                      height: 40, // Make header taller
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[700],
                                        border: const Border(
                                          bottom: BorderSide(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Editor ${i + 1} - Roll No: ${_editorRollNumbers[_monacoDivIds[i]] ?? 'N/A'}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16, // Larger font
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Refresh button right beside the roll number
                                            GestureDetector(
                                              onTap:
                                                  () => _regenerateRollNumber(
                                                    _monacoDivIds[i],
                                                  ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Icon(
                                                  Icons.refresh,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    //TabBar
                                    Container(
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        border: const Border(
                                          bottom: BorderSide(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children:
                                            TabType.values.map((tab) {
                                              final isActive =
                                                  _currentTabs[_monacoDivIds[i]] ==
                                                  tab;
                                              return Expanded(
                                                child: GestureDetector(
                                                  onTap:
                                                      () => _switchTab(
                                                        _monacoDivIds[i],
                                                        tab,
                                                      ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color:
                                                          isActive
                                                              ? Colors.blue[600]
                                                              : Colors
                                                                  .transparent,
                                                      border: Border(
                                                        right: BorderSide(
                                                          color:
                                                              Colors.grey[600]!,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        tab.name.toUpperCase(),
                                                        style: TextStyle(
                                                          color:
                                                              isActive
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .grey[300],
                                                          fontWeight:
                                                              isActive
                                                                  ? FontWeight
                                                                      .bold
                                                                  : FontWeight
                                                                      .normal,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),

                                    // Show keyboard above editor if selected
                                    if (_keyboardPositions[_monacoDivIds[i]] ==
                                        KeyboardPosition.aboveEditor)
                                      _buildKeyboard(i),

                                    // Editor section
                                    Builder(
                                      builder: (context) {
                                        final heights =
                                            _calculateDynamicHeights(
                                              constraints,
                                              i,
                                            );
                                        return SizedBox(
                                          key: ValueKey(
                                            'editor-expanded-${_monacoElementIds[i]}',
                                          ),
                                          height: heights['editor']!,
                                          child: Stack(
                                            key: ValueKey(
                                              'editor-stack-${_monacoElementIds[i]}',
                                            ),
                                            children: [
                                              ClipRect(
                                                child: HtmlElementView(
                                                  key: ValueKey(
                                                    _monacoElementIds[i],
                                                  ),
                                                  viewType:
                                                      _monacoElementIds[i],
                                                ),
                                              ),
                                              if (!_monacoInitialized)
                                                const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),

                                    // Show keyboard between editor and preview if selected and preview not expanded
                                    if (_keyboardPositions[_monacoDivIds[i]] ==
                                            KeyboardPosition
                                                .betweenEditorOutput &&
                                        _previewExpanded[_monacoDivIds[i]] !=
                                            true)
                                      _buildKeyboard(i),

                                    const Divider(
                                      height: 1,
                                      color: Colors.grey,
                                    ),
                                    // Unified expandable preview/output section
                                    Builder(
                                      builder: (context) {
                                        return Expanded(
                                          key: ValueKey(
                                            'preview-expanded-${_monacoElementIds[i]}',
                                          ),
                                          child: Container(
                                            key: ValueKey(
                                              'preview-container-${_monacoElementIds[i]}',
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  _showOutputInPreview[_monacoDivIds[i]] ==
                                                          true
                                                      ? Colors.grey[900]
                                                      : Colors.white,
                                              border: const Border(
                                                top: BorderSide(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                // Preview/Output header with controls
                                                Container(
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _showOutputInPreview[_monacoDivIds[i]] ==
                                                                true
                                                            ? Colors.grey[800]
                                                            : Colors.green[700],
                                                    border: const Border(
                                                      bottom: BorderSide(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const SizedBox(width: 8),
                                                      Icon(
                                                        _showOutputInPreview[_monacoDivIds[i]] ==
                                                                true
                                                            ? Icons.terminal
                                                            : Icons.preview,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          _showOutputInPreview[_monacoDivIds[i]] ==
                                                                  true
                                                              ? 'Output ${i + 1}'
                                                              : 'Live Preview',
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                              ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),

                                                      // Toggle between Preview and Output
                                                      IconButton(
                                                        icon: Icon(
                                                          _showOutputInPreview[_monacoDivIds[i]] ==
                                                                  true
                                                              ? Icons.preview
                                                              : Icons.terminal,
                                                          color: Colors.white,
                                                          size: 18,
                                                        ),
                                                        onPressed:
                                                            () => _toggleOutputInPreview(
                                                              _monacoDivIds[i],
                                                            ),
                                                        tooltip:
                                                            _showOutputInPreview[_monacoDivIds[i]] ==
                                                                    true
                                                                ? 'Switch to Preview'
                                                                : 'Switch to Output',
                                                        constraints:
                                                            const BoxConstraints(
                                                              minWidth: 36,
                                                              minHeight: 36,
                                                            ),
                                                      ),

                                                      // Show action buttons based on current mode
                                                      if (_showOutputInPreview[_monacoDivIds[i]] ==
                                                          true) ...[
                                                        // Output mode buttons
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.play_arrow,
                                                            color: Colors.white,
                                                            size: 18,
                                                          ),
                                                          onPressed: () {
                                                            final currentTab =
                                                                _currentTabs[_monacoDivIds[i]];
                                                            if (currentTab ==
                                                                TabType.html) {
                                                              _previewHTML(
                                                                _monacoDivIds[i],
                                                              );
                                                            } else {
                                                              _validateCode(
                                                                _monacoDivIds[i],
                                                                currentTab!,
                                                              );
                                                            }
                                                          },
                                                          tooltip:
                                                              _currentTabs[_monacoDivIds[i]] ==
                                                                      TabType
                                                                          .html
                                                                  ? 'Preview HTML'
                                                                  : 'Validate Code',
                                                          constraints:
                                                              const BoxConstraints(
                                                                minWidth: 36,
                                                                minHeight: 36,
                                                              ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.clear,
                                                            color: Colors.white,
                                                            size: 18,
                                                          ),
                                                          onPressed:
                                                              () => _clearOutput(
                                                                _monacoDivIds[i],
                                                              ),
                                                          tooltip:
                                                              'Clear Output',
                                                          constraints:
                                                              const BoxConstraints(
                                                                minWidth: 36,
                                                                minHeight: 36,
                                                              ),
                                                        ),
                                                      ] else ...[
                                                        // Preview mode buttons
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.refresh,
                                                            color: Colors.white,
                                                            size: 18,
                                                          ),
                                                          onPressed: () {
                                                            _updateLivePreview(
                                                              _monacoDivIds[i],
                                                            );
                                                          },
                                                          tooltip:
                                                              'Refresh Preview',
                                                          constraints:
                                                              const BoxConstraints(
                                                                minWidth: 36,
                                                                minHeight: 36,
                                                              ),
                                                        ),
                                                        // Arrow expand/collapse button beside Refresh button
                                                        IconButton(
                                                          icon: Icon(
                                                            _previewExpanded[_monacoDivIds[i]] ==
                                                                    true
                                                                ? Icons
                                                                    .keyboard_arrow_down
                                                                : Icons
                                                                    .keyboard_arrow_up,
                                                            color: Colors.white,
                                                            size: 18,
                                                          ),
                                                          onPressed:
                                                              () => _togglePreviewExpansion(
                                                                _monacoDivIds[i],
                                                              ),
                                                          tooltip:
                                                              _previewExpanded[_monacoDivIds[i]] ==
                                                                      true
                                                                  ? 'Collapse Preview'
                                                                  : 'Expand Preview',
                                                          constraints:
                                                              const BoxConstraints(
                                                                minWidth: 36,
                                                                minHeight: 36,
                                                              ),
                                                        ),
                                                        // Live preview toggle switch (smaller)
                                                        Tooltip(
                                                          message:
                                                              _livePreviewEnabled[_monacoDivIds[i]] ==
                                                                      true
                                                                  ? 'Live Preview: ON (Auto-update preview when typing)'
                                                                  : 'Live Preview: OFF (Manual refresh required)',
                                                          child: Transform.scale(
                                                            scale: 0.7,
                                                            child: Switch(
                                                              value:
                                                                  _livePreviewEnabled[_monacoDivIds[i]] ??
                                                                  true,
                                                              onChanged: (
                                                                value,
                                                              ) {
                                                                setState(() {
                                                                  _livePreviewEnabled[_monacoDivIds[i]] =
                                                                      value;
                                                                  if (value) {
                                                                    _updateLivePreview(
                                                                      _monacoDivIds[i],
                                                                    );
                                                                  }
                                                                });
                                                              },

                                                              thumbColor: MaterialStateProperty.resolveWith(
                                                                (states) =>
                                                                    states.contains(
                                                                          MaterialState
                                                                              .selected,
                                                                        )
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .grey[400],
                                                              ),
                                                              trackColor: MaterialStateProperty.resolveWith(
                                                                (states) =>
                                                                    states.contains(
                                                                          MaterialState
                                                                              .selected,
                                                                        )
                                                                        ? Colors
                                                                            .blue
                                                                        : Colors
                                                                            .grey[700],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                      const SizedBox(width: 8),
                                                    ],
                                                  ),
                                                ),

                                                // Content area - shows either preview or output based on toggle
                                                Expanded(
                                                  child:
                                                      _showOutputInPreview[_monacoDivIds[i]] ==
                                                              true
                                                          ? // Output content
                                                          Container(
                                                            color:
                                                                Colors
                                                                    .grey[900],
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  8.0,
                                                                ),
                                                            child: SingleChildScrollView(
                                                              child: SelectableText(
                                                                _editorOutputs[_monacoDivIds[i]]
                                                                            ?.isEmpty ??
                                                                        true
                                                                    ? 'Output will appear here...'
                                                                    : _editorOutputs[_monacoDivIds[i]] ??
                                                                        '',
                                                                style: TextStyle(
                                                                  color:
                                                                      (_editorOutputs[_monacoDivIds[i]] ??
                                                                                  '')
                                                                              .contains(
                                                                                'Error',
                                                                              )
                                                                          ? Colors
                                                                              .red
                                                                          : Colors
                                                                              .white,
                                                                  fontFamily:
                                                                      'monospace',
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                          : // Preview content
                                                          Container(
                                                            color: Colors.white,
                                                            child: ClipRect(
                                                              child: HtmlElementView(
                                                                key: ValueKey(
                                                                  _previewElementIds[i],
                                                                ),
                                                                viewType:
                                                                    _previewElementIds[i],
                                                              ),
                                                            ),
                                                          ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // History panel overlay - moved outside Column and directly inside Stack
          if (_showHistoryPanel)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.9,
                          maxHeight: constraints.maxHeight * 0.8,
                        ),
                        child: PromptHistoryWidget(
                          onPromptSelected: (String prompt) {
                            // Find the full PromptHistoryItem by prompt text
                            // This is a temporary workaround - ideally the widget should pass the full item
                            PromptHistoryService.getHistory().then((items) {
                              final item = items.firstWhere(
                                (item) => item.prompt == prompt,
                                orElse:
                                    () => PromptHistoryItem(
                                      id: '',
                                      prompt: prompt,
                                      timestamp: DateTime.now(),
                                      responses: [],
                                    ),
                              );
                              _loadPromptFromHistory(item);
                            });
                          },
                          onClose: _hideHistory,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    ); // Close the Scaffold
  }
}
