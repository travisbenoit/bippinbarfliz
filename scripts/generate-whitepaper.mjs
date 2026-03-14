/**
 * Generate LUSH Whitepaper as styled HTML (printable to PDF)
 * Run: node scripts/generate-whitepaper.mjs
 * Then open the HTML and print/save as PDF
 */
import { readFileSync, writeFileSync } from 'fs';

const md = readFileSync('WHITEPAPER.md', 'utf-8');

// Simple markdown to HTML conversion
function mdToHtml(text) {
  let html = text;

  // Tables
  html = html.replace(/^(\|.+\|)\n(\|[-| :]+\|)\n((?:\|.+\|\n?)+)/gm, (_, header, sep, body) => {
    const thCells = header.split('|').filter(c => c.trim()).map(c => `<th>${c.trim()}</th>`).join('');
    const rows = body.trim().split('\n').map(row => {
      const cells = row.split('|').filter(c => c.trim()).map(c => `<td>${c.trim()}</td>`).join('');
      return `<tr>${cells}</tr>`;
    }).join('\n');
    return `<table><thead><tr>${thCells}</tr></thead><tbody>${rows}</tbody></table>`;
  });

  // Code blocks
  html = html.replace(/```(\w*)\n([\s\S]*?)```/g, (_, lang, code) =>
    `<pre><code>${code.replace(/</g, '&lt;').replace(/>/g, '&gt;')}</code></pre>`
  );

  // Headers
  html = html.replace(/^#### (.+)$/gm, '<h4>$1</h4>');
  html = html.replace(/^### (.+)$/gm, '<h3>$1</h3>');
  html = html.replace(/^## (.+)$/gm, '<h2>$1</h2>');
  html = html.replace(/^# (.+)$/gm, '<h1>$1</h1>');

  // Horizontal rules
  html = html.replace(/^---$/gm, '<hr>');

  // Bold and italic
  html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
  html = html.replace(/\*(.+?)\*/g, '<em>$1</em>');

  // Inline code
  html = html.replace(/`([^`]+)`/g, '<code class="inline">$1</code>');

  // Lists
  html = html.replace(/^- (.+)$/gm, '<li>$1</li>');
  html = html.replace(/(<li>.*<\/li>\n?)+/g, '<ul>$&</ul>');

  // Numbered lists
  html = html.replace(/^\d+\. (.+)$/gm, '<li>$1</li>');

  // Paragraphs (lines that aren't already tagged)
  html = html.replace(/^(?!<[huptlo]|<\/|<li|<hr|<pre|<code|\s*$)(.+)$/gm, '<p>$1</p>');

  return html;
}

const bodyHtml = mdToHtml(md);

const fullHtml = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>LUSH Coin Whitepaper — Barfliz</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');
  @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500&display=swap');

  :root {
    --pink: #E91E63;
    --dark: #0f1219;
    --darker: #080b10;
    --card: #1a1f2e;
    --border: #2a3040;
    --text: #e5e7eb;
    --muted: #9ca3af;
    --cyan: #00D9FF;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: 'Inter', system-ui, sans-serif;
    background: var(--darker);
    color: var(--text);
    line-height: 1.7;
    font-size: 15px;
  }

  .container {
    max-width: 860px;
    margin: 0 auto;
    padding: 60px 40px;
  }

  h1 {
    font-size: 36px;
    font-weight: 800;
    color: var(--pink);
    margin: 50px 0 10px;
    letter-spacing: -0.5px;
  }

  h1:first-of-type {
    font-size: 42px;
    text-align: center;
    margin-top: 0;
    margin-bottom: 5px;
  }

  h2 {
    font-size: 24px;
    font-weight: 700;
    color: #fff;
    margin: 50px 0 15px;
    padding-bottom: 8px;
    border-bottom: 2px solid var(--pink);
  }

  h3 {
    font-size: 18px;
    font-weight: 600;
    color: var(--cyan);
    margin: 30px 0 10px;
  }

  h4 {
    font-size: 16px;
    font-weight: 600;
    color: var(--text);
    margin: 20px 0 8px;
  }

  p {
    margin: 10px 0;
    color: var(--text);
  }

  strong { color: #fff; }

  em { color: var(--muted); font-style: italic; }

  a { color: var(--cyan); text-decoration: none; }
  a:hover { text-decoration: underline; }

  hr {
    border: none;
    border-top: 1px solid var(--border);
    margin: 40px 0;
  }

  ul, ol {
    padding-left: 24px;
    margin: 10px 0;
  }

  li {
    margin: 6px 0;
    color: var(--text);
  }

  table {
    width: 100%;
    border-collapse: collapse;
    margin: 15px 0;
    font-size: 14px;
  }

  thead tr {
    background: var(--pink);
    color: var(--dark);
  }

  th {
    padding: 10px 14px;
    text-align: left;
    font-weight: 600;
    font-size: 13px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  td {
    padding: 10px 14px;
    border-bottom: 1px solid var(--border);
    color: var(--text);
  }

  tbody tr:hover {
    background: rgba(233, 30, 99, 0.05);
  }

  pre {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 16px 20px;
    margin: 15px 0;
    overflow-x: auto;
    font-size: 13px;
    line-height: 1.6;
  }

  pre code {
    font-family: 'JetBrains Mono', monospace;
    color: var(--cyan);
  }

  code.inline {
    font-family: 'JetBrains Mono', monospace;
    background: var(--card);
    border: 1px solid var(--border);
    padding: 2px 6px;
    border-radius: 4px;
    font-size: 13px;
    color: var(--cyan);
  }

  /* Title page styling */
  .title-meta {
    text-align: center;
    color: var(--muted);
    margin-bottom: 40px;
  }

  /* Disclaimer box */
  h2:first-of-type + p {
    background: var(--card);
    border: 1px solid var(--border);
    border-left: 4px solid var(--pink);
    padding: 16px 20px;
    border-radius: 0 8px 8px 0;
    font-size: 13px;
    color: var(--muted);
    line-height: 1.8;
  }

  /* Print styles */
  @media print {
    body { background: white; color: #1a1a1a; font-size: 11pt; }
    .container { padding: 20px; max-width: 100%; }
    h1 { color: #E91E63; }
    h2 { color: #1a1a1a; border-bottom-color: #E91E63; }
    h3 { color: #1a1a1a; }
    strong { color: #1a1a1a; }
    pre { background: #f5f5f5; border-color: #ddd; }
    pre code { color: #333; }
    code.inline { background: #f5f5f5; border-color: #ddd; color: #333; }
    thead tr { background: #E91E63; color: white; }
    td { border-bottom-color: #ddd; color: #333; }
    p, li { color: #333; }
    em { color: #666; }
    hr { border-top-color: #ddd; }
  }
</style>
</head>
<body>
<div class="container">
${bodyHtml}
</div>
</body>
</html>`;

const outPath = 'C:/Users/User/Projects/bippinbarliz-main/LUSH_Whitepaper.html';
writeFileSync(outPath, fullHtml, 'utf-8');
console.log('Whitepaper HTML saved to:', outPath);
