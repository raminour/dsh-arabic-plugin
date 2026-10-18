# dsh-ar — حزمة اللغة العربية لواجهة DeepSeek Harness

بلوجن محلي (client plugin) بيسجّل لغة `ar` في نظام اللغات الرسمي للـ Harness،
مع قواميس عربية لعدد من الـ namespaces. أي مفتاح لسه غير مترجم بيظهر بالإنجليزي
تلقائيًا (سلسلة fallback)، فالتغطية الجزئية مش بتكسر الواجهة.

مكمّل لبلوجن `dsh-rtl`: ده بيقلب **الاتجاه**، وده بيقلب **النصوص**.

## التغطية الحالية

50 namespace · ~1870 نص (تقريبًا كل ما يراه المستخدم العادي):

| المجموعة | الـ namespaces |
|---|---|
| المحادثة | `conversation`, `chat` — مربع الكتابة، المرفقات، الصور، الأدوار، الإحصاءات، بطاقات الأدوات |
| الإعدادات | `settings`, `settings.theme`, `settings.locale`, `settings.account`, `settings.models`, `settings.agentPreset`, `settings.agentLoop`, `settings.shell`, `settings.subagent`, `settings.webSearch`, `settings.plugins`, `settings.sessionLog` |
| الصلاحيات | `permission.access`, `settings.permission`, `approval` |
| الأوامر والنموذج | `command`, `slash.menu`, `model` |
| الشريط الجانبي | `sidebar`, `sidebarFiles`, `sidebarRight`, `sidebarTerminal`, `sidebarBrowser` + معاينات المستندات |
| الجلسات | `workspace` (قائمة الجلسات ومساحات العمل) |
| أسئلة/خطط/أهداف/مهام | `question`, `plan`, `goal`, `feedback`, `job`, `schedule.catalog`, `schedule.manager`, `skill`, `reference` |
| المخرجات والتغييرات | `deliverables`, `open-in-app` |
| متنوّع | `shortcuts`, `subagent`, `workflowRun`, `agent-team`, `voice-input` |

**لسه غير مترجم (أدوات مطوّرين/عرض كود — مخفية افتراضيًا):**
`trajectory` (~192)، `pluginManager` (~189)، `cordis` (~51)، `settings.pluginInventory` (~40).

## التثبيت

1. الحزمة لازم تكون في بروفايل البرنامج:

   ```powershell
   pwsh -File .\install-ar.ps1
   ```

2. في البرنامج: **الإعدادات → عام → اللغة → العربية**.
   الاختيار بيتحفظ تلقائيًا في `cordis.patch.yml` ويفضل بعد إعادة التشغيل.

> على جهاز جديد: نزّل Harness، افتحه مرة، انسخ فولدر `dsh-ar` (وفولدر `dsh-rtl` لو عايزه)،
> وشغّل السكربتين، وبعدها اختار اللغة من الإعدادات.

## الإزالة

```powershell
pwsh -File .\uninstall-ar.ps1
```

لو اللغة كانت مختارة، البرنامج بيرجع لللغة الافتراضية المتاحة.

## هيكل الملفات

| ملف | الدور |
|---|---|
| `package.json` | مانيفست الحزمة + `dsh.client` |
| `index.js` | النصف الخاص بالمضيف — فاضي |
| `client.js` | يسجّل `addLanguage` + `register(ns, 'ar', dict)` لكل namespace |
| `cordis.patch.yml` | سطر التفعيل (مرجعي؛ السكربت بيضيفه) |
| `install-ar.ps1` / `uninstall-ar.ps1` | تثبيت/إزالة |

## قيود معروفة

- **الجمع**: نظام اللغات لا يوفّر plural rules؛ الصيغ مكتوبة لتتفادى اللبس (مثل «{n} جلسة»).
- **قوالب النصوص**: أي مفتاح جديد بعد تحديث البرنامج يظهر إنجليزي لحد ما يُضاف.
- **الأرقام والتواريخ**: تُعرض بالأرقام اللاتينية (`{y}-{m}-{d}` كما هي).
- **الإنجليزية تفضل مرجع النموذج**: نصوص الأدوات/البرومبتات متسيبة إنجليزي عن قصد.
