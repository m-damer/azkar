#!/usr/bin/env python3
"""يرسم صور شاشات التطبيق لصفحة الهبوط من ألوان التطبيق وخطوطه ونصوصه الفعلية.

الاستخدام: python3 tools/make_screens.py  (يحتاج google-chrome و Pillow)
المخرجات: site/img/*.webp
"""
import json, pathlib, subprocess, html, shutil, tempfile
from PIL import Image

R = pathlib.Path(__file__).resolve().parents[1]
OUT = R / 'site' / 'img'
OUT.mkdir(parents=True, exist_ok=True)
C = json.load(open(R / 'content/content.json'))
CH = {b['id']: b for s in C['sections'] for k in s['categories'] for b in k['chapters']}

def find(chapter, title=None, idx=None):
    items = CH[chapter]['items']
    return next(i for i in items if i.get('title') == title) if title else items[idx]

morning = find('b027', title='التسبيح اليومي')   # سبحان الله وبحمده ×100
sleep_it = find('b028', idx=0)
kursi = find('b027', title='آية الكرسي')
cats = C['sections'][0]['categories'][1:]

AR = str.maketrans('0123456789', '٠١٢٣٤٥٦٧٨٩')
def ar(n): return str(n).translate(AR)

def strip_q(t): return t.strip('«»').split('\n')[0]

