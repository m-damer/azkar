#!/usr/bin/env python3
"""يبني content/content.json من content/source/imadislam_raw.json (صفحات imadislam.com).
لا يُعدَّل content.json يدوياً. التصنيف (الأقسام/الفئات) من الهيكل المعتمد سابقاً (content/structure.json).
كل ما يُغيَّر في النص غير حرفي مذكور في docs/06-content-rules.md."""
import re, json, pathlib, difflib, copy
R = pathlib.Path(__file__).resolve().parents[2]
raw = json.load(open(R/'content/source/imadislam_raw.json'))
struct = json.load(open(R/'content/structure.json'))
DIAC = re.compile('[ً-ْٰـ]')
def nrm(s):
    s = DIAC.sub('', s)
    s = re.sub('[إأآٱ]', 'ا', s).replace('ى', 'ي').replace('ة', 'ه')
    return s
NUMPRE = re.compile(r'^(?:\d+\s+)*\d+\s*[-–]\s*')
SRC_WORDS = re.compile(r'البخاري|مسلم|أبو داود|الترمذي|أحمد|النسائي|ابن ماج|الألباني|صحيح|رواه|أخرجه|الحاكم|السني|الطبراني|انظر|سورة|ابن حجر|ابن حبان|البيهقي|الدارمي|مالك|الفتح|مجمع|زاد المعاد|الأرناؤوط|ابن باز|حسنه|صححه')
REVIEW = {'variants': [], 'counts_in_text': [], 'splits': [], 'manual': []}
COUNT_MAP = {'ثلاث مرات': 3, 'ثلاثا': 3, 'ثلاثاً': 3, 'سبع مرات': 7, 'أربع مرات': 4, 'عشر مرات': 10, 'مائة مرة': 100, 'مرتين': 2}

def split_markers(t):
    """ينفصل النص عن علامات ⟦k⟧ ويعيد (نص بلا علامات، [(موضع بالأحرف، k)])"""
    out, marks, pos = [], [], 0
    for m in re.finditer(r'⟦([^⟧]*)⟧', t):
        out.append(t[pos:m.start()]); pos = m.end()
        marks.append((len(''.join(out)), m.group(1)))
    out.append(t[pos:])
    return ''.join(out), marks

def tidy(t):
    t = re.sub(r'\s+', ' ', t).strip()
    t = t.replace('{', '﴿').replace('}', '﴾')
    t = re.sub(r'\s*\*\s*', ' ', t)              # فواصل الآيات في المصدر
    t = re.sub(r'﴿\s+', '﴿', t); t = re.sub(r'\s+﴾', '﴾', t)
    t = re.sub(r'\s+([،؛؟.!:])', r'\1', t)
    t = re.sub(r'([،؛])(?=[^\s\d])', r'\1 ', t)
    t = re.sub(r'﴾(?=[^\s،؛.:)\]»"])', '﴾ ', t)
    t = re.sub(r'(?<=[^\s﴿(\["«])﴿', ' ﴿', t)
    t = re.sub(r'\s+([\u064B-\u0652])', r'\1', t)     # تنوين/حركة منفصلة
    t = re.sub(r'([(\[])\s+', r'\1', t); t = re.sub(r'\s+([)\]])', r'\1', t)
    t = re.sub(r'(?<=[\u0621-\u064A\u064B-\u0652])([(\[])', r' \1', t)
    t = re.sub(r'([)\]])(?=[\u0621-\u064A])', r'\1 ', t)
    t = re.sub(r'\s+', ' ', t).strip()
    return t

