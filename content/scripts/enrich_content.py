#!/usr/bin/env python3
"""Adds intro/virtue/takhrij/note and repeat info to content/content.json.
Run after build_content.py. The original `source` field is kept untouched.
Also writes content/review/*.json for human review."""
import json, re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
data = json.loads((ROOT / 'content.json').read_text(encoding='utf-8'))

AR = r'[ء-ي]'
CIT_WORDS = ['رواه','أخرجه','أخرج','البخاري','مسلم','أبو داود','أبي داود','الترمذي','النسائي','ابن ماجه','ابن ماجة','أحمد','مالك','الحاكم','ابن السني','الطبراني','ابن حبان','الدارمي','البيهقي','الدارقطني','سورة','صحيح','وانظر','انظر','متفق','زاد المعاد','ابن خزيمة','البزار','أبو يعلى','برقم','تحفة','مجمع','إرواء','الألباني','الأرناؤوط','عبدالقادر','عبد القادر']
CIT = re.compile(rf'(?<!{AR})و?(?:{"|".join(map(re.escape,CIT_WORDS))})(?!{AR})')
NUMREF = re.compile(r'\d\s*/\s*\d|\bرقم\s*\d|\d{3,}')
VIRTUE_START = re.compile(r'^(من|ومن|فمن|كل من)\s')
INTRO_START = re.compile(r'^(كان|كانت|قال|وقال|عن|إذا|اذا|أن|ثم|لما|يقول|وكان|لقد|سمعت|أمر|أتى|دخل|خرج|رأى|عند|وعن|أول|ويقول|وإذا)\s')
SEP = re.compile(r'(\s*[،؛]\s*|(?<=\.)\s+|\s*؛\s*)')

def classify(seg):
    t = seg.strip()
    if not t: return 'empty'
    if CIT.search(t[:30]) and (CIT.match(t) or NUMREF.search(t)): return 'cit'
    if NUMREF.search(t) and len(t.split()) <= 8: return 'cit'
    if '..' in t or 'الحديث' in t or t.endswith(':'): return 'intro'
    if VIRTUE_START.match(t): return 'virtue'
    if INTRO_START.match(t): return 'intro'
    return 'other'

def atoms(s):
    parts = SEP.split(s)
    segs = []; i = 0
    while i < len(parts):
        body = parts[i]; sep = parts[i+1] if i+1 < len(parts) else ''
        i += 2
        segs.append([body, sep])
    out = []
    for body, sep in segs:
        m = CIT.search(body)
        # split at a citation that starts after >=3 non-citation words
        if m and m.start() > 0 and len(body[:m.start()].split()) >= 3 and not NUMREF.search(body[:m.start()]):
            out.append([body[:m.start()].rstrip(), ' '])
            out.append([body[m.start():], sep])
        else:
            out.append([body, sep])
    return out

def split_source(src):
    res = {'intro': [], 'virtue': [], 'takhrij': [], 'note': []}
    flag = None
    seen_cit = False
    last = None
    for body, sep in atoms(src):
        c = classify(body)
        if c == 'empty': continue
        if c == 'other':
            if seen_cit and len(body.split()) <= 14: c = 'note'
            elif not seen_cit and len(body.split()) <= 3: c = 'cit'  # e.g. a book name fragment
            else:
                c = 'virtue' if not seen_cit else 'note'
                flag = 'unclear: ' + body[:40]
        if c == 'cit': seen_cit = True
        key = {'cit': 'takhrij'}.get(c, c)
        res[key].append((body, sep))
    out = {}
    for k, v in res.items():
        if not v: out[k] = None; continue
        txt = ''
        for j, (b, sp) in enumerate(v):
            txt += b + (sp if j < len(v)-1 else '')
        out[k] = re.sub(r'\s+', ' ', txt).strip(' ،؛') or None
    # integrity: same Arabic letters+digits as the source
    keep = lambda x: re.sub(r'[^ء-ي0-9]', '', x or '')
    if sorted(keep(src)) != sorted(keep(''.join(filter(None, out.values())))):
        flag = (flag or '') + ' integrity-mismatch'
    return out, flag