IC = {
 'search': 'M15.5 14h-.79l-.28-.27A6.47 6.47 0 0 0 16 9.5 6.5 6.5 0 1 0 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z',
 'heart': 'M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 3.78 3.4 6.86 8.55 11.54L12 21.35l1.45-1.32C18.6 15.36 22 12.28 22 8.5 22 5.42 19.58 3 16.5 3zm-4.4 15.55-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05z',
 'heartf': 'M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z',
 'close': 'M19 6.41 17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z',
 'right': 'M10 6 8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z',
 'left': 'M15.41 7.41 14 6l-6 6 6 6 1.41-1.59L10.83 12z',
 'list': 'M4 10.5c-.83 0-1.5.67-1.5 1.5s.67 1.5 1.5 1.5 1.5-.67 1.5-1.5-.67-1.5-1.5-1.5zm0-6c-.83 0-1.5.67-1.5 1.5S3.17 7.5 4 7.5 5.5 6.83 5.5 6 4.83 4.5 4 4.5zm0 12c-.83 0-1.5.68-1.5 1.5s.68 1.5 1.5 1.5 1.5-.68 1.5-1.5-.67-1.5-1.5-1.5zM7 19h14v-2H7v2zm0-6h14v-2H7v2zm0-8v2h14V5H7z',
 'book': 'M21 5c-1.11-.35-2.33-.5-3.5-.5-1.95 0-4.05.4-5.5 1.5-1.45-1.1-3.55-1.5-5.5-1.5S2.45 4.9 1 6v14.65c0 .25.25.5.5.5.1 0 .15-.05.25-.05C3.1 20.45 5.05 20 6.5 20c1.95 0 4.05.4 5.5 1.5 1.35-.85 3.8-1.5 5.5-1.5 1.65 0 3.35.3 4.75 1.05.1.05.15.05.25.05.25 0 .5-.25.5-.5V6c-.6-.45-1.25-.75-2-1zm0 13.5c-1.1-.35-2.3-.5-3.5-.5-1.7 0-4.15.65-5.5 1.5V8c1.35-.85 3.8-1.5 5.5-1.5 1.2 0 2.4.15 3.5.5v11.5z',
 'moon': 'M12 3a9 9 0 1 0 9 9c0-.46-.04-.92-.1-1.36a5.389 5.389 0 0 1-4.4 2.26 5.403 5.403 0 0 1-3.14-9.8c-.44-.06-.9-.1-1.36-.1z',
 'sun': 'M12 7a5 5 0 1 0 0 10 5 5 0 0 0 0-10zM2 13h2v-2H2v2zm18 0h2v-2h-2v2zM11 2v2h2V2h-2zm0 18v2h2v-2h-2zM5.99 4.58 4.58 5.99l1.41 1.41 1.41-1.41-1.41-1.41zm12.37 12.37-1.41 1.41 1.41 1.41 1.41-1.41-1.41-1.41zm1.41-11.96-1.41-1.41-1.41 1.41 1.41 1.41 1.41-1.41zM7.4 18.36 5.99 16.95l-1.41 1.41 1.41 1.41 1.41-1.41z',
 'twilight': 'M5 18h14v2H5zm7-11a6 6 0 0 0-6 6v2h12v-2a6 6 0 0 0-6-6zM11 2v3h2V2h-2zM3.5 6.1 2.1 7.5l2.1 2.1 1.4-1.4-2.1-2.1zm17 0-2.1 2.1 1.4 1.4 2.1-2.1-1.4-1.4z',
 'alarm': 'M12 4a8 8 0 1 0 0 16 8 8 0 0 0 0-16zm.5 4H11v5l4 2.4.8-1.2-3.3-2V8zM7.9 2.3 2.3 6.9l1.3 1.5 5.6-4.6-1.3-1.5zm8.2 0-1.3 1.5 5.6 4.6 1.3-1.5-5.6-4.6z',
 'plus': 'M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm5 11h-4v4h-2v-4H7v-2h4V7h2v4h4v2z',
 'tune': 'M3 17v2h6v-2H3zM3 5v2h10V5H3zm10 16v-2h8v-2h-8v-2h-2v6h2zM7 9v2H3v2h4v2h2V9H7zm14 4v-2H11v2h10zm-6-4h2V7h4V5h-4V3h-2v6z',
 'bell': 'M12 22c1.1 0 2-.9 2-2h-4a2 2 0 0 0 2 2zm6-6v-5c0-3.07-1.63-5.64-4.5-6.32V4a1.5 1.5 0 0 0-3 0v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z',
 'text': 'M2.5 4v3h5v12h3V7h5V4h-13zm19 5h-9v3h3v7h3v-7h3V9z',
 'widgets': 'M13 13v8h8v-8h-8zM3 21h8v-8H3v8zM3 3v8h8V3H3zm13.66-1.31L11 7.34 16.66 13l5.66-5.66-5.66-5.65z',
 'fire': 'M13.5.67s.74 2.65.74 4.8c0 2.06-1.35 3.73-3.41 3.73-2.07 0-3.63-1.67-3.63-3.73l.03-.36C5.21 7.51 4 10.62 4 14c0 4.42 3.58 8 8 8s8-3.58 8-8C20 8.61 17.41 3.8 13.5.67zM11.71 19c-1.78 0-3.22-1.4-3.22-3.14 0-1.62 1.05-2.76 2.81-3.12 1.77-.36 3.6-1.21 4.62-2.58.39 1.29.59 2.65.59 4.04 0 2.65-2.15 4.8-4.8 4.8z',
 'info': 'M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z',
 'update': 'M21 3H3c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h5v2h8v-2h5c1.1 0 1.99-.9 1.99-2L23 5c0-1.1-.9-2-2-2zm-5 9-4 4-4-4h3V8h2v4h3z',
 'check': 'M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z',
 'drag': 'M20 9H4v2h16V9zM4 15h16v-2H4v2z',
 'eye': 'M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17a5 5 0 1 1 0-10 5 5 0 0 1 0 10zm0-8a3 3 0 1 0 0 6 3 3 0 0 0 0-6z',
 'trash': 'M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z',
}
def ic(name, size=24, color='currentColor'):
    return f'<svg viewBox="0 0 24 24" width="{size}" height="{size}" fill="{color}"><path d="{IC[name]}"/></svg>'

LIGHT = dict(base='#F4EDE0', raised='#FBF7EE', sunken='#EFE5D0', border='#D8CCB2', text='#2B2A24', text2='#625B4B',
  accent='#5B6B3A', onaccent='#F6F0E4', warm='#F2D2A9', onwarm='#3B2A12', iconwarm='#8A4E2B',
  morning='#F2D2A9', onmorning='#3B2A12', evening='#E4D6B8', onevening='#2B2A24', wake='#EBC4B0', onwake='#4A2414',
  sleep='#8A4524', onsleep='#FFF8EE', done='#5B6B3A', ondone='#F6F0E4', nav='#2B2A24', onnav='#F2D2A9', danger='#9A2F1B')
