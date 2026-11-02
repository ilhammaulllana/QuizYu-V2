from pathlib import Path
import html, re
src=Path(r'C:\Users\asus\.codex\attachments\789b58db-0bc3-4780-a682-338bb8109373\Pasted text.txt')
text=src.read_text(encoding='utf-8-sig')
lines=text.replace('\r\n','\n').split('\n')
blocks=[]; code=False; codebuf=[]; para=[]; table=[]
def flush_para():
    global para
    if para:
        s=' '.join(x.strip() for x in para).strip()
        if s: blocks.append('<p>'+html.escape(s)+'</p>')
        para=[]
def flush_table():
    global table
    if table:
        rows=[]
        for line in table:
            cells=re.split(r'\t+|\s{2,}',line.strip())
            rows.append(cells)
        if len(rows)>1 and all(set(c.strip())<=set('-| ') for c in rows[1]): rows.pop(1)
        out=['<table>']
        for ri,row in enumerate(rows):
            tag='th' if ri==0 else 'td'
            out.append('<tr>'+''.join(f'<{tag}>{html.escape(c.strip())}</{tag}>' for c in row)+'</tr>')
        out.append('</table>'); blocks.append(''.join(out)); table=[]
for raw in lines:
    s=raw.rstrip()
    if s.strip() in ('dart','javascript'):
        flush_para(); flush_table(); code=True; codebuf=[]; continue
    if code:
        if not s.strip():
            if codebuf and codebuf[-1].strip(): codebuf.append('')
            continue
        # A code block ends when a prose paragraph/question is reached after a blank line.
        codebuf.append(s)
        continue
    if not s.strip(): flush_para(); flush_table(); continue
    if re.match(r'^\d+\. ',s):
        flush_para(); flush_table(); blocks.append('<h2>'+html.escape(s)+'</h2>'); continue
    if s.startswith('🎯 '):
        flush_para(); blocks.append('<h1>'+html.escape(s)+'</h1>'); continue
    if s.startswith('📋 '):
        flush_para(); blocks.append('<h2>'+html.escape(s)+'</h2>'); continue
    if s.startswith('❓ '):
        flush_para(); flush_table(); blocks.append('<h3>'+html.escape(s.replace('❓ ',''))+'</h3>'); continue
    if s in ('IMPORTANT','TIP'):
        flush_para(); blocks.append('<div class="callout"><b>'+html.escape(s)+'</b></div>'); continue
    if '\t' in s and len(s.split('\t'))>=2:
        flush_para(); table.append(s); continue
    if s.startswith('```'):
        flush_para(); continue
    if s.startswith('    '):
        flush_para(); flush_table(); blocks.append('<pre>'+html.escape(s.strip())+'</pre>'); continue
    # Normal prose. Repair minor spacing and common typos.
    s=s.replace('IMPORTANT','PENTING').replace('Gimana','Bagaimana').replace('gimana','bagaimana').replace('Ceritain','Ceritakan').replace('dibuat, pattern','dibuat, pola').replace('perfect untuk','sangat cocok untuk').replace('readable','mudah dibaca').replace('prop drill','meneruskan data melalui banyak widget')
    para.append(s)
flush_para(); flush_table()
# The source code blocks are identified from language labels; reconstruct separately with a focused parser.
# Remove inline code-language marker paragraphs if any and highlight all preformatted snippets.
body='\n'.join(blocks)
# Add clean section intro and table of contents from source contents.
toc=['Perkenalan Diri & Project','Arsitektur & Cara Kerja Aplikasi','State Management — Riverpod','Model & Data Layer','Cara Kerja Pemanggilan API','Backend — Node.js + Gemini AI','Flutter Teknis','Debugging & Error Handling','Responsive Design','Pertanyaan Jebakan & Cara Jawabnya']
toc_html='<nav><strong>Daftar Isi</strong><ol>'+''.join('<li>'+html.escape(x)+'</li>' for x in toc)+'</ol></nav>'
# Source lines include code; preserve them as readable code blocks by collecting language marker spans.
# In this document, code labels occur as standalone lines; use line-state pass for better rendering.
# Current converted body uses paragraph text for code, so redo conversion preserving blocks below.
blocks=[]; para=[]; code_lines=[]; in_code=False; table=[]
def flushp():
    if para:
        blocks.append('<p>'+html.escape(' '.join(x.strip() for x in para))+'</p>'); para.clear()
def flusht():
    if table:
        rows=[re.split(r'\t+|\s{2,}',x.strip()) for x in table]
        out=['<table>']
        for i,row in enumerate(rows): out.append('<tr>'+''.join(f'<{"th" if i==0 else "td"}>{html.escape(c.strip())}</{"th" if i==0 else "td"}>' for c in row)+'</tr>')
        out.append('</table>'); blocks.append(''.join(out)); table.clear()
