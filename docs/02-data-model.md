# 02 · نموذج البيانات

## محتوى ثابت (يُجمَّع مع التطبيق، للقراءة فقط)
`content/content.json` → `sections[] → categories[] → chapters[] → items[]`

| الحقل | النوع | ملاحظة |
|---|---|---|
| `Section.id` | string | `s1` أذكار، `s2` أدعية، `s3` ملحق |
| `Category.id` | string | `s1c1` … |
| `Chapter.id` | string | `b027` = رقم الباب في الكتاب (ثابت) |
| `Chapter.bookNo` | number | |
| `Item.id` | string | `b027-03` ثابت ولا يُعاد ترقيمه (المفضلة والأوراد تشير إليه) |
| `Item.text` | string | النص المشكّل |
| `Item.source` | string | التخريج كما في الملف |
| `Item.repeat` | number\|null | مستخرج آلياً، **يحتاج مراجعة** |
| `Item.kind` | `text`\|`quran` | يبدأ بـ `{` = آية |

حقول مستقبلية: `virtue`, `explanation` (غير موجودة في المصدر).

## بيانات المستخدم (محلية على الجهاز)
`FavoriteList{id,name,itemIds[],createdAt}` · `Wird{id,name,items[{itemId,count}],schedule}` · `DayProgress{date,doneSessions[],doneItems}` · `Streak{current,best}` · `Reminder{id,session,time,enabled}` · `Settings{theme,fontScale,language}`

لا حساب ولا سحابة في الإصدار الأول.
