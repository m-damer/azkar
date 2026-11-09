#!/usr/bin/env python3
"""يحلّل صفحات imadislam المحفوظة (content/source/imadislam/*.htm) إلى content/source/imadislam_raw.json
لا يعدّل أي نص: يحذف فقط علامات الحواشي ويسجلها بمواضعها ⟦K⟧."""
import re, json, pathlib, sys
from bs4 import BeautifulSoup, NavigableString, Tag
R = pathlib.Path(__file__).resolve().parents[2]
SRC = R/'content/source/imadislam'
def para_text(p):
    # يستبدل مراجع الحواشي (a name=_ftnrefK) بـ ⟦K⟧ ويحذف أي نص بداخلها
    for a in p.find_all('a'):
        n = a.get('name') or ''
        if re.match(r'_ftnref\d+$', n):
            shown = re.sub(r'[\s\[\]]', '', a.get_text())
            a.replace_with(NavigableString(f'⟦{shown}⟧'))
    return re.sub(r'\s+', ' ', p.get_text(' ')).strip()
def parse(path):
    s = BeautifulSoup(open(path, encoding='utf-8').read().replace('\ufffd', '–'), 'lxml')
    for x in s.find_all(['script', 'style']): x.decompose()
    paras = [p for p in s.find_all(['p', 'div', 'li']) if not p.find(['p', 'div', 'li'])]
    out = {'body': [], 'foot': []}
    infoot = False
    for p in paras:
        fn = None
        for a in p.find_all('a'):
            m = re.match(r'_ftn(\d+)$', a.get('name') or '')
            if m: fn = int(m.group(1)); break
        t = para_text(p)
        if not t or t == 'من أذكار الكتاب والسنة': continue
        if not infoot and (fn is not None or (len(out['body']) >= 2 and '⟦' not in t and re.match(r'(\*|1\s*[-–])', t))):
            infoot = True
        if infoot:
            out['foot'].append(t)
        else:
            out['body'].append(t)
    return out
if __name__ == '__main__':
    res = {}
    for i in range(1, 133):
        res[i] = parse(SRC/f'{i:03d}.htm')
    f = parse(SRC/'fazlolzkr.htm')
    f['foot'] = [re.sub(r'^\[(\d+)\]\s*-', r'\1 -', t) for t in f['foot']]
    res[0] = f
    json.dump(res, open(R/'content/source/imadislam_raw.json', 'w'), ensure_ascii=False, indent=1)
    bad = sum(v['body'][k].count('�') for v in res.values() for k in range(len(v['body'])))
    print('chapters', len(res), 'U+FFFD in body', bad)
