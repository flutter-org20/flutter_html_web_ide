import 'package:flutter/material.dart';

class KeyboardToolbar extends StatefulWidget {
  final Function(String) onKeyPress;
  final VoidCallback onBackspace;
  final VoidCallback onEnter;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onArrowUp;
  final VoidCallback onArrowDown;
  final VoidCallback onArrowLeft;
  final VoidCallback onArrowRight;
  final VoidCallback onPrettify;
  final VoidCallback onToggleAutocomplete;
  final bool isAutocompleteEnabled;
  final bool isPrettifying; // Add prettifying state
  final Function(String, String)?
  onMenuSelection; // Updated to include editorId
  final String editorId; // Add editorId parameter
  final String currentTab; // Add current tab parameter

  const KeyboardToolbar({
    super.key,
    required this.onKeyPress,
    required this.onBackspace,
    required this.onEnter,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    required this.onArrowUp,
    required this.onArrowDown,
    required this.onArrowLeft,
    required this.onArrowRight,
    required this.onPrettify,
    required this.onToggleAutocomplete,
    required this.isAutocompleteEnabled,
    this.isPrettifying = false, // Default to false
    this.onMenuSelection, // Add this
    required this.editorId, // Add this as required
    this.currentTab = 'html', // Default to html tab
  });

  @override
  State<KeyboardToolbar> createState() => _KeyboardToolbarState();
}

class _KeyboardToolbarState extends State<KeyboardToolbar> {
  int _currentMode = 0; // 0: letters, 1: digits, 2: web (HTML/CSS/JS)
  bool _isUpperCase = false;

  // ScrollController instances for proper Scrollbar attachment
  late ScrollController _abcScrollController;
  late ScrollController _digitScrollController;
  late ScrollController _webScrollController;