# ---- repeats
DIAC = re.compile(r'[ً-ْٰـ]')
def norm(s):
    s = DIAC.sub('', s)
    return s.replace('أ','ا').replace('إ','ا').replace('آ','ا').replace('ة','ه').replace('ى','ي').replace('ـ','')
NUMS = [('ثلاثا وثلاثين',33),('ثلاث وثلاثين',33),('اربعا وثلاثين',34),('اربع وثلاثين',34),('مايه',100),('ماءه',100),('مائه',100),('مئه',100),
        ('ثلاثين',30),('عشرا',10),('عشر',10),('سبعا',7),('سبع',7),('ثلاثا',3),('ثلاث',3),('اربعا',4),('اربع',4),('خمسا',5),('خمس',5),('ستا',6),('ست',6),('ثمان',8),('تسعا',9),('تسع',9),('مرتين',2),('مره واحده',1),('مره',1)]
NUMRE = '|'.join(re.escape(n) for n,_ in NUMS)
COUNT = re.compile(rf'(?<![ء-ي])({NUMRE})\s*(?:و\s*)?(?:(?:مرات|مرار|مره|مرتين|مرا)\b)?')
def repeats(text):
    t = norm(text)
    found = []
    for m in re.finditer(r'\(([^)]*)\)', t):
        inner = m.group(1)
        if not re.search(r'مر|ثلاث|اربع|خمس|سبع|عشر|ماي|مئ|ثلاثين|مائ', inner): continue
        for w, n in NUMS:
            if re.search(rf'(?<![ء-ي]){re.escape(w)}', inner):
                found.append(n); break
    if not found:
        for m in re.finditer(rf'(?<![\u0621-\u064A])({NUMRE})\s*(?:مرات|مرار|مرتين|مره)', t):
            found.append(dict(NUMS)[m.group(1)])
    return found

ref = []; ambiguous = []; rep_review = []
for s in data['sections']:
    for k in s['categories']:
        for b in k['chapters']:
            for it in b['items']:
                parts, flag = split_source(it['source'] or '')
                if (flag or (it['source'] and not parts['takhrij'])) and it['source']:
                    # not confident: keep the whole original text as takhrij, split nothing
                    parts = {'intro': None, 'virtue': None, 'takhrij': it['source'], 'note': None}
                    it['splitReviewed'] = False
                else:
                    it['splitReviewed'] = True
                it.update({'intro': parts['intro'], 'virtue': parts['virtue'], 'takhrij': parts['takhrij'], 'note': parts['note']})
                if flag or (it['source'] and not parts['takhrij']):
                    ambiguous.append({'id': it['id'], 'chapter': b['title'], 'source': it['source'], 'proposed': parts, 'flag': flag or 'no takhrij found'})
                f = repeats(it['text'])
                it['repeat'] = f[0] if len(f) == 1 else None
                it['repeatParts'] = f if len(f) > 1 else None
                mentions = bool(re.search(r'مر[ةات]|مرتين|مرار|ثلاثا|ثلاثين', norm(it['text'])))
                if f or mentions:
                    rep_review.append({'id': it['id'], 'chapter': b['title'], 'text': it['text'][:160], 'detected': f, 'mentionsCount': mentions})
(ROOT / 'content.json').write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding='utf-8')
(ROOT / 'review').mkdir(exist_ok=True)
(ROOT / 'review' / 'ambiguous_splits.json').write_text(json.dumps(ambiguous, ensure_ascii=False, indent=1), encoding='utf-8')
(ROOT / 'review' / 'repeats.json').write_text(json.dumps(rep_review, ensure_ascii=False, indent=1), encoding='utf-8')
n = sum(len(b['items']) for s in data['sections'] for k in s['categories'] for b in k['chapters'])
sp = sum(1 for s in data['sections'] for k in s['categories'] for b in k['chapters'] for i in b['items'] if i['intro'] or i['virtue'] or i['note'])
print('items', n, 'with intro/virtue/note', sp, 'ambiguous', len(ambiguous), 'repeat review rows', len(rep_review))
