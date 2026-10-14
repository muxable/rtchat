import 'package:on_device_tts/on_device_tts.dart';

/// "Hello! This is how my voice sounds." in each language a voice pack
/// speaks, for previewing a voice in that language. These are in the
/// voice's language, not the app's, so they aren't in the app's strings.
const _samples = {
  'ar': 'مرحبًا! هكذا يبدو صوتي.',
  'bg': 'Здравейте! Ето как звучи гласът ми.',
  'cs': 'Dobrý den! Takhle zní můj hlas.',
  'da': 'Hej! Sådan lyder min stemme.',
  'de': 'Hallo! So klingt meine Stimme.',
  'el': 'Γεια σας! Έτσι ακούγεται η φωνή μου.',
  'en': 'Hello! This is how my voice sounds.',
  'es': '¡Hola! Así suena mi voz.',
  'et': 'Tere! Selline kõlab minu hääl.',
  'fi': 'Hei! Tältä minun ääneni kuulostaa.',
  'fr': 'Bonjour ! Voici à quoi ressemble ma voix.',
  'hi': 'नमस्ते! मेरी आवाज़ ऐसी सुनाई देती है।',
  'hr': 'Bok! Ovako zvuči moj glas.',
  'hu': 'Szia! Így szól a hangom.',
  'id': 'Halo! Beginilah suara saya.',
  'it': 'Ciao! Ecco come suona la mia voce.',
  'ja': 'こんにちは!私の声はこんな感じです。',
  'ko': '안녕하세요! 제 목소리는 이렇게 들려요.',
  'lt': 'Labas! Štai kaip skamba mano balsas.',
  'lv': 'Sveiki! Lūk, kā skan mana balss.',
  'nl': 'Hallo! Zo klinkt mijn stem.',
  'pl': 'Cześć! Tak brzmi mój głos.',
  'pt': 'Olá! É assim que soa a minha voz.',
  'ro': 'Bună! Așa sună vocea mea.',
  'ru': 'Привет! Вот так звучит мой голос.',
  'sk': 'Ahoj! Takto znie môj hlas.',
  'sl': 'Živjo! Tako zveni moj glas.',
  'sv': 'Hej! Så här låter min röst.',
  'tr': 'Merhaba! Sesim böyle duyuluyor.',
  'uk': 'Привіт! Ось так звучить мій голос.',
  'vi': 'Xin chào! Đây là giọng nói của tôi.',
  'zh': '你好!这就是我的声音。',
};

/// A short sentence in [language] (a BCP-47 tag) to preview a voice with,
/// or [fallback] (e.g. the app's own sample message) for a language without
/// one.
String voiceSample(String language, {required String fallback}) =>
    _samples[LanguageTag.parse(language).language] ?? fallback;
