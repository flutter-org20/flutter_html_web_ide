// --- Globals ---
let monacoEditors = {}; // Object to store editor instances
let pyodide;
let monacoLoaded = false;
let monacoLoadPromise = null;

// Helper function to clean common invalid characters from code
function sanitizeCode(code) {
  // Replaces non-breaking spaces and other problematic characters
  return code.replace(/\u00A0/g, " ").replace(/\u2028/g, "\n").replace(/\u2029/g, "\n");
}

// --- Helper function to format code using Black in Pyodide ---
async function formatPythonCodeWithBlack(code) {
  if (!pyodide) {
    console.error("Pyodide not loaded, cannot format.");
    throw new Error("Pyodide not loaded");
  }

  const sanitizedCode = sanitizeCode(code);

  try {
    // Pass the code to the Python environment
    pyodide.globals.set("unformatted_code", sanitizedCode);

    // Let Pyodide handle exceptions. If this fails, the promise will reject
    // and be caught by the JavaScript 'catch' block.
    const formattedCode = await pyodide.runPythonAsync(`
import black

# Get the code from the global scope
source_code = unformatted_code

# Configure black's formatting mode
mode = black.FileMode(line_length=88, string_normalization=True)

# Format the string. This will raise an exception on invalid syntax.
black.format_str(source_code, mode=mode)
    `);

    return formattedCode;
  } catch (err) {
    // This will now catch Python exceptions directly!
    console.error("Error during Pyodide formatting execution:", err);
    throw err; // Re-throw to be caught by the Monaco format provider
  }
}

// Function to initialize Monaco only once
function loadMonaco() {
  if (!monacoLoadPromise) {
    monacoLoadPromise = new Promise((resolve) => {
      require.config({
        paths: { 'vs': 'https://unpkg.com/monaco-editor@0.41.0/min/vs' }
      });

      require(['vs/editor/editor.main'], () => {
        monacoLoaded = true;
        resolve();
      });
    });
  }
  return monacoLoadPromise;
}

console.log('Monaco Interop JavaScript loaded');