DARK = dict(base='#1E1C17', raised='#2A2720', sunken='#38342A', border='#4A4538', text='#EDE6D6', text2='#B4AB97',
  accent='#9DB06B', onaccent='#16140F', warm='#E3B77F', onwarm='#2B1D0A', iconwarm='#E0925E',
  morning='#8A6330', onmorning='#FFF3DF', evening='#4A4130', onevening='#EDE6D6', wake='#6E4A3A', onwake='#FFEFE4',
  sleep='#A2522B', onsleep='#FFF8EE', done='#2F3A1D', ondone='#EEF2DF', nav='#EDE6D6', onnav='#2B2A24', danger='#F0907A')

FONTS = f'''
@font-face{{font-family:Plex;src:url(file://{R}/assets/fonts/IBMPlexSansArabic-Regular.ttf);font-weight:400}}
@font-face{{font-family:Plex;src:url(file://{R}/assets/fonts/IBMPlexSansArabic-Medium.ttf);font-weight:500}}
@font-face{{font-family:Plex;src:url(file://{R}/assets/fonts/IBMPlexSansArabic-Bold.ttf);font-weight:700}}
@font-face{{font-family:Amiri;src:url(file://{R}/assets/fonts/Amiri-Regular.ttf)}}
@font-face{{font-family:QCF2BSML;src:url(file://{R}/assets/fonts/mushaf/QCF2BSML.ttf)}}
@font-face{{font-family:QCF2042;src:url(file://{R}/assets/fonts/mushaf/QCF2042.ttf)}}
'''

def page(c, body, nav=None):
    css = FONTS + ''.join(f'--{k}:{v};' for k, v in []) 
    vars_ = ''.join(f'--{k}:{v};' for k, v in c.items())
    navhtml = ''
    if nav is not None:
        items = [('twilight', 'اليوم'), ('plus', 'أوراد'), ('tune', 'الإعدادات')]
        navhtml = '<div class="nav">' + ''.join(
            f'<div class="ni{" on" if i == nav else ""}">{ic(n, 24)}<span>{l}</span></div>' for i, (n, l) in enumerate(items)) + '</div>'
    return f'''<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><style>
{FONTS}
:root{{{vars_}}}
*{{box-sizing:border-box;margin:0;padding:0}}
html,body{{width:390px;height:844px;overflow:hidden}}
body{{background:var(--base);color:var(--text);font-family:Plex,sans-serif;font-size:16px;line-height:24px;position:relative}}
.scr{{position:absolute;inset:0;padding:30px 20px 0;display:flex;flex-direction:column}}
.row{{display:flex;align-items:center}}
.b{{font-weight:700}} .c2{{color:var(--text2)}} .cap{{font-size:12px;line-height:20px;font-weight:500}}
.rbtn{{width:44px;height:44px;border-radius:50%;display:grid;place-items:center;background:var(--raised)}}
.nav{{position:absolute;left:20px;right:20px;bottom:26px;height:68px;border-radius:999px;background:var(--raised);border:1px solid var(--border);display:flex;padding:4px}}
.ni{{flex:1;border-radius:999px;display:flex;flex-direction:column;align-items:center;justify-content:center;font-size:13px;line-height:16px;color:var(--text2);gap:2px}}
.ni.on{{background:var(--nav);color:var(--onnav);font-weight:700}}
.hdr{{display:flex;align-items:center;gap:12px;padding:6px 0 14px}}
.hdr h1{{font-size:22px;line-height:30px;font-weight:700}}
.card{{background:var(--raised);border-radius:20px}}
.irow{{background:var(--raised);border-radius:20px;padding:12px 16px;display:flex;align-items:center;gap:12px;min-height:64px;margin-bottom:10px}}
.irow .t{{flex:1;font-weight:700;line-height:24px}}
.irow .s{{font-size:12px;line-height:20px;color:var(--text2);font-weight:500}}
.irow svg.chev{{color:var(--text2)}}
.tile{{border-radius:28px;padding:16px;display:flex;flex-direction:column;justify-content:space-between}}
.tile .tt{{font-weight:700;font-size:20px;line-height:28px}}
.tile .ts{{font-size:12px;line-height:20px;opacity:.85;font-weight:500}}
.chip{{align-self:flex-start;border-radius:999px;padding:2px 12px;font-size:12px;line-height:20px;font-weight:700;background:rgba(0,0,0,.12)}}
.link{{border-radius:24px;padding:12px 16px;display:flex;align-items:center;gap:12px}}
.link .t{{font-weight:700;line-height:22px}}
.link .s{{font-size:12px;line-height:18px;opacity:.85}}
.gl{{font-size:13px;font-weight:700;color:var(--text2);padding:0 8px 8px}}
</style></head><body>{body}{navhtml}</body></html>'''

