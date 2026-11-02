"""Hand-curated Arabic / Hebrew terms for tools/gen_rtl_i18n.py.

Keys are the exact English text of one segment (one line / one '|' part, without
leading/trailing blanks and WITHOUT the '&' accelerator marker: the generator
appends " (&X)" itself when the source had an accelerator). They win over machine
translation. Keep the list short: only terms where the machine output is wrong or
inconsistent for a UI (single words come back as verbs in the wrong form, with
vowel marks, or with the wrong sense, e.g. "Lines" -> strokes).
"""

# language names (native name of each language is used in its own list)
_NAMES_AR = {
    "Arabic": "العربية",
    "Hebrew": "العبرية",
}
_NAMES_HE = {
    "Arabic": "ערבית",
    "Hebrew": "עברית",
}

_AR = {
    "OK": "موافق",
    "Cancel": "إلغاء",
    "Close": "إغلاق",
    "Yes": "نعم",
    "No": "لا",
    "Open": "فتح",
    "Open file": "فتح ملف",
    "Open folder": "فتح مجلد",
    "Save": "حفظ",
    "Edit": "تحرير",
    "View": "عرض",
    "Help": "مساعدة",
    "File": "ملف",
    "Folder": "مجلد",
    "Search": "بحث",
    "Find": "بحث",
    "Find...": "بحث...",
    "Find Next": "بحث عن التالي",
    "Replace": "استبدال",
    "Replace All": "استبدال الكل",
    "Delete": "حذف",
    "Remove": "إزالة",
    "Remove all": "إزالة الكل",
    "Copy": "نسخ",
    "Copy path": "نسخ المسار",
    "Copy paths": "نسخ المسارات",
    "Clear": "مسح",
    "Clear all": "مسح الكل",
    "Select": "تحديد",
    "Select all": "تحديد الكل",
    "Undo": "تراجع",
    "Redo": "إعادة",
    "Apply": "تطبيق",
    "Export": "تصدير",
    "Export...": "تصدير...",
    "Merge": "دمج",
    "Merge lines": "دمج الأسطر",
    "Merge files": "دمج الملفات",
    "Split": "تقسيم",
    "Split Files": "تقسيم الملفات",
    "Exit": "خروج",
    "Stop": "إيقاف",
    "Continue": "متابعة",
    "Continue?": "هل تريد المتابعة؟",
    "Back": "رجوع",
    "Send": "إرسال",
    "Retry": "إعادة المحاولة",
    "Hide": "إخفاء",
    "Show more": "عرض المزيد",
    "Options": "خيارات",
    "Tools": "أدوات",
    "Details": "التفاصيل",
    "Details:": "التفاصيل:",
    "Read": "قراءة",
    "Write": "كتابة",
    "Line": "سطر",
    "Lines": "الأسطر",
    "Line %s": "السطر %s",
    "Line: %d": "السطر: %d",
    "Line:": "السطر:",
    "Words": "الكلمات",
    "Text": "نص",
    "Tab": "علامة تبويب",
    "Space": "مسافة",
    "Size": "الحجم",
    "Recent": "الأخيرة",
    "None": "لا شيء",
    "All": "الكل",
    "Default": "افتراضي",
    "Automatic": "تلقائي",
    "Modified": "تاريخ التعديل",
    "Created": "تاريخ الإنشاء",
    "Accessed": "تاريخ الوصول",
    "Attributes": "السمات",
    "Original": "الأصل",
    "Before": "قبل",
    "After": "بعد",
    "Output": "المخرجات",
    "Output:": "المخرجات:",
    "Error": "خطأ",
    "Warning": "تحذير",
    "Information": "معلومات",
    "Confirmation": "تأكيد",
    "About": "حول",
    "About FastFile": "حول FastFile",
    "Appearance": "المظهر",
    "Bookmarks": "الإشارات المرجعية",
    "Encoding": "الترميز",
    "Line endings": "نهايات الأسطر",
    "Word wrap": "التفاف الكلمات",
    "Whole word": "كلمة كاملة",
    "Match case": "مطابقة حالة الأحرف",
    "Case sensitive search?": "هل البحث حساس لحالة الأحرف؟",
    "Not found": "غير موجود",
    "Text not found.": "لم يُعثر على النص.",
    "Cancelled": "تم الإلغاء",
    "Cancelled.": "تم الإلغاء.",
    "Done.": "تم.",
    "Ready.": "جاهز.",
    "Copied!": "تم النسخ!",
    "Nothing to copy.": "لا يوجد ما يمكن نسخه.",
    "Reading file...": "جارٍ قراءة الملف...",
    "Saving file...": "جارٍ حفظ الملف...",
    "Properties": "الخصائص",
    "Add folder...": "إضافة مجلد...",
    "Add folders": "إضافة مجلدات",
    "Add files...": "إضافة ملفات...",
    "Include subfolders": "تضمين المجلدات الفرعية",
    "Go to line...": "الانتقال إلى سطر...",
    "Previous page": "الصفحة السابقة",
    "Next page": "الصفحة التالية",
    "Last page": "الصفحة الأخيرة",
    "Filter": "تصفية",
    "Filter / Grep": "تصفية / Grep",
    "Ask AI": "اسأل الذكاء الاصطناعي",
    "AI agent": "وكيل الذكاء الاصطناعي",
    "AI Assistant": "مساعد الذكاء الاصطناعي",
    "Fix with AI": "إصلاح بالذكاء الاصطناعي",
    "Generate with AI": "إنشاء بالذكاء الاصطناعي",
    "Version History": "سجل الإصدارات",
    "Compare / merge": "مقارنة / دمج",
    "Anonymize data": "إخفاء هوية البيانات",
    "Anonymize": "إخفاء الهوية",
    "Equal parts": "أجزاء متساوية",
    "Extract parts": "استخراج الأجزاء",
    "Delete Lines": "حذف الأسطر",
    "Insert line before": "إدراج سطر قبل",
    "Insert line after": "إدراج سطر بعد",
    "Select folder": "تحديد مجلد",
    "Select skin": "اختيار المظهر",
    "Random Skin": "مظهر عشوائي",
    "Total lines:": "إجمالي الأسطر:",
    "English": "الإنجليزية",
    "Portuguese (Brazil)": "البرتغالية (البرازيل)",
    "Spanish": "الإسبانية",
    "French": "الفرنسية",
    "German": "الألمانية",
    "Italian": "الإيطالية",
    "Greek": "اليونانية",
}

