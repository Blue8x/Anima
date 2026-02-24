import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TranslationService extends ChangeNotifier {
  String _language;

  TranslationService({String initialLanguage = 'Español'})
      : _language = initialLanguage;

  String get language => _language;

  void setLanguage(String language) {
    _language = language;
    notifyListeners();
  }

  static const List<String> supportedLanguages = [
    'Inglés',
    'Español',
    'Chino',
    'Árabe',
    'Ruso',
  ];

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
      'Inglés': 'What is your name?',
      'Español': '¿Cómo te llamas?',
      'Chino': '你叫什么名字？',
      'Árabe': 'ما اسمك؟',
      'Ruso': 'Как тебя зовут?',
    },
    'optionalSeedQuestion': {
      'Inglés': 'What should I know about you to begin? (Optional)',
      'Español': '¿Qué te gustaría que supiera de ti para empezar? (Opcional)',
      'Chino': '你希望我一开始了解你什么？（可选）',
      'Árabe': 'ما الذي تود أن أعرفه عنك في البداية؟ (اختياري)',
      'Ruso': 'Что мне стоит знать о тебе для начала? (Необязательно)',
    },
    'startJourney': {
      'Inglés': 'Start journey',
      'Español': 'Empezar viaje',
      'Chino': '开始旅程',
      'Árabe': 'ابدأ الرحلة',
      'Ruso': 'Начать путь',
    },
    'languageLabel': {
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
  };

  String tr(String key) {
    final languageMap = _translations[key];
    if (languageMap == null) return key;
    return languageMap[_language] ?? languageMap['Español'] ?? key;
  }
}

String tr(BuildContext context, String key) {
  return context.watch<TranslationService>().tr(key);
}
