import 'package:flutter/widgets.dart';
import 'package:rtchat/l10n/app_localizations.dart';

/// A voice preview uses the voice's language, independently of the settings UI.
/// Extra samples cover speech languages for which the app has no UI translation.
String ttsSampleMessage(String language) {
  final parts = language.replaceAll('_', '-').toLowerCase().split('-');
  final base = parts.first;
  if (base == 'zh') {
    return parts.any((part) => const ['hant', 'tw', 'hk', 'mo'].contains(part))
        ? '這是文字轉語音的訊息範例。'
        : '这是文字转语音的信息示例。';
  }
  if (_samples[base] case final sample?) return sample;
  for (final locale in AppLocalizations.supportedLocales) {
    if (locale.languageCode.toLowerCase() == base) {
      return lookupAppLocalizations(locale).sampleMessage;
    }
  }
  return lookupAppLocalizations(const Locale('en')).sampleMessage;
}

const _samples = {
  'af': 'Hierdie is ’n voorbeeldboodskap vir teks-na-spraak.',
  'bg': 'Това е примерно съобщение за преобразуване на текст в реч.',
  'ca': 'Aquest és un missatge de mostra per a la síntesi de veu.',
  'cs': 'Toto je ukázková zpráva pro převod textu na řeč.',
  'da': 'Dette er en eksempelbesked til tekst til tale.',
  'el': 'Αυτό είναι ένα δείγμα μηνύματος για μετατροπή κειμένου σε ομιλία.',
  'et': 'See on kõnesünteesi näidissõnum.',
  'fi': 'Tämä on esimerkkiviesti tekstin puheeksi muuntamista varten.',
  'gu': 'આ લખાણને વાણીમાં ફેરવવા માટેનો નમૂના સંદેશ છે.',
  'hi': 'यह टेक्स्ट को आवाज़ में बदलने के लिए एक नमूना संदेश है।',
  'hr': 'Ovo je primjer poruke za pretvaranje teksta u govor.',
  'hu': 'Ez egy mintaszöveg a szövegfelolvasáshoz.',
  'id': 'Ini adalah contoh pesan untuk mengubah teks menjadi suara.',
  'is': 'Þetta eru prufuskilaboð fyrir talgervil.',
  'kn': 'ಇದು ಪಠ್ಯವನ್ನು ಧ್ವನಿಗೆ ಪರಿವರ್ತಿಸುವ ಮಾದರಿ ಸಂದೇಶವಾಗಿದೆ.',
  'lt': 'Tai pavyzdinis teksto vertimo į kalbą pranešimas.',
  'lv': 'Šis ir teksta pārvēršanas runā parauga ziņojums.',
  'ml': 'വാചകം ശബ്ദമാക്കുന്നതിനുള്ള ഒരു മാതൃകാ സന്ദേശമാണിത്.',
  'ms': 'Ini ialah contoh mesej untuk penukaran teks kepada pertuturan.',
  'nb': 'Dette er en eksempelmelding for tekst til tale.',
  'no': 'Dette er en eksempelmelding for tekst til tale.',
  'pa': 'ਇਹ ਲਿਖਤ ਨੂੰ ਆਵਾਜ਼ ਵਿੱਚ ਬਦਲਣ ਲਈ ਇੱਕ ਨਮੂਨਾ ਸੁਨੇਹਾ ਹੈ।',
  'ro': 'Acesta este un mesaj de probă pentru conversia textului în vorbire.',
  'sk': 'Toto je ukážková správa pre prevod textu na reč.',
  'sl': 'To je vzorčno sporočilo za pretvorbo besedila v govor.',
  'sr': 'Ово је пример поруке за претварање текста у говор.',
  'ta': 'இது உரையைப் பேச்சாக மாற்றுவதற்கான மாதிரி செய்தி.',
  'te': 'ఇది వచనాన్ని మాటగా మార్చడానికి ఒక నమూనా సందేశం.',
  'th': 'นี่คือข้อความตัวอย่างสำหรับการแปลงข้อความเป็นเสียงพูด',
  'tl': 'Ito ay isang halimbawang mensahe para sa pagbigkas ng teksto.',
  'tr': 'Bu, metni konuşmaya dönüştürmek için örnek bir mesajdır.',
  'vi': 'Đây là tin nhắn mẫu để chuyển văn bản thành giọng nói.',
};
