const fs = require('fs');
let c = fs.readFileSync('lib/MVVM/utils/printer_web.dart', 'utf8');
c = c.replace(/<table>/g, '<div class="table-wrapper">\n      <table>');
c = c.replace(/<\/table>/g, '</table>\n      </div>');
const style = `.table-wrapper { overflow: auto; max-height: 70vh; border: 1px solid #E2E8F0; border-radius: 8px; } .table-wrapper::-webkit-scrollbar { width: 8px; height: 8px; } .table-wrapper::-webkit-scrollbar-track { background: #F1F5F9; } .table-wrapper::-webkit-scrollbar-thumb { background: #CBD5E1; border-radius: 4px; } th { position: sticky; top: 0; z-index: 10; }`;
c = c.replace(/<\/style>/g, style + '\n    </style>');
fs.writeFileSync('lib/MVVM/utils/printer_web.dart', c);
console.log("Done");