def unquote(t):
    """يزيل علامتي التنصيص الخارجيتين، ويحوّل الداخلية إلى « »"""
    t = t.strip()
    t = re.sub(r'\s*"\s*', '"', t) if t.count('"') % 2 == 0 else t
    if t.startswith('"') and t.rstrip(' .').endswith('"') and t.count('"') == 2:
        t = t.strip('. ').strip('"').strip()
        return t
    # علامات داخلية: تزاوج بالتناوب
    parts = t.split('"')
    if len(parts) > 1 and len(parts) % 2 == 1:
        t = ''.join((p + ('«' if i % 2 == 0 else '»') if i < len(parts) - 1 else p) for i, p in enumerate(parts))
        t = re.sub(r'«\s+', '«', t); t = re.sub(r'\s+»', '»', t)
        t = re.sub(r'(?<=[\u0621-\u064A\u064B-\u0652:،])«', ' «', t)
        t = re.sub(r'»(?=[\u0621-\u064A])', '» ', t)
    elif len(parts) > 1:
        REVIEW['manual'].append('تنصيص فردي حُذف: ' + t[:40]); t = t.replace('"', '')
    m = re.fullmatch(r'«([^«»]*)»\s*[،.؛]?', t)
    if m: t = m.group(1).strip()
    return t

def cut_count(t):
    """يستخرج عدّاً من قوس خالص مثل (ثلاث مرات) ويحذفه من النص. يعيد (نص، عدد|None)"""
    cnt = None
    def f(m):
        nonlocal cnt
        w = re.sub(r'\s+', ' ', m.group(1)).strip()
        if w in COUNT_MAP:
            cnt = COUNT_MAP[w]; return ''
        return m.group(0)
    t2 = re.sub(r'\(\s*([^()]*?)\s*\)', f, t)
    return t2, cnt

def build_chapter_items(no):
    ch = raw[str(no)]
    foot_num, foot_star, last = {}, [], None
    for t in ch['foot']:
        m = re.match(r'(\d+)\s*[-–]\s*(.*)$', t)
        if m: foot_num[m.group(1)] = m.group(2).strip(); last = ('n', m.group(1))
        elif t.startswith('*'): foot_star.append(t.lstrip('* ').strip()); last = ('s', len(foot_star)-1)
        elif last:  # تتمة حاشية
            if last[0] == 'n': foot_num[last[1]] += ' ' + t
            else: foot_star[last[1]] += ' ' + t
    groups = []
    for t in ch['body'][1:]:
        if NUMPRE.match(t) or not groups: groups.append([NUMPRE.sub('', t, 1)])
        else: groups[-1].append(t)
    stars = iter(foot_star)
    items = []
    for g in groups:
        parts, nums, snotes = [], [], []
        for p in g:
            body, marks = split_markers(p)
            parts.append(body)
            for _, k in marks:
                if k == '*': snotes.append(next(stars))
                else: nums.append(foot_num[k])
        items.append({'parts': parts, 'nums': nums, 'stars': snotes})
    assert not list(stars), (no, 'نجوم زائدة')
    return ch['body'][0], items

def classify(nums, stars):
    tak, note = [], list(stars)
    for n in nums:
        (tak if SRC_WORDS.search(n) else note).append(n)
    return ('\n'.join(tak) or None), ('\n'.join(note) or None)

# ───────────────────────── التجميع ─────────────────────────
SURAH_SPLIT = re.compile(r'(?=بسم الله الرحمن الرحيم\s*[{﴿])')
def render(parts):
    """يجمع فقرات عنصر واحد: يزيل التنصيص ويفصل بينها بسطر"""
    return '\n'.join(unquote(tidy(p)) for p in parts if tidy(p))

def mk(cid, n, text, repeat=None, intro=None, takhrij=None, note=None, repeat_parts=None):
    d = {'id': f'{cid}-{n:02d}', 'text': text, 'source': '', 'repeat': repeat, 'kind': 'text'}
    for k, v in (('intro', intro), ('takhrij', takhrij), ('note', note)):
        if v: d[k] = v
    if repeat_parts: d['repeatParts'] = repeat_parts
    return d

def split_surahs(text):
    """يفصل ثلاث سور متتالية (الإخلاص/الفلق/الناس) إلى ثلاثة نصوص"""
    segs = [s.strip() for s in SURAH_SPLIT.split(text) if s.strip()]
    return segs

