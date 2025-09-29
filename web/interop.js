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

// Web development suggestions for HTML, CSS, and JavaScript
const htmlSuggestions = [
  // HTML Tags
  { label: 'div', kind: 25, insertText: '<div>${1}>${2}</div>', insertTextRules: 4 },
  { label: 'span', kind: 25, insertText: '<span>${1}>${2}</span>', insertTextRules: 4 },
  { label: 'p', kind: 25, insertText: '<p>${1}</p>', insertTextRules: 4 },
  { label: 'h1', kind: 25, insertText: '<h1>${1}</h1>', insertTextRules: 4 },
  { label: 'h2', kind: 25, insertText: '<h2>${1}</h2>', insertTextRules: 4 },
  { label: 'h3', kind: 25, insertText: '<h3>${1}</h3>', insertTextRules: 4 },
  { label: 'a', kind: 25, insertText: '<a href="${1}">${2}</a>', insertTextRules: 4 },
  { label: 'img', kind: 25, insertText: '<img src="${1}" alt="${2}">', insertTextRules: 4 },
  { label: 'input', kind: 25, insertText: '<input type="${1}" value="${2}">', insertTextRules: 4 },
  { label: 'button', kind: 25, insertText: '<button>${1}</button>', insertTextRules: 4 },
  { label: 'form', kind: 25, insertText: '<form>${1}</form>', insertTextRules: 4 },
  { label: 'ul', kind: 25, insertText: '<ul>\n  <li>${1}</li>\n</ul>', insertTextRules: 4 },
  { label: 'ol', kind: 25, insertText: '<ol>\n  <li>${1}</li>\n</ol>', insertTextRules: 4 },
  { label: 'li', kind: 25, insertText: '<li>${1}</li>', insertTextRules: 4 },
  { label: 'table', kind: 25, insertText: '<table>\n  <tr>\n    <td>${1}</td>\n  </tr>\n</table>', insertTextRules: 4 },
  { label: 'tr', kind: 25, insertText: '<tr>${1}</tr>', insertTextRules: 4 },
  { label: 'td', kind: 25, insertText: '<td>${1}</td>', insertTextRules: 4 },
  { label: 'th', kind: 25, insertText: '<th>${1}</th>', insertTextRules: 4 },
  { label: 'head', kind: 25, insertText: '<head>${1}</head>', insertTextRules: 4 },
  { label: 'body', kind: 25, insertText: '<body>${1}</body>', insertTextRules: 4 },
  { label: 'html', kind: 25, insertText: '<html>\n<head>\n  <title>${1}</title>\n</head>\n<body>\n  ${2}\n</body>\n</html>', insertTextRules: 4 },
  
  // HTML Attributes
  { label: 'class', kind: 10, insertText: 'class="${1}"', insertTextRules: 4 },
  { label: 'id', kind: 10, insertText: 'id="${1}"', insertTextRules: 4 },
  { label: 'src', kind: 10, insertText: 'src="${1}"', insertTextRules: 4 },
  { label: 'href', kind: 10, insertText: 'href="${1}"', insertTextRules: 4 },
  { label: 'alt', kind: 10, insertText: 'alt="${1}"', insertTextRules: 4 },
  { label: 'style', kind: 10, insertText: 'style="${1}"', insertTextRules: 4 },
  { label: 'onclick', kind: 10, insertText: 'onclick="${1}"', insertTextRules: 4 },
  { label: 'onload', kind: 10, insertText: 'onload="${1}"', insertTextRules: 4 },
  { label: 'type', kind: 10, insertText: 'type="${1}"', insertTextRules: 4 },
  { label: 'value', kind: 10, insertText: 'value="${1}"', insertTextRules: 4 }
];

