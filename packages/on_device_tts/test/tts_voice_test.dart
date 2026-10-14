import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

void main() {
  const enUs = TtsVoice(id: 'a', name: 'Samantha', locale: 'en-US');
  const enGb = TtsVoice(id: 'b', name: 'Daniel', locale: 'en_GB');
  const ptBr = TtsVoice(id: 'c', name: 'Luciana', locale: 'pt-BR');

  test('languageCode is the lowercase language subtag', () {
    expect(enUs.languageCode, 'en');
    expect(enGb.languageCode, 'en');
    expect(const TtsVoice(id: 'd', name: 'd', locale: 'FR').languageCode, 'fr');
  });

  test('a bare language matches every region', () {
    expect(enUs.speaks('en'), isTrue);
    expect(enGb.speaks('en'), isTrue);
    expect(ptBr.speaks('en'), isFalse);
  });

  test('a language with a region matches only that region', () {
    expect(enUs.speaks('en-US'), isTrue);
    expect(enUs.speaks('en-GB'), isFalse);
    expect(enGb.speaks('en-GB'), isTrue);
  });

  test('matching ignores case and separators', () {
    expect(enGb.speaks('EN-gb'), isTrue);
    expect(ptBr.speaks('pt_br'), isTrue);
  });

  test('a language is not matched by its prefix', () {
    const fil = TtsVoice(id: 'e', name: 'e', locale: 'fil-PH');
    expect(fil.speaks('fi'), isFalse);
  });

  test('equality', () {
    expect(const TtsVoice(id: 'a', name: 'Samantha', locale: 'en-US'), enUs);
    expect(const TtsVoice(id: 'a', name: 'Samantha', locale: 'en-US').hashCode,
        enUs.hashCode);
    expect(enUs == enGb, isFalse);
  });
}