# ─── استبدال المساء في الصباح والمساء ───
def apply_variant(text, pos_words, variant):
    """يستبدل أفضل مقطع قبل/حول موضع الحاشية بنص المساء. يعيد (نص جديد، نسبة التشابه، المقطع الأصلي)"""
    W = text.split(' ')
    V = variant.split(' ')
    nV = nrm(' '.join(V))
    best = (0, None, None)
    for i in range(max(0, pos_words - len(V) - 6), pos_words):
        for j in range(i + 1, min(len(W), pos_words + len(V) + 3) + 1):
            seg = nrm(' '.join(W[i:j]))
            s = difflib.SequenceMatcher(None, seg, nV).ratio()
            if s > best[0] + 1e-9 or (abs(s - best[0]) < 1e-9 and best[1] and j - i < best[2] - best[1]):
                best = (s, i, j)
    s, i, j = best
    seg = ' '.join(W[i:j])
    lead = re.match(r'^["«]*', seg).group(0)
    trail = re.search(r'[\s"»،؛:.]*$', seg).group(0)
    core = seg[len(lead):len(seg) - len(trail)] if trail else seg[len(lead):]
    new = ' '.join(W[:i] + [lead + variant + trail] + W[j:]).strip()
    return new, s, core

def foot_maps(no):
    num, star, last = {}, [], None
    for t in raw[str(no)]['foot']:
        m = re.match(r'(\d+)\s*[-–]\s*(.*)$', t)
        if m: num[m.group(1)] = m.group(2).strip(); last = ('n', m.group(1))
        elif t.startswith('*'): star.append(t.lstrip('* ').strip()); last = ('s', len(star)-1)
        elif last:
            if last[0] == 'n': num[last[1]] += ' ' + t
            else: star[last[1]] += ' ' + t
    return num, star

def groups_with_marks(no):
    groups = []
    for t in raw[str(no)]['body'][1:]:
        if NUMPRE.match(t) or not groups: groups.append([NUMPRE.sub('', t, 1)])
        else: groups[-1].append(t)
    return groups