_HE = {
    "OK": "אישור",
    "Cancel": "ביטול",
    "Close": "סגירה",
    "Yes": "כן",
    "No": "לא",
    "Open": "פתיחה",
    "Open file": "פתיחת קובץ",
    "Open folder": "פתיחת תיקייה",
    "Save": "שמירה",
    "Edit": "עריכה",
    "View": "תצוגה",
    "Help": "עזרה",
    "File": "קובץ",
    "Folder": "תיקייה",
    "Search": "חיפוש",
    "Find": "חיפוש",
    "Find...": "חיפוש...",
    "Find Next": "חפש את הבא",
    "Replace": "החלפה",
    "Replace All": "החלף הכול",
    "Delete": "מחיקה",
    "Remove": "הסרה",
    "Remove all": "הסר הכול",
    "Copy": "העתקה",
    "Copy path": "העתקת נתיב",
    "Copy paths": "העתקת נתיבים",
    "Clear": "ניקוי",
    "Clear all": "נקה הכול",
    "Select": "בחירה",
    "Select all": "בחר הכול",
    "Undo": "ביטול פעולה",
    "Redo": "ביצוע חוזר",
    "Apply": "החלה",
    "Export": "ייצוא",
    "Export...": "ייצוא...",
    "Merge": "מיזוג",
    "Merge lines": "מיזוג שורות",
    "Merge files": "מיזוג קבצים",
    "Split": "פיצול",
    "Split Files": "פיצול קבצים",
    "Exit": "יציאה",
    "Stop": "עצירה",
    "Continue": "המשך",
    "Continue?": "להמשיך?",
    "Back": "חזרה",
    "Send": "שליחה",
    "Retry": "נסה שוב",
    "Hide": "הסתרה",
    "Show more": "הצג עוד",
    "Options": "אפשרויות",
    "Tools": "כלים",
    "Details": "פרטים",
    "Details:": "פרטים:",
    "Read": "קריאה",
    "Write": "כתיבה",
    "Line": "שורה",
    "Lines": "שורות",
    "Line %s": "שורה %s",
    "Line: %d": "שורה: %d",
    "Line:": "שורה:",
    "Words": "מילים",
    "Text": "טקסט",
    "Tab": "לשונית",
    "Space": "רווח",
    "Size": "גודל",
    "Recent": "אחרונים",
    "None": "ללא",
    "All": "הכול",
    "Default": "ברירת מחדל",
    "Automatic": "אוטומטי",
    "Modified": "תאריך שינוי",
    "Created": "תאריך יצירה",
    "Accessed": "תאריך גישה",
    "Attributes": "מאפיינים",
    "Original": "מקור",
    "Before": "לפני",
    "After": "אחרי",
    "Output": "פלט",
    "Output:": "פלט:",
    "Error": "שגיאה",
    "Warning": "אזהרה",
    "Information": "מידע",
    "Confirmation": "אישור",
    "About": "אודות",
    "About FastFile": "אודות FastFile",
    "Appearance": "מראה",
    "Bookmarks": "סימניות",
    "Encoding": "קידוד",
    "Line endings": "סופי שורות",
    "Word wrap": "גלישת מילים",
    "Whole word": "מילה שלמה",
    "Match case": "התאמת רישיות",
    "Case sensitive search?": "חיפוש תלוי רישיות?",
    "Not found": "לא נמצא",
    "Text not found.": "הטקסט לא נמצא.",
    "Cancelled": "בוטל",
    "Cancelled.": "בוטל.",
    "Done.": "בוצע.",
    "Ready.": "מוכן.",
    "Copied!": "הועתק!",
    "Nothing to copy.": "אין מה להעתיק.",
    "Reading file...": "קורא קובץ...",
    "Saving file...": "שומר קובץ...",
    "Properties": "מאפיינים",
    "Add folder...": "הוספת תיקייה...",
    "Add folders": "הוספת תיקיות",
    "Add files...": "הוספת קבצים...",
    "Include subfolders": "כולל תת-תיקיות",
    "Go to line...": "מעבר לשורה...",
    "Previous page": "הדף הקודם",
    "Next page": "הדף הבא",
    "Last page": "הדף האחרון",
    "Filter": "סינון",
    "Filter / Grep": "סינון / Grep",
    "Ask AI": "שאל את הבינה המלאכותית",
    "AI agent": "סוכן בינה מלאכותית",
    "AI Assistant": "עוזר בינה מלאכותית",
    "Fix with AI": "תיקון בעזרת בינה מלאכותית",
    "Generate with AI": "יצירה בעזרת בינה מלאכותית",
    "Version History": "היסטוריית גרסאות",
    "Compare / merge": "השוואה / מיזוג",
    "Anonymize data": "הסתרת זהות הנתונים",
    "Anonymize": "הסתרת זהות",
    "Equal parts": "חלקים שווים",
    "Extract parts": "חילוץ חלקים",
    "Delete Lines": "מחיקת שורות",
    "Insert line before": "הוספת שורה לפני",
    "Insert line after": "הוספת שורה אחרי",
    "Select folder": "בחירת תיקייה",
    "Select skin": "בחירת עיצוב",
    "Random Skin": "עיצוב אקראי",
    "Total lines:": "סך כל השורות:",
    "English": "אנגלית",
    "Portuguese (Brazil)": "פורטוגזית (ברזיל)",
    "Spanish": "ספרדית",
    "French": "צרפתית",
    "German": "גרמנית",
    "Italian": "איטלקית",
    "Greek": "יוונית",
}