# ---------------- screens ----------------
def home(c):
    return f'''<div class="scr" style="padding-bottom:110px">
<div class="row" style="height:30px;gap:8px;background:var(--raised);border-radius:999px;padding:0 14px;margin-bottom:10px;font-size:12px;font-weight:700"><span style="color:var(--iconwarm)">{ic('fire',16)}</span><span>سلسلتك ٧ أيام</span></div>
<div class="row" style="justify-content:space-between;margin-bottom:10px"><div class="b" style="font-size:28px;line-height:36px">صباح الخير</div><div class="rbtn">{ic('search',24)}</div></div>
<div style="display:flex;flex-direction:column;gap:10px;flex:1">
 <div class="tile" style="flex:4;background:var(--morning);color:var(--onmorning)"><div style="display:flex;justify-content:space-between;align-items:flex-start">{ic('twilight',40)}<span class="chip">الآن</span></div><div><div class="tt" style="font-size:26px;line-height:34px">أذكار الصباح</div><div class="ts">ابدأ يومك بذكر الله</div></div></div>
 <div style="flex:3;display:flex;gap:10px">
  <div class="tile" style="flex:1;background:var(--evening);color:var(--onevening)">{ic('sun',32)}<div><div class="tt">أذكار المساء</div><div class="ts">بعد العصر</div></div></div>
  <div class="tile" style="flex:1;background:var(--sleep);color:var(--onsleep)">{ic('moon',32)}<div><div class="tt">أذكار النوم</div><div class="ts">قبل النوم</div></div></div>
 </div>
 <div style="flex:3;display:flex;gap:10px">
  <div class="tile" style="flex:3;background:var(--wake);color:var(--onwake)">{ic('alarm',32)}<div><div class="tt">الاستيقاظ من النوم</div><div class="ts">أول ما تفتح عينيك</div></div></div>
  <div class="tile" style="flex:2;background:var(--raised)"><span style="color:var(--iconwarm)">{ic('heart',32)}</span><div><div class="tt" style="font-size:18px">المفضلة</div><div class="ts">٣٢ عنصراً</div></div></div>
 </div>
 <div class="link" style="background:var(--warm);color:var(--onwarm)">{ic('list',28)}<div><div class="t">المزيد من الأذكار والأدعية</div><div class="s">من كتاب حصن المسلم</div></div></div>
 <div class="link" style="background:var(--evening);color:var(--onevening)">{ic('book',28)}<div><div class="t">من أدعية الرسول ﷺ</div><div class="s">قريباً</div></div></div>
</div></div>'''

def reader(c, item, heading, title, pos, total, count, tot, done=False):
    txt = strip_q(item['text'])
    return f'''<div class="scr" style="padding:30px 0 0">
<div style="padding:0 20px"><div class="row" style="gap:6px">
 <div class="rbtn" style="background:var(--text);color:var(--base)">{ic('close',24)}</div>
 <div style="flex:1;text-align:center;font-weight:700">{title}</div>
 <div class="cap">{ar(pos)} / {ar(total)}</div>
 <div class="rbtn" style="background:none;color:var(--text)">{ic('heart',24)}</div>
 <div class="rbtn" style="background:none;border:2px solid var(--text);color:var(--text)">{ic('list',22)}</div>
</div>
<div style="height:6px;border-radius:99px;background:rgba(128,128,128,.25);margin:8px 0 12px;overflow:hidden"><div style="height:100%;width:{int(100*pos/total)}%;background:var(--text);margin-inline-start:auto"></div></div>
<div class="card" style="text-align:center;padding:12px;font-weight:700;margin-bottom:8px;border-radius:24px">{heading}</div></div>
<div class="card" style="flex:1;border-radius:32px;margin:0 0 12px;display:flex;flex-direction:column;justify-content:center;align-items:center;padding:30px 26px;gap:16px;text-align:center">
 <div style="font-family:Amiri;font-size:34px;line-height:2.1;font-weight:400">«{txt}»</div>
 
</div>
<div style="padding:0 20px 26px">
 <div class="row" style="justify-content:center;height:52px;border:2px solid var(--text);border-radius:99px;gap:8px;font-weight:700;margin-bottom:12px">{ic('book',22)}الفضل والتخريج</div>
 <div class="row" style="gap:12px">
  <div class="rbtn" style="width:56px;height:56px;border:2px solid var(--text);background:none;color:var(--text);opacity:.45">{ic('left',26)}</div>
  <div class="row" style="flex:1;height:80px;border-radius:28px;background:{'var(--done)' if done else 'var(--text)'};color:{'var(--ondone)' if done else 'var(--base)'};padding:0 22px;justify-content:space-between">
   <div><div class="b" style="font-size:17px;line-height:24px">{'اكتمل' if done else 'اضغط للعدّ'}</div><div class="cap">{tot}</div></div>
   {ic('check',40) if done else f'<div class="b" style="font-size:38px">{count}</div>'}
  </div>
  <div class="rbtn" style="width:56px;height:56px;border:2px solid var(--text);background:none;color:var(--text)">{ic('right',26)}</div>
 </div>
</div></div>'''

