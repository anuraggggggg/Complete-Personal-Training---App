import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class TranslatorController extends GetxController {
  /// Current selected language
  final RxString currentLang = 'en'.obs;

  /// Cache to reduce API cost
  final Map<String, String> _cache = {};

  /// Avoid duplicate API calls
  final Set<String> _inProgress = {};

  /// 🔑 GOOGLE CLOUD TRANSLATE API KEY
  static const String _apiKey = "YOUR_GOOGLE_TRANSLATE_API_KEY";

  /// 🌍 Supported languages (UI ke liye)
  final List<LangModel> languages = const [
    LangModel(code: 'en', name: 'English'),
    LangModel(code: 'hi', name: 'हिंदी'),
    LangModel(code: 'es', name: 'Español'),
    LangModel(code: 'fr', name: 'Français'),
    LangModel(code: 'ar', name: 'العربية'),
  ];

  /// Change language
  void changeLanguage(String lang) {
    if (currentLang.value == lang) return;

    currentLang.value = lang;
    _cache.clear(); // 🔥 important
    _inProgress.clear();
    update();
  }

  /// ===============================
  /// MAIN TRANSLATE METHOD
  /// ===============================
  String tr(String text) {
    if (text.trim().isEmpty) return text;
    if (currentLang.value == 'en') return text;

    // 1️⃣ Dictionary (instant)
    final dict = _dictionary[currentLang.value]?[text];
    if (dict != null) return dict;

    // 2️⃣ Cache
    if (_cache.containsKey(text)) {
      return _cache[text]!;
    }

    // 3️⃣ Avoid duplicate API calls
    if (!_inProgress.contains(text)) {
      _inProgress.add(text);
      _translateFromCloud(text);
    }

    // 4️⃣ Temporary fallback
    return text;
  }

  /// ===============================
  /// GOOGLE CLOUD TRANSLATE
  /// ===============================
  Future<void> _translateFromCloud(String text) async {
    try {
      final uri = Uri.parse(
        "https://translation.googleapis.com/language/translate/v2?key=$_apiKey",
      );

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "q": text,
          "source": "en",
          "target": currentLang.value,
          "format": "text",
        }),
      );

      final decoded = jsonDecode(response.body);
      final translated =
          decoded['data']?['translations']?[0]?['translatedText'];

      if (translated != null && translated.isNotEmpty) {
        _cache[text] = translated;
        update(); // 🔥 refresh UI
      }
    } catch (_) {
      _cache[text] = text;
    } finally {
      _inProgress.remove(text);
    }
  }

  /// ===============================
  /// OFFLINE DICTIONARY
  /// ===============================
  final Map<String, Map<String, String>> _dictionary = {
   'hi': {
  "🥗 Diet Plans": "🥗 डाइट योजनाएँ",
  "Choose Diet Type": "डाइट का प्रकार चुनें",
  "Select your food preference": "अपनी भोजन पसंद चुनें",
  "Select Variety": "भोजन श्रेणी चुनें",
  "Continue": "आगे बढ़ें",
  "Fitness Goal": "फिटनेस लक्ष्य",
  "Choose your transformation plan": "अपना फिटनेस लक्ष्य चुनें",
  "Select Goal": "लक्ष्य चुनें",
  "Next": "अगला",
  "High Nutrition": "उच्च पोषण",
  "Failed to load diets": "डाइट लोड करने में समस्या आई",
  "Muscle Building": "मसल्स बनाना",
  "Fat Loss": "वजन घटाना",
  "veg": "शाकाहारी",
  "nonveg": "मांसाहारी",
  "Diet Plan": "डाइट योजना",
  "You Will Have To Purchase Diet Plan Plus Workout Plans Or Only Diet Plans":
      "डाइट प्लान देखने के लिए आपको डाइट या वर्कआउट प्लान खरीदना होगा",
  "Gender": "लिंग",
"Personalized diet plans": "व्यक्तिगत डाइट योजनाएँ",
"Male": "पुरुष",
"Female": "महिला",
"Language": "भाषा",
"Choose a language to read your diet plan":
    "अपनी डाइट योजना पढ़ने के लिए भाषा चुनें",
"English": "अंग्रेज़ी",
"Hindi": "हिंदी",
"Spanish": "स्पेनिश",
"French": "फ़्रेंच",
"Arabic": "अरबी",

},


  'es': {
  "🥗 Diet Plans": "🥗 Planes de dieta",
  "Choose Diet Type": "Elige el tipo de dieta",
  "Select your food preference": "Selecciona tu preferencia de comida",
  "Select Variety": "Seleccionar variedad",
  "Continue": "Continuar",
  "Fitness Goal": "Objetivo de fitness",
  "Choose your transformation plan": "Elige tu plan de transformación",
  "Select Goal": "Seleccionar objetivo",
  "Next": "Siguiente",
  "High Nutrition": "Alta nutrición",
  "Failed to load diets": "No se pudieron cargar las dietas",
  "Muscle Building": "Construcción muscular",
  "Fat Loss": "Pérdida de grasa",
  "veg": "Vegetariano",
  "nonveg": "No vegetariano",
  "Diet Plan": "Plan de dieta",
  "Gender": "Género",
"Personalized diet plans": "Planes de dieta personalizados",
"Male": "Hombre",
"Female": "Mujer",
"Language": "Idioma",
"Choose a language to read your diet plan":
    "Elige un idioma para leer tu plan de dieta",

},

    'fr': {
  "🥗 Diet Plans": "🥗 Plans alimentaires",
  "Choose Diet Type": "Choisissez le type de régime",
  "Select your food preference": "Sélectionnez vos préférences alimentaires",
  "Select Variety": "Sélectionner la variété",
  "Continue": "Continuer",
  "Fitness Goal": "Objectif fitness",
  "Choose your transformation plan": "Choisissez votre plan de transformation",
  "Select Goal": "Sélectionner l'objectif",
  "Next": "Suivant",
  "High Nutrition": "Nutrition élevée",
  "Failed to load diets": "Échec du chargement des régimes",
  "Muscle Building": "Prise de muscle",
  "Fat Loss": "Perte de graisse",
  "veg": "Végétarien",
  "nonveg": "Non végétarien",
  "Diet Plan": "Plan alimentaire",
  "Gender": "Genre",
"Personalized diet plans": "Plans alimentaires personnalisés",
"Male": "Homme",
"Female": "Femme",
"Language": "Langue",
"Choose a language to read your diet plan":
    "Choisissez une langue pour lire votre plan alimentaire",

},

  'ar': {
  "🥗 Diet Plans": "🥗 خطط النظام الغذائي",
  "Choose Diet Type": "اختر نوع النظام الغذائي",
  "Select your food preference": "اختر تفضيلات الطعام",
  "Select Variety": "اختر الفئة",
  "Continue": "متابعة",
  "Fitness Goal": "هدف اللياقة البدنية",
  "Choose your transformation plan": "اختر خطة التحول الخاصة بك",
  "Select Goal": "اختر الهدف",
  "Next": "التالي",
  "High Nutrition": "تغذية عالية",
  "Failed to load diets": "فشل في تحميل الأنظمة الغذائية",
  "Muscle Building": "بناء العضلات",
  "Fat Loss": "فقدان الدهون",
  "veg": "نباتي",
  "nonveg": "غير نباتي",
  "Diet Plan": "خطة غذائية",
  "Gender": "الجنس",
"Personalized diet plans": "خطط غذائية مخصصة",
"Male": "ذكر",
"Female": "أنثى",
"Language": "اللغة",
"Choose a language to read your diet plan":
    "اختر لغة لقراءة خطة نظامك الغذائي",

},
  };
}

/// 🌍 Language model
class LangModel {
  final String code;
  final String name;

  const LangModel({required this.code, required this.name});
}