// Pre-define Python suggestions for faster lookup (defined once globally)
const pythonSuggestions = [
  // Keywords
  { label: 'def', kind: 14, insertText: 'def ${1:function_name}(${2:parameters}):\n    ${3:pass}', insertTextRules: 4 },
  { label: 'class', kind: 14, insertText: 'class ${1:ClassName}:\n    def __init__(self${2:, args}):\n        ${3:pass}', insertTextRules: 4 },
  { label: 'if', kind: 14, insertText: 'if ${1:condition}:\n    ${2:pass}', insertTextRules: 4 },
  { label: 'elif', kind: 14, insertText: 'elif ${1:condition}:\n    ${2:pass}', insertTextRules: 4 },
  { label: 'else', kind: 14, insertText: 'else:\n    ${1:pass}', insertTextRules: 4 },
  { label: 'for', kind: 14, insertText: 'for ${1:item} in ${2:iterable}:\n    ${3:pass}', insertTextRules: 4 },
  { label: 'while', kind: 14, insertText: 'while ${1:condition}:\n    ${2:pass}', insertTextRules: 4 },
  { label: 'try', kind: 14, insertText: 'try:\n    ${1:pass}\nexcept ${2:Exception} as ${3:e}:\n    ${4:pass}', insertTextRules: 4 },
  { label: 'except', kind: 14, insertText: 'except ${1:Exception} as ${2:e}:\n    ${3:pass}', insertTextRules: 4 },
  { label: 'finally', kind: 14, insertText: 'finally:\n    ${1:pass}', insertTextRules: 4 },
  { label: 'with', kind: 14, insertText: 'with ${1:expression} as ${2:variable}:\n    ${3:pass}', insertTextRules: 4 },
  { label: 'import', kind: 14, insertText: 'import ${1:module}', insertTextRules: 4 },
  { label: 'from', kind: 14, insertText: 'from ${1:module} import ${2:name}', insertTextRules: 4 },
  { label: 'return', kind: 14, insertText: 'return ${1:value}', insertTextRules: 4 },
  { label: 'yield', kind: 14, insertText: 'yield ${1:value}', insertTextRules: 4 },
  { label: 'break', kind: 14, insertText: 'break' },
  { label: 'continue', kind: 14, insertText: 'continue' },
  { label: 'pass', kind: 14, insertText: 'pass' },
  { label: 'lambda', kind: 14, insertText: 'lambda ${1:args}: ${2:expression}', insertTextRules: 4 },
  { label: 'async', kind: 14, insertText: 'async def ${1:function_name}(${2:parameters}):\n    ${3:pass}', insertTextRules: 4 },
  { label: 'await', kind: 14, insertText: 'await ${1:expression}', insertTextRules: 4 },
  { label: 'global', kind: 14, insertText: 'global ${1:variable}', insertTextRules: 4 },
  { label: 'nonlocal', kind: 14, insertText: 'nonlocal ${1:variable}', insertTextRules: 4 },
  { label: 'raise', kind: 14, insertText: 'raise ${1:Exception}', insertTextRules: 4 },
  { label: 'assert', kind: 14, insertText: 'assert ${1:condition}', insertTextRules: 4 },
  { label: 'del', kind: 14, insertText: 'del ${1:variable}', insertTextRules: 4 },
  
  // Additional 'p' keywords and decorators
  { label: 'property', kind: 10, insertText: '@property\ndef ${1:name}(self):\n    return ${2:value}', insertTextRules: 4 },
  { label: 'partial', kind: 3, insertText: 'partial(${1:func}, ${2:args})', insertTextRules: 4 },
  { label: 'pathlib', kind: 9, insertText: 'from pathlib import Path', insertTextRules: 4 },
  
  // Built-in functions
  { label: 'print', kind: 3, insertText: 'print(${1:value})', insertTextRules: 4 },
  { label: 'len', kind: 3, insertText: 'len(${1:obj})', insertTextRules: 4 },
  { label: 'range', kind: 3, insertText: 'range(${1:stop})', insertTextRules: 4 },
  { label: 'enumerate', kind: 3, insertText: 'enumerate(${1:iterable})', insertTextRules: 4 },
  { label: 'zip', kind: 3, insertText: 'zip(${1:iterable1}, ${2:iterable2})', insertTextRules: 4 },
  { label: 'map', kind: 3, insertText: 'map(${1:function}, ${2:iterable})', insertTextRules: 4 },
  { label: 'filter', kind: 3, insertText: 'filter(${1:function}, ${2:iterable})', insertTextRules: 4 },
  { label: 'sorted', kind: 3, insertText: 'sorted(${1:iterable})', insertTextRules: 4 },
  { label: 'sum', kind: 3, insertText: 'sum(${1:iterable})', insertTextRules: 4 },
  { label: 'max', kind: 3, insertText: 'max(${1:iterable})', insertTextRules: 4 },
  { label: 'min', kind: 3, insertText: 'min(${1:iterable})', insertTextRules: 4 },
  { label: 'abs', kind: 3, insertText: 'abs(${1:number})', insertTextRules: 4 },
  { label: 'round', kind: 3, insertText: 'round(${1:number})', insertTextRules: 4 },
  { label: 'input', kind: 3, insertText: 'input(${1:prompt})', insertTextRules: 4 },
  { label: 'open', kind: 3, insertText: 'open(${1:filename}, ${2:mode})', insertTextRules: 4 },
  { label: 'type', kind: 3, insertText: 'type(${1:obj})', insertTextRules: 4 },
  { label: 'isinstance', kind: 3, insertText: 'isinstance(${1:obj}, ${2:type})', insertTextRules: 4 },
  { label: 'hasattr', kind: 3, insertText: 'hasattr(${1:obj}, ${2:attr})', insertTextRules: 4 },
  { label: 'getattr', kind: 3, insertText: 'getattr(${1:obj}, ${2:attr})', insertTextRules: 4 },
  { label: 'setattr', kind: 3, insertText: 'setattr(${1:obj}, ${2:attr}, ${3:value})', insertTextRules: 4 },
  { label: 'pow', kind: 3, insertText: 'pow(${1:base}, ${2:exp})', insertTextRules: 4 },
  
  // Built-in types
  { label: 'str', kind: 7, insertText: 'str(${1:obj})', insertTextRules: 4 },
  { label: 'int', kind: 7, insertText: 'int(${1:obj})', insertTextRules: 4 },
  { label: 'float', kind: 7, insertText: 'float(${1:obj})', insertTextRules: 4 },
  { label: 'bool', kind: 7, insertText: 'bool(${1:obj})', insertTextRules: 4 },
  { label: 'list', kind: 7, insertText: 'list(${1:iterable})', insertTextRules: 4 },
  { label: 'tuple', kind: 7, insertText: 'tuple(${1:iterable})', insertTextRules: 4 },
  { label: 'dict', kind: 7, insertText: 'dict(${1:mapping})', insertTextRules: 4 },
  { label: 'set', kind: 7, insertText: 'set(${1:iterable})', insertTextRules: 4 },
  
  // Constants
  { label: 'True', kind: 21, insertText: 'True' },
  { label: 'False', kind: 21, insertText: 'False' },
  { label: 'None', kind: 21, insertText: 'None' },
  
  // Magic methods
  { label: '__init__', kind: 2, insertText: 'def __init__(self${1:, args}):\n    ${2:pass}', insertTextRules: 4 },
  { label: '__str__', kind: 2, insertText: 'def __str__(self):\n    return ${1:"string representation"}', insertTextRules: 4 },
  { label: '__repr__', kind: 2, insertText: 'def __repr__(self):\n    return ${1:"repr string"}', insertTextRules: 4 },
  { label: '__len__', kind: 2, insertText: 'def __len__(self):\n    return ${1:length}', insertTextRules: 4 }
];

