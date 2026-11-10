"""يطبّق نص المصحف (خط QCF V2) على العناصر القرآنية بعد بناء المحتوى.

المصدر: content/source/quran/verses.json (من api.quran.com، يُجلب عبر workflow «Fetch Quran data and fonts»).
لكل عنصر قرآني تُضاف الحقول: title و quran و taawwudh و mushaf (مقاطع خط لكل صفحة)،
ويُستبدل `text` بنص الآيات العثماني (للبحث والنسخ).
"""
import json, re
from pathlib import Path

R = Path(__file__).resolve().parents[2]
V = json.load(open(R / 'content/source/quran/verses.json'))

_DIAC = re.compile('[ً-ٰٟـۖ-ۭ]')
def plain(s):
    s = _DIAC.sub('', s)
    return s.replace('ٱ', 'ا').replace('أ', 'ا').replace('إ', 'ا').replace('آ', 'ا')

BASMALA = 'بسم الله الرحمن الرحيم'
TAAWWUDH = 'أعوذ بالله من الشيطان الرجيم'
ZW = '​'

# بصمة بداية النص (بلا تشكيل) -> (مفتاح، عنوان، آيات، ترويسة)
SPECS = [
    ('قل هو الله احد', ('112', 'سورة الإخلاص', [f'112:{i}' for i in range(1, 5)], 'basmala')),
    ('قل اعوذ برب الفلق', ('113', 'سورة الفلق', [f'113:{i}' for i in range(1, 6)], 'basmala')),
    ('قل اعوذ برب الناس', ('114', 'سورة الناس', [f'114:{i}' for i in range(1, 7)], 'basmala')),
    ('الله لا اله الا هو الحي القيوم', ('2:255', 'آية الكرسي', ['2:255'], 'taawwudh')),
    ('امن الرسول بما انزل', ('2:285-286', 'أواخر سورة البقرة', ['2:285', '2:286'], 'taawwudh')),
]

def runs(keys):
    out = []
    for k in keys:
        ws = V[k]['words']
        for j, w in enumerate(ws):
            if j + 1 == len(ws):
                sep = ' '
            elif ws[j + 1]['k'] == 'end':
                sep = ''
            else:
                sep = ZW
            if out and out[-1]['p'] == w['p']:
                out[-1]['g'] += w['c'] + sep
            else:
                out.append({'p': w['p'], 'g': w['c'] + sep})
    out[-1]['g'] = out[-1]['g'].rstrip(' ')
    return out

def plain_text(keys, header):
    body = ' '.join(V[k]['text'].strip() for k in keys)
    t = '﴿' + body + '﴾'
    h = {'basmala': BASMALA, 'taawwudh': TAAWWUDH}.get(header)
    return (h + '\n' + t) if h else t

def apply_item(it, spec):
    key, title, keys, header = spec
    d = dict(it)
    d['text'] = plain_text(keys, header)
    d['title'] = title
    d['quran'] = key
    d['header'] = header
    d['mushaf'] = runs(keys)
    return d

def body_of(text):
    t = text.replace('\n', ' ')
    t = re.sub(r'^\s*(بسم الله الرحمن الرحيم|أعوذ بالله من الشيطان الرجيم)\s*', '', t)
    return plain(t).lstrip('﴿ ')

def apply_chapter(ch):
    items, out = ch['items'], []
    for it in items:
        b = body_of(it['text'])
        if b.startswith('يقرا الم تنزيل السجده') or it['text'].startswith('يقرأ ﴿ألم﴾'):
            a = apply_item(it, ('32', 'سورة السجدة', [f'32:{i}' for i in range(1, 31)], 'basmala'))
            m = apply_item(it, ('67', 'سورة الملك', [f'67:{i}' for i in range(1, 31)], 'basmala'))
            out += [a, m]
            continue
        for pre, spec in SPECS:
            if b.startswith(pre):
                it = apply_item(it, spec)
                break
        out.append(it)
    for i, it in enumerate(out, 1):
        it['id'] = f"{ch['id']}-{i:02d}"
    ch['items'] = out

def main_apply(chapters):
    for ch in chapters:
        apply_chapter(ch)
