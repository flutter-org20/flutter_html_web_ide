# Keyboard Position Fix

## Issue

When changing keyboard positions (above editor, between editor/output, below output), the Monaco editor content would disappear, showing an empty screen instead of preserving the code content.

## Root Cause

The issue occurred because:

1. Widget tree restructuring during keyboard position changes caused Flutter to potentially lose track of Monaco editor platform views
2. Monaco editor content was not being preserved during layout changes
3. Lack of stable widget keys for keyboard containers

## Solution Implemented

### 1. Content Preservation

- Added `_saveCurrentEditorContent()` method to save content before keyboard position changes
- Added `_restoreEditorContent()` method to restore content after layout changes
- Enhanced `_handleMenuSelection()` to save/restore content during keyboard position changes

### 2. Stable Widget Keys

- Added stable `ValueKey` containers for all keyboard positions:
  - `'keyboard-above-${editorId}'` for above position
  - `'keyboard-between-${editorId}'` for between position
  - `'keyboard-below-${editorId}'` for below position
- This prevents Flutter from unnecessarily recreating widgets during layout changes

### 3. Enhanced Layout Verification

- Added `_verifyEditorsAfterLayoutChange()` method to check editor responsiveness
- Enhanced `_scheduleEditorLayoutRefresh()` to verify and restore content if needed
- Implemented multi-stage verification with timeouts

### 4. Robust Error Handling

- Added try-catch blocks around content save/restore operations
- Added console logging for debugging keyboard position changes
- Graceful fallback if content restoration fails

## Technical Details

### Key Files Modified

- `lib/ide_screen.dart`: Main implementation of content preservation and stable keys

### Key Methods Added/Enhanced

- `_saveCurrentEditorContent(String editorId)`: Saves content before layout change
- `_restoreEditorContent(String editorId)`: Restores content after layout change
- `_verifyEditorsAfterLayoutChange()`: Verifies editor state after changes
- Enhanced `_handleMenuSelection()`: Implements save/restore workflow
- Enhanced `_scheduleEditorLayoutRefresh()`: Added verification step

### Widget Key Strategy

```dart
Container(
  key: ValueKey('keyboard-above-${editorId}'),
  child: condition ? _buildKeyboard(i) : const SizedBox.shrink(),
)
```

## Testing

1. Start the application with multiple editors
2. Add content to editors
3. Change keyboard positions using the dropdown menu
4. Verify that editor content is preserved across all position changes
5. Test with all keyboard positions: above, between, below

## Future Improvements

- Consider implementing a more robust state management solution for Monaco editors
- Add unit tests for content preservation logic
- Monitor for any edge cases with rapid keyboard position changes