def sabah_masaa():
    num, _ = foot_maps(27)
    is_ev = lambda k: re.match(r'وإذا أمس[يى]', num[k]) is not None
    groups = groups_with_marks(27)
    morning, evening = [], []
    # جدول يدوي: فهرس المجموعة → (يظهر صباحاً, يظهر مساءً)
    only_m = {19, 20, 21}; only_e = {23}
    for gi, g in enumerate(groups):
        txt = g[0]
        marks = [(m.start(), m.group(1)) for m in re.finditer(r'⟦([^⟧]*)⟧', txt)]
        plain, _ = split_markers(txt)
        ks = [k for _, k in marks]
        tak_ks = [k for k in ks if not is_ev(k)]
        tak, note = classify([num[k] for k in tak_ks], [])
        base = plain
        # ثلاث سور
        if gi == 2:
            body = re.sub(r'\(\s*ثلاث مرات\s*\)', '', base)
            segs = split_surahs(tidy(body))
            assert len(segs) == 3, segs
            for lst in (morning, evening):
                for sgm in segs: lst.append(dict(text=unquote(sgm), repeat=3, takhrij=tak, note=note, gi=gi))
            REVIEW['splits'].append('b027/b027e: السور الثلاث → ثلاث صفحات بعدّاد 3')
            continue
        # العدّاد
        cnt = None
        m_en = re.search(r'\(\s*([^()]*?)\s*\)\s*$', tidy(base).rstrip(' .'))
        cm = re.findall(r'\(\s*([^()]*?)\s*\)', base)
        extra = None
        def eat(b):
            nonlocal cnt, extra
            def f(m):
                nonlocal cnt, extra
                w = re.sub(r'\s+', ' ', m.group(1)).strip()
                for k, v in COUNT_MAP.items():
                    if w == k: cnt = v; return ''
                if w in ('مائة مرة في اليوم',): cnt = 100; return ''
                if w == 'مائة مرة إذا أصبح': cnt = 100; return ''
                if w == 'ثلاث مرات إذا أصبح': cnt = 3; return ''
                if w == 'ثلاث مرات إذا أمسى': cnt = 3; return ''
                if w == 'إذا أصبح': return ''
                if w == 'أو مرة واحدة عند الكسل': extra = 'أو مرة واحدة عند الكسل'; return ''
                return m.group(0)
            return re.sub(r'\(\s*([^()]*?)\s*\)', f, b)
        # الاستبدال المسائي
        m_text = base; e_text = base
        if gi == 3:   # 77 : التعليمة المضمّنة
            m_text = re.sub(r'\s*وإذا أمسي قال ذلك أيضا.*$', '', base)
            e_text = m_text
        elif gi == 4:  # 78 : الثاني داخل النص
            m_text, e_part = re.split(r'\s*وإذا أمسي فليقل\s*:?', base, maxsplit=1)
            e_text = e_part
        # بناء الصباح
        mt = eat(m_text); 
        m_cnt, m_extra = cnt, extra
        cnt = None; extra = None
        et = eat(e_text)
        e_cnt, e_extra = cnt, extra
        # علامات الحواشي تُحذف من النص قبل التقدير الموضعي
        def with_words_pos(text_with_marks, k):
            i = text_with_marks.index(f'⟦{k}⟧')
            before = split_markers(text_with_marks[:i])[0]
            return len(tidy(before).split(' ')) if tidy(before) else 0
        # تطبيق متغيّرات المساء
        if gi == 4:
            m_final = unquote(tidy(mt)); e_final = unquote(tidy(et))
        else:
            e_cur = tidy(split_markers(et)[0]) if False else tidy(mt)
            e_final_t = tidy(mt)
            for k in ks:
                if not is_ev(k): continue
                v = re.sub(r'^وإذا أمس[يى]\s*(قال|فليقل)?\s*:?\s*', '', num[k]).strip()
                v = unquote(tidy(v)).strip(' .')
                pw = with_words_pos(txt, k) - (0)
                new, sc, old = apply_variant(e_final_t, pw, v)
                REVIEW['variants'].append({'item': gi, 'note': k, 'score': round(sc, 2), 'old': old, 'new': v})
                e_final_t = new
            m_final = unquote(tidy(mt)); e_final = unquote(e_final_t)
        ev_tak = tak
        if gi not in only_e:
            morning.append(dict(text=m_final, repeat=m_cnt, takhrij=tak, note=note, extra=m_extra, gi=gi))
        if gi not in only_m:
            evening.append(dict(text=e_final if gi in (3, 4) or True else m_final, repeat=e_cnt if e_cnt else m_cnt, takhrij=tak, note=note, extra=e_extra or m_extra, gi=gi))
    return morning, evening

# ─────────────── بقية الأبواب ───────────────
def one_count(text):
    """يستخرج عدّاً وحيداً من قوس عدّ خالص. يعيد (نص، عدد|None). إن تعددت العدّات يترك النص كما هو."""
    hits = [m for m in re.finditer(r'\(\s*([^()]*?)\s*\)', text) if re.sub(r'\s+', ' ', m.group(1)).strip() in COUNT_MAP]
    if len(hits) != 1: return text, None
    m = hits[0]
    return text[:m.start()] + text[m.end():], COUNT_MAP[re.sub(r'\s+', ' ', m.group(1)).strip()]

def chapter_items(no):
    num, star = foot_maps(no)
    stars = iter(star)
    out = []
    for g in groups_with_marks(no):
        parts, nums, sn = [], [], []
        for p in g:
            body, marks = split_markers(p)
            parts.append(body)
            for _, k in marks:
                if k == '*': sn.append(next(stars))
                else: nums.append(num[k])
        out.append(dict(parts=parts, nums=nums, stars=sn))
    assert not list(stars), no
    return out

def two_part(parts):
    return '\n'.join(parts)