const cssSuggestions = [
  // CSS Properties
  { label: 'color', kind: 19, insertText: 'color: ${1};', insertTextRules: 4 },
  { label: 'background-color', kind: 19, insertText: 'background-color: ${1};', insertTextRules: 4 },
  { label: 'background', kind: 19, insertText: 'background: ${1};', insertTextRules: 4 },
  { label: 'font-size', kind: 19, insertText: 'font-size: ${1};', insertTextRules: 4 },
  { label: 'font-family', kind: 19, insertText: 'font-family: ${1};', insertTextRules: 4 },
  { label: 'font-weight', kind: 19, insertText: 'font-weight: ${1};', insertTextRules: 4 },
  { label: 'margin', kind: 19, insertText: 'margin: ${1};', insertTextRules: 4 },
  { label: 'margin-top', kind: 19, insertText: 'margin-top: ${1};', insertTextRules: 4 },
  { label: 'margin-right', kind: 19, insertText: 'margin-right: ${1};', insertTextRules: 4 },
  { label: 'margin-bottom', kind: 19, insertText: 'margin-bottom: ${1};', insertTextRules: 4 },
  { label: 'margin-left', kind: 19, insertText: 'margin-left: ${1};', insertTextRules: 4 },
  { label: 'padding', kind: 19, insertText: 'padding: ${1};', insertTextRules: 4 },
  { label: 'padding-top', kind: 19, insertText: 'padding-top: ${1};', insertTextRules: 4 },
  { label: 'padding-right', kind: 19, insertText: 'padding-right: ${1};', insertTextRules: 4 },
  { label: 'padding-bottom', kind: 19, insertText: 'padding-bottom: ${1};', insertTextRules: 4 },
  { label: 'padding-left', kind: 19, insertText: 'padding-left: ${1};', insertTextRules: 4 },
  { label: 'width', kind: 19, insertText: 'width: ${1};', insertTextRules: 4 },
  { label: 'height', kind: 19, insertText: 'height: ${1};', insertTextRules: 4 },
  { label: 'max-width', kind: 19, insertText: 'max-width: ${1};', insertTextRules: 4 },
  { label: 'max-height', kind: 19, insertText: 'max-height: ${1};', insertTextRules: 4 },
  { label: 'min-width', kind: 19, insertText: 'min-width: ${1};', insertTextRules: 4 },
  { label: 'min-height', kind: 19, insertText: 'min-height: ${1};', insertTextRules: 4 },
  { label: 'display', kind: 19, insertText: 'display: ${1|block,inline,flex,grid,none|};', insertTextRules: 4 },
  { label: 'position', kind: 19, insertText: 'position: ${1|static,relative,absolute,fixed,sticky|};', insertTextRules: 4 },
  { label: 'top', kind: 19, insertText: 'top: ${1};', insertTextRules: 4 },
  { label: 'left', kind: 19, insertText: 'left: ${1};', insertTextRules: 4 },
  { label: 'right', kind: 19, insertText: 'right: ${1};', insertTextRules: 4 },
  { label: 'bottom', kind: 19, insertText: 'bottom: ${1};', insertTextRules: 4 },
  { label: 'border', kind: 19, insertText: 'border: ${1};', insertTextRules: 4 },
  { label: 'border-radius', kind: 19, insertText: 'border-radius: ${1};', insertTextRules: 4 },
  { label: 'text-align', kind: 19, insertText: 'text-align: ${1|left,center,right,justify|};', insertTextRules: 4 },
  { label: 'text-decoration', kind: 19, insertText: 'text-decoration: ${1};', insertTextRules: 4 },
  { label: 'flex', kind: 19, insertText: 'flex: ${1};', insertTextRules: 4 },
  { label: 'flex-direction', kind: 19, insertText: 'flex-direction: ${1|row,column|};', insertTextRules: 4 },
  { label: 'justify-content', kind: 19, insertText: 'justify-content: ${1|flex-start,center,flex-end,space-between,space-around|};', insertTextRules: 4 },
  { label: 'align-items', kind: 19, insertText: 'align-items: ${1|flex-start,center,flex-end,stretch|};', insertTextRules: 4 },
  { label: 'grid', kind: 19, insertText: 'grid: ${1};', insertTextRules: 4 },
  { label: 'grid-template-columns', kind: 19, insertText: 'grid-template-columns: ${1};', insertTextRules: 4 },
  { label: 'grid-template-rows', kind: 19, insertText: 'grid-template-rows: ${1};', insertTextRules: 4 },
  { label: 'gap', kind: 19, insertText: 'gap: ${1};', insertTextRules: 4 },
  { label: 'opacity', kind: 19, insertText: 'opacity: ${1};', insertTextRules: 4 },
  { label: 'transform', kind: 19, insertText: 'transform: ${1};', insertTextRules: 4 },
  { label: 'transition', kind: 19, insertText: 'transition: ${1};', insertTextRules: 4 },
  { label: 'animation', kind: 19, insertText: 'animation: ${1};', insertTextRules: 4 },
  { label: 'z-index', kind: 19, insertText: 'z-index: ${1};', insertTextRules: 4 },
  { label: 'box-shadow', kind: 19, insertText: 'box-shadow: ${1};', insertTextRules: 4 },
  { label: 'overflow', kind: 19, insertText: 'overflow: ${1|visible,hidden,scroll,auto|};', insertTextRules: 4 },
  { label: 'cursor', kind: 19, insertText: 'cursor: ${1|pointer,default,text,move,not-allowed|};', insertTextRules: 4 }
];

