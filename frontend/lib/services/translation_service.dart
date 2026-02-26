import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'anima_service.dart';

class AppTranslations {
  static const Map<String, Map<String, String>> values = {
    'appTitle': {
      'EN': 'Anima - Your Digital Brain',
      'ES': 'Anima - Tu Cerebro Digital',
      'DE': 'Anima - Dein digitales Gehirn',
      'RU': 'Anima — ваш цифровой мозг',
      'JP': 'Anima - あなたのデジタル脳',
      'ZH': 'Anima - 你的数字大脑',
      'AR': 'Anima - دماغك الرقمي',
    },
    'chat': {
      'EN': 'Chat',
      'ES': 'Chat',
      'DE': 'Chat',
      'RU': 'Чат',
      'JP': 'チャット',
      'ZH': '聊天',
      'AR': 'الدردشة',
    },
    'memoryExplorer': {
      'EN': 'Memory Explorer',
      'ES': 'Explorador de Memoria',
      'DE': 'Memory-Explorer',
      'RU': 'Проводник памяти',
      'JP': 'メモリエクスプローラー',
      'ZH': '记忆浏览器',
      'AR': 'مستكشف الذاكرة',
    },
    'commandCenter': {
      'EN': 'Settings',
      'ES': 'Ajustes',
      'DE': 'Einstellungen',
      'RU': 'Настройки',
      'JP': '設定',
      'ZH': '设置',
      'AR': 'الإعدادات',
    },
    'digitalBrain': {
      'EN': 'Digital Brain',
      'ES': 'Cerebro Digital',
      'DE': 'Digitales Gehirn',
      'RU': 'Цифровой мозг',
      'JP': 'デジタル脳',
      'ZH': '数字大脑',
      'AR': 'الدماغ الرقمي',
    },
    'openMenu': {
      'EN': 'Open menu',
      'ES': 'Abrir menú',
      'DE': 'Menü öffnen',
      'RU': 'Открыть меню',
      'JP': 'メニューを開く',
      'ZH': '打开菜单',
      'AR': 'افتح القائمة',
    },
    'deleteMemory': {
      'EN': 'Delete memory',
      'ES': 'Eliminar memoria',
      'DE': 'Erinnerung löschen',
      'RU': 'Удалить воспоминание',
      'JP': '記憶を削除',
      'ZH': '删除记忆',
      'AR': 'حذف الذاكرة',
    },
    'now': {
      'EN': 'Now',
      'ES': 'Ahora',
      'DE': 'Jetzt',
      'RU': 'Сейчас',
      'JP': '今',
      'ZH': '刚刚',
      'AR': 'الآن',
    },
    'minutesAgo': {
      'EN': '{n}m ago',
      'ES': 'hace {n}m',
      'DE': 'vor {n} Min',
      'RU': '{n} мин назад',
      'JP': '{n}分前',
      'ZH': '{n}分钟前',
      'AR': 'قبل {n} د',
    },
    'hoursAgo': {
      'EN': '{n}h ago',
      'ES': 'hace {n}h',
      'DE': 'vor {n} Std',
      'RU': '{n} ч назад',
      'JP': '{n}時間前',
      'ZH': '{n}小时前',
      'AR': 'قبل {n} س',
    },
    'typeMessage': {
      'EN': 'Type your message...',
      'ES': 'Escribe tu mensaje...',
      'DE': 'Schreibe deine Nachricht...',
      'RU': 'Напишите сообщение...',
      'JP': 'メッセージを入力...',
      'ZH': '输入你的消息...',
      'AR': 'اكتب رسالتك...',
    },
    'failedLoadHistory': {
      'EN': 'Failed to load history',
      'ES': 'Error al cargar historial',
      'DE': 'Verlauf konnte nicht geladen werden',
      'RU': 'Не удалось загрузить историю',
      'JP': '履歴の読み込みに失敗しました',
      'ZH': '加载历史失败',
      'AR': 'فشل تحميل السجل',
    },
    'failedProcessMessage': {
      'EN': 'Failed to process message',
      'ES': 'Error al procesar mensaje',
      'DE': 'Nachricht konnte nicht verarbeitet werden',
      'RU': 'Не удалось обработать сообщение',
      'JP': 'メッセージの処理に失敗しました',
      'ZH': '处理消息失败',
      'AR': 'فشل في معالجة الرسالة',
    },
    'failedGenerateGreeting': {
      'EN': 'Failed to generate greeting',
      'ES': 'Error al generar saludo',
      'DE': 'Begrüßung konnte nicht erstellt werden',
      'RU': 'Не удалось сгенерировать приветствие',
      'JP': '挨拶の生成に失敗しました',
      'ZH': '生成问候语失败',
      'AR': 'فشل إنشاء التحية',
    },
    'hidePreviousHistory': {
      'EN': 'Hide previous history',
      'ES': 'Ocultar historial anterior',
      'DE': 'Vorherigen Verlauf ausblenden',
      'RU': 'Скрыть предыдущую историю',
      'JP': '過去の履歴を隠す',
      'ZH': '隐藏之前的历史',
      'AR': 'إخفاء السجل السابق',
    },
    'showPreviousHistory': {
      'EN': 'Show previous history',
      'ES': 'Mostrar historial anterior',
      'DE': 'Vorherigen Verlauf anzeigen',
      'RU': 'Показать предыдущую историю',
      'JP': '過去の履歴を表示',
      'ZH': '显示之前的历史',
      'AR': 'إظهار السجل السابق',
    },
    'aiBiographerTagline': {
      'EN': 'Your AI biographer, journal, and mentor',
      'ES': 'Tu biógrafa, diario y mentora de IA',
      'DE': 'Deine KI-Biografin, dein Tagebuch und Mentor',
      'RU': 'Ваш ИИ-биограф, дневник и наставник',
      'JP': 'あなたのAI伝記作家・日記・メンター',
      'ZH': '你的 AI 传记作者、日记与导师',
      'AR': 'سيرتك الذاتية ومذكرتك ومرشدك بالذكاء الاصطناعي',
    },
    'welcomeIntro': {
      'EN': 'Hello! I am Anima. I am here to listen, remember what matters, and support your journey. Share your day or whatever is on your mind.',
      'ES': '¡Hola! Soy Anima. Estoy aquí para escucharte, recordar lo importante y acompañarte en tu camino. Cuéntame tu día o lo que tengas en mente.',
      'DE': 'Hallo! Ich bin Anima. Ich bin hier, um dir zuzuhören, Wichtiges zu behalten und dich auf deinem Weg zu begleiten. Erzähl mir von deinem Tag oder was dir durch den Kopf geht.',
      'RU': 'Привет! Я Anima. Я здесь, чтобы слушать, помнить важное и поддерживать тебя. Расскажи о своём дне или о том, что у тебя на уме.',
      'JP': 'こんにちは！私はAnima。あなたの話を聞き、大切なことを覚え、あなたの歩みを支えます。今日のことや今考えていることを話してね。',
      'ZH': '你好！我是 Anima。我会倾听你、记住重要的事，并陪伴你的旅程。分享你的一天或任何心事。',
      'AR': 'مرحبًا! أنا أنيما. أنا هنا لأستمع إليك وأتذكر ما يهم وأدعم رحلتك. شاركني يومك أو ما يدور في ذهنك.',
    },
    'memoryTitle': {
      'EN': 'Memories',
      'ES': 'Memorias',
      'DE': 'Erinnerungen',
      'RU': 'Воспоминания',
      'JP': '記憶',
      'ZH': '记忆',
      'AR': 'الذكريات',
    },
    'noMemoriesSaved': {
      'EN': 'No memories saved',
      'ES': 'No hay memorias guardadas',
      'DE': 'Keine gespeicherten Erinnerungen',
      'RU': 'Сохранённых воспоминаний нет',
      'JP': '保存された記憶はありません',
      'ZH': '没有已保存的记忆',
      'AR': 'لا توجد ذكريات محفوظة',
    },
    'errorLoadingMemories': {
      'EN': 'Error loading memories',
      'ES': 'Error cargando memorias',
      'DE': 'Fehler beim Laden der Erinnerungen',
      'RU': 'Ошибка загрузки воспоминаний',
      'JP': '記憶の読み込みエラー',
      'ZH': '加载记忆时出错',
      'AR': 'خطأ في تحميل الذكريات',
    },
    'deleteMemoryFailed': {
      'EN': 'Could not delete memory',
      'ES': 'No se pudo borrar la memoria',
      'DE': 'Erinnerung konnte nicht gelöscht werden',
      'RU': 'Не удалось удалить воспоминание',
      'JP': '記憶を削除できませんでした',
      'ZH': '无法删除记忆',
      'AR': 'تعذر حذف الذاكرة',
    },
    'memoryDeleted': {
      'EN': 'Memory deleted',
      'ES': 'Memoria eliminada',
      'DE': 'Erinnerung gelöscht',
      'RU': 'Воспоминание удалено',
      'JP': '記憶を削除しました',
      'ZH': '记忆已删除',
      'AR': 'تم حذف الذاكرة',
    },
    'errorDeletingMemory': {
      'EN': 'Error deleting memory',
      'ES': 'Error borrando memoria',
      'DE': 'Fehler beim Löschen der Erinnerung',
      'RU': 'Ошибка удаления воспоминания',
      'JP': '記憶の削除エラー',
      'ZH': '删除记忆时出错',
      'AR': 'خطأ أثناء حذف الذاكرة',
    },
    'brainTitle': {
      'EN': 'Digital Brain',
      'ES': 'Cerebro Digital',
      'DE': 'Digitales Gehirn',
      'RU': 'Цифровой мозг',
      'JP': 'デジタル脳',
      'ZH': '数字大脑',
      'AR': 'الدماغ الرقمي',
    },
    'searchMemoriesHint': {
      'EN': 'Search words, dates, or memories...',
      'ES': 'Buscar palabras, fechas o recuerdos...',
      'DE': 'Wörter, Daten oder Erinnerungen suchen...',
      'RU': 'Искать слова, даты или воспоминания...',
      'JP': '単語・日付・記憶を検索...',
      'ZH': '搜索关键词、日期或记忆...',
      'AR': 'ابحث عن كلمات أو تواريخ أو ذكريات...',
    },
    'errorSearchingMemories': {
      'EN': 'Error searching memories',
      'ES': 'Error buscando recuerdos',
      'DE': 'Fehler beim Suchen von Erinnerungen',
      'RU': 'Ошибка поиска воспоминаний',
      'JP': '記憶検索エラー',
      'ZH': '搜索记忆时出错',
      'AR': 'خطأ أثناء البحث في الذكريات',
    },
    'factoryResetCognitive': {
      'EN': 'Cognitive Factory Reset',
      'ES': 'Factory Reset Cognitivo',
      'DE': 'Kognitiver Werksreset',
      'RU': 'Когнитивный сброс',
      'JP': '認知ファクトリーリセット',
      'ZH': '认知恢复出厂设置',
      'AR': 'إعادة ضبط معرفية',
    },
    'confirmDeleteCognitive': {
      'EN': 'Delete cognitive evolution?',
      'ES': '¿Borrar evolución cognitiva?',
      'DE': 'Kognitive Entwicklung löschen?',
      'RU': 'Удалить когнитивную эволюцию?',
      'JP': '認知の進化を削除しますか？',
      'ZH': '删除认知演化吗？',
      'AR': 'حذف التطور المعرفي؟',
    },
    'cancel': {
      'EN': 'Cancel',
      'ES': 'Cancelar',
      'DE': 'Abbrechen',
      'RU': 'Отмена',
      'JP': 'キャンセル',
      'ZH': '取消',
      'AR': 'إلغاء',
    },
    'delete': {
      'EN': 'Delete',
      'ES': 'Borrar',
      'DE': 'Löschen',
      'RU': 'Удалить',
      'JP': '削除',
      'ZH': '删除',
      'AR': 'حذف',
    },
    'cognitiveDeleted': {
      'EN': 'Cognitive evolution deleted',
      'ES': 'Evolución cognitiva borrada',
      'DE': 'Kognitive Entwicklung gelöscht',
      'RU': 'Когнитивная эволюция удалена',
      'JP': '認知の進化を削除しました',
      'ZH': '认知演化已删除',
      'AR': 'تم حذف التطور المعرفي',
    },
    'cognitiveDeleteFailed': {
      'EN': 'Could not delete cognitive profile',
      'ES': 'No se pudo borrar el perfil cognitivo',
      'DE': 'Kognitives Profil konnte nicht gelöscht werden',
      'RU': 'Не удалось удалить когнитивный профиль',
      'JP': '認知プロフィールを削除できませんでした',
      'ZH': '无法删除认知档案',
      'AR': 'تعذر حذف الملف المعرفي',
    },
    'errorDeletingProfile': {
      'EN': 'Error deleting profile',
      'ES': 'Error borrando perfil',
      'DE': 'Fehler beim Löschen des Profils',
      'RU': 'Ошибка удаления профиля',
      'JP': 'プロフィール削除エラー',
      'ZH': '删除档案时出错',
      'AR': 'خطأ أثناء حذف الملف',
    },
    'sleepStart': {
      'EN': 'Starting sleep cycle...',
      'ES': 'Iniciando ciclo de sueño...',
      'DE': 'Schlafzyklus wird gestartet...',
      'RU': 'Запуск цикла сна...',
      'JP': 'スリープサイクルを開始中...',
      'ZH': '正在启动睡眠周期...',
      'AR': 'بدء دورة النوم...',
    },
    'sleepLoadingToday': {
      'EN': 'Loading today\'s messages...',
      'ES': 'Cargando los mensajes del día...',
      'DE': 'Nachrichten von heute werden geladen...',
      'RU': 'Загрузка сообщений за сегодня...',
      'JP': '今日のメッセージを読み込み中...',
      'ZH': '正在加载今日消息...',
      'AR': 'جاري تحميل رسائل اليوم...',
    },
    'sleepAnalyzing': {
      'EN': 'Analyzing raw memories...',
      'ES': 'Analizando recuerdos crudos...',
      'DE': 'Rohe Erinnerungen werden analysiert...',
      'RU': 'Анализ сырых воспоминаний...',
      'JP': '生の記憶を分析中...',
      'ZH': '正在分析原始记忆...',
      'AR': 'تحليل الذكريات الخام...',
    },
    'sleepExtracting': {
      'EN': 'Extracting personality traits...',
      'ES': 'Extrayendo rasgos de personalidad...',
      'DE': 'Persönlichkeitsmerkmale werden extrahiert...',
      'RU': 'Извлечение черт личности...',
      'JP': '性格特性を抽出中...',
      'ZH': '正在提取人格特征...',
      'AR': 'استخراج سمات الشخصية...',
    },
    'sleepConsolidating': {
      'EN': 'Consolidating Digital Brain...',
      'ES': 'Consolidando Cerebro Digital...',
      'DE': 'Digitales Gehirn wird konsolidiert...',
      'RU': 'Консолидация цифрового мозга...',
      'JP': 'デジタル脳を統合中...',
      'ZH': '正在巩固数字大脑...',
      'AR': 'دمج الدماغ الرقمي...',
    },
    'sleepCompleted': {
      'EN': 'Cycle complete. Good night!',
      'ES': '¡Ciclo completado. Buenas noches!',
      'DE': 'Zyklus abgeschlossen. Gute Nacht!',
      'RU': 'Цикл завершён. Спокойной ночи!',
      'JP': 'サイクル完了。おやすみなさい！',
      'ZH': '周期完成，晚安！',
      'AR': 'اكتملت الدورة. تصبح على خير!',
    },
    'errorSleepCycle': {
      'EN': 'Sleep cycle error',
      'ES': 'Error en ciclo de sueño',
      'DE': 'Fehler im Schlafzyklus',
      'RU': 'Ошибка цикла сна',
      'JP': 'スリープサイクルエラー',
      'ZH': '睡眠周期错误',
      'AR': 'خطأ في دورة النوم',
    },
    'sleepProgressLabel': {
      'EN': 'Sleep cycle progress',
      'ES': 'Progreso del ciclo de sueño',
      'DE': 'Fortschritt des Schlafzyklus',
      'RU': 'Прогресс цикла сна',
      'JP': 'スリープサイクル進行状況',
      'ZH': '睡眠周期进度',
      'AR': 'تقدم دورة النوم',
    },
    'noMemoriesForSearch': {
      'EN': 'No memories for this search',
      'ES': 'No hay recuerdos para esta búsqueda',
      'DE': 'Keine Erinnerungen für diese Suche',
      'RU': 'Нет воспоминаний для этого поиска',
      'JP': 'この検索に一致する記憶はありません',
      'ZH': '此搜索没有匹配的记忆',
      'AR': 'لا توجد ذكريات لهذا البحث',
    },
    'goodNightAction': {
      'EN': 'Say good night (Process and Shutdown)',
      'ES': 'Dar las buenas noches (Procesar y Apagar)',
      'DE': 'Gute Nacht sagen (Verarbeiten und Herunterfahren)',
      'RU': 'Пожелать спокойной ночи (обработать и выключить)',
      'JP': 'おやすみを言う（処理して終了）',
      'ZH': '道晚安（处理并关机）',
      'AR': 'قل تصبح على خير (معالجة وإيقاف)',
    },
    'settingsTitle': {
      'EN': 'Settings',
      'ES': 'Ajustes',
      'DE': 'Einstellungen',
      'RU': 'Настройки',
      'JP': '設定',
      'ZH': '设置',
      'AR': 'الإعدادات',
    },
    'identitySection': {
      'EN': 'IDENTITY',
      'ES': 'IDENTIDAD',
      'DE': 'IDENTITÄT',
      'RU': 'ЛИЧНОСТЬ',
      'JP': 'アイデンティティ',
      'ZH': '身份',
      'AR': 'الهوية',
    },
    'changeName': {
      'EN': 'Change name',
      'ES': 'Cambiar nombre',
      'DE': 'Name ändern',
      'RU': 'Изменить имя',
      'JP': '名前を変更',
      'ZH': '更改姓名',
      'AR': 'تغيير الاسم',
    },
    'yourName': {
      'EN': 'Your name',
      'ES': 'Tu nombre',
      'DE': 'Dein Name',
      'RU': 'Ваше имя',
      'JP': 'あなたの名前',
      'ZH': '你的名字',
      'AR': 'اسمك',
    },
    'save': {
      'EN': 'Save',
      'ES': 'Guardar',
      'DE': 'Speichern',
      'RU': 'Сохранить',
      'JP': '保存',
      'ZH': '保存',
      'AR': 'حفظ',
    },
    'undefined': {
      'EN': 'Undefined',
      'ES': 'Sin definir',
      'DE': 'Nicht definiert',
      'RU': 'Не задано',
      'JP': '未設定',
      'ZH': '未设置',
      'AR': 'غير محدد',
    },
    'changeLanguage': {
      'EN': 'Change language',
      'ES': 'Cambiar idioma',
      'DE': 'Sprache ändern',
      'RU': 'Изменить язык',
      'JP': '言語を変更',
      'ZH': '更改语言',
      'AR': 'تغيير اللغة',
    },
    'languageUpdated': {
      'EN': 'Language updated',
      'ES': 'Idioma actualizado',
      'DE': 'Sprache aktualisiert',
      'RU': 'Язык обновлён',
      'JP': '言語を更新しました',
      'ZH': '语言已更新',
      'AR': 'تم تحديث اللغة',
    },
    'languageChangeFailed': {
      'EN': 'Could not change language',
      'ES': 'No se pudo cambiar el idioma',
      'DE': 'Sprache konnte nicht geändert werden',
      'RU': 'Не удалось изменить язык',
      'JP': '言語を変更できませんでした',
      'ZH': '无法更改语言',
      'AR': 'تعذر تغيير اللغة',
    },
    'behaviorSection': {
      'EN': 'BEHAVIOR',
      'ES': 'COMPORTAMIENTO',
      'DE': 'VERHALTEN',
      'RU': 'ПОВЕДЕНИЕ',
      'JP': 'ふるまい',
      'ZH': '行为',
      'AR': 'السلوك',
    },
    'modelCreativity': {
      'EN': 'Model creativity',
      'ES': 'Creatividad del modelo',
      'DE': 'Modell-Kreativität',
      'RU': 'Креативность модели',
      'JP': 'モデルの創造性',
      'ZH': '模型创造力',
      'AR': 'إبداع النموذج',
    },
    'dataPrivacySection': {
      'EN': 'DATA & PRIVACY',
      'ES': 'DATOS Y PRIVACIDAD',
      'DE': 'DATEN & DATENSCHUTZ',
      'RU': 'ДАННЫЕ И ПРИВАТНОСТЬ',
      'JP': 'データとプライバシー',
      'ZH': '数据与隐私',
      'AR': 'البيانات والخصوصية',
    },
    'exportBrain': {
      'EN': 'Export my brain',
      'ES': 'Exportar mi Cerebro',
      'DE': 'Mein Gehirn exportieren',
      'RU': 'Экспортировать мой мозг',
      'JP': '脳データをエクスポート',
      'ZH': '导出我的大脑',
      'AR': 'تصدير دماغي',
    },
    'saveLocalJson': {
      'EN': 'Save local copy as .json',
      'ES': 'Guardar copia local en .json',
      'DE': 'Lokale Kopie als .json speichern',
      'RU': 'Сохранить локальную копию в .json',
      'JP': '.json としてローカル保存',
      'ZH': '保存本地 .json 副本',
      'AR': 'حفظ نسخة محلية بصيغة .json',
    },
    'panicReset': {
      'EN': 'Format Anima (Panic Button)',
      'ES': 'Formatear Anima (Botón de Pánico)',
      'DE': 'Anima formatieren (Panikknopf)',
      'RU': 'Форматировать Anima (кнопка паники)',
      'JP': 'Animaを初期化（緊急ボタン）',
      'ZH': '格式化 Anima（紧急按钮）',
      'AR': 'تهيئة Anima (زر الطوارئ)',
    },
    'dangerZoneIrreversible': {
      'EN': 'Danger zone · irreversible full wipe',
      'ES': 'Zona de peligro · borrado total irreversible',
      'DE': 'Gefahrenzone · vollständiges irreversibles Löschen',
      'RU': 'Опасная зона · полное необратимое удаление',
      'JP': '危険ゾーン・完全削除は元に戻せません',
      'ZH': '危险区域 · 完全删除不可逆',
      'AR': 'منطقة خطر · حذف كامل غير قابل للاسترجاع',
    },
    'errorLoadingSettings': {
      'EN': 'Error loading settings',
      'ES': 'Error cargando ajustes',
      'DE': 'Fehler beim Laden der Einstellungen',
      'RU': 'Ошибка загрузки настроек',
      'JP': '設定の読み込みエラー',
      'ZH': '加载设置出错',
      'AR': 'خطأ في تحميل الإعدادات',
    },
    'nameSaveFailed': {
      'EN': 'Could not save name',
      'ES': 'No se pudo guardar el nombre',
      'DE': 'Name konnte nicht gespeichert werden',
      'RU': 'Не удалось сохранить имя',
      'JP': '名前を保存できませんでした',
      'ZH': '无法保存姓名',
      'AR': 'تعذر حفظ الاسم',
    },
    'nameUpdated': {
      'EN': 'Name updated',
      'ES': 'Nombre actualizado',
      'DE': 'Name aktualisiert',
      'RU': 'Имя обновлено',
      'JP': '名前を更新しました',
      'ZH': '姓名已更新',
      'AR': 'تم تحديث الاسم',
    },
    'errorSavingName': {
      'EN': 'Error saving name',
      'ES': 'Error guardando nombre',
      'DE': 'Fehler beim Speichern des Namens',
      'RU': 'Ошибка сохранения имени',
      'JP': '名前保存エラー',
      'ZH': '保存姓名时出错',
      'AR': 'خطأ أثناء حفظ الاسم',
    },
    'creativitySaveFailed': {
      'EN': 'Could not save creativity',
      'ES': 'No se pudo guardar la creatividad',
      'DE': 'Kreativität konnte nicht gespeichert werden',
      'RU': 'Не удалось сохранить креативность',
      'JP': '創造性を保存できませんでした',
      'ZH': '无法保存创造力',
      'AR': 'تعذر حفظ الإبداع',
    },
    'creativityUpdated': {
      'EN': 'Creativity updated',
      'ES': 'Creatividad actualizada',
      'DE': 'Kreativität aktualisiert',
      'RU': 'Креативность обновлена',
      'JP': '創造性を更新しました',
      'ZH': '创造力已更新',
      'AR': 'تم تحديث الإبداع',
    },
    'errorSavingCreativity': {
      'EN': 'Error saving creativity',
      'ES': 'Error guardando creatividad',
      'DE': 'Fehler beim Speichern der Kreativität',
      'RU': 'Ошибка сохранения креативности',
      'JP': '創造性保存エラー',
      'ZH': '保存创造力时出错',
      'AR': 'خطأ أثناء حفظ الإبداع',
    },
    'brainExportedAt': {
      'EN': 'Brain exported to',
      'ES': 'Cerebro exportado en',
      'DE': 'Gehirn exportiert nach',
      'RU': 'Мозг экспортирован в',
      'JP': '脳データを次にエクスポートしました',
      'ZH': '大脑已导出到',
      'AR': 'تم تصدير الدماغ إلى',
    },
    'errorExportingBrain': {
      'EN': 'Error exporting brain',
      'ES': 'Error exportando cerebro',
      'DE': 'Fehler beim Exportieren des Gehirns',
      'RU': 'Ошибка экспорта мозга',
      'JP': '脳データのエクスポートエラー',
      'ZH': '导出大脑时出错',
      'AR': 'خطأ أثناء تصدير الدماغ',
    },
    'exportCancelled': {
      'EN': 'Export canceled',
      'ES': 'Exportación cancelada',
      'DE': 'Export abgebrochen',
      'RU': 'Экспорт отменён',
      'JP': 'エクスポートがキャンセルされました',
      'ZH': '导出已取消',
      'AR': 'تم إلغاء التصدير',
    },
    'encryptBackupTitle': {
      'EN': 'Protect backup with password',
      'ES': 'Proteger backup con contraseña',
      'DE': 'Backup mit Passwort schützen',
      'RU': 'Защитить бэкап паролем',
      'JP': 'バックアップをパスワードで保護',
      'ZH': '使用密码保护备份',
      'AR': 'حماية النسخة الاحتياطية بكلمة مرور',
    },
    'encryptBackupHint': {
      'EN': 'Optional: leave blank to export plain JSON.',
      'ES': 'Opcional: déjalo vacío para exportar JSON sin cifrar.',
      'DE': 'Optional: Leer lassen für unverschlüsseltes JSON.',
      'RU': 'Необязательно: оставьте пустым для обычного JSON.',
      'JP': '任意: 空欄にすると暗号化なし JSON でエクスポートします。',
      'ZH': '可选：留空则导出未加密 JSON。',
      'AR': 'اختياري: اتركه فارغًا لتصدير JSON بدون تشفير.',
    },
    'backupPassword': {
      'EN': 'Password',
      'ES': 'Contraseña',
      'DE': 'Passwort',
      'RU': 'Пароль',
      'JP': 'パスワード',
      'ZH': '密码',
      'AR': 'كلمة المرور',
    },
    'backupPasswordConfirm': {
      'EN': 'Confirm password',
      'ES': 'Confirmar contraseña',
      'DE': 'Passwort bestätigen',
      'RU': 'Подтвердите пароль',
      'JP': 'パスワード確認',
      'ZH': '确认密码',
      'AR': 'تأكيد كلمة المرور',
    },
    'showPassword': {
      'EN': 'Show password',
      'ES': 'Mostrar contraseña',
      'DE': 'Passwort anzeigen',
      'RU': 'Показать пароль',
      'JP': 'パスワードを表示',
      'ZH': '显示密码',
      'AR': 'إظهار كلمة المرور',
    },
    'passwordMismatch': {
      'EN': 'Passwords do not match',
      'ES': 'Las contraseñas no coinciden',
      'DE': 'Passwörter stimmen nicht überein',
      'RU': 'Пароли не совпадают',
      'JP': 'パスワードが一致しません',
      'ZH': '密码不匹配',
      'AR': 'كلمتا المرور غير متطابقتين',
    },
    'warningTitle': {
      'EN': 'Warning',
      'ES': '¿Atención?',
      'DE': 'Achtung',
      'RU': 'Внимание',
      'JP': '警告',
      'ZH': '注意',
      'AR': 'تحذير',
    },
    'factoryResetFirstConfirm': {
      'EN': 'You are about to erase all your memories, your digital brain, and your identity. Anima will start from zero. Do you want to continue?',
      'ES': 'Estás a punto de borrar todos tus recuerdos, tu cerebro digital y tu identidad. Anima empezará de cero. ¿Quieres continuar?',
      'DE': 'Du bist dabei, alle Erinnerungen, dein digitales Gehirn und deine Identität zu löschen. Anima startet bei null. Möchtest du fortfahren?',
      'RU': 'Вы собираетесь удалить все воспоминания, цифровой мозг и личность. Anima начнёт с нуля. Продолжить?',
      'JP': 'すべての記憶、デジタル脳、アイデンティティを削除しようとしています。Anima はゼロから始まります。続行しますか？',
      'ZH': '你即将删除所有记忆、数字大脑和身份信息。Anima 将从零开始。要继续吗？',
      'AR': 'أنت على وشك حذف جميع ذكرياتك ودماغك الرقمي وهويتك. ستبدأ Anima من الصفر. هل تريد المتابعة؟',
    },
    'continue': {
      'EN': 'Continue',
      'ES': 'Continuar',
      'DE': 'Weiter',
      'RU': 'Продолжить',
      'JP': '続ける',
      'ZH': '继续',
      'AR': 'متابعة',
    },
    'back': {
      'EN': 'Back',
      'ES': 'Volver',
      'DE': 'Zurück',
      'RU': 'Назад',
      'JP': '戻る',
      'ZH': '返回',
      'AR': 'رجوع',
    },
    'finalWarningTitle': {
      'EN': '⚠️ FINAL WARNING',
      'ES': '⚠️ ÚLTIMA ADVERTENCIA',
      'DE': '⚠️ LETZTE WARNUNG',
      'RU': '⚠️ ПОСЛЕДНЕЕ ПРЕДУПРЕЖДЕНИЕ',
      'JP': '⚠️ 最終警告',
      'ZH': '⚠️ 最后警告',
      'AR': '⚠️ تحذير أخير',
    },
    'factoryResetSecondConfirm': {
      'EN': 'This action is irreversible. Are you absolutely sure you want to destroy this version of Anima?',
      'ES': 'Esta acción es irreversible. ¿Estás absolutamente seguro de que quieres destruir a esta versión de Anima?',
      'DE': 'Diese Aktion ist irreversibel. Bist du absolut sicher, dass du diese Version von Anima zerstören möchtest?',
      'RU': 'Это действие необратимо. Вы абсолютно уверены, что хотите уничтожить эту версию Anima?',
      'JP': 'この操作は元に戻せません。このバージョンの Anima を本当に破棄しますか？',
      'ZH': '此操作不可逆。你确定要销毁这个版本的 Anima 吗？',
      'AR': 'هذا الإجراء لا رجعة فيه. هل أنت متأكد تمامًا من أنك تريد تدمير هذه النسخة من Anima؟',
    },
    'deleteAll': {
      'EN': 'DELETE ALL',
      'ES': '¡BORRAR TODO!',
      'DE': 'ALLES LÖSCHEN',
      'RU': 'УДАЛИТЬ ВСЁ',
      'JP': 'すべて削除',
      'ZH': '全部删除',
      'AR': 'احذف الكل',
    },
    'formattingAnima': {
      'EN': 'Formatting Anima...',
      'ES': 'Formateando Anima...',
      'DE': 'Anima wird formatiert...',
      'RU': 'Форматирование Anima...',
      'JP': 'Anima を初期化中...',
      'ZH': '正在格式化 Anima...',
      'AR': 'جارٍ تهيئة Anima...',
    },
    'factoryResetFailed': {
      'EN': 'Could not complete full format',
      'ES': 'No se pudo completar el formateo total',
      'DE': 'Vollständige Formatierung konnte nicht abgeschlossen werden',
      'RU': 'Не удалось завершить полное форматирование',
      'JP': '完全初期化を完了できませんでした',
      'ZH': '无法完成完全格式化',
      'AR': 'تعذر إكمال التهيئة الكاملة',
    },
    'factoryResetError': {
      'EN': 'Error during full format',
      'ES': 'Error en formateo total',
      'DE': 'Fehler bei vollständiger Formatierung',
      'RU': 'Ошибка полного форматирования',
      'JP': '完全初期化中にエラー',
      'ZH': '完全格式化时出错',
      'AR': 'خطأ أثناء التهيئة الكاملة',
    },
    'factoryResetForcedCompleted': {
      'EN': 'Reset took too long. Forced reset completed, restarting onboarding...',
      'ES': 'El reset tardó demasiado. Reset forzado completado, reiniciando onboarding...',
      'DE': 'Der Reset dauerte zu lange. Erzwungener Reset abgeschlossen, Onboarding wird neu gestartet...',
      'RU': 'Сброс занял слишком много времени. Принудительный сброс завершён, перезапуск онбординга...',
      'JP': 'リセットに時間がかかりすぎました。強制リセット完了、オンボーディングを再起動します...',
      'ZH': '重置耗时过长。强制重置已完成，正在重新启动引导流程...',
      'AR': 'استغرق إعادة الضبط وقتًا طويلاً. تم إكمال إعادة الضبط القسري، جارٍ إعادة تشغيل الإعداد...',
    },
    'languageLabel': {
      'EN': 'Language',
      'ES': 'Idioma',
      'DE': 'Sprache',
      'RU': 'Язык',
      'JP': '言語',
      'ZH': '语言',
      'AR': 'اللغة',
    },
    'nameQuestion': {
      'EN': 'What is your name?',
      'ES': '¿Cómo te llamas?',
      'DE': 'Wie heißt du?',
      'RU': 'Как тебя зовут?',
      'JP': 'お名前は何ですか？',
      'ZH': '你叫什么名字？',
      'AR': 'ما اسمك؟',
    },
    'nameInputHint': {
      'EN': 'Type your name...',
      'ES': 'Escribe tu nombre...',
      'DE': 'Gib deinen Namen ein...',
      'RU': 'Введите ваше имя...',
      'JP': '名前を入力してください...',
      'ZH': '输入你的名字...',
      'AR': 'اكتب اسمك...',
    },
    'optionalSeedQuestion': {
      'EN': 'What should I know about you to begin? (Optional)',
      'ES': '¿Qué te gustaría que supiera de ti para empezar? (Opcional)',
      'DE': 'Was sollte ich zu Beginn über dich wissen? (Optional)',
      'RU': 'Что мне стоит знать о тебе для начала? (Необязательно)',
      'JP': '始める前にあなたについて何を知っておくべきですか？（任意）',
      'ZH': '你希望我一开始了解你什么？（可选）',
      'AR': 'ما الذي تود أن أعرفه عنك في البداية؟ (اختياري)',
    },
    'optionalSeedHint': {
      'EN': 'Ex: Your age, where you are from, what you do, or your goals. This will help me start building your digital brain...',
      'ES': 'Ej: Tu edad, de dónde eres, a qué te dedicas o tus metas. Esto me ayudará a empezar a construir tu cerebro digital...',
      'DE': 'Beispiel: Dein Alter, woher du kommst, was du machst oder deine Ziele. Das hilft mir, dein digitales Gehirn aufzubauen...',
      'RU': 'Например: ваш возраст, откуда вы, чем занимаетесь или ваши цели. Это поможет мне начать формировать ваш цифровой мозг...',
      'JP': '例：年齢、出身地、仕事、または目標。これにより、あなたのデジタル脳を作り始める助けになります...',
      'ZH': '例如：你的年龄、来自哪里、从事什么工作或你的目标。这将帮助我开始构建你的数字大脑...',
      'AR': 'مثال: عمرك، من أين أنت، ماذا تعمل، أو أهدافك. هذا سيساعدني على البدء في بناء دماغك الرقمي...',
    },
    'startJourney': {
      'EN': 'Start journey',
      'ES': 'Empezar viaje',
      'DE': 'Reise starten',
      'RU': 'Начать путь',
      'JP': '旅を始める',
      'ZH': '开始旅程',
      'AR': 'ابدأ الرحلة',
    },
    'requiredNameStart': {
      'EN': 'Your name is required to start.',
      'ES': 'Tu nombre es obligatorio para empezar.',
      'DE': 'Dein Name ist erforderlich, um zu starten.',
      'RU': 'Чтобы начать, нужно указать имя.',
      'JP': '開始するには名前が必要です。',
      'ZH': '开始前必须填写你的名字。',
      'AR': 'اسمك مطلوب للبدء.',
    },
    'languageSaveFailed': {
      'EN': 'Could not save language.',
      'ES': 'No se pudo guardar el idioma.',
      'DE': 'Sprache konnte nicht gespeichert werden.',
      'RU': 'Не удалось сохранить язык.',
      'JP': '言語を保存できませんでした。',
      'ZH': '无法保存语言。',
      'AR': 'تعذر حفظ اللغة.',
    },
    'couldNotSaveName': {
      'EN': 'Could not save your name.',
      'ES': 'No se pudo guardar tu nombre.',
      'DE': 'Dein Name konnte nicht gespeichert werden.',
      'RU': 'Не удалось сохранить ваше имя.',
      'JP': '名前を保存できませんでした。',
      'ZH': '无法保存你的名字。',
      'AR': 'تعذر حفظ اسمك.',
    },
    'onboardingError': {
      'EN': 'Onboarding error',
      'ES': 'Error durante onboarding',
      'DE': 'Onboarding-Fehler',
      'RU': 'Ошибка онбординга',
      'JP': 'オンボーディングエラー',
      'ZH': '引导流程出错',
      'AR': 'خطأ أثناء الإعداد',
    },
  };
}

