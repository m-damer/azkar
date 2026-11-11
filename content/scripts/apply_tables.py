"""يستبدل محتوى أذكار الصباح والمساء والنوم والاستيقاظ بجداول محمود (content/source/tables).

كل صف: عنوان | عدد | نص | فضل | تخريج. تُحفظ الألفاظ كما هي. الصفوف القرآنية تُعرض بخط المصحف
(apply_quran)، والمعوذات الثلاث تُفصل إلى ثلاث صفحات بعدّاد ثلاث مرات لكل صفحة.
"""
import json
from pathlib import Path
import apply_quran as Q

R = Path(__file__).resolve().parents[2]
T = json.load(open(R / 'content/source/tables/tables.json'))

CHAPTERS = {'sabah': 'b027', 'masaa': 'b027e', 'nawm': 'b028', 'istiqaz': 'b001'}

def rng(c, a, b):
    return [f'{c}:{i}' for i in range(a, b + 1)]

KURSI = ('2:255', 'آية الكرسي', ['2:255'], 'taawwudh')
BAQARA = ('2:285-286', 'أواخر سورة البقرة', ['2:285', '2:286'], 'taawwudh')
IKHLAS = ('112', 'سورة الإخلاص', rng(112, 1, 4), 'basmala')
FALAQ = ('113', 'سورة الفلق', rng(113, 1, 5), 'basmala')
NAS = ('114', 'سورة الناس', rng(114, 1, 6), 'basmala')
SAJDA = ('32', 'سورة السجدة', rng(32, 1, 30), 'basmala')
MULK = ('67', 'سورة الملك', rng(67, 1, 30), 'basmala')
IMRAN = ('3:190-200', 'أواخر سورة آل عمران', rng(3, 190, 200), None)
MUAWWIDHAT = [IKHLAS, FALAQ, NAS]

COUNTS = {
    'مرة واحدة': None, 'ثلاث مرات': 3, 'أربع مرات': 4, 'سبع مرات': 7, 'عشر مرات': 10,
    'عشر مرات أو مائة مرة': 10, 'مائة مرة': 100, '٣٣ مرة': 33, '٣٤ مرة': 34,
}

NAFTH_PRE = 'يجمع كفيه ثم ينفث فيهما فيقرأ'
NAFTH_POST = 'ثم يمسح بهما ما استطاع من جسده، يبدأ بهما على رأسه ووجهه وما أقبل من جسده'

def base(row):
    d = {'source': '', 'kind': 'text'}
    if row['virtue']:
        d['virtue'] = row['virtue']
    if row['takhrij']:
        d['takhrij'] = row['takhrij']
    return d

def rows_to_items(rows):
    out = []
    for r in rows:
        title, cnt = r['title'], COUNTS[r['count']]
        if title.startswith('المعوذات') or title.startswith('قراءة المعوذات'):
            for i, spec in enumerate(MUAWWIDHAT):
                d = base(r)
                d['repeat'] = cnt
                if title.startswith('قراءة المعوذات'):
                    if i == 0:
                        d['intro'] = NAFTH_PRE
                    if i == 2:
                        d['intro'] = NAFTH_POST
                out.append(Q.apply_item(d | {'text': ''}, spec))
            continue
        spec = {'آية الكرسي': KURSI, 'خواتيم سورة البقرة': BAQARA, 'قراءة سورة السجدة': SAJDA,
                'قراءة سورة الملك': MULK, 'قراءة أواخر سورة آل عمران': IMRAN}.get(title)
        d = base(r)
        d['repeat'] = cnt
        d['title'] = title
        if spec:
            it = Q.apply_item(d | {'text': ''}, spec)
            it['title'] = title
            out.append(it)
            continue
        d['text'] = r['text']
        if r['count'] == 'عشر مرات أو مائة مرة':
            d['intro'] = r['count']
        out.append(d)
    return out

def main_apply(chapters):
    byid = {c['id']: c for c in chapters}
    for key, cid in CHAPTERS.items():
        ch = byid[cid]
        items = rows_to_items(T[key])
        for i, it in enumerate(items, 1):
            it['id'] = f'{cid}-{i:02d}'
        ch['items'] = items