const jsSuggestions = [
  // JavaScript Keywords
  { label: 'function', kind: 14, insertText: 'function ${1:name}(${2:params}) {\n  ${3}\n}', insertTextRules: 4 },
  { label: 'const', kind: 14, insertText: 'const ${1:name} = ${2:value};', insertTextRules: 4 },
  { label: 'let', kind: 14, insertText: 'let ${1:name} = ${2:value};', insertTextRules: 4 },
  { label: 'var', kind: 14, insertText: 'var ${1:name} = ${2:value};', insertTextRules: 4 },
  { label: 'if', kind: 14, insertText: 'if (${1:condition}) {\n  ${2}\n}', insertTextRules: 4 },
  { label: 'else', kind: 14, insertText: 'else {\n  ${1}\n}', insertTextRules: 4 },
  { label: 'else if', kind: 14, insertText: 'else if (${1:condition}) {\n  ${2}\n}', insertTextRules: 4 },
  { label: 'for', kind: 14, insertText: 'for (let ${1:i} = 0; ${1:i} < ${2:length}; ${1:i}++) {\n  ${3}\n}', insertTextRules: 4 },
  { label: 'while', kind: 14, insertText: 'while (${1:condition}) {\n  ${2}\n}', insertTextRules: 4 },
  { label: 'return', kind: 14, insertText: 'return ${1:value};', insertTextRules: 4 },
  { label: 'break', kind: 14, insertText: 'break;' },
  { label: 'continue', kind: 14, insertText: 'continue;' },
  { label: 'try', kind: 14, insertText: 'try {\n  ${1}\n} catch (${2:error}) {\n  ${3}\n}', insertTextRules: 4 },
  { label: 'catch', kind: 14, insertText: 'catch (${1:error}) {\n  ${2}\n}', insertTextRules: 4 },
  { label: 'finally', kind: 14, insertText: 'finally {\n  ${1}\n}', insertTextRules: 4 },
  { label: 'throw', kind: 14, insertText: 'throw ${1:error};', insertTextRules: 4 },
  
  // JavaScript Constants
  { label: 'true', kind: 21, insertText: 'true' },
  { label: 'false', kind: 21, insertText: 'false' },
  { label: 'null', kind: 21, insertText: 'null' },
  { label: 'undefined', kind: 21, insertText: 'undefined' },
  
  // JavaScript Built-in Functions
  { label: 'console.log', kind: 3, insertText: 'console.log(${1});', insertTextRules: 4 },
  { label: 'console.error', kind: 3, insertText: 'console.error(${1});', insertTextRules: 4 },
  { label: 'console.warn', kind: 3, insertText: 'console.warn(${1});', insertTextRules: 4 },
  { label: 'alert', kind: 3, insertText: 'alert(${1});', insertTextRules: 4 },
  { label: 'prompt', kind: 3, insertText: 'prompt(${1});', insertTextRules: 4 },
  { label: 'confirm', kind: 3, insertText: 'confirm(${1});', insertTextRules: 4 },
  { label: 'parseInt', kind: 3, insertText: 'parseInt(${1});', insertTextRules: 4 },
  { label: 'parseFloat', kind: 3, insertText: 'parseFloat(${1});', insertTextRules: 4 },
  { label: 'typeof', kind: 3, insertText: 'typeof ${1}', insertTextRules: 4 },
  
  // DOM Methods
  { label: 'document.getElementById', kind: 3, insertText: 'document.getElementById(${1});', insertTextRules: 4 },
  { label: 'document.querySelector', kind: 3, insertText: 'document.querySelector(${1});', insertTextRules: 4 },
  { label: 'document.querySelectorAll', kind: 3, insertText: 'document.querySelectorAll(${1});', insertTextRules: 4 },
  { label: 'document.createElement', kind: 3, insertText: 'document.createElement(${1});', insertTextRules: 4 },
  { label: 'addEventListener', kind: 3, insertText: 'addEventListener(${1:event}, ${2:handler});', insertTextRules: 4 },
  { label: 'removeEventListener', kind: 3, insertText: 'removeEventListener(${1:event}, ${2:handler});', insertTextRules: 4 },
  { label: 'appendChild', kind: 3, insertText: 'appendChild(${1});', insertTextRules: 4 },
  { label: 'removeChild', kind: 3, insertText: 'removeChild(${1});', insertTextRules: 4 },
  { label: 'innerHTML', kind: 10, insertText: 'innerHTML = ${1};', insertTextRules: 4 },
  { label: 'textContent', kind: 10, insertText: 'textContent = ${1};', insertTextRules: 4 },
  { label: 'setAttribute', kind: 3, insertText: 'setAttribute(${1:name}, ${2:value});', insertTextRules: 4 },
  { label: 'getAttribute', kind: 3, insertText: 'getAttribute(${1:name});', insertTextRules: 4 },
  
  // Array Methods
  { label: 'push', kind: 3, insertText: 'push(${1});', insertTextRules: 4 },
  { label: 'pop', kind: 3, insertText: 'pop();' },
  { label: 'shift', kind: 3, insertText: 'shift();' },
  { label: 'unshift', kind: 3, insertText: 'unshift(${1});', insertTextRules: 4 },
  { label: 'map', kind: 3, insertText: 'map(${1:item} => ${2});', insertTextRules: 4 },
  { label: 'filter', kind: 3, insertText: 'filter(${1:item} => ${2});', insertTextRules: 4 },
  { label: 'forEach', kind: 3, insertText: 'forEach(${1:item} => ${2});', insertTextRules: 4 },
  { label: 'find', kind: 3, insertText: 'find(${1:item} => ${2});', insertTextRules: 4 }
];