class TranslationService extends ChangeNotifier {
  TranslationService({
    required AnimaService animaService,
    String initialLanguage = 'ES',
  })  : _animaService = animaService,
        _language = normalizeLanguageCode(initialLanguage);

  final AnimaService _animaService;
  String _language;

  static const List<String> supportedLanguages = ['EN', 'ES', 'DE', 'RU', 'JP', 'ZH', 'AR'];

  String get language => _language;

  Locale get locale {
    final code = _language == 'ZH' ? 'zh' : _language.toLowerCase();
    return Locale(code);
  }

  Future<bool> changeLanguage(String language) async {
    final normalized = normalizeLanguageCode(language);
    if (_language != normalized) {
      _language = normalized;
      notifyListeners();
    }

    try {
      return await _animaService.setAppLanguage(normalized);
    } catch (_) {
      return false;
    }
  }

  void setLanguageLocal(String language) {
    final normalized = normalizeLanguageCode(language);
    if (_language == normalized) return;
    _language = normalized;
    notifyListeners();
  }

  String tr(String key) {
    final languageMap = AppTranslations.values[key];
    if (languageMap == null) return key;
    return languageMap[_language] ?? languageMap['EN'] ?? key;
  }

  static String normalizeLanguageCode(String value) {
    switch (value.trim().toUpperCase()) {
      case 'EN':
      case 'ENGLISH':
      case 'INGLÉS':
      case 'INGLES':
        return 'EN';
      case 'ES':
      case 'ESPAÑOL':
        return 'ES';
      case 'DE':
      case 'DEUTSCH':
      case 'ALEMÁN':
      case 'ALEMAN':
        return 'DE';
      case 'RU':
      case 'РУССКИЙ':
      case 'RUSO':
        return 'RU';
      case 'JP':
      case 'JA':
      case '日本語':
      case 'JAPONÉS':
      case 'JAPONES':
        return 'JP';
      case 'ZH':
      case 'CH':
      case '中文':
      case 'CHINO':
        return 'ZH';
      case 'AR':
      case 'العربية':
      case 'ÁRABE':
      case 'ARABE':
        return 'AR';
      default:
        return 'ES';
    }
  }
}

String tr(BuildContext context, String key) {
  return context.watch<TranslationService>().tr(key);
}
