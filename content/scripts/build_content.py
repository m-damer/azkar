#!/usr/bin/env python3
"""Parse hisn_almuslim_v3.docx -> content/content.json (+ report)."""
import docx, json, re, sys, collections
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
d=docx.Document(ROOT/'source/hisn_almuslim_v3.docx')
AR=str.maketrans('٠١٢٣٤٥٦٧٨٩','0123456789')
sections=[];sec=cat=chap=None;pending=None;issues=[]
def new(lst,o): lst.append(o);return o
body=d.element.body
from docx.text.paragraph import Paragraph
from docx.table import Table
items_seen=0
for el in body.iterchildren():
    if el.tag.endswith('}tbl'):
        break  # appendix table starts: stop (handled separately)
    if not el.tag.endswith('}p'): continue
    p=Paragraph(el,d); t=p.text.strip(); st=p.style.name
    if not t: continue
    if st=='Heading 1':
        if 'مطابقة' in t: break
        if t.startswith('ملحق'):
            sec=new(sections,{'id':f's{len(sections)+1}','title':'الآداب الجامعة','appendix':False,'categories':[]});cat=new(sec['categories'],{'id':sec['id']+'c1','title':t.split(':',1)[-1].strip(),'chapters':[]});chap=None;continue
        sec=new(sections,{'id':f's{len(sections)+1}','title':t.replace('القسم','').split(':')[-1].strip() or t,'categories':[]});cat=chap=None
    elif st=='Heading 2':
        if 'مطابقة' in t: break
        cat=new(sec['categories'],{'id':f"{sec['id']}c{len(sec['categories'])+1}",'title':re.sub(r'^[\d٠-٩]+\s*[.\-]\s*','',t),'chapters':[]});chap=None
    elif st=='Heading 3':
        m=re.match(r'^([\d٠-٩]+)\s*[.\-]\s*(.*)$',t)
        chap=new(cat['chapters'],{'id':f"b{int(m.group(1).translate(AR)):03d}" if m else f"b_x{len(cat['chapters'])}",'bookNo':int(m.group(1).translate(AR)) if m else None,'title':m.group(2) if m else t,'items':[]})
    elif chap is not None:
        if t.startswith('المصدر'):
            if pending is None: issues.append(('source without text',chap['id'],t[:60]));continue
            pending['source']=re.sub(r'^المصدر\s*[:：]\s*','',t);pending=None
        else:
            if pending is not None: issues.append(('text without source',chap['id'],pending['text'][:40]))
            items_seen+=1
            pending=new(chap['items'],{'id':f"{chap['id']}-{len(chap['items'])+1:02d}",'text':t,'source':None})
    else:
        pass
# post: repeat counts
NUM={'مرة':1,'مرتين':2,'ثلاث':3,'ثلاثا':3,'ثلاثاً':3,'أربع':4,'أربعا':4,'أربعاً':4,'خمس':5,'سبع':7,'عشر':10,'مائة':100,'مئة':100}
def strip(s): return re.sub(r'[ً-ْٰـ]','',s)
def repeat(text):
    s=strip(text)
    m=re.search(r'\(([^)]*?)(مرات|مرة|مرتين|ثلاثا|ثلاثين|وثلاثين|مرار)[^)]*\)',s)
    if not m: return None
    g=m.group(0)
    for w,n in (('مائة',100),('مئة',100),('ثلاث وثلاثين',33),('ثلاثا وثلاثين',33),('سبع',7),('عشر',10),('ثلاث',3),('مرتين',2),('اربع',4),('خمس',5)):
        if w in g: return n
    return None
for s in sections:
    for c in s['categories']:
        for b in c['chapters']:
            for it in b['items']:
                r=repeat(it['text']); it['repeat']=r
                it['kind']='quran' if it['text'].lstrip().startswith('{') else 'text'
tot=sum(len(b['items']) for s in sections for c in s['categories'] for b in c['chapters'])
# appendix table
appendix=[]
if d.tables:
    for r in d.tables[-1].rows: appendix.append([c.text.strip() for c in r.cells])
out={'source':'hisn_almuslim_v3.docx','sections':sections}
(ROOT/'content.json').write_text(json.dumps(out,ensure_ascii=False,indent=1),encoding='utf-8')
(ROOT/'appendix_discrepancies.json').write_text(json.dumps(appendix,ensure_ascii=False,indent=1),encoding='utf-8')
print('sections',len(sections),'categories',sum(len(s['categories']) for s in sections),'chapters',sum(len(c['chapters']) for s in sections for c in s['categories']),'items',tot)
for s in sections:
    print('##',s['title'],sum(len(b['items']) for c in s['categories'] for b in c['chapters']))
    for c in s['categories']:
        print('  -',c['title'],len(c['chapters']),'ch',sum(len(b['items']) for b in c['chapters']),'items')
print('issues',len(issues),issues[:10])
print('with repeat',sum(1 for s in sections for c in s['categories'] for b in c['chapters'] for i in b['items'] if i['repeat']))
print('no source',sum(1 for s in sections for c in s['categories'] for b in c['chapters'] for i in b['items'] if not i['source']))
print('appendix rows',len(appendix))
