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
  });

  @override
  State<KeyboardToolbar> createState() => _KeyboardToolbarState();
}

class _KeyboardToolbarState extends State<KeyboardToolbar> {
  int _currentMode = 0; // 0: letters, 1: digits, 2: special chars
  bool _isUpperCase = false;

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

  final List<List<String>> _specialRows = [
    ['if', 'else', 'elif', 'for', 'while', 'def'],
    ['class', 'import', 'from', 'return', 'print', 'len'],
    ['True', 'False', 'None', 'and', 'or', 'not'],
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D30),
        border: const Border(top: BorderSide(color: Color(0xFF404040))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode selector row
          _buildModeSelector(),

          // Keyboard rows
          _buildKeyboardRows(),

          // Bottom action row
          _buildActionRow(),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.hardEdge,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModeButton('ABC', 0),
            const SizedBox(width: 8),
            _buildModeButton('123', 1),
            const SizedBox(width: 8),
            _buildModeButton('PY', 2),
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
        tooltip = 'PY - Python Symbols Mode';
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
    List<List<String>> currentRows;
    switch (_currentMode) {
      case 1:
        currentRows = _digitRows;
        break;
      case 2:
        currentRows = _specialRows;
        break;
      default:
        currentRows = _letterRows;
    }

    return Column(
      children: currentRows.map((row) => _buildKeyboardRow(row)).toList(),
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: keys.map((key) => _buildKey(key)).toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    String displayKey = key;
    if (_currentMode == 0 && _isUpperCase) {
      displayKey = key.toUpperCase();
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        child: GestureDetector(
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
              ),
            ),
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
        child: Row(
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
