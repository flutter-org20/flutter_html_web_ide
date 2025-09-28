# 🧪 Flutter HTML/CSS/JS IDE Testing Guide

## 🎯 **PROJECT OVERVIEW**

Your Flutter IDE has been successfully converted from Python/Pyodide to a 4-panel HTML/CSS/JavaScript web development environment.

## 🚀 **How to Run**

```bash
flutter run -d web-server --web-port 3000
# Access at: http://localhost:3000
```

## ✅ **CORE FEATURES TESTING CHECKLIST**

### **1. Tabbed Editor System**

- [ ] **HTML Tab Active**: Default tab shows HTML editor with syntax highlighting
- [ ] **CSS Tab**: Click CSS tab, editor shows CSS syntax highlighting
- [ ] **JavaScript Tab**: Click JS tab, editor shows JavaScript syntax highlighting
- [ ] **Tab Switching**: Content persists when switching between tabs
- [ ] **Content Changes**: Type in each tab, verify content is saved per tab

**Test Code Example:**

```html
<!-- HTML Tab -->
<h1>Hello World</h1>
<div class="container">Test</div>
```

```css
/* CSS Tab */
.container {
  color: blue;
  background: #f0f0f0;
}
```

```javascript
// JS Tab
console.log("Hello from JavaScript");
document.querySelector("h1").style.color = "red";
```

### **2. Live Preview System**

- [ ] **HTML Rendering**: HTML content appears in preview panel
- [ ] **CSS Styling**: CSS styles applied to HTML elements
- [ ] **JS Execution**: JavaScript runs and affects the preview
- [ ] **Real-time Updates**: Changes reflect immediately in preview
- [ ] **Error Console**: JavaScript errors appear in console section

**Test Workflow:**

1. Add HTML structure in HTML tab
2. Add styling in CSS tab → See visual changes
3. Add JavaScript in JS tab → See console output
4. Create intentional JS error → Check error display

### **3. AI Code Generation**

- [ ] **Simple Prompts**: "Create a button" → Generates HTML/CSS/JS
- [ ] **Targeted Prompts**: "Editor 1: Create navbar" → Updates correct editor
- [ ] **Complex Requests**: "Create responsive card layout" → Full implementation
- [ ] **Language Detection**: AI selects appropriate tab based on content
- [ ] **Response Parsing**: Generated code properly formatted

**Test Prompts:**

- "Create a responsive navigation bar"
- "Editor 2: Add a contact form with validation"
- "Build a todo list with JavaScript functionality"
- "Create a dark mode toggle button"

### **4. Keyboard Shortcuts & Toolbar**

- [ ] **Context Switching**: Toolbar changes based on active tab
- [ ] **HTML Shortcuts**: `<div>`, `<span>`, `<button>` buttons work
- [ ] **CSS Shortcuts**: Properties like `color:`, `background:` insert correctly
- [ ] **JS Shortcuts**: `function`, `console.log`, event handlers work
- [ ] **Smart Insertion**: Cursor positioned correctly after insertion

**Test Each Mode:**

1. **HTML Mode**: Test tag shortcuts, attributes
2. **CSS Mode**: Test property shortcuts, selectors
3. **JS Mode**: Test function shortcuts, DOM methods

### **5. File Operations**

- [ ] **Save Functionality**: Click save button downloads appropriate file
- [ ] **File Extensions**: HTML saves as .html, CSS as .css, JS as .js
- [ ] **Content Accuracy**: Downloaded content matches editor content
- [ ] **Multiple Editors**: Each editor saves its own content correctly

### **6. Code Examples**

- [ ] **Example Loading**: "Load Example" button shows example list
- [ ] **Example Application**: Selecting example loads content in appropriate tabs
- [ ] **Available Examples**:
  - Landing page
  - Dashboard
  - Game interface
  - Portfolio site
- [ ] **Content Distribution**: Examples load HTML, CSS, JS into correct tabs