def kursi_reader(c):
    g = kursi['mushaf'][0]['g']
    return f'''<div class="scr" style="padding:30px 0 0">
<div style="padding:0 20px"><div class="row" style="gap:6px">
 <div class="rbtn" style="background:var(--text);color:var(--base)">{ic('close',24)}</div>
 <div style="flex:1;text-align:center;font-weight:700">أذكار الصباح</div>
 <div class="cap">١ / ٢٣</div>
 <div class="rbtn" style="background:none;color:var(--text)">{ic('heart',24)}</div>
 <div class="rbtn" style="background:none;border:2px solid var(--text);color:var(--text)">{ic('list',22)}</div>
</div>
<div style="height:6px;border-radius:99px;background:rgba(128,128,128,.25);margin:8px 0 12px"></div>
<div class="card" style="text-align:center;padding:12px;font-weight:700;margin-bottom:8px;border-radius:24px">آية الكرسي</div></div>
<div class="card" style="flex:1;border-radius:32px;margin:0 0 12px;display:flex;flex-direction:column;justify-content:center;align-items:center;padding:20px 10px;gap:18px;text-align:center">
 <div style="font-family:QCF2BSML;font-size:26px;line-height:1.6;display:flex;flex-direction:row;direction:rtl;gap:7px;justify-content:center"><span>G</span><span>H</span><span>D</span><span>E</span><span>F</span></div>
 <div style="font-family:QCF2042;font-size:25px;line-height:1.95;direction:rtl;text-align:center">{g}</div>
</div>
<div style="padding:0 20px 26px">
 <div class="row" style="justify-content:center;height:52px;border:2px solid var(--text);border-radius:99px;gap:8px;font-weight:700;margin-bottom:12px">{ic('book',22)}الفضل والتخريج</div>
 <div class="row" style="gap:12px">
  <div class="rbtn" style="width:56px;height:56px;border:2px solid var(--text);background:none;color:var(--text);opacity:.45">{ic('left',26)}</div>
  <div class="row" style="flex:1;height:80px;border-radius:28px;background:var(--text);color:var(--base);padding:0 22px;justify-content:space-between"><div><div class="b" style="font-size:17px;line-height:24px">اضغط للعدّ</div><div class="cap">مرة واحدة</div></div><div class="b" style="font-size:38px">٠</div></div>
  <div class="rbtn" style="width:56px;height:56px;border:2px solid var(--text);background:none;color:var(--text)">{ic('right',26)}</div>
 </div></div></div>'''

def hisn(c):
    rows = ''.join(f'<div class="irow"><div style="flex:1"><div class="t" style="font-size:15px;line-height:22px">{k["title"]}</div><div class="s">{ar(sum(len(b["items"]) for b in k["chapters"]))} ذكراً</div></div><span class="chev c2">{ic("right",22)}</span></div>' for k in cats[:8])
    return f'''<div class="scr" style="padding-bottom:20px">
<div class="hdr"><div class="rbtn">{ic('left',24)}</div><div><h1>المزيد من الأذكار والأدعية</h1><div class="cap c2">من كتاب حصن المسلم · ١١ قسماً</div></div></div>
{rows}</div>'''