// Global flag to ensure completion provider is registered only once
let pythonCompletionProviderRegistered = false;

// Register Python completion provider globally (only once)
function registerPythonCompletionProvider() {
  if (pythonCompletionProviderRegistered || !window.monaco) {
    return;
  }
  
  monaco.languages.registerCompletionItemProvider('python', {
    provideCompletionItems: function(model, position) {
      console.log('Completion provider called at position:', position);
      
      const word = model.getWordUntilPosition(position);
      const range = {
        startLineNumber: position.lineNumber,
        endLineNumber: position.lineNumber,
        startColumn: word.startColumn,
        endColumn: word.endColumn
      };

      // Get the partial word being typed (convert to lowercase for case-insensitive matching)
      const partialWord = word.word.toLowerCase();
      console.log('Partial word:', partialWord);

      // Quick return for empty input - show all suggestions
      if (partialWord === '') {
        console.log('Returning all suggestions');
        return { 
          suggestions: pythonSuggestions.map(s => ({...s, range}))
        };
      }

      // Fast filtering using built-in array methods
      const filteredSuggestions = pythonSuggestions
        .filter(suggestion => suggestion.label.toLowerCase().startsWith(partialWord))
        .map(suggestion => ({...suggestion, range}));

      console.log('Filtered suggestions:', filteredSuggestions.length);
      return { suggestions: filteredSuggestions };
    }
  });
  
  pythonCompletionProviderRegistered = true;
  console.log('Python completion provider registered');
}

