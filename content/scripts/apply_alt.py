"""يضيف repeatAlt للأذكار التي نصّها الأصلي «عشر مرات أو مائة مرة» حتى يختار المستخدم العدد.

يُستدعى من build_content_imadislam.py بعد apply_hisn، ويمكن تشغيله وحده على content/content.json.
"""
import json, re
from pathlib import Path

R = Path(__file__).resolve().parents[2]
ALT = re.compile(r'(?:مائة|مئة) مرة')


def apply_chapters(chapters):
    n = 0
    for c in chapters:
        for it in c['items']:
            intro = it.get('intro') or ''
            if it.get('repeat') == 10 and 'أو' in intro and ALT.search(intro):
                it['repeatAlt'] = 100
                n += 1
    return n


if __name__ == '__main__':
    p = R / 'content/content.json'
    d = json.load(open(p, encoding='utf-8'))
    n = apply_chapters([c for s in d['sections'] for k in s['categories'] for c in k['chapters']])
    json.dump(d, open(p, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('repeatAlt on', n, 'items')