def favs(c):
    def lst(color, name, n): return f'<div class="irow"><div style="width:32px;height:32px;border-radius:50%;background:{color}"></div><div style="flex:1"><div class="t">{name}</div><div class="s">{n} أذكار</div></div><span class="c2">{ic("right",22)}</span></div>'
    return f'''<div class="scr">
<div class="hdr"><div class="rbtn">{ic('left',24)}</div><h1>المفضلة</h1></div>
<div class="cap c2" style="padding:0 8px 10px">٣٢ ذكراً · ٣ قوائم</div>
<div class="irow"><span style="color:var(--iconwarm)">{ic('heartf',28)}</span><div style="flex:1"><div class="t">كل المفضلة</div><div class="s">١٢ عنصراً</div></div><span class="c2">{ic("right",22)}</span></div>
<div class="gl" style="margin-top:14px">قوائمي</div>
{lst('#E3B77F','أذكاري اليومية','١٤')}{lst('#9DB06B','بعد الصلاة','٩')}{lst('#C98F72','قبل السفر','٩')}
<div class="row" style="justify-content:center;height:56px;border-radius:20px;border:2px dashed var(--border);color:var(--text2);gap:8px;font-weight:700;margin-bottom:14px">{ic('plus',22)}قائمة جديدة</div>
<div class="gl">قوائم محفوظة</div>
<div class="irow"><span style="color:var(--iconwarm)">{ic('list',26)}</span><div style="flex:1"><div class="t">أذكار الطعام</div><div class="s">قائمة محفوظة</div></div><span class="c2">{ic("close",20)}</span></div>
</div>'''

def list_sheet(c):
    items = [i for i in CH['b028']['items'] if i['id'] in ('b028-09','b028-10','b028-11','b028-12','b028-13','b028-14')] or CH['b028']['items'][5:11]
    def row(i, it, hidden=False, cur=False, doneit=False):
        bg = 'var(--warm)' if cur else 'var(--raised)'
        fg = 'var(--onwarm)' if cur else 'var(--text)'
        num = f'<span style="color:var(--accent)">{ic("check",24)}</span>' if doneit else f'<span class="b c2" style="width:24px;text-align:center">{i+1}</span>'
        lab = it['title']
        return f'<div style="background:{bg};color:{fg};border-radius:16px;min-height:56px;display:flex;align-items:center;gap:6px;padding:0 4px;margin-bottom:8px"><span style="width:40px;display:grid;place-items:center;color:var(--text2)">{ic("drag",24)}</span>{num}<div style="flex:1;opacity:{.4 if hidden else 1};font-size:15px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{lab}</div><span style="width:40px;display:grid;place-items:center">{ic("eye",22)}</span></div>'
    rows = row(0, items[0], doneit=True) + row(1, items[1], cur=True) + row(2, items[2], hidden=True) + row(3, items[3]) + row(4, items[4]) + row(5, items[5])
    return f'''<div class="scr" style="padding:0">
<div style="position:absolute;inset:0;background:rgba(0,0,0,.55)"></div>
<div style="position:absolute;left:0;right:0;bottom:0;top:150px;background:var(--base);border-radius:32px 32px 0 0;padding:22px 20px">
 <div class="row" style="justify-content:space-between"><div><div class="b" style="font-size:22px;line-height:30px">أذكار النوم</div><div class="cap c2" style="display:flex;gap:6px"><span>أنت عند ٢</span><span>·</span><span>١ مخفي</span></div></div><div style="color:var(--text)">{ic('close',26)}</div></div>
 <div class="row" style="margin:10px 0 12px;gap:8px"><div class="cap c2" style="flex:1">اضغط مطولاً على أي ذكر ثم اسحبه لتغيير ترتيبه. الأذكار المخفية لا تظهر عند القراءة.</div><div class="b" style="color:var(--accent);font-size:14px">استعادة الافتراضي</div></div>
 {rows}</div></div>'''