_AR.update({
    "OFF": "إيقاف",
    "PAUSED": "متوقف مؤقتًا",
    "ANONYMIZED": "تم إخفاء الهوية",
    "TAB": "TAB",
    "Name && Location": "الاسم والموقع",
    "Date && Time": "التاريخ والوقت",
    "Size && Attributes": "الحجم والسمات",
    (
        "RECENT UPDATES (v3.0.5.255 – v3.0.5.261)\r\n"
        "---------------------------------------------------------------\r\n"
        "  The interface now has 22 languages, including Hindi, Russian, Korean,\r\n"
        "    Dutch, Turkish and Ukrainian. Hindi uses a left-to-right layout.\r\n"
        "  Equal-parts processing reads memory-mapped chunks without loading\r\n"
        "    the whole file; the split tab stays open when it finishes.\r\n"
        "  After reading a file, the next-steps guide suggests useful actions.\r\n"
        "    Reopen it in Preferences or turn it off there.\r\n"
        "  The editing context menu and session-history wording were localized.\r\n"
        "  The guide and Preferences were redesigned; the guide initializes\r\n"
        "    without flicker or interrupting file reading.\r\n"
    ): (
        "التحديثات الأخيرة (v3.0.5.255 – v3.0.5.261)\r\n"
        "---------------------------------------------------------------\r\n"
        "  أصبحت الواجهة متاحة بـ 22 لغة، منها الهندية والروسية والكورية،\r\n"
        "    والهولندية والتركية والأوكرانية. تستخدم الهندية تخطيطًا من اليسار إلى اليمين.\r\n"
        "  تعالج عملية التقسيم إلى أجزاء متساوية كتل MMF دون تحميل الملف بالكامل؛\r\n"
        "    وتظل علامة تبويب التقسيم مفتوحة عند الانتهاء.\r\n"
        "  بعد قراءة الملف، يقترح دليل الخطوات التالية إجراءات مفيدة.\r\n"
        "    يمكن إعادة فتحه أو تعطيله من التفضيلات.\r\n"
        "  تمت ترجمة قائمة سياق المحرر ومصطلحات محفوظات الجلسة.\r\n"
        "  أُعيد تصميم الدليل والتفضيلات؛ ويبدأ الدليل دون وميض\r\n"
        "    أو مقاطعة قراءة الملف.\r\n"
    ),
    "Next step": "الخطوة التالية",
    "Show the next-step guide.": "إظهار دليل الخطوة التالية.",
    (
        "RECENT UPDATES (v3.0.5.262 – v3.0.5.265)\r\n"
        "---------------------------------------------------------------\r\n"
        "  Thai, Greek, Norwegian, Swedish, Danish and Icelandic bring\r\n"
        "    the interface to 28 languages. All six read left to right.\r\n"
        "  Next steps follow the current activity, such as find, filter,\r\n"
        "    split, merge or read, instead of one fixed list.\r\n"
        "  Each activity offers more follow-up actions.\r\n"
        "  A button to the left of Copy reopens the next-steps guide.\r\n"
    ): (
        "التحديثات الأخيرة (v3.0.5.262 – v3.0.5.265)\r\n"
        "---------------------------------------------------------------\r\n"
        "  التايلاندية واليونانية والنرويجية والسويدية والدنماركية والأيسلندية ترفع\r\n"
        "    الواجهة إلى 28 لغة. والست تقرأ من اليسار إلى اليمين.\r\n"
        "  الخطوات التالية تتبع النشاط الحالي، مثل البحث والتصفية\r\n"
        "    والتقسيم والدمج أو القراءة، بدلا من قائمة ثابتة واحدة.\r\n"
        "  كل نشاط يقدم المزيد من الإجراءات التالية.\r\n"
        "  زر على يسار نسخ يعيد فتح دليل الخطوات التالية.\r\n"
    ),
    (
        "RECENT UPDATES (v3.0.5.266 – v3.0.5.268)\r\n"
        "---------------------------------------------------------------\r\n"
        "  The next-steps guide is shorter, so the file list stays visible.\r\n"
        "  A Read icon sits inside the file path field, left of the clear X.\r\n"
        "  It uses the same glyph as Read on the toolbar and loads that path.\r\n"
    ): (
        "التحديثات الأخيرة (v3.0.5.266 – v3.0.5.268)\r\n"
        "---------------------------------------------------------------\r\n"
        "  دليل الخطوات التالية أقصر، فتبقى قائمة الملف ظاهرة.\r\n"
        "  أيقونة قراءة داخل حقل المسار، إلى يسار علامة X للمسح.\r\n"
        "  تستخدم نفس رسم قراءة في شريط الأدوات وتحمّل ذلك المسار.\r\n"
    ),
})