def special(no, gi, g):
    """معالجات يدوية موثّقة. تعيد قائمة عناصر (dict) أو None للمعالجة العامة."""
    tak, note = classify(g['nums'], g['stars'])
    txt = ' '.join(g['parts'])
    def item(text, repeat=None, intro=None, tk=tak, nt=note): return dict(text=text, repeat=repeat, intro=(tidy(intro) if intro else None), takhrij=tk, note=nt)
    SUR = lambda t: [unquote(tidy(x)) for x in split_surahs(tidy(t))]
    if no == 25 and gi == 0:
        m = re.match(r'\s*"\s*أستغفر الله\s*"\s*ثلاثاً\s*\.*\s*"?\s*(.*)$', txt)
        assert m, txt
        return [item('أستغفر الله', 3), item(unquote(tidy(m.group(1))))]
    if no == 25 and gi == 3:
        m = re.search(r'\(\s*ثلاثاً وثلاثين\s*\)\s*(.*)$', txt); tail = unquote(tidy('"' + m.group(1)) if not m.group(1).startswith('"') else tidy(m.group(1)))
        return [item('سبحان الله', 33), item('الحمد لله', 33), item('الله أكبر', 33), item(unquote(tidy(m.group(1))), 1)]
    if no == 25 and gi == 4:
        m = re.match(r'(.*﴾|.*\})\s*(بعد كل صلاة.*)$', txt)
        body, direction = m.group(1), m.group(2)
        return [item(s, None, tidy(direction)) for s in SUR(body)]
    if no == 25 and gi == 5:
        m = re.match(r'(.*[}﴾])\s*(عقب كل صلاة)\s*$', txt)
        return [item(unquote(tidy(m.group(1))), None, m.group(2))]
    if no == 25 and gi == 6:
        m = re.match(r'(.*?)\s*عشر مرات\s*(بعد صلاة المغرب والصبح)\s*\.?$', txt)
        return [item(unquote(tidy(m.group(1))), 10, m.group(2))]
    if no == 25 and gi == 7:
        m = re.match(r'(.*?)\s*(بعد السلام من صلاة الفجر)\s*\.?$', txt)
        return [item(unquote(tidy(m.group(1))), None, m.group(2))]
    if no == 28 and gi == 0:
        pre, rest = re.split(r'(?=بسم الله الرحمن الرحيم\s*\{)', txt, maxsplit=1)
        i = rest.rindex('}') + 1
        sur, post = rest[:i], rest[i:]
        post = re.sub(r'\(\s*يفعل ذلك ثلاث مرات\s*\)', '', post)
        segs = SUR(sur)
        assert len(segs) == 3
        pre_t = tidy(unquote(tidy(pre)).replace(':', ':')); post_t = unquote(tidy(post)).strip(' "')
        return [item(segs[0], 3, pre_t), item(segs[1], 3), item(segs[2], 3, post_t)]
    if no == 28 and gi == 7:
        return [item('سبحان الله', 33), item('الحمد لله', 33), item('الله أكبر', 34)]
    return None

def build_general(no):
    items, n = [], 0
    for gi, g in enumerate(chapter_items(no)):
        sp = special(no, gi, g)
        if sp is None:
            tak, note = classify(g['nums'], g['stars'])
            txt = '\n'.join(g['parts'])
            txt, cnt = one_count(txt)
            mm = re.match(r'^\s*«([^«»]+)»\s*[،,]?\s*(ثلاث مرات|ثلاثاً)\s*\.?\s*$', unquote(tidy(txt)) if cnt is None and txt.count('"') == 2 else txt)
            if cnt is None and mm:
                txt, cnt = mm.group(1), 3
            if cnt is None and re.search(r'\(\s*[^()]*?(مرة|مرات|ثلاثاً|ثلاثا|مرتين)[^()]*\)', txt):
                REVIEW['counts_in_text'].append(f'b{no:03d}#{gi+1}')
            body = '\n'.join(unquote(tidy(p)) for p in txt.split('\n') if tidy(p))
            sp = [dict(text=body, repeat=cnt, intro=None, takhrij=tak, note=note)]
        for x in sp:
            n += 1; items.append(x | {'n': n})
    return items