### **7. Prompt History**

- [ ] **History Saving**: Successful AI generations saved to history
- [ ] **History Access**: History button opens prompt history panel
- [ ] **Prompt Reuse**: Clicking saved prompt loads and executes it
- [ ] **History Persistence**: History survives browser refresh
- [ ] **Search Function**: Can search through saved prompts

### **8. Multi-Editor System**

- [ ] **4 Editors**: All 4 editor panels visible and functional
- [ ] **Independent Tabs**: Each editor has its own HTML/CSS/JS tabs
- [ ] **Separate Content**: Content in each editor is independent
- [ ] **AI Targeting**: "Editor N:" syntax works for all editors
- [ ] **Preview Isolation**: Each editor has its own preview panel

### **9. Error Handling**

- [ ] **Network Errors**: AI service failures show error messages
- [ ] **JavaScript Errors**: Runtime errors displayed in console
- [ ] **Syntax Errors**: Invalid code doesn't break the editor
- [ ] **Empty Prompts**: Empty AI prompts show appropriate feedback
- [ ] **Recovery**: Errors don't crash the application

### **10. Theme & Appearance**

- [ ] **Dark Theme**: Code editor uses dark theme by default
- [ ] **Syntax Colors**: Different code elements properly highlighted
- [ ] **UI Consistency**: All panels follow the same design system
- [ ] **Responsive Layout**: Works on different screen sizes
- [ ] **Font Sizing**: Code is readable and well-sized

## 🔧 **PERFORMANCE TESTING**

### **Response Times**

- [ ] **Tab Switching**: < 100ms response time
- [ ] **AI Generation**: < 10s for simple requests
- [ ] **Preview Updates**: < 500ms for content changes
- [ ] **File Operations**: < 2s for save operations

### **Memory Usage**

- [ ] **Multiple Editors**: No memory leaks with 4 editors
- [ ] **Long Sessions**: Performance stable after extended use
- [ ] **Large Content**: Handles substantial code files
- [ ] **History Growth**: Performance doesn't degrade with large history

## 🐛 **KNOWN LIMITATIONS & WORKAROUNDS**

### **Expected Behaviors**

- **WebAssembly Warnings**: Normal - dart:html not WASM compatible
- **Monaco Editor**: Uses external CDN links (check network connectivity)
- **AI Rate Limits**: Pollinations.ai may have usage limits
- **Browser Security**: Some features require specific browser permissions

### **Troubleshooting**

1. **No Preview**: Check browser console for JavaScript errors
2. **AI Not Working**: Verify internet connection and API availability
3. **Syntax Highlighting**: Ensure all packages installed correctly
4. **File Downloads**: Check browser download settings

## 📋 **FINAL VALIDATION**

**Complete User Workflow Test:**

1. Open IDE → 4 panels visible with tabbed editors ✓
2. Create HTML structure → Preview shows content ✓
3. Add CSS styling → Visual changes appear ✓
4. Add JavaScript → Functionality works in preview ✓
5. Use AI to enhance → AI generates appropriate code ✓
6. Save work → Files download correctly ✓
7. Load example → Content populates properly ✓
8. Check history → Previous prompts accessible ✓

## 🎉 **SUCCESS CRITERIA**

**✅ CONVERSION SUCCESSFUL IF:**

- All 4 editor panels functional with HTML/CSS/JS tabs
- Live preview shows real-time updates
- AI generates appropriate web development code
- Keyboard shortcuts work for all three languages
- File operations work correctly
- Examples and history systems functional
- No critical compilation or runtime errors

## 📞 **Need Help?**

If any tests fail, check:

1. Browser developer console for JavaScript errors
2. Network tab for failed resource loads
3. Flutter debug console for Dart exceptions
4. Verify all dependencies in pubspec.yaml are installed

---

**🎯 Your IDE transformation from Python/Pyodide to HTML/CSS/JS is complete!**