// Global flags to ensure completion providers are registered only once
let htmlCompletionProviderRegistered = false;
let cssCompletionProviderRegistered = false;
let jsCompletionProviderRegistered = false;

// Register completion providers for HTML, CSS, and JavaScript
function registerWebCompletionProviders() {
  if (!window.monaco) {
    return;
  }
  
  // Register HTML completion provider
  if (!htmlCompletionProviderRegistered) {
    monaco.languages.registerCompletionItemProvider('html', {
      provideCompletionItems: function(model, position) {
        const word = model.getWordUntilPosition(position);
        const range = {
          startLineNumber: position.lineNumber,
          endLineNumber: position.lineNumber,
          startColumn: word.startColumn,
          endColumn: word.endColumn
        };

        const partialWord = word.word.toLowerCase();
        const filteredSuggestions = htmlSuggestions
          .filter(suggestion => suggestion.label.toLowerCase().startsWith(partialWord))
          .map(suggestion => ({...suggestion, range}));

        return { suggestions: filteredSuggestions };
      }
    });
    htmlCompletionProviderRegistered = true;
    console.log('HTML completion provider registered');
  }

  // Register CSS completion provider
  if (!cssCompletionProviderRegistered) {
    monaco.languages.registerCompletionItemProvider('css', {
      provideCompletionItems: function(model, position) {
        const word = model.getWordUntilPosition(position);
        const range = {
          startLineNumber: position.lineNumber,
          endLineNumber: position.lineNumber,
          startColumn: word.startColumn,
          endColumn: word.endColumn
        };

        const partialWord = word.word.toLowerCase();
        const filteredSuggestions = cssSuggestions
          .filter(suggestion => suggestion.label.toLowerCase().startsWith(partialWord))
          .map(suggestion => ({...suggestion, range}));

        return { suggestions: filteredSuggestions };
      }
    });
    cssCompletionProviderRegistered = true;
    console.log('CSS completion provider registered');
  }

  // Register JavaScript completion provider
  if (!jsCompletionProviderRegistered) {
    monaco.languages.registerCompletionItemProvider('javascript', {
      provideCompletionItems: function(model, position) {
        const word = model.getWordUntilPosition(position);
        const range = {
          startLineNumber: position.lineNumber,
          endLineNumber: position.lineNumber,
          startColumn: word.startColumn,
          endColumn: word.endColumn
        };

        const partialWord = word.word.toLowerCase();
        const filteredSuggestions = jsSuggestions
          .filter(suggestion => suggestion.label.toLowerCase().startsWith(partialWord))
          .map(suggestion => ({...suggestion, range}));

        return { suggestions: filteredSuggestions };
      }
    });
    jsCompletionProviderRegistered = true;
    console.log('JavaScript completion provider registered');
  }
}

