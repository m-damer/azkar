"""يفصل «الفضل» عن «التخريج» في الحقل takhrij دون تغيير أي لفظ.

القاعدة: الفضل هو الجملة التي تذكر الأجر/الثواب وتبدأ بـ «من قال/من قرأ/من قالها/من صلى علي»
(أو «قال صلى الله عليه وسلم لمن قال ذلك»)، وتنتهي قبل أول عزو إلى مصدر (رواه/أخرجه/البخاري/مسلم…).
ما قبل الفضل وما بعده يبقى في التخريج بترتيبه. يُحذف التكرار فقط إذا تطابق جزءا التخريج حرفياً.
"""
import json, re
from pathlib import Path

R = Path(__file__).resolve().parents[2]

MARKS = ('رواه|أخرجه|أخرجها|رواها|البخاري|مسلم|أبو داود|أبي داود|الترمذي|النسائي|ابن ماجه|أحمد|الحاكم|صحيح|'
         'انظر|وانظر|متفق|الألباني|ابن السني|الطبراني|سنن|حسنه|صححه|الموطأ|مالك|البيهقي|ابن حبان|ابن خزيمة|'
         'الدارمي|أبو يعلى|الدارقطني|مسند|فتح الباري|الفتح|زاد المعاد|الأدب المفرد|عمل اليوم|السلسلة|الجامع')
MARK = re.compile(r'(?<![ء-ي])و?(?:%s)' % MARKS)
VIRTUE = re.compile(r'(?<![ء-ي])(?<!فضل )(?:من (?:قال|قرأ|قالها|قرأها|صلى علي)|قال صلى الله عليه وسلم لمن قال ذلك)')

def clean(s):
    return re.sub(r'\s+', ' ', s).strip(' ،,')

def split(t):
    m = VIRTUE.search(t)
    if not m:
        return None
    start = m.start()
    e = MARK.search(t, m.end())
    end = e.start() if e else len(t)
    v = clean(t[start:end])
    before, after = clean(t[:start]), clean(t[end:])
    tak = after if before == after else clean(before + ' ' + after)
    if tak.startswith('و') and not before:
        tak = tak[1:].lstrip()
    if not v or not tak:
        return None
    return v.rstrip(' ،,') , tak

# عناصر يظهر فيها «من قال» داخل نص حديث مقتبس لا فضلاً للذكر
SKIP = {'b085-01'}

def apply_chapters(chapters, report):
    for ch in chapters:
        for it in ch['items']:
            t = it.get('takhrij')
            if not t or it.get('virtue') or it['id'] in SKIP:
                continue
            r = split(t)
            if r is None:
                continue
            it['virtue'], it['takhrij'] = r
            report.append({'id': it['id'], 'virtue': r[0], 'takhrij': r[1], 'original': t})