  @override
  void initState() {
    super.initState();
    _abcScrollController = ScrollController();
    _digitScrollController = ScrollController();
    _webScrollController = ScrollController();

    // Add post-frame callback to ensure scroll controllers are properly attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScrollControllers();
    });
  }

  void _refreshScrollControllers() {
    // Force refresh of scroll controllers to fix inconsistent scrolling
    if (mounted) {
      setState(() {
        // Trigger rebuild with properly initialized controllers
      });
    }
  }

  @override
  void dispose() {
    _abcScrollController.dispose();
    _digitScrollController.dispose();
    _webScrollController.dispose();
    super.dispose();
  }

  final List<List<String>> _letterRows = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
  ];

  final List<List<String>> _digitRows = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['(', ')', '[', ']', '{', '}', '<', '>', '=', '!'],
    ['+', '-', '*', '/', '\\', '_', '.', ',', ':', ';'],
    ['"', "'", '@', '#', '%', '&', '|', '^', '?', '~'],
  ];

  // HTML-specific keyboard rows
  final List<List<String>> _htmlRows = [
    ['<div>', '<span>', '<p>', '<h1>', '<h2>', '<h3>'],
    ['<a>', '<img>', '<input>', '<button>', '<form>', '<table>'],
    ['<ul>', '<ol>', '<li>', '<head>', '<body>', '<html>'],
    ['<tr>', '<td>', '<th>', '<script>', '<style>', '<meta>'],
    ['class=', 'id=', 'src=', 'href=', 'alt=', 'title='],
    ['type=', 'value=', 'onclick=', 'onload=', 'style=', 'data-'],
  ];

  // CSS-specific keyboard rows
  final List<List<String>> _cssRows = [
    ['color:', 'background:', 'font-size:', 'margin:', 'padding:', 'width:'],
    ['height:', 'display:', 'position:', 'border:', 'flex:', 'grid:'],
    ['top:', 'left:', 'right:', 'bottom:', 'z-index:', 'opacity:'],
    [
      'text-align:',
      'font-weight:',
      'line-height:',
      'overflow:',
      'cursor:',
      'transform:',
    ],
    [
      'justify-content:',
      'align-items:',
      'flex-direction:',
      'gap:',
      'border-radius:',
      'box-shadow:',
    ],
    ['transition:', 'animation:', 'hover:', 'focus:', 'active:', 'before:'],
  ];

  // JS-specific keyboard rows
  final List<List<String>> _jsRows = [
    ['function', 'const', 'let', 'var', 'if', 'else'],
    ['for', 'while', 'return', 'break', 'continue', 'try'],
    ['catch', 'finally', 'true', 'false', 'null', 'undefined'],
    ['console.log', 'document.', 'window.', 'alert()', 'prompt()', 'confirm()'],
    [
      'getElementById',
      'querySelector',
      'addEventListener',
      'createElement',
      'appendChild',
      'innerHTML',
    ],
    ['textContent', 'className', 'style.', 'value', 'checked', 'disabled'],
  ];

  void _handleMenuSelection(String value) {
    // Call the parent widget's callback if provided
    widget.onMenuSelection?.call(value, widget.editorId);

    switch (value) {
      case 'above':
        print('Keyboard position: Above Editor');
        break;
      case 'between':
        print('Keyboard position: Between Editor and Output');
        break;
      case 'below':
        print('Keyboard position: Below Output');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Ensure we have valid constraints to work with
          final maxHeight =
              constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : MediaQuery.of(context).size.height * 0.4;
          final maxWidth =
              constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.of(context).size.width;

          return Container(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
              maxWidth: maxWidth,
              minHeight: 200, // Ensure minimum usable height
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D30),
              border: const Border(top: BorderSide(color: Color(0xFF404040))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mode selector row (fixed height)
                _buildModeSelector(),

                // Keyboard rows (flexible height with constraints)
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          maxHeight -
                          120, // Reserve space for mode selector and action row
                      minHeight: 100,
                    ),
                    child: _buildKeyboardRows(),
                  ),
                ),

                // Bottom action row (fixed height)
                _buildActionRow(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildModeButton('ABC', 0),
            const SizedBox(width: 8),
            _buildModeButton('123', 1),
            const SizedBox(width: 8),
            _buildModeButton('WEB', 2),
            const SizedBox(width: 8),

            // Prettify button
            _buildFeatureButton(
              icon: Icons.auto_fix_high,
              onPressed: widget.onPrettify,
              tooltip: 'Prettify - Format Code',
              color: Colors.purple,
              isToggled: widget.isPrettifying,
            ),
            const SizedBox(width: 4),

            // Autocomplete toggle button
            _buildFeatureButton(
              icon: Icons.auto_awesome,
              onPressed: widget.onToggleAutocomplete,
              tooltip:
                  widget.isAutocompleteEnabled
                      ? 'Autocomplete - Disable Suggestions'
                      : 'Autocomplete - Enable Suggestions',
              color: widget.isAutocompleteEnabled ? Colors.green : Colors.grey,
              isToggled: widget.isAutocompleteEnabled,
            ),
            const SizedBox(width: 8),

            _buildUndoRedoButton(
              icon: Icons.undo,
              onPressed: widget.canUndo ? widget.onUndo : null,
              tooltip: 'Undo - Revert Last Action',
            ),
            const SizedBox(width: 4),
            _buildUndoRedoButton(
              icon: Icons.redo,
              onPressed: widget.canRedo ? widget.onRedo : null,
              tooltip: 'Redo - Restore Last Action',
            ),
            const SizedBox(width: 8),
            if (_currentMode == 0) // Only show caps lock for letters
              _buildCapsButton(),
            _buildMenuButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF3C3C3C),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.more_vert, color: Colors.white70, size: 16),
      ),
      color: const Color(0xFF2D2D30),
      offset: const Offset(0, -120),
      onSelected: (String value) {
        // Handle menu selection
        _handleMenuSelection(value);
      },
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'above',
              child: ListTile(
                leading: Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.white70,
                  size: 20,
                ),
                title: Text(
                  'Above Editor',
                  style: TextStyle(color: Colors.white),
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'between',
              child: ListTile(
                leading: Icon(
                  Icons.keyboard_double_arrow_down,
                  color: Colors.white70,
                  size: 20,
                ),
                title: Text(
                  'Between Editor and Output',
                  style: TextStyle(color: Colors.white),
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'below',
              child: ListTile(
                leading: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white70,
                  size: 20,
                ),
                title: Text(
                  'Below Output',
                  style: TextStyle(color: Colors.white),
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
    );
  }

  Widget _buildUndoRedoButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
      ),
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 28,
          decoration: BoxDecoration(
            color:
                onPressed != null
                    ? const Color(0xFF3C3C3C)
                    : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color:
                  onPressed != null
                      ? const Color(0xFF505050)
                      : const Color(0xFF333333),
            ),
          ),
          child: Icon(
            icon,
            color: onPressed != null ? Colors.white70 : Colors.grey[600],
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required Color color,
    bool isToggled = false,
  }) {
    return Tooltip(
      message: tooltip,
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
      ),
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 28,
          decoration: BoxDecoration(
            color: isToggled ? color.withOpacity(0.2) : const Color(0xFF3C3C3C),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isToggled ? color : const Color(0xFF505050),
            ),
          ),
          child: Icon(
            icon,
            color: isToggled ? color : Colors.white70,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, int mode) {
    final bool isSelected = _currentMode == mode;

    // Define tooltips for each mode
    String tooltip;
    switch (mode) {
      case 0:
        tooltip = 'ABC - Letters Mode';
        break;
      case 1:
        tooltip = '123 - Numbers Mode';
        break;
      case 2:
        tooltip = 'WEB - HTML/CSS/JS Symbols Mode';
        break;
      default:
        tooltip = label;
    }

    return Tooltip(
      message: tooltip,
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
      ),
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: () => setState(() => _currentMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : const Color(0xFF3C3C3C),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCapsButton() {
    return Tooltip(
      message:
          _isUpperCase ? 'CAPS - Disable Uppercase' : 'CAPS - Enable Uppercase',
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
      ),
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: () => setState(() => _isUpperCase = !_isUpperCase),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _isUpperCase ? Colors.orange : const Color(0xFF3C3C3C),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.keyboard_capslock,
            color: _isUpperCase ? Colors.white : Colors.white70,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardRows() {
    // Calculate the intrinsic height needed for ABC keyboard (3 rows + padding)
    const double keyHeight = 35.0;
    const double verticalPadding =
        4.0; // 2 * 2 (top and bottom padding per row)
    const double abcKeyboardHeight =
        (keyHeight + verticalPadding) * 3; // 3 rows for ABC

    switch (_currentMode) {
      case 1: // 123 mode - constrained to ABC size with scrolling
        return SizedBox(
          key: const ValueKey('keyboard_123'), // Add key for proper rebuilding
          height: abcKeyboardHeight,
          child: _build123KeyboardWithScroll(),
        );
      case 2: // WEB mode - constrained to ABC size with scrolling
        return SizedBox(
          key: const ValueKey('keyboard_web'), // Add key for proper rebuilding
          height: abcKeyboardHeight,
          child: _buildWebKeyboardWithSections(),
        );
      default: // ABC mode - natural size (our reference size)
        return Container(
          key: const ValueKey('keyboard_abc'), // Add key for proper rebuilding
          child: _buildABCKeyboardWithScroll(),
        );
    }
  }

  Widget _buildWebKeyboardWithSections() {
    return Scrollbar(
      controller: _webScrollController,
      thumbVisibility: true,
      interactive: true,
      child: SingleChildScrollView(
        controller: _webScrollController,
        physics:
            const ClampingScrollPhysics(), // Changed from AlwaysScrollableScrollPhysics
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageSection('HTML', _htmlRows, Colors.orange),
            const SizedBox(height: 8),
            _buildLanguageSection('CSS', _cssRows, Colors.blue),
            const SizedBox(height: 8),
            _buildLanguageSection('JS', _jsRows, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(
    String title,
    List<List<String>> rows,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Icon(_getIconForLanguage(title), size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children:
                  rows.map((row) => _buildSystematicKeyboardRow(row)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForLanguage(String language) {
    switch (language) {
      case 'HTML':
        return Icons.language;
      case 'CSS':
        return Icons.palette;
      case 'JS':
        return Icons.code;
      default:
        return Icons.keyboard;
    }
  }

  Widget _buildABCKeyboardWithScroll() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children:
          _letterRows.map((row) => _buildSystematicKeyboardRow(row)).toList(),
    );
  }

  Widget _build123KeyboardWithScroll() {
    return Scrollbar(
      controller: _digitScrollController,
      thumbVisibility: true,
      interactive: true,
      child: SingleChildScrollView(
        controller: _digitScrollController,
        physics:
            const ClampingScrollPhysics(), // Changed from AlwaysScrollableScrollPhysics
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              _digitRows
                  .map((row) => _buildSystematicKeyboardRow(row))
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildSystematicKeyboardRow(List<String> keys) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            keys
                .map(
                  (key) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      child: _buildSystematicKey(key),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildSystematicKey(String key) {
    String displayKey = key;
    if (_currentMode == 0 && _isUpperCase) {
      displayKey = key.toUpperCase();
    }

    return GestureDetector(
      onTap: () => widget.onKeyPress(displayKey),
      child: Container(
        height: 35,
        decoration: BoxDecoration(
          color: const Color(0xFF3C3C3C),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF505050)),
        ),
        child: Center(
          child: Text(
            displayKey,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 30,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFF4C4C4C),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF505050)),
        ),
        child: Icon(icon, color: Colors.white70, size: 14),
      ),
    );
  }

  Widget _buildActionRow() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(), // Add consistent physics
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Add this to prevent unnecessary expansion
          children: [
            // Arrow Navigation Section
            SizedBox(
              width: 90,
              height: 35,
              child: Stack(
                children: [
                  // Up Arrow
                  Positioned(
                    top: 0,
                    left: 30,
                    child: _buildArrowButton(
                      Icons.keyboard_arrow_up,
                      widget.onArrowUp,
                    ),
                  ),
                  // Left Arrow
                  Positioned(
                    top: 15,
                    left: 0,
                    child: _buildArrowButton(
                      Icons.keyboard_arrow_left,
                      widget.onArrowLeft,
                    ),
                  ),
                  // Down Arrow
                  Positioned(
                    bottom: 0,
                    left: 30,
                    child: _buildArrowButton(
                      Icons.keyboard_arrow_down,
                      widget.onArrowDown,
                    ),
                  ),
                  // Right Arrow
                  Positioned(
                    top: 15,
                    left: 60,
                    child: _buildArrowButton(
                      Icons.keyboard_arrow_right,
                      widget.onArrowRight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Space bar
            SizedBox(
              width: 120,
              child: GestureDetector(
                onTap: () => widget.onKeyPress(' '),
                child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4C4C4C),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text(
                      'Space',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Backspace
            GestureDetector(
              onTap: widget.onBackspace,
              child: Container(
                width: 50,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFF5C5C5C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.backspace_outlined,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Enter
            GestureDetector(
              onTap: widget.onEnter,
              child: Container(
                width: 50,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.keyboard_return,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