def awrad(c):
    def w(name, cur, tot, remind=None, done=False):
        pct = int(100 * cur / tot)
        return f'''<div class="card" style="padding:16px;margin-bottom:12px"><div class="row" style="justify-content:space-between"><div class="b" style="font-size:18px;line-height:26px">{name}</div><div class="b" style="color:var(--accent)">{ar(cur)} / {ar(tot)}</div></div>
<div style="height:8px;border-radius:99px;background:var(--sunken);margin:10px 0;overflow:hidden"><div style="height:100%;width:{pct}%;background:var(--accent);margin-inline-start:auto"></div></div>
<div class="row" style="justify-content:space-between"><span class="cap c2">{('⏰ '+remind) if remind else 'بلا تذكير'}</span><span class="cap c2">يتجدد كل يوم</span></div></div>'''
    return f'''<div class="scr" style="padding-bottom:110px">
<div style="height:24px"></div><div class="b" style="font-size:32px;line-height:40px;margin-bottom:4px">أوراد</div><div class="c2" style="margin-bottom:18px">أذكار تعدّها كل يوم بعدد تحدده</div>
{w('الاستغفار',67,100,'٩:٠٠ م')}{w('الصلاة على النبي ﷺ',20,50,'أيام الجمعة · ٨:٠٠ ص')}{w('سبحان الله وبحمده',33,100)}
<div class="row" style="justify-content:center;height:56px;border-radius:20px;border:2px dashed var(--border);color:var(--text2);gap:8px;font-weight:700">{ic('plus',22)}ورد جديد</div></div>'''

def settings(c):
    def r(icn, t, s=None, warn=False): return f'<div class="irow" style="min-height:60px;margin-bottom:8px"><span style="color:{"var(--danger)" if warn else "var(--text)"}">{ic(icn,24)}</span><div style="flex:1"><div class="t">{t}</div>{f"<div class=s>{s}</div>" if s else ""}</div><span class="chev c2">{ic("right",22)}</span></div>'
    return f'''<div class="scr" style="padding-bottom:110px;overflow:hidden">
<div style="height:14px"></div><div class="b" style="font-size:32px;line-height:40px;margin-bottom:12px">الإعدادات</div>
<div class="gl">التذكير</div>{r('bell','التذكيرات','مواعيد أذكار الصباح والمساء والنوم')}
<div class="gl" style="margin-top:6px">القراءة</div>{r('text','حجم الخط','أصغر بـ ٥ درجات')}
<div class="irow" style="min-height:64px;margin-bottom:8px"><div style="flex:1"><div class="t" style="font-size:15px">الانتقال التلقائي بعد انتهاء العد</div></div><div style="width:52px;height:32px;border-radius:99px;background:var(--accent);position:relative"><div style="position:absolute;top:4px;left:4px;width:24px;height:24px;border-radius:50%;background:var(--onaccent)"></div></div></div>
<div class="gl" style="margin-top:6px">المظهر</div>
<div class="card" style="padding:12px 16px;margin-bottom:8px"><div class="b" style="margin-bottom:8px">المظهر</div><div style="display:flex;border:1px solid var(--border);border-radius:99px;overflow:hidden;text-align:center;font-size:14px"><div style="flex:1;padding:8px">فاتح</div><div style="flex:1;padding:8px;border-inline-start:1px solid var(--border)">داكن</div><div style="flex:1;padding:8px;background:var(--warm);color:var(--onwarm);font-weight:700;border-inline-start:1px solid var(--border)">تلقائي</div></div></div>
<div class="gl" style="margin-top:6px">الإنجاز والويدجت</div>{r('fire','السلسلة')}{r('widgets','ويدجت الأذكار','اختر ما يظهر على شاشتك')}
</div>'''