// --- Monaco Interop ---
window.monacoInterop = {
  init: async (containerId, initialCode, theme, fontSize, onContentChanged, language = 'python') => {
    console.log('Monaco init called for:', containerId);
    try {
      // Check if DOM element exists
      const container = document.getElementById(containerId);
      if (!container) {
        throw new Error(`DOM element with ID '${containerId}' not found`);
      }
      console.log('DOM element found for:', containerId);

      // Ensure Monaco is loaded first
      if (!monacoLoaded) {
        await loadMonaco();
      }

      const editor = monaco.editor.create(container, language, {
        value: initialCode,
        language: language,
        theme: theme,
        fontSize: fontSize,
        automaticLayout: true,
        formatOnPaste: true,
        formatOnType: false,
        wordWrap: 'on',
        minimap: { enabled: false },
        scrollBeyondLastLine: false,
        renderLineHighlight: 'line',
        selectOnLineNumbers: true,
        // Enhanced autocomplete settings for instant response
        quickSuggestions: true, // Enable for all contexts
        quickSuggestionsDelay: 0, // Instant suggestions
        suggestOnTriggerCharacters: true,
        acceptSuggestionOnCommitCharacter: true,
        acceptSuggestionOnEnter: 'on',
        wordBasedSuggestions: false, // Disable default word-based suggestions to prevent duplicates
        tabCompletion: 'on',
        parameterHints: { 
          enabled: true,
          cycle: true
        },
        suggest: {
          showKeywords: true,
          showSnippets: true,
          showFunctions: true,
          showConstructors: true,
          showFields: true,
          showVariables: true,
          showClasses: true,
          showStructs: true,
          showInterfaces: true,
          showModules: true,
          showProperties: true,
          showEvents: true,
          showOperators: true,
          showUnits: true,
          showValues: true,
          showConstants: true,
          showEnums: true,
          showEnumMembers: true,
          showWords: false, // Disable word suggestions to avoid duplicates
          showColors: true,
          showFiles: true,
          showReferences: true,
          showFolders: true,
          showTypeParameters: true,
          filterGraceful: true,
          snippetsPreventQuickSuggestions: false,
          insertMode: 'insert',
          localityBonus: true,
          delay: 0, // No delay for suggestions
          maxVisibleSuggestions: 12 // Show more suggestions
        },
        // Disable system keyboard on mobile
        readOnly: false,
        contextmenu: false,
        // Prevent virtual keyboard on mobile
        'semanticHighlighting.enabled': false
      });

      // Store the editor instance
      monacoEditors[containerId] = editor;

      // Register the Python completion provider globally (only once)
      registerPythonCompletionProvider();

      // Prevent system keyboard on mobile devices
      const editorDomNode = editor.getDomNode();
      if (editorDomNode) {
        // Prevent focus events that trigger system keyboard
        editorDomNode.addEventListener('touchstart', (e) => {
          e.preventDefault();
          e.stopPropagation();
        }, { passive: false });
        
        editorDomNode.addEventListener('touchend', (e) => {
          e.preventDefault();
          e.stopPropagation();
        }, { passive: false });

        // Prevent input focus
        const textArea = editorDomNode.querySelector('textarea');
        if (textArea) {
          textArea.setAttribute('readonly', 'readonly');
          textArea.setAttribute('inputmode', 'none');
          textArea.style.caretColor = 'transparent';
          
          // Remove readonly when we want to programmatically set content
          const originalSetValue = editor.setValue.bind(editor);
          editor.setValue = function(value) {
            textArea.removeAttribute('readonly');
            originalSetValue(value);
            textArea.setAttribute('readonly', 'readonly');
          };
        }
      }

      // Set up content change listener
      editor.onDidChangeModelContent((e) => {
        onContentChanged(editor.getValue());
        
        // Manually trigger suggestions on content change for better responsiveness
        const position = editor.getPosition();
        if (position) {
          const model = editor.getModel();
          const word = model.getWordUntilPosition(position);
          
          // Trigger suggestions if user is typing a word (not deleting or just whitespace)
          if (word.word.length > 0 && e.changes.some(change => change.text.length > 0)) {
            setTimeout(() => {
              editor.trigger('keyboard', 'editor.action.triggerSuggest', {});
            }, 10);
          }
        }
      });

      return editor;
    } catch (error) {
      console.error('Error creating Monaco editor:', error);
      throw error;
    }
  },

  getValue: (containerId) => {
    const editor = monacoEditors[containerId];
    return editor ? editor.getValue() : '';
  },

  setValue: (containerId, content) => {
    const editor = monacoEditors[containerId];
    if (editor) {
      editor.setValue(content);
    }
  },

  updateOptions: (containerId, theme, fontSize) => {
    const editor = monacoEditors[containerId];
    if (editor) {
      editor.updateOptions({ theme, fontSize });
    }
  },

  formatDocument: (containerId) => {
    const editor = monacoEditors[containerId];
    if (editor) {
      try {
        // For Python, implement proper indentation that fixes bad indentation
        const model = editor.getModel();
        const value = model.getValue();
        
        // Split into lines and fix indentation
        const lines = value.split('\n');
        const formattedLines = [];
        let currentIndentLevel = 0;
        
        for (let i = 0; i < lines.length; i++) {
          const line = lines[i];
          const trimmedLine = line.trim();
          
          // Skip empty lines - preserve them as is
          if (trimmedLine === '') {
            formattedLines.push('');
            continue;
          }
          
          // Check if this line should decrease indentation
          if (trimmedLine.match(/^(except|elif|else|finally):/)) {
            currentIndentLevel = Math.max(0, currentIndentLevel - 1);
          }
          
          // Determine if this should be at top level (unindented)
          // Top level: function definitions, class definitions, imports, top-level statements that don't follow a colon
          let shouldBeTopLevel = false;
          
          if (i === 0) {
            // First line is always top level
            shouldBeTopLevel = true;
          } else {
            // Check if this looks like a top-level statement
            if (trimmedLine.match(/^(def |class |import |from |if __name__|#|@)/)) {
              shouldBeTopLevel = true;
              currentIndentLevel = 0;
            } else {
              // Look back to see if we're following a function/class definition or other top-level code
              let foundTopLevelContext = false;
              for (let j = i - 1; j >= 0; j--) {
                const prevLine = lines[j].trim();
                if (prevLine === '') continue; // Skip empty lines
                
                // If previous line was a function/class definition, we should be indented
                if (prevLine.match(/^(def |class |if |for |while |try:|with |except|elif|else:)/)) {
                  foundTopLevelContext = false;
                  break;
                }
                
                // If previous line was clearly top-level, and this line doesn't look like it should be indented
                if (prevLine.match(/^(import |from |#|@)/) || 
                    (!prevLine.endsWith(':') && !prevLine.match(/^(def |class |if |for |while |try:|with )/))) {
                  // Check if current line looks like it should be top-level
                  if (trimmedLine.match(/^(print|[a-zA-Z_][a-zA-Z0-9_]*\s*=|[a-zA-Z_][a-zA-Z0-9_]*\()/)) {
                    foundTopLevelContext = true;
                  }
                  break;
                }
                break;
              }
              
              if (foundTopLevelContext) {
                shouldBeTopLevel = true;
                currentIndentLevel = 0;
              }
            }
          }
          
          // Apply indentation
          if (shouldBeTopLevel) {
            formattedLines.push(trimmedLine);
            currentIndentLevel = 0;
          } else {
            // Use current indent level
            formattedLines.push('    '.repeat(currentIndentLevel) + trimmedLine);
          }
          
          // Increase indent for lines ending with ':' (but not comments)
          if (trimmedLine.endsWith(':') && !trimmedLine.trimStart().startsWith('#')) {
            currentIndentLevel++;
          }
        }
        
        // Set the formatted code back to the editor
        model.setValue(formattedLines.join('\n'));
      } catch (error) {
        console.log('Python formatting failed, using Monaco default:', error);
        // Fallback to Monaco's built-in formatter
        try {
          editor.getAction('editor.action.formatDocument').run();
        } catch (fallbackError) {
          console.log('Monaco formatter also failed:', fallbackError);
        }
      }
    }
  },

  selectAll: (containerId) => {
    const editor = monacoEditors[containerId];
    if (editor) {
      editor.setSelection(editor.getModel().getFullModelRange());
    }
  },

  insertText: (containerId, text) => {
    const editor = monacoEditors[containerId];
    if (editor) {
      editor.trigger('keyboard', 'type', { text });
    }
  },

  copySelection: (containerId) => {
    const editor = monacoEditors[containerId];
    if (editor) {
      const selection = editor.getSelection();
      const text = editor.getModel().getValueInRange(selection);
      navigator.clipboard.writeText(text);
    }
  },

  setAutocomplete: (containerId, enabled) => {
    const editor = monacoEditors[containerId];
    if (editor) {
      editor.updateOptions({
        quickSuggestions: enabled ? {
          other: true,
          comments: false,
          strings: false
        } : false,
        quickSuggestionsDelay: 0, // Instant suggestions
        suggestOnTriggerCharacters: enabled,
        acceptSuggestionOnCommitCharacter: enabled,
        acceptSuggestionOnEnter: enabled ? 'on' : 'off',
        wordBasedSuggestions: enabled,
        parameterHints: { 
          enabled: enabled,
          cycle: enabled
        },
        suggest: {
          showKeywords: enabled,
          showSnippets: enabled,
          showFunctions: enabled,
          showConstructors: enabled,
          showFields: enabled,
          showVariables: enabled,
          showClasses: enabled,
          showStructs: enabled,
          showInterfaces: enabled,
          showModules: enabled,
          showProperties: enabled,
          showEvents: enabled,
          showOperators: enabled,
          showUnits: enabled,
          showValues: enabled,
          showConstants: enabled,
          showEnums: enabled,
          showEnumMembers: enabled,
          showWords: enabled,
          showColors: enabled,
          showFiles: enabled,
          showReferences: enabled,
          showFolders: enabled,
          showTypeParameters: enabled,
          filterGraceful: enabled,
          snippetsPreventQuickSuggestions: false,
          insertMode: 'insert',
          localityBonus: enabled,
          delay: 0, // No delay for suggestions
          maxVisibleSuggestions: 12 // Show more suggestions
        }
      });
      
      // Trigger suggestions to show immediately when enabling
      if (enabled) {
        editor.trigger('keyboard', 'editor.action.triggerSuggest', {});
      }
    }
  },

  // Manual trigger for autocomplete suggestions
  triggerAutocomplete: (containerId) => {
    const editor = monacoEditors[containerId];
    if (editor) {
      editor.trigger('keyboard', 'editor.action.triggerSuggest', {});
    }
  },

  // Set language for Monaco editor
  setLanguage: (containerId, language) => {
    console.log(`Setting language to ${language} for ${containerId}`);
    const editor = monacoEditors[containerId];
    if (editor && monaco) {
      try {
        const model = editor.getModel();
        if (model) {
          monaco.editor.setModelLanguage(model, language);
          console.log(`Language successfully set to ${language} for ${containerId}`);
        } else {
          console.warn(`No model found for editor ${containerId}`);
        }
      } catch (error) {
        console.error(`Error setting language for ${containerId}:`, error);
      }
    } else {
      console.warn(`Editor ${containerId} or Monaco not available`);
    }
  }
};

window.destroyMonacoEditor = function(elementId) {
  if(monacoEditors && monacoEditors[elementId]) {
    // Dispose the Monaco editor
    monacoEditors[elementId].dispose();
    delete monacoEditors[elementId];
    
    // Also clear the DOM container
    const container = document.getElementById(elementId);
    if (container) {
      container.innerHTML = '';
    }
  }
}

window.insertTextAtCursor = function(editorId, text) {
  const editor = monacoEditors[editorId];
  if (editor) {
    const selection = editor.getSelection();
    const range = new monaco.Range(
      selection.startLineNumber,
      selection.startColumn,
      selection.endLineNumber,
      selection.endColumn
    );
    editor.executeEdits('keyboard-input', [{
      range: range,
      text: text
    }]);
    editor.focus();
  }
};

window.deleteCharacterBeforeCursor = function(editorId) {
  const editor = monacoEditors[editorId];
  if (editor) {
    const position = editor.getPosition();
    if (position.column > 1) {
      const range = new monaco.Range(
        position.lineNumber,
        position.column - 1,
        position.lineNumber,
        position.column
      );
      editor.executeEdits('backspace', [{
        range: range,
        text: ''
      }]);
    } else if (position.lineNumber > 1) {
      // Handle backspace at beginning of line
      const model = editor.getModel();
      const prevLineLength = model.getLineLength(position.lineNumber - 1);
      const range = new monaco.Range(
        position.lineNumber - 1,
        prevLineLength + 1,
        position.lineNumber,
        1
      );
      editor.executeEdits('backspace', [{
        range: range,
        text: ''
      }]);
    }
    editor.focus();
  }
};

window.moveCursor = function(editorId, direction) {
  const editor = monacoEditors[editorId];
  if (editor) {
    const position = editor.getPosition();
    let newPosition;
    
    switch(direction) {
      case 'up':
        newPosition = { lineNumber: Math.max(1, position.lineNumber - 1), column: position.column };
        break;
      case 'down':
        const lineCount = editor.getModel().getLineCount();
        newPosition = { lineNumber: Math.min(lineCount, position.lineNumber + 1), column: position.column };
        break;
      case 'left':
        if (position.column > 1) {
          newPosition = { lineNumber: position.lineNumber, column: position.column - 1 };
        } else if (position.lineNumber > 1) {
          const prevLineLength = editor.getModel().getLineLength(position.lineNumber - 1);
          newPosition = { lineNumber: position.lineNumber - 1, column: prevLineLength + 1 };
        } else {
          newPosition = position;
        }
        break;
      case 'right':
        const currentLineLength = editor.getModel().getLineLength(position.lineNumber);
        if (position.column <= currentLineLength) {
          newPosition = { lineNumber: position.lineNumber, column: position.column + 1 };
        } else {
          const lineCount = editor.getModel().getLineCount();
          if (position.lineNumber < lineCount) {
            newPosition = { lineNumber: position.lineNumber + 1, column: 1 };
          } else {
            newPosition = position;
          }
        }
        break;
      default:
        newPosition = position;
    }
    
    editor.setPosition(newPosition);
    editor.focus();
  }
};
// --- Pyodide Interop ---
window.pyodideInterop = {
  init: (onOutput) => {
    return new Promise(async (resolve, reject) => {
      try {
        console.log('Loading Pyodide...');
        pyodide = await loadPyodide();
        
        // Set up proper output redirection using the modern Pyodide API
        pyodide.setStdout({
          batched: (text) => {
            console.log('Python output:', text);
            onOutput(text);
          }
        });
        
        pyodide.setStderr({
          batched: (text) => {
            console.error('Python error:', text);
            onOutput(text);
          }
        });

        console.log('Installing basic packages...');
        // Only load essential packages, skip black for now
        await pyodide.loadPackage(['micropip']);
        
        console.log('Pyodide ready for Python execution!');
        resolve('Pyodide initialized successfully!');
      } catch (err) {
        console.error('Error initializing Pyodide:', err);
        reject(err.toString());
      }
    });
  },

  runCode: async (code) => {
    if (!pyodide) {
      throw new Error('Pyodide not initialized');
    }

    try {
      await pyodide.runPythonAsync(code);
      return null; // No error
    } catch (err) {
      return err.message; // Return error message
    }
  }
};

// Additional mobile keyboard prevention
window.disableSystemKeyboard = function() {
  // Disable system keyboard globally on mobile
  document.addEventListener('touchstart', function(e) {
    if (e.target.tagName === 'TEXTAREA' || e.target.tagName === 'INPUT') {
      e.target.setAttribute('readonly', 'readonly');
      e.target.setAttribute('inputmode', 'none');
    }
  });
  
  // Prevent zoom on input focus (mobile Safari)
  document.addEventListener('touchend', function(e) {
    if (e.target.tagName === 'TEXTAREA' || e.target.tagName === 'INPUT') {
      e.target.blur();
    }
  });
};

// Auto-disable on mobile devices
if (/Android|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)) {
  window.disableSystemKeyboard();
}

console.log('monacoInterop object created:', window.monacoInterop);
console.log('pyodideInterop object created:', window.pyodideInterop);