def flushc():
    if code_lines:
        # code already indented where applicable; preserve exact characters
        blocks.append('<pre><code>'+html.escape('\n'.join(code_lines))+'</code></pre>'); code_lines.clear()
for raw in lines:
    s=raw.rstrip()
    if s.strip() in ('dart','javascript'):
        flushp(); flusht(); flushc(); in_code=True; continue
    if in_code:
        # Code ends on a blank line followed by a question or narrative sentence.
        if not s.strip():
            flushc(); in_code=False; continue
        code_lines.append(s); continue
    if not s.strip(): flushp(); flusht(); continue
    if re.match(r'^\d+\. ',s): flushp(); flusht(); blocks.append('<h2>'+html.escape(s)+'</h2>'); continue
    if s.startswith('🎯 '): flushp(); blocks.append('<h1>'+html.escape(s)+'</h1>'); continue
    if s.startswith('📋 '): flushp(); blocks.append('<h2>'+html.escape(s)+'</h2>'); continue
    if s.startswith('❓ '): flushp(); flusht(); blocks.append('<h3>'+html.escape(s.replace('❓ ',''))+'</h3>'); continue
    if s in ('IMPORTANT','TIP'): flushp(); blocks.append('<div class="callout"><b>'+('PENTING' if s=='IMPORTANT' else 'TIPS')+'</b></div>'); continue
    if '\t' in s: flushp(); table.append(s); continue
    s=s.replace('Gimana','Bagaimana').replace('gimana','bagaimana').replace('Ceritain','Ceritakan').replace('pattern','pola').replace('perfect untuk','sangat cocok untuk').replace('readable','mudah dibaca').replace('prop drill','meneruskan data melalui banyak widget')
    para.append(s)
flushp(); flusht(); flushc()
body='\n'.join(blocks)
html_doc='''<!doctype html><html lang="id"><head><meta charset="utf-8"><title>Materi Interview — Project QuizYu</title><style>
@page{size:A4;margin:18mm 17mm 20mm;@bottom-center{content:"Materi Interview — Project QuizYu  •  " counter(page);font:9pt Arial;color:#667085}}
*{box-sizing:border-box}body{font:10.3pt/1.52 Arial,"Segoe UI",sans-serif;color:#202939;margin:0}h1{font-size:23pt;line-height:1.18;color:#162b55;margin:0 0 18px;border-bottom:3px solid #526de5;padding:0 0 12px}h2{font-size:16pt;color:#243b70;margin:25px 0 11px;padding-bottom:5px;border-bottom:1px solid #d9e0ed;page-break-after:avoid}h3{font-size:11.5pt;color:#273b65;margin:17px 0 7px;page-break-after:avoid}p{margin:5px 0 9px}nav{background:#f3f6fc;border:1px solid #dfe6f2;border-radius:8px;padding:12px 18px;margin:15px 0 20px;page-break-after:always}nav strong{font-size:14pt;color:#243b70}nav ol{columns:2;padding-left:23px;margin:8px 0 0}nav li{padding:2px 0}table{width:100%;border-collapse:collapse;margin:8px 0 12px;font-size:9.4pt;page-break-inside:avoid}th{background:#e9eef9;color:#243b70;text-align:left}td,th{border:1px solid #ccd5e4;padding:6px 8px;vertical-align:top}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f5f7fa;border:1px solid #e2e7ef;border-radius:5px;padding:10px 12px;font:8.2pt/1.4 Consolas,"Courier New",monospace;margin:7px 0 12px;page-break-inside:avoid}code{font:inherit}.callout{background:#fff6db;border-left:4px solid #e4ad28;padding:8px 11px;margin:12px 0;color:#594713}.callout b{letter-spacing:.04em}h2,h3{break-after:avoid}p,table,pre{orphans:2;widows:2}
</style></head><body><h1>🎯 Materi Interview — Project QuizYu</h1><div class="callout"><b>PENTING</b><br>Dokumen ini mencakup topik yang mungkin ditanyakan interviewer, mulai dari perkenalan diri dan arsitektur sistem hingga pemanggilan API, state management, serta debugging. Pahami alurnya, bukan sekadar menghafalnya.</div>'''+toc_html+body+'''</body></html>'''
out=Path(r'D:\project\quizyu\Materi_Interview_Project_QuizYu.html'); out.write_text(html_doc,encoding='utf-8')
print(f'Created {out} ({len(html_doc)} chars, {len(blocks)} blocks)')
