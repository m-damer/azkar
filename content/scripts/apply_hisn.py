"""يستبدل محتوى قسم «المزيد من الأذكار والأدعية» بقائمة حصن المسلم الشاملة.

المصدر: content/source/tables/hisn.json (مستخرج حرفياً من hisn_almuslim.docx: 11 قسماً، 214 ذكراً).
كل قسم ← فئة، وكل مناسبة (باب) ← فصل، وكل ذكر ← عنصر (text/virtue/takhrij حرفياً).
تبقى فصول الجلسات الأربعة (b001, b027, b027e, b028) في فئة مخفية لأن الرئيسية تقرأها.
"""
import json, re
from pathlib import Path

import apply_quran as Q

R = Path(__file__).resolve().parents[2]
H = json.load(open(R / 'content/source/tables/hisn.json'))
SESSION_IDS = {'b001', 'b027', 'b027e', 'b028'}
SECTION_TITLE = 'المزيد من الأذكار والأدعية'

_DIAC = re.compile('[ً-ٰٟـ]')
def bare(s):
    return _DIAC.sub('', s).replace('أ', 'ا').replace('إ', 'ا').replace('ٱ', 'ا')

NUMS = [('مائة', 100), ('مئة', 100), ('سبعين', 70), ('سبع', 7), ('عشر', 10), ('ثلاثا', 3), ('ثلاث', 3), ('مرتان', 2), ('مرتين', 2)]

def parse_rep(rep):
    """يعيد (repeat, intro): العدد حين يكون صريحاً، والعبارة الأصلية مقدّمةً إن كان فيها شرط."""
    b = bare(rep).strip()
    if b == 'مرة واحدة':
        return 1, None
    if b.startswith('مرة واحدة'):
        return 1, rep
    if b.startswith('اكثر من') or 'ثلاثا وثلاثين' in b or 'ثلاثا للاستغفار' in b or 'ثلاثا (للتكبير' in b:
        return None, rep
    if ('،' in b or 'تكبيرات' in b) and not b.startswith('مرة'):
        return None, rep
    if b.startswith(('ثلاث', 'مرتان', 'سبع', 'عشر', 'مائة', 'مئة')):
        for w, n in NUMS:
            if b.startswith(w):
                plain = re.fullmatch(r'(ثلاثا|ثلاث مرات|مرتان|سبع مرات|مائة مرة|مئة مرة)( في اليوم)?', b) is not None
                return n, (None if plain else rep)
    return None, rep

MUAWWIDHAT = [
    ('112', 'سورة الإخلاص', [f'112:{i}' for i in range(1, 5)], 'basmala'),
    ('113', 'سورة الفلق', [f'113:{i}' for i in range(1, 6)], 'basmala'),
    ('114', 'سورة الناس', [f'114:{i}' for i in range(1, 7)], 'basmala'),
]

def _extras(r, it):
    if r['virtue']:
        it['virtue'] = r['virtue']
    if r['src']:
        it['takhrij'] = r['src']
    return it

def special(r, cur):
    """57: كل تسبيحة بصفحة ×33 ثم التهليل ×1. 58: كل سورة من المعوذات بصفحتها ×3."""
    base = {'source': '', 'kind': 'text'}
    out = []
    if r['n'] == 57:
        body = r['text'].strip().lstrip('«').rstrip('»')
        head, tail = body.split('(')[0], body.split(')')[-1]
        for w in [x.strip() for x in head.split('،')]:
            w = re.sub('^وَ', '', w)
            out.append(('«%s»' % w, 33))
        out.append(('«%s»' % tail.strip(), 1))
        items = [dict(base, text=t, repeat=n) for t, n in out]
    else:
        items = []
        for spec in MUAWWIDHAT:
            d = Q.apply_item(dict(base, text='', repeat=3), spec)
            d['intro'] = r['rep']
            items.append(d)
    for i, it in enumerate(items, len(cur['items']) + 1):
        it['id'] = f'{cur["id"]}-{i:02d}'
        _extras(r, it)
    return items

def build_categories():
    cats = []
    for s in H:
        cid = f's1h{s["no"]:02d}'
        chapters, cur, last = [], None, None
        for r in s['items']:
            if r['occ'] != last:
                cur = {'id': f'h{r["n"]:03d}', 'bookNo': r['n'], 'title': r['occ'], 'items': []}
                chapters.append(cur)
                last = r['occ']
            if r['n'] in (57, 58):
                cur['items'] += special(r, cur)
                continue
            rep, intro = parse_rep(r['rep'])
            it = {'id': f'{cur["id"]}-{len(cur["items"]) + 1:02d}', 'text': r['text'], 'source': '',
                  'kind': 'text', 'repeat': rep}
            if intro:
                it['intro'] = intro
            if r['virtue']:
                it['virtue'] = r['virtue']
            if r['src']:
                it['takhrij'] = r['src']
            cur['items'].append(it)
        cats.append({'id': cid, 'title': s['title'], 'chapters': chapters})
    return cats

def apply(secs):
    s1 = next(s for s in secs if s['id'] == 's1')
    keep = [c for k in s1['categories'] for c in k['chapters'] if c['id'] in SESSION_IDS]
    s1['title'] = SECTION_TITLE
    s1['categories'] = [{'id': 's1c0', 'title': 'أذكار اليوم', 'chapters': keep}] + build_categories()
    s2 = next(s for s in secs if s['id'] == 's2')
    s2['title'] = 'من أدعية الرسول ﷺ'
    s2['categories'] = []
