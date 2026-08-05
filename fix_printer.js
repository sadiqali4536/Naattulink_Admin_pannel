const fs = require('fs');
let c = fs.readFileSync('lib/MVVM/utils/printer_web.dart', 'utf8');

const style = '.table-wrapper { overflow: auto; max-height: 70vh; border: 1px solid #E2E8F0; border-radius: 8px; } .table-wrapper::-webkit-scrollbar { width: 8px; height: 8px; } .table-wrapper::-webkit-scrollbar-track { background: #F1F5F9; } .table-wrapper::-webkit-scrollbar-thumb { background: #CBD5E1; border-radius: 4px; } th { position: sticky; top: 0; z-index: 10; }';

// Remove all injected styles
while(c.includes(style)) {
    c = c.replace(style, '');
}
// Clean up blank lines left before </style>
c = c.replace(/\n\s*\n\s*<\/style>/g, '\n    </style>');

// Re-add the style exactly once
c = c.replace(/<\/style>/g, style + '\n    </style>');

// Remove all <div class="table-wrapper">
c = c.replace(/<div class="table-wrapper">\n\s*/g, '');

// Remove all </div> after </table>
c = c.replace(/<\/table>\n\s*<\/div>/g, '</table>');
c = c.replace(/<\/table>\n\s*<\/div>/g, '</table>');
c = c.replace(/<\/table>\n\s*<\/div>/g, '</table>');

// Re-add them correctly exactly once
c = c.replace(/<table>/g, '<div class="table-wrapper">\n        <table>');
c = c.replace(/<\/table>/g, '</table>\n      </div>');

fs.writeFileSync('lib/MVVM/utils/printer_web.dart', c);
console.log("Fixed printer_web.dart duplicates");
