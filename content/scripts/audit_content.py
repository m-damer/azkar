#!/usr/bin/env python3
"""تدقيق المحتوى — تقرير فقط، لا يعدّل أي نص. الاستخدام: python3 content/scripts/audit_content.py"""
import json, re, unicodedata, collections, pathlib
R = pathlib.Path(__file__).resolve().parents[2]
c = json.load(open(R/'content/content.json'))
DIAC = re.compile('[ً-ْٰـ]')
def norm(s):
    s = DIAC.sub('', s)
    s = re.sub('[إأآٱ]', 'ا', s).replace('ى', 'ي').replace('ة', 'ه')
    return re.sub(r'\s+', ' ', s).strip()
items = []; chapters = []
for s in c['sections']:
    for cat in s['categories']:
        for ch in cat['chapters']:
            chapters.append((s['id'], ch))
            for it in ch['items']: items.append((ch, it))
rep = collections.defaultdict(list)
def add(k, ch, it, msg=''): rep[k].append({'id': it['id'] if it else ch['id'], 'chapter': ch['title'], 'detail': msg})
ids = collections.Counter(i['id'] for _, i in items)
for _, i in items:
    if ids[i['id']] > 1: rep['معرّف مكرر'].append({'id': i['id']})
nos = sorted(ch['bookNo'] for _, ch in chapters)
gaps = sorted(set(range(1, max(nos)+1)) - set(nos))
if gaps: rep['أرقام أبواب ناقصة'].append({'detail': gaps})
for _, ch in chapters:
    if not ch['items']: add('باب بلا نصوص', ch, None)
OPEN, CLOSE = '({[«﴿', ')}]»﴾'
for ch, it in items:
    t = it['text']
    if not t.strip(): add('نص فارغ', ch, it); continue
    if '  ' in t: add('مسافة مزدوجة', ch, it)
    if t != t.strip(): add('مسافة طرفية', ch, it)
    if re.search('[A-Za-z]', t): add('أحرف لاتينية', ch, it, ''.join(re.findall('[A-Za-z]+', t))[:30])
    if re.search('[0-9٠-٩]', t): add('أرقام داخل النص', ch, it, ''.join(re.findall('[0-9٠-٩]+', t))[:30])
    if re.search('[​-‏‪-‮ ﻿]', t): add('محارف خفية/NBSP', ch, it)
    if 'ـ' in t: add('تطويل', ch, it)
    for o, cl in zip(OPEN, CLOSE):
        if t.count(o) != t.count(cl): add('أقواس غير متوازنة', ch, it, o+cl)
    if not DIAC.search(t.replace('ـ', '')): add('بلا تشكيل', ch, it)
    if not re.search(r'[.!؟?»﴾)\]"”:؛…]\s*$', t): add('بلا علامة ختام', ch, it, t[-20:])
    if not (it.get('takhrij') or '').strip(): add('بلا تخريج', ch, it)
    if it.get('splitReviewed') is False: add('تقسيم غير مراجَع', ch, it)
    m = re.search(r'\(([^)]*?(مرة|مرات|مره)[^)]*)\)', norm(t).replace('ه', 'ة'))
    if m and not it.get('repeat'): add('عدد مذكور في النص وrepeat فارغ', ch, it, m.group(1))
    if it.get('repeat') and m: add('عدد مكرر: في النص وفي العدّاد', ch, it, f"repeat={it['repeat']} / {m.group(1)}")
seen = collections.defaultdict(list)
for ch, it in items: seen[norm(it['text'])].append((ch, it))
for k, v in seen.items():
    if len(v) > 1: rep['نص مكرر بعد التطبيع'].append({'id': [i['id'] for _, i in v], 'detail': k[:50]})
b27 = None
split = {'صباح فقط': [], 'مساء فقط': [], 'مشترك': []}
if b27:
    for it in b27['items']:
        n = norm(it['text']); a = 'اصبحنا' in n or 'اصبح ' in n; m_ = 'امسينا' in n or 'امسى' in n
        split['صباح فقط' if a and not m_ else 'مساء فقط' if m_ and not a else 'مشترك'].append(it['id'])
summary = {k: len(v) for k, v in sorted(rep.items(), key=lambda x: -len(x[1]))}
out = {'items': len(items), 'chapters': len(chapters), 'summary': summary, 'b027_split': {k: len(v) for k, v in split.items()}, 'b027_ids': split, 'findings': rep}
json.dump(out, open(R/'content/audit_report.json', 'w'), ensure_ascii=False, indent=1)
L = ['# تدقيق المحتوى (آلي — تقرير فقط، لم يُعدَّل أي نص)', '', f'- النصوص: {len(items)} — الأبواب: {len(chapters)}', '', '## الملخص', '', '| الفحص | العدد |', '|---|---|']
L += [f'| {k} | {v} |' for k, v in summary.items()] or ['| (لا ملاحظات) | 0 |']
L += ['', '## أذكار الصباح والمساء (b027)', '', ' / '.join(f'{k}: {len(v)}' for k, v in split.items()), '', 'التفاصيل الكاملة: `content/audit_report.json`']
open(R/'docs/05-content-audit.md', 'w').write('\n'.join(L)+'\n')
print(json.dumps(out['summary'], ensure_ascii=False, indent=1)); print(out['b027_split'], len(items), len(chapters))