def fonts(c):
    return f'''<div class="scr" style="padding-bottom:20px">
<div class="hdr"><div class="rbtn">{ic('left',24)}</div><h1>حجم الخط</h1></div>
<div class="b" style="font-size:20px;line-height:28px;margin-bottom:6px">نصوص الأذكار والأدعية</div>
<div class="card" style="border-radius:32px;padding:22px;text-align:center;font-family:Amiri;font-size:30px;line-height:2;margin-bottom:10px">سُبْحَانَ اللهِ وَبِحَمْدِهِ</div>
<div class="row" style="justify-content:space-between;margin-bottom:18px"><div class="rbtn" style="background:var(--warm);color:var(--onwarm)"><b style="font-size:28px;line-height:1">−</b></div><div class="b">أصغر بـ ٥ درجات</div><div class="rbtn" style="background:var(--warm);color:var(--onwarm)"><b style="font-size:26px">+</b></div></div>
<div class="b" style="font-size:20px;line-height:28px;margin-bottom:6px">الآيات</div>
<div class="card" style="border-radius:32px;padding:18px;text-align:center;margin-bottom:10px"><div style="font-family:QCF2BSML;font-size:26px;line-height:1.6;display:flex;flex-direction:row;direction:rtl;gap:7px;justify-content:center"><span>*</span><span>+</span><span>,</span><span>-</span></div></div>
<div class="row" style="justify-content:space-between;margin-bottom:12px"><div class="rbtn" style="background:var(--warm);color:var(--onwarm)"><b style="font-size:28px;line-height:1">−</b></div><div class="b">أصغر بـ ٥ درجات</div><div class="rbtn" style="background:var(--warm);color:var(--onwarm)"><b style="font-size:26px">+</b></div></div>
<div class="irow"><div class="t">عرض التشكيل</div><div style="width:52px;height:32px;border-radius:99px;background:var(--accent);position:relative"><div style="position:absolute;top:4px;left:4px;width:24px;height:24px;border-radius:50%;background:var(--onaccent)"></div></div></div>
</div>'''

def widget(c):
    return f'''<div class="scr" style="background:linear-gradient(160deg,#5f6f7c,#2f3b46 60%,#1d242b);padding:70px 18px 0;color:#fff">
<div style="font-size:54px;line-height:60px;font-weight:300;text-align:center;margin-bottom:6px">٩:٤١</div>
<div style="text-align:center;opacity:.85;margin-bottom:34px;font-size:15px">الأربعاء ١١ نوفمبر</div>
<div style="background:var(--base);color:var(--text);border-radius:28px;padding:16px 18px;box-shadow:0 12px 30px rgba(0,0,0,.35)">
 <div class="row" style="justify-content:space-between;margin-bottom:6px"><div class="b" style="font-size:14px;color:var(--text2)">التسبيح اليومي</div><div class="cap c2" style="color:var(--text2)">٦:٠٠ ص – ٩:٠٠ ص</div></div>
 <div style="font-family:Amiri;font-size:26px;line-height:2;text-align:center;padding:6px 0 8px">«سُبْحَانَ اللَّهِ وَبِحَمْدِهِ»</div>
</div>
<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:22px 10px;margin-top:34px;text-align:center;font-size:12px">
 {''.join(f'<div><div style="width:58px;height:58px;border-radius:18px;background:rgba(255,255,255,.16);margin:0 auto 6px"></div><span style="opacity:.8">&nbsp;</span></div>' for _ in range(8))}
</div></div>'''

SCREENS = [
 ('widget', LIGHT, widget, None),
 ('home', LIGHT, home, 0), ('reader', LIGHT, lambda c: reader(c, morning, morning['title'], 'أذكار الصباح', 20, 23, '٣٣', '١٠٠ مرة'), None),
 ('mushaf', LIGHT, kursi_reader, None), ('hisn', LIGHT, hisn, None), ('favs', LIGHT, favs, None),
 ('lists', LIGHT, list_sheet, None), ('awrad', LIGHT, awrad, 1), ('settings', LIGHT, settings, 2), ('fonts', LIGHT, fonts, None),
 ('home-dark', DARK, home, 0), ('reader-dark', DARK, lambda c: reader(c, morning, morning['title'], 'أذكار الصباح', 20, 23, '٣٣', '١٠٠ مرة'), None),
]

def main():
    tmp = pathlib.Path(tempfile.mkdtemp())
    for name, pal, fn, nav in SCREENS:
        h = tmp / f'{name}.html'
        h.write_text(page(pal, fn(pal), nav), encoding='utf-8')
        png = tmp / f'{name}.png'
        subprocess.run(['google-chrome', '--headless=new', '--no-sandbox', '--disable-gpu', '--hide-scrollbars',
                        '--force-device-scale-factor=2', '--window-size=390,844', '--virtual-time-budget=4000',
                        f'--screenshot={png}', f'file://{h}'], check=True, capture_output=True)
        im = Image.open(png).convert('RGB')
        im.save(OUT / f'{name}.webp', 'WEBP', quality=88, method=6)
        print(name, im.size, (OUT / f'{name}.webp').stat().st_size // 1024, 'KB')
    shutil.rmtree(tmp)

if __name__ == '__main__':
    main()
