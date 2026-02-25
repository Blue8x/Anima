import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TranslationService extends ChangeNotifier {
  String _language;

  TranslationService({String initialLanguage = 'ES'})
      : _language = normalizeLanguageCode(initialLanguage);

  String get language => _language;

  void setLanguage(String language) {
    _language = normalizeLanguageCode(language);
    notifyListeners();
  }

  static const List<String> supportedLanguages = [
    'ES',
    'EN',
    'CH',
    'AR',
    'RU',
    'JP',
    'DE',
    'FR',
    'HI',
    'PT',
    'BN',
    'UR',
    'ID',
    'KO',
    'VI',
    'IT',
    'TR',
    'TA',
    'TH',
    'PL',
  ];

  static String normalizeLanguageCode(String value) {
    switch (value.trim().toUpperCase()) {
      case 'ES':
      case 'ESPAÑOL':
        return 'ES';
      case 'EN':
      case 'INGLÉS':
      case 'INGLES':
      case 'ENGLISH':
        return 'EN';
      case 'CH':
      case 'ZH':
      case 'CHINO':
      case '中文':
        return 'CH';
      case 'AR':
      case 'ÁRABE':
      case 'ARABE':
      case 'العربية':
        return 'AR';
      case 'RU':
      case 'RUSO':
      case 'РУССКИЙ':
        return 'RU';
      case 'JP':
      case 'JA':
      case 'JAPONÉS':
      case 'JAPONES':
      case '日本語':
        return 'JP';
      case 'DE':
      case 'ALEMÁN':
      case 'ALEMAN':
      case 'DEUTSCH':
        return 'DE';
      case 'FR':
      case 'FRANCÉS':
      case 'FRANCES':
      case 'FRANÇAIS':
        return 'FR';
      case 'PT':
      case 'PORTUGUÉS':
      case 'PORTUGUES':
      case 'PORTUGUÊS':
        return 'PT';
      case 'HI':
      case 'हिन्दी':
      case 'HINDI':
        return 'HI';
      case 'BN':
      case 'বাংলা':
      case 'BENGALI':
        return 'BN';
      case 'UR':
      case 'اردو':
      case 'URDU':
        return 'UR';
      case 'ID':
      case 'BAHASA INDONESIA':
      case 'INDONESIAN':
        return 'ID';
      case 'KO':
      case 'KOREAN':
      case '한국어':
        return 'KO';
      case 'VI':
      case 'VIETNAMESE':
      case 'TIẾNG VIỆT':
      case 'TIENG VIET':
        return 'VI';
      case 'IT':
      case 'ITALIAN':
      case 'ITALIANO':
        return 'IT';
      case 'TR':
      case 'TURKISH':
      case 'TÜRKÇE':
      case 'TURKCE':
        return 'TR';
      case 'TA':
      case 'TAMIL':
      case 'தமிழ்':
        return 'TA';
      case 'TH':
      case 'THAI':
      case 'ไทย':
        return 'TH';
      case 'PL':
      case 'POLISH':
      case 'POLSKI':
        return 'PL';
      default:
        return 'ES';
    }
  }

  static const Map<String, Map<String, String>> _translations = {
    'chat': {
      'Inglés': 'Chat',
      'Español': 'Chat',
      'Chino': '聊天',
      'Árabe': 'الدردشة',
      'Ruso': 'Чат',
    },
    'memoryExplorer': {
      'Inglés': 'Memory Explorer',
      'Español': 'Explorador de Memoria',
      'Chino': '记忆浏览器',
      'Árabe': 'مستكشف الذاكرة',
      'Ruso': 'Проводник памяти',
    },
    'commandCenter': {
      'Inglés': 'Command Center & Legacy',
      'Español': 'Sala de Mandos y Legado',
      'Chino': '控制中心与遗产',
      'Árabe': 'غرفة القيادة والإرث',
      'Ruso': 'Командный центр и наследие',
    },
    'digitalBrain': {
      'Inglés': 'Digital Brain',
      'Español': 'Cerebro Digital',
      'Chino': '数字大脑',
      'Árabe': 'الدماغ الرقمي',
      'Ruso': 'Цифровой мозг',
    },
    'onboardingTitle': {
      'Inglés': 'Hi, I am Anima.',
      'Español': 'Hola, soy Anima.',
      'Chino': '你好，我是 Anima。',
      'Árabe': 'مرحبًا، أنا أنيما.',
      'Ruso': 'Привет, я Anima.',
    },
    'onboardingDescription': {
      'Inglés':
          'I am your local brain: private, persistent, and designed to remember, support, and help you grow.',
      'Español':
          'Soy tu cerebro local: privado, persistente y diseñado para acompañarte, recordarte y ayudarte a crecer.',
      'Chino': '我是你的本地大脑：私密、持久，专为陪伴你、记住你并帮助你成长而设计。',
      'Árabe':
          'أنا عقلك المحلي: خاص ودائم ومصمم لمرافقتك وتذكّرك ومساعدتك على النمو.',
      'Ruso':
          'Я твой локальный мозг: приватный, постоянный и созданный, чтобы сопровождать тебя, помнить и помогать расти.',
    },
    'nameQuestion': {
      'EN': 'What is your name?',
      'ES': '¿Cómo te llamas?',
      'CH': '你叫什么名字？',
      'AR': 'ما اسمك؟',
      'RU': 'Как тебя зовут?',
      'JP': 'お名前は何ですか？',
      'DE': 'Wie heißt du?',
      'FR': 'Comment tu t’appelles ?',
      'HI': 'तुम्हारा नाम क्या है?',
      'PT': 'Como você se chama?',
      'BN': 'তোমার নাম কী?',
      'UR': 'آپ کا نام کیا ہے؟',
      'ID': 'Siapa namamu?',
      'KO': '이름이 뭐예요?',
      'VI': 'Bạn tên là gì?',
      'IT': 'Come ti chiami?',
      'TR': 'Adın ne?',
      'TA': 'உன் பெயர் என்ன?',
      'TH': 'คุณชื่ออะไร?',
      'PL': 'Jak masz na imię?',
      'Inglés': 'What is your name?',
      'Español': '¿Cómo te llamas?',
      'Chino': '你叫什么名字？',
      'Árabe': 'ما اسمك؟',
      'Ruso': 'Как тебя зовут?',
    },
    'optionalSeedQuestion': {
      'EN': 'What should I know about you to begin? (Optional)',
      'ES': '¿Qué te gustaría que supiera de ti para empezar? (Opcional)',
      'CH': '你希望我一开始了解你什么？（可选）',
      'AR': 'ما الذي تود أن أعرفه عنك في البداية؟ (اختياري)',
      'RU': 'Что мне стоит знать о тебе для начала? (Необязательно)',
      'JP': '始める前にあなたについて何を知っておくべきですか？（任意）',
      'DE': 'Was sollte ich zu Beginn über dich wissen? (Optional)',
      'FR': 'Que devrais-je savoir sur toi pour commencer ? (Optionnel)',
      'HI': 'शुरू करने के लिए मुझे तुम्हारे बारे में क्या जानना चाहिए? (वैकल्पिक)',
      'PT': 'O que devo saber sobre você para começar? (Opcional)',
      'BN': 'শুরু করতে তোমার সম্পর্কে আমার কী জানা উচিত? (ঐচ্ছিক)',
      'UR': 'شروع کرنے کے لیے مجھے آپ کے بارے میں کیا معلوم ہونا چاہیے؟ (اختیاری)',
      'ID': 'Apa yang perlu aku ketahui tentangmu untuk memulai? (Opsional)',
      'KO': '시작하려면 너에 대해 무엇을 알면 좋을까? (선택 사항)',
      'VI': 'Để bắt đầu, mình nên biết gì về bạn? (Tùy chọn)',
      'IT': 'Cosa dovrei sapere di te per iniziare? (Facoltativo)',
      'TR': 'Başlamak için senin hakkında ne bilmeliyim? (İsteğe bağlı)',
      'TA': 'தொடங்க நான் உன்னைப் பற்றி என்ன தெரிந்திருக்க வேண்டும்? (விருப்பத்தேர்வு)',
      'TH': 'ฉันควรรู้อะไรเกี่ยวกับคุณเพื่อเริ่มต้น? (ไม่บังคับ)',
      'PL': 'Co powinienem o tobie wiedzieć na początek? (Opcjonalnie)',
      'Inglés': 'What should I know about you to begin? (Optional)',
      'Español': '¿Qué te gustaría que supiera de ti para empezar? (Opcional)',
      'Chino': '你希望我一开始了解你什么？（可选）',
      'Árabe': 'ما الذي تود أن أعرفه عنك في البداية؟ (اختياري)',
      'Ruso': 'Что мне стоит знать о тебе для начала? (Необязательно)',
    },
    'startJourney': {
      'EN': 'Start journey',
      'ES': 'Empezar viaje',
      'CH': '开始旅程',
      'AR': 'ابدأ الرحلة',
      'RU': 'Начать путь',
      'JP': '旅を始める',
      'DE': 'Reise starten',
      'FR': 'Commencer le voyage',
      'HI': 'यात्रा शुरू करें',
      'PT': 'Começar jornada',
      'BN': 'যাত্রা শুরু করুন',
      'UR': 'سفر شروع کریں',
      'ID': 'Mulai perjalanan',
      'KO': '여정을 시작하기',
      'VI': 'Bắt đầu hành trình',
      'IT': 'Inizia il viaggio',
      'TR': 'Yolculuğa başla',
      'TA': 'பயணத்தை தொடங்கு',
      'TH': 'เริ่มการเดินทาง',
      'PL': 'Rozpocznij podróż',
      'Inglés': 'Start journey',
      'Español': 'Empezar viaje',
      'Chino': '开始旅程',
      'Árabe': 'ابدأ الرحلة',
      'Ruso': 'Начать путь',
    },
    'languageLabel': {
      'EN': 'Language',
      'ES': 'Idioma',
      'CH': '语言',
      'AR': 'اللغة',
      'RU': 'Язык',
      'JP': '言語',
      'DE': 'Sprache',
      'Inglés': 'Language',
      'Español': 'Idioma',
      'Chino': '语言',
      'Árabe': 'اللغة',
      'Ruso': 'Язык',
    },
    'failedLoadHistory': {
      'Inglés': 'Failed to load history',
      'Español': 'Error al cargar historial',
      'Chino': '加载历史失败',
      'Árabe': 'فشل تحميل السجل',
      'Ruso': 'Не удалось загрузить историю',
    },
    'failedProcessMessage': {
      'Inglés': 'Failed to process message',
      'Español': 'Error al procesar mensaje',
      'Chino': '处理消息失败',
      'Árabe': 'فشل في معالجة الرسالة',
      'Ruso': 'Не удалось обработать сообщение',
    },
    'personalCompanion': {
      'Inglés': 'Your personal AI companion',
      'Español': 'Tu compañera de IA personal',
      'Chino': '你的个人 AI 伙伴',
      'Árabe': 'رفيقك الشخصي بالذكاء الاصطناعي',
      'Ruso': 'Твой личный ИИ-компаньон',
    },
    'hidePreviousHistory': {
      'Inglés': 'Hide previous history',
      'Español': 'Ocultar historial anterior',
      'Chino': '隐藏之前的历史记录',
      'Árabe': 'إخفاء السجل السابق',
      'Ruso': 'Скрыть предыдущую историю',
    },
    'showPreviousHistory': {
      'Inglés': 'Show previous history',
      'Español': 'Desplegar historial anterior',
      'Chino': '显示之前的历史记录',
      'Árabe': 'عرض السجل السابق',
      'Ruso': 'Показать предыдущую историю',
    },
    'aiBiographerTagline': {
      'Inglés': 'Your AI biographer, journal, and mentor',
      'Español': 'Tu biógrafa, diario y mentora de IA',
      'Chino': '你的 AI 传记作者、日记与导师',
      'Árabe': 'كاتبة سيرتك ومذكرتك ومرشدتك بالذكاء الاصطناعي',
      'Ruso': 'Твой ИИ-биограф, дневник и наставник',
    },
    'welcomeIntro': {
      'Inglés':
          'Hello! I am Anima. I am here to listen, remember what matters, and support your journey. Share your day or whatever is on your mind.',
      'Español':
          '¡Hola! Soy Anima. Estoy aquí para escucharte, recordar lo importante y acompañarte en tu camino. Cuéntame tu día o lo que tengas en mente.',
      'Chino': '你好！我是 Anima。我会倾听你、记住重要的事，并陪伴你的旅程。分享你的一天或任何心事。',
      'Árabe':
          'مرحبًا! أنا أنيما. أنا هنا لأستمع إليك، وأتذكر ما يهم، وأدعم رحلتك. شاركني يومك أو أي شيء يدور في ذهنك.',
      'Ruso':
          'Привет! Я Anima. Я здесь, чтобы слушать, помнить важное и поддерживать твой путь. Поделись своим днем или тем, что у тебя на уме.',
    },
    'typeMessage': {
      'Inglés': 'Type your message...',
      'Español': 'Escribe tu mensaje...',
      'Chino': '输入你的消息...',
      'Árabe': 'اكتب رسالتك...',
      'Ruso': 'Напиши сообщение...',
    },
    'now': {
      'Inglés': 'Now',
      'Español': 'Ahora',
      'Chino': '刚刚',
      'Árabe': 'الآن',
      'Ruso': 'Сейчас',
    },
    'minutesAgo': {
      'Inglés': '{n}m ago',
      'Español': 'hace {n}m',
      'Chino': '{n}分钟前',
      'Árabe': 'قبل {n} د',
      'Ruso': '{n}м назад',
    },
    'hoursAgo': {
      'Inglés': '{n}h ago',
      'Español': 'hace {n}h',
      'Chino': '{n}小时前',
      'Árabe': 'قبل {n} س',
      'Ruso': '{n}ч назад',
    },
    'back': {
      'EN': 'Back',
      'ES': 'Volver',
      'CH': '返回',
      'AR': 'رجوع',
      'RU': 'Назад',
      'JP': '戻る',
      'DE': 'Zurück',
      'FR': 'Retour',
      'HI': 'वापस',
      'PT': 'Voltar',
      'BN': 'ফিরে যান',
      'UR': 'واپس',
      'ID': 'Kembali',
      'KO': '뒤로',
      'VI': 'Quay lại',
      'IT': 'Indietro',
      'TR': 'Geri',
      'TA': 'திரும்பு',
      'TH': 'ย้อนกลับ',
      'PL': 'Wróć',
      'Inglés': 'Back',
      'Español': 'Atrás',
      'Chino': '返回',
      'Árabe': 'رجوع',
      'Ruso': 'Назад',
    },
    'continue': {
      'EN': 'Continue',
      'ES': 'Continuar',
      'CH': '继续',
      'AR': 'متابعة',
      'RU': 'Продолжить',
      'JP': '続ける',
      'DE': 'Weiter',
      'FR': 'Continuer',
      'HI': 'जारी रखें',
      'PT': 'Continuar',
      'BN': 'চালিয়ে যান',
      'UR': 'جاری رکھیں',
      'ID': 'Lanjutkan',
      'KO': '계속하기',
      'VI': 'Tiếp tục',
      'IT': 'Continua',
      'TR': 'Devam et',
      'TA': 'தொடரவும்',
      'TH': 'ดำเนินการต่อ',
      'PL': 'Kontynuuj',
      'Inglés': 'Continue',
      'Español': 'Continuar',
      'Chino': '继续',
      'Árabe': 'متابعة',
      'Ruso': 'Продолжить',
    },
    'nameInputHint': {
      'EN': 'Type your name...',
      'ES': 'Escribe tu nombre...',
      'CH': '输入你的名字...',
      'AR': 'اكتب اسمك...',
      'RU': 'Введите ваше имя...',
      'JP': 'あなたの名前を入力してください...',
      'DE': 'Gib deinen Namen ein...',
      'FR': 'Écris ton prénom...',
      'HI': 'अपना नाम लिखें...',
      'PT': 'Digite seu nome...',
      'BN': 'তোমার নাম লিখো...',
      'UR': 'اپنا نام لکھیں...',
      'ID': 'Ketik namamu...',
      'KO': '이름을 입력해 주세요...',
      'VI': 'Nhập tên của bạn...',
      'IT': 'Scrivi il tuo nome...',
      'TR': 'Adını yaz...',
      'TA': 'உன் பெயரை உள்ளிடு...',
      'TH': 'พิมพ์ชื่อของคุณ...',
      'PL': 'Wpisz swoje imię...',
      'Inglés': 'Type your name...',
      'Español': 'Escribe tu nombre...',
      'Chino': '输入你的名字...',
      'Árabe': 'اكتب اسمك...',
      'Ruso': 'Введите ваше имя...',
    },
    'optionalSeedHint': {
      'EN': 'Tell me something about you, your goals, or your context...',
      'ES': 'Cuéntame algo sobre ti, tus metas o tu contexto...',
      'CH': '告诉我一些关于你、你的目标或你的背景...',
      'AR': 'أخبرني شيئًا عنك أو عن أهدافك أو عن سياقك...',
      'RU': 'Расскажите что-нибудь о себе, своих целях или контексте...',
      'JP': 'あなたのことや目標、背景について教えてください...',
      'DE': 'Erzähl mir etwas über dich, deine Ziele oder deinen Kontext...',
      'FR': 'Parle-moi un peu de toi, de tes objectifs ou de ton contexte...',
      'HI': 'मुझे अपने बारे में, अपने लक्ष्यों या अपनी स्थिति के बारे में बताओ...',
      'PT': 'Conte-me algo sobre você, seus objetivos ou seu contexto...',
      'BN': 'তোমার সম্পর্কে, তোমার লক্ষ্য বা প্রেক্ষাপট সম্পর্কে কিছু বলো...',
      'UR': 'اپنے بارے میں، اپنے اہداف یا اپنے حالات کے بارے میں کچھ بتائیں...',
      'ID': 'Ceritakan sesuatu tentang dirimu, tujuanmu, atau konteksmu...',
      'KO': '너 자신, 목표 또는 상황에 대해 알려줘...',
      'VI': 'Hãy kể cho mình về bạn, mục tiêu hoặc bối cảnh của bạn...',
      'IT': 'Raccontami qualcosa di te, dei tuoi obiettivi o del tuo contesto...',
      'TR': 'Bana kendinden, hedeflerinden veya bağlamından bahset...',
      'TA': 'உன்னைப் பற்றி, உன் இலக்குகள் அல்லது உன் சூழலைப் பற்றி சொல்லு...',
      'TH': 'เล่าเกี่ยวกับตัวคุณ เป้าหมาย หรือบริบทของคุณให้ฉันฟัง...',
      'PL': 'Opowiedz mi coś o sobie, swoich celach lub swoim kontekście...',
      'Inglés': 'Tell me something about you, your goals, or your context...',
      'Español': 'Cuéntame algo sobre ti, tus metas o tu contexto...',
      'Chino': '告诉我一些关于你、你的目标或你的背景...',
      'Árabe': 'أخبرني شيئًا عنك أو عن أهدافك أو عن سياقك...',
      'Ruso': 'Расскажите что-нибудь о себе, своих целях или контексте...',
    },
    'openMenu': {
      'EN': 'Open menu',
      'ES': 'Abrir menú',
      'CH': '打开菜单',
      'AR': 'افتح القائمة',
      'RU': 'Открыть меню',
      'Inglés': 'Open menu',
      'Español': 'Abrir menú',
      'Chino': '打开菜单',
      'Árabe': 'افتح القائمة',
      'Ruso': 'Открыть меню',
    },
    'closeMenu': {
      'EN': 'Close menu',
      'ES': 'Cerrar menú',
      'CH': '关闭菜单',
      'AR': 'إغلاق القائمة',
      'RU': 'Закрыть меню',
      'Inglés': 'Close menu',
      'Español': 'Cerrar menú',
      'Chino': '关闭菜单',
      'Árabe': 'إغلاق القائمة',
      'Ruso': 'Закрыть меню',
    },
    'deleteMemory': {
      'EN': 'Delete memory',
      'ES': 'Eliminar memoria',
      'CH': '删除记忆',
      'AR': 'حذف الذكرى',
      'RU': 'Удалить воспоминание',
      'Inglés': 'Delete memory',
      'Español': 'Eliminar memoria',
      'Chino': '删除记忆',
      'Árabe': 'حذف الذكرى',
      'Ruso': 'Удалить воспоминание',
    },
    'factoryResetCognitive': {
      'EN': 'Cognitive factory reset',
      'ES': 'Reinicio cognitivo de fábrica',
      'CH': '认知恢复出厂设置',
      'AR': 'إعادة ضبط معرفية للمصنع',
      'RU': 'Когнитивный сброс до заводских настроек',
      'Inglés': 'Cognitive factory reset',
      'Español': 'Reinicio cognitivo de fábrica',
      'Chino': '认知恢复出厂设置',
      'Árabe': 'إعادة ضبط معرفية للمصنع',
      'Ruso': 'Когнитивный сброс до заводских настроек',
    },
  };

  String tr(String key) {
    final languageMap = _translations[key];
    if (languageMap == null) return key;

    final legacyLanguageKey = _legacyLanguageKey(_language);
    return languageMap[_language] ??
        (legacyLanguageKey != null ? languageMap[legacyLanguageKey] : null) ??
        languageMap['ES'] ??
        languageMap['Español'] ??
        key;
  }

  String? _legacyLanguageKey(String languageCode) {
    switch (languageCode) {
      case 'EN':
        return 'Inglés';
      case 'ES':
        return 'Español';
      case 'CH':
        return 'Chino';
      case 'AR':
        return 'Árabe';
      case 'RU':
        return 'Ruso';
      default:
        return null;
    }
  }
}

String tr(BuildContext context, String key) {
  return context.watch<TranslationService>().tr(key);
}
