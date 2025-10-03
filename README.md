# HTML Web IDE

<img width="495" height="470" alt="image" src="https://github.com/user-attachments/assets/90404559-a0ae-47a3-8e51-d342bc032a4f" />

## Keyboard Position Blank Screen Fix

When moving the custom keyboard toolbar between positions (above editor, between editor & output, below output) the web editor (Monaco inside `HtmlElementView`) previously went blank. This happened because inserting/removing the keyboard widget changed the child list structure in the Column, causing the underlying platform view to unmount on web.

The fix keeps a stable widget tree by reserving persistent slots (using `SizedBox.shrink()` when hidden) for all three possible keyboard positions. This prevents platform view re-creation and preserves editor state & visibility.

If further layout issues appear on very small heights, consider:

- Wrapping the entire editor column in a `LayoutBuilder` and adding min height constraints.
- Adding `MediaQuery.of(context).viewInsets.bottom` padding when running on mobile with an on-screen keyboard.
- Avoiding conditional removal of widgets that wrap `HtmlElementView`.