// --- Monaco Interop ---
window.monacoInterop = {
  init: async (containerId, initialCode, theme, fontSize, onContentChanged, language = 'html') => {
    console.log('Monaco init called for:', containerId, 'with language:', language);
    try {
      // Check if DOM element exists
      const container = document.getElementById(containerId);
      if (!container) {
        throw new Error(`DOM element with ID '${containerId}' not found`);
      }
      console.log('DOM element found for:', containerId);

      // Check if editor already exists and dispose it first
      if (monacoEditors[containerId]) {
        console.log('Existing editor found for', containerId, 'disposing first...');
        try {
          monacoEditors[containerId].dispose();
        } catch (e) {
          console.warn('Error disposing existing editor:', e);
        }
        delete monacoEditors[containerId];
      }

      // Ensure the container is completely clean
      while (container.firstChild) {
        container.removeChild(container.firstChild);
      }
      container.innerHTML = '';

      // Ensure Monaco is loaded first
      if (!monacoLoaded) {
        await loadMonaco();
      }

      // Small delay to ensure DOM is ready
      await new Promise(resolve => setTimeout(resolve, 50));

      const editor = monaco.editor.create(container, {
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
      console.log('Monaco editor created successfully for:', containerId);

      // Register the web completion providers globally (only once)
      registerWebCompletionProviders();

      // Force a layout and refresh to ensure syntax highlighting appears immediately
      setTimeout(() => {
        if (editor) {
          editor.layout();
          const model = editor.getModel();
          if (model) {
            // Force re-tokenization to ensure syntax highlighting appears
            monaco.editor.setModelLanguage(model, model.getLanguageId());
            // Trigger a refresh of the editor
            editor.trigger('', 'editor.action.refresh', {});
          }
        }
      }, 100);

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
        const model = editor.getModel();
        const language = model.getLanguageId();
        
        // Enhanced formatting with language-specific options
        switch (language) {
          case 'html':
            // For HTML, try Monaco's formatter first
            editor.getAction('editor.action.formatDocument').run();
            break;
          case 'css':
            // For CSS, use Monaco's built-in formatter
            editor.getAction('editor.action.formatDocument').run();
            break;
          case 'javascript':
          case 'typescript':
            // For JS/TS, use Monaco's formatter with enhanced options
            editor.getAction('editor.action.formatDocument').run();
            break;
          case 'python':
            // For Python, basic indentation fix
            const code = model.getValue();
            const lines = code.split('\n');
            let indentLevel = 0;
            const formattedLines = lines.map(line => {
              const trimmed = line.trim();
              if (trimmed === '') return '';
              
              // Decrease indent for dedent keywords
              if (trimmed.match(/^(except|elif|else|finally):/)) {
                indentLevel = Math.max(0, indentLevel - 1);
              }
              
              const formatted = '  '.repeat(indentLevel) + trimmed;
              
              // Increase indent after colon (class, def, if, etc.)
              if (trimmed.endsWith(':') && !trimmed.startsWith('#')) {
                indentLevel++;
              }
              
              return formatted;
            });
            
            model.setValue(formattedLines.join('\n'));
            break;
          default:
            // For other languages, use Monaco's default formatter
            editor.getAction('editor.action.formatDocument').run();
        }
      } catch (error) {
        console.log('Enhanced formatting failed, falling back to Monaco default:', error);
        try {
          // Fallback to Monaco's default formatter
          editor.getAction('editor.action.formatDocument').run();
        } catch (fallbackError) {
          console.log('Monaco formatting also failed:', fallbackError);
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
  console.log(`Destroying Monaco editor: ${elementId}`);
  
  if(monacoEditors && monacoEditors[elementId]) {
    try {
      // Dispose the Monaco editor instance
      monacoEditors[elementId].dispose();
      console.log(`Monaco editor ${elementId} disposed successfully`);
    } catch (e) {
      console.error(`Error disposing Monaco editor ${elementId}:`, e);
    }
    
    // Remove from our tracking object
    delete monacoEditors[elementId];
  }
  
  // Clear the DOM container completely
  const container = document.getElementById(elementId);
  if (container) {
    // Remove all children
    while (container.firstChild) {
      container.removeChild(container.firstChild);
    }
    
    // Clear innerHTML as backup
    container.innerHTML = '';
    
    // Remove any Monaco-specific attributes
    container.removeAttribute('data-monaco-initialized');
    
    console.log(`DOM container ${elementId} cleared successfully`);
  } else {
    console.warn(`DOM container ${elementId} not found for cleanup`);
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