_HE.update({
    "OFF": "כבוי",
    "PAUSED": "מושהה",
    "ANONYMIZED": "זהות מוסתרת",
    "TAB": "TAB",
    "Name && Location": "שם ומיקום",
    "Date && Time": "תאריך ושעה",
    "Size && Attributes": "גודל ומאפיינים",
    (
        "RECENT UPDATES (v3.0.5.255 – v3.0.5.261)\r\n"
        "---------------------------------------------------------------\r\n"
        "  The interface now has 22 languages, including Hindi, Russian, Korean,\r\n"
        "    Dutch, Turkish and Ukrainian. Hindi uses a left-to-right layout.\r\n"
        "  Equal-parts processing reads memory-mapped chunks without loading\r\n"
        "    the whole file; the split tab stays open when it finishes.\r\n"
        "  After reading a file, the next-steps guide suggests useful actions.\r\n"
        "    Reopen it in Preferences or turn it off there.\r\n"
        "  The editing context menu and session-history wording were localized.\r\n"
        "  The guide and Preferences were redesigned; the guide initializes\r\n"
        "    without flicker or interrupting file reading.\r\n"
    ): (
        "עדכונים אחרונים (v3.0.5.255 – v3.0.5.261)\r\n"
        "---------------------------------------------------------------\r\n"
        "  הממשק תומך כעת ב-22 שפות, כולל הינדית, רוסית וקוריאנית,\r\n"
        "    וגם הולנדית, טורקית ואוקראינית. פריסת ההינדית היא משמאל לימין.\r\n"
        "  חלוקה לחלקים שווים מעבדת מקטעי MMF בלי לטעון את הקובץ כולו;\r\n"
        "    לשונית החלוקה נשארת פתוחה כשהפעולה מסתיימת.\r\n"
        "  לאחר קריאת קובץ, מדריך השלבים הבאים מציע פעולות שימושיות.\r\n"
        "    אפשר לפתוח אותו מחדש או לכבות אותו בהעדפות.\r\n"
        "  תפריט ההקשר של העורך ומונחי היסטוריית ההפעלה תורגמו.\r\n"
        "  המדריך וההעדפות עוצבו מחדש; המדריך נפתח ללא הבהובים\r\n"
        "    וללא הפרעה לקריאת הקובץ.\r\n"
    ),
    "To enable it: install Go from go.dev (gofmt comes with it).":
        "כדי להפעיל: התקינו את Go מהאתר go.dev (gofmt מגיע איתו).",
    "To enable it: install a JDK (for example Eclipse Temurin) and add its bin folder to PATH or set JAVA_HOME.":
        "כדי להפעיל: התקינו JDK (למשל Eclipse Temurin) והוסיפו את תיקיית ה-bin שלו ל-PATH או הגדירו JAVA_HOME.",
    "To enable it: install the Visual Studio Build Tools (modern C#) or the .NET Framework 4.x (csc.exe, C# 5 only).":
        "כדי להפעיל: התקינו את Visual Studio Build Tools (C# מודרני) או את .NET Framework 4.x (csc.exe, C# 5 בלבד).",
    "No .partNNN files were found for this name.": "לא נמצאו קבצי .partNNN עבור שם זה.",
    "FastFile actions in the list must be accepted one at a time.":
        "יש לאשר את פעולות FastFile שברשימה אחת אחת.",
    "Recent files and folders: click to add one again (Alt+Down in the filter box). Find, remove items, properties and delete all, like the other recent lists.":
        "קבצים ותיקיות אחרונים: לחצו כדי להוסיף אחד שוב (Alt+Down בתיבת הסינון). חיפוש, הסרת פריטים, מאפיינים ומחיקת הכול, כמו ברשימות האחרונים האחרות.",
    "Next step": "השלב הבא",
    "Show the next-step guide.": "הצג את מדריך השלב הבא.",
    (
        "RECENT UPDATES (v3.0.5.262 – v3.0.5.265)\r\n"
        "---------------------------------------------------------------\r\n"
        "  Thai, Greek, Norwegian, Swedish, Danish and Icelandic bring\r\n"
        "    the interface to 28 languages. All six read left to right.\r\n"
        "  Next steps follow the current activity, such as find, filter,\r\n"
        "    split, merge or read, instead of one fixed list.\r\n"
        "  Each activity offers more follow-up actions.\r\n"
        "  A button to the left of Copy reopens the next-steps guide.\r\n"
    ): (
        "עדכונים אחרונים (v3.0.5.262 – v3.0.5.265)\r\n"
        "---------------------------------------------------------------\r\n"
        "  תאית, יוונית, נורווגית, שוודית, דנית ואיסלנדית מביאות\r\n"
        "    את הממשק ל-28 שפות. ששתן נקראות משמאל לימין.\r\n"
        "  השלבים הבאים עוקבים אחר הפעולה הנוכחית, כגון חיפוש וסינון,\r\n"
        "    פיצול, מיזוג או קריאה, במקום רשימה קבועה אחת.\r\n"
        "  כל פעולה מציעה עוד פעולות המשך.\r\n"
        "  כפתור משמאל להעתקה פותח שוב את מדריך השלבים הבאים.\r\n"
    ),
    (
        "RECENT UPDATES (v3.0.5.266 – v3.0.5.268)\r\n"
        "---------------------------------------------------------------\r\n"
        "  The next-steps guide is shorter, so the file list stays visible.\r\n"
        "  A Read icon sits inside the file path field, left of the clear X.\r\n"
        "  It uses the same glyph as Read on the toolbar and loads that path.\r\n"
    ): (
        "עדכונים אחרונים (v3.0.5.266 – v3.0.5.268)\r\n"
        "---------------------------------------------------------------\r\n"
        "  מדריך השלבים הבאים קצר יותר, כך שרשימת הקובץ נשארת גלויה.\r\n"
        "  סמל קריאה בתוך שדה הנתיב, משמאל ל-X לניקוי.\r\n"
        "  משתמש באותו ציור כמו קריאה בסרגל הכלים וטוען את הנתיב הזה.\r\n"
    ),
})

OVERRIDES = {
    "ar": {**_AR, **_NAMES_AR},
    "he": {**_HE, **_NAMES_HE},
}