def finalize(cid, items):
    out = []
    for i, x in enumerate(items, 1):
        t = '\n'.join(re.sub(r'\s+', ' ', l).strip() for l in x['text'].replace('\u0640', '').split('\n'))
        t = re.sub(r'^(بسم الله الرحمن الرحيم)\s*(?=﴿)', r'\1\n', t)
        d = {'id': f'{cid}-{i:02d}', 'text': t, 'source': '', 'repeat': x.get('repeat'), 'kind': 'text'}
        intro = x.get('intro'); extra = x.get('extra')
        if extra: intro = (intro + '، ' if intro else '') + extra
        for k, v in (('intro', intro), ('takhrij', x.get('takhrij')), ('note', x.get('note'))):
            if v: d[k] = v.replace('ـ', '')
        out.append(d)
    return out

def fazl_items():
    num, _ = foot_maps(0)
    body = ' '.join(raw['0']['body'][1:])
    parts = re.findall(r'.*?⟦\d+⟧', body)
    out = []
    for seg in parts:
        seg = seg.strip(' .')
        ks = re.findall(r'⟦(\d+)⟧', seg)
        if not ks: continue
        txt, _m = split_markers(seg)
        tak, note = classify([num[k] for k in ks], [])
        out.append(dict(text=unquote(tidy(txt)).strip(' .'), repeat=None, intro=None, takhrij=tak, note=note))
    return out

def title_of(no):
    return re.sub(r'^\s*\d+\s*[-–]\s*', '', raw[str(no)]['body'][0]).strip()

def main():
    mo, ev = sabah_masaa()
    chapters = {}
    for no in range(1, 133):
        if no == 27: continue
        chapters[no] = [dict(id=f'b{no:03d}', bookNo=no, title=title_of(no), items=finalize(f'b{no:03d}', build_general(no)))]
    # 27: فصلان
    # أول عنصر في الصباح والمساء ليس ذكراً يُعدّ: يُنقل إلى «فضل الذكر»
    first = mo[0]; assert first['text'].startswith('الحمد لله وحده'), first['text']
    mo, ev = mo[1:], ev[1:]
    chapters[0] = [dict(id='b000', bookNo=0, title='فضل الذكر', items=finalize('b000', [first] + fazl_items()))]
    for x in mo + ev:
        if x['text'].startswith('من قال:'):
            x['text'] = re.sub(r'^من قال:\s*«(.*?)»\.?$', r'\1', x['text'])
    chapters[27] = [
        dict(id='b027', bookNo=27, title='أذكار الصباح', items=finalize('b027', mo)),
        dict(id='b027e', bookNo=27, title='أذكار المساء', items=finalize('b027e', ev)),
    ]
    secs = []
    for s in struct['sections']:
        cats = []
        for k in s['categories']:
            chs = [c for no in k['bookNos'] for c in chapters[no]]
            cats.append({'id': k['id'], 'title': k['title'], 'chapters': chs})
        sec = {'id': s['id'], 'title': s['title'], 'categories': cats}
        secs.append(sec)
    import apply_tables, apply_quran
    apply_tables.main_apply([c for s in secs for k in s['categories'] for c in k['chapters']])
    apply_quran.main_apply([c for s in secs for k in s['categories'] for c in k['chapters']])
    import split_virtue
    vrep = []
    split_virtue.apply_chapters([c for s in secs for k in s['categories'] for c in k['chapters']], vrep)
    json.dump(vrep, open(R/'content/review/virtue_split.json', 'w'), ensure_ascii=False, indent=1)
    out = {'source': 'imadislam.com/hisnulmuslim', 'sections': secs}
    json.dump(out, open(R/'content/content.json', 'w'), ensure_ascii=False, indent=1)
    json.dump(REVIEW, open(R/'content/review/imadislam_build.json', 'w'), ensure_ascii=False, indent=1)
    n = sum(len(c['items']) for s in secs for k in s['categories'] for c in k['chapters'])
    print('items', n, 'chapters', sum(len(k['chapters']) for s in secs for k in s['categories']))

if __name__ == '__main__':
    main()
