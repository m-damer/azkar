"""يستبدل محتوى قسم «المزيد من الأذكار والأدعية» بقائمة حصن المسلم الشاملة.

المصدر: content/source/tables/hisn.json (مستخرج حرفياً من hisn_almuslim.docx: 11 قسماً، 214 ذكراً).
كل قسم ← فئة، وكل مناسبة (باب) ← فصل، وكل ذكر ← عنصر (text/virtue/takhrij حرفياً).
تبقى فصول الجلسات الأربعة (b001, b027, b027e, b028) في فئة مخفية لأن الرئيسية تقرأها.
"""
import json, re
from pathlib import Path

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
