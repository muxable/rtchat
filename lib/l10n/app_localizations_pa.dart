// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Panjabi Punjabi (`pa`).
class AppLocalizationsPa extends AppLocalizations {
  AppLocalizationsPa([String locale = 'pa']) : super(locale);

  @override
  String get sendAMessage => 'ਸੁਨੇਹਾ ਭੇਜੋ...';

  @override
  String get writeSomething => 'ਕੁਝ ਲਿਖੋ...';

  @override
  String get speakToTheCrowds => 'ਭੀੜ ਨਾਲ ਗੱਲ ਕਰੋ...';

  @override
  String get shareYourThoughts => 'ਆਪਣੇ ਵਿਚਾਰ ਸਾਂਝੇ ਕਰੋ...';

  @override
  String get saySomethingYouLittleBitch => 'ਕੁਝ ਤਾਂ ਬੋਲ, ਕਮੀਨਿਆ...';

  @override
  String get search => 'ਖੋਜੋ';

  @override
  String get notSignedIn => 'ਸਾਈਨ ਇਨ ਨਹੀਂ ਕੀਤਾ';

  @override
  String get searchChannels => 'ਖੋਜੋ';

  @override
  String get raidAChannel => 'ਰੇਡ';

  @override
  String get noMessagesEmptyState => 'ਇੱਥੇ ਕਾਫ਼ੀ ਸ਼ਾਂਤੀ ਹੈ।';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ਨਵੇਂ ਸੁਨੇਹੇ',
      one: '1 ਨਵਾਂ ਸੁਨੇਹਾ',
      zero: 'ਕੋਈ ਨਵਾਂ ਸੁਨੇਹਾ ਨਹੀਂ',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Twitch ਨਾਲ ਸਾਈਨ ਇਨ ਕਰੋ';

  @override
  String get signInError =>
      'ਸਾਈਨ ਇਨ ਕਰਨ ਵੇਲੇ ਕੋਈ ਗੜਬੜ ਹੋਈ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get continueAsGuest => 'ਮਹਿਮਾਨ ਵਜੋਂ ਜਾਰੀ ਰੱਖੋ';

  @override
  String get signInToSendMessages => 'ਸੁਨੇਹੇ ਭੇਜਣ ਲਈ ਸਾਈਨ ਇਨ ਕਰੋ';

  @override
  String get currentViewers => 'ਮੌਜੂਦਾ ਦਰਸ਼ਕ';

  @override
  String get textToSpeech => 'ਟੈਕਸਟ ਟੂ ਸਪੀਚ';

  @override
  String get streamPreview => 'ਸਟ੍ਰੀਮ ਪੂਰਵਦਰਸ਼ਨ';

  @override
  String get activityFeed => 'ਗਤੀਵਿਧੀ ਫੀਡ';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString \'ਤੇ ਸਟ੍ਰੀਮ ਆਨਲਾਈਨ ਹੋਈ';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString \'ਤੇ ਸਟ੍ਰੀਮ ਆਫ਼ਲਾਈਨ ਹੋਈ';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString \'ਤੇ ਚੈਟ ਸਾਫ਼ ਕੀਤੀ ਗਈ';
  }

  @override
  String get configureQuickLinks => 'ਤੁਰੰਤ ਲਿੰਕ ਕੌਂਫਿਗਰ ਕਰੋ';

  @override
  String get disableRainMode => 'ਰੇਨ ਮੋਡ ਬੰਦ ਕਰੋ';

  @override
  String get enableRainMode => 'ਰੇਨ ਮੋਡ ਚਾਲੂ ਕਰੋ';

  @override
  String get disableRainModeSubtitle => 'ਇੰਟਰੈਕਸ਼ਨ ਚਾਲੂ ਹੋ ਜਾਵੇਗਾ';

  @override
  String get enableRainModeSubtitle => 'ਇੰਟਰੈਕਸ਼ਨ ਬੰਦ ਹੋ ਜਾਵੇਗਾ';

  @override
  String get refreshAudioSources => 'ਆਡੀਓ ਸਰੋਤ ਰੀਫ੍ਰੈਸ਼ ਕਰੋ';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ਆਡੀਓ ਸਰੋਤ ਰੀਫ੍ਰੈਸ਼ ਕੀਤੇ ਗਏ',
      one: '1 ਆਡੀਓ ਸਰੋਤ ਰੀਫ੍ਰੈਸ਼ ਕੀਤਾ ਗਿਆ',
      zero: 'ਕੋਈ ਆਡੀਓ ਸਰੋਤ ਰੀਫ੍ਰੈਸ਼ ਨਹੀਂ ਕੀਤਾ ਗਿਆ',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'ਸੈਟਿੰਗਾਂ';

  @override
  String get signOut => 'ਸਾਈਨ ਆਊਟ ਕਰੋ';

  @override
  String get cancel => 'ਰੱਦ ਕਰੋ';

  @override
  String get signOutConfirmation => 'ਕੀ ਤੁਸੀਂ ਵਾਕਈ ਸਾਈਨ ਆਊਟ ਕਰਨਾ ਚਾਹੁੰਦੇ ਹੋ?';

  @override
  String get broadcaster => 'ਬ੍ਰੌਡਕਾਸਟਰ';

  @override
  String get moderators => 'ਮੌਡਰੇਟਰ';

  @override
  String get viewers => 'ਦਰਸ਼ਕ';

  @override
  String get communityVips => 'ਕਮਿਊਨਿਟੀ VIPs';

  @override
  String get searchViewers => 'ਦਰਸ਼ਕ ਖੋਜੋ';

  @override
  String get reconnecting => 'ਮੁੜ-ਕਨੈਕਟ ਕੀਤਾ ਜਾ ਰਿਹਾ ਹੈ...';

  @override
  String get twitchBadges => 'Twitch ਬੈਜ';

  @override
  String get selectAll => 'ਸਭ ਚੁਣੋ';

  @override
  String get quickLinks => 'ਤੁਰੰਤ ਲਿੰਕ';

  @override
  String get swipeToDeleteQuickLinks =>
      'ਤੁਰੰਤ ਲਿੰਕ ਮਿਟਾਉਣ ਲਈ ਖੱਬੇ ਜਾਂ ਸੱਜੇ ਸਵਾਈਪ ਕਰੋ';

  @override
  String get quickLinksLabelHint => 'ਲੇਬਲ';

  @override
  String get invalidUrlErrorText => 'ਇਹ ਕੋਈ ਵੈਧ URL ਨਹੀਂ ਲੱਗਦਾ';

  @override
  String get duplicateUrlErrorText => 'ਇਹ ਲਿੰਕ ਪਹਿਲਾਂ ਹੀ ਮੌਜੂਦ ਹੈ';

  @override
  String get or => 'ਜਾਂ';

  @override
  String get clearCookies => 'ਕੂਕੀਜ਼ ਸਾਫ਼ ਕਰੋ';

  @override
  String get disabled => 'ਬੰਦ';

  @override
  String get twitchActivityFeed => 'Twitch ਗਤੀਵਿਧੀ ਫੀਡ';

  @override
  String get signInToEnable =>
      'ਇਸਨੂੰ ਚਾਲੂ ਕਰਨ ਲਈ ਤੁਹਾਡਾ ਸਾਈਨ ਇਨ ਹੋਣਾ ਜ਼ਰੂਰੀ ਹੈ';

  @override
  String get customUrl => 'ਕਸਟਮ URL';

  @override
  String get preview => 'ਪੂਰਵਦਰਸ਼ਨ';

  @override
  String get audioSources => 'ਆਡੀਓ ਸਰੋਤ';

  @override
  String get enableOffStreamSwitchTitle =>
      'ਆਫ਼-ਸਟ੍ਰੀਮ ਚਾਲੂ ਕਰੋ (ਵੱਧ ਬੈਟਰੀ ਵਰਤਦਾ ਹੈ)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'ਜਦੋਂ ਤੁਸੀਂ ਆਫ਼ਲਾਈਨ ਹੋਵੋਗੇ ਤਾਂ ਵੀ ਆਡੀਓ ਚੱਲੇਗਾ';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'ਆਡੀਓ ਸਿਰਫ਼ ਉਦੋਂ ਚੱਲੇਗਾ ਜਦੋਂ ਤੁਸੀਂ ਲਾਈਵ ਹੋਵੋਗੇ';

  @override
  String get iosOggWarningTitle => 'ਹੇ! ਸੁਣੋ!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS *.ogg ਮੀਡੀਆ ਫ਼ਾਈਲਾਂ ਦਾ ਸਮਰਥਨ ਨਹੀਂ ਕਰਦਾ, ਜੋ ਕਿ Streamlabs \'ਤੇ ਡਿਫੌਲਟ ਫ਼ਾਈਲਾਂ ਹੁੰਦੀਆਂ ਹਨ। ਯਕੀਨੀ ਬਣਾਓ ਕਿ ਤੁਹਾਡੇ ਆਡੀਓ ਸਰੋਤ ਕਿਸੇ ਹੋਰ ਫਾਰਮੈਟ ਦੀ ਵਰਤੋਂ ਕਰਦੇ ਹਨ, ਨਹੀਂ ਤਾਂ ਉਹ ਨਹੀਂ ਚੱਲਣਗੇ।';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'ਆਪਣੀ ਗਤੀਵਿਧੀ ਫੀਡ ਨੂੰ ਕਸਟਮਾਈਜ਼ ਕਰੋ';

  @override
  String get audioSourcesSubtitle => 'ਅਲਰਟ ਆਵਾਜ਼ਾਂ ਲਈ ਵੈੱਬ ਸਰੋਤ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get quickLinksSubtitle =>
      'ਆਮ ਵਰਤੇ ਜਾਣ ਵਾਲੇ ਟੂਲਾਂ ਲਈ ਸ਼ਾਰਟਕੱਟ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get chatHistory => 'ਚੈਟ ਇਤਿਹਾਸ';

  @override
  String get chatHistorySubtitle => 'ਚੈਟ ਦੀ ਦਿੱਖ ਬਦਲੋ';

  @override
  String get textToSpeechSubtitle => 'ਟੈਕਸਟ ਟੂ ਸਪੀਚ ਸੈਟਿੰਗਾਂ ਬਦਲੋ';

  @override
  String get events => 'ਈਵੈਂਟ';

  @override
  String get eventsSubtitle => 'Twitch ਈਵੈਂਟ ਕੌਂਫਿਗਰ ਕਰੋ';

  @override
  String get thirdPartyServices => 'ਥਰਡ-ਪਾਰਟੀ ਸੇਵਾਵਾਂ';

  @override
  String get thirdPartyServicesSubtitle => 'ਕਿਸੇ ਥਰਡ-ਪਾਰਟੀ ਸੇਵਾ ਨਾਲ ਕਨੈਕਟ ਕਰੋ';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> ਤੁਹਾਨੂੰ ਫੌਲੋ ਕਰ ਰਿਹਾ ਹੈ';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> ਅਤੇ <b>$displayNameTwo</b> ਤੁਹਾਨੂੰ ਫੌਲੋ ਕਰ ਰਹੇ ਹਨ';
  }

  @override
  String followingEvent3(
    String displayName,
    String displayNameTwo,
    int numOthers,
  ) {
    final intl.NumberFormat numOthersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>, <b>$displayNameTwo</b> ਅਤੇ $numOthersString ਹੋਰ ਤੁਹਾਨੂੰ ਫੌਲੋ ਕਰ ਰਹੇ ਹਨ';
  }

  @override
  String unmuteUser(String displayName) {
    return '$displayName ਨੂੰ ਅਨਮਿਊਟ ਕਰੋ';
  }

  @override
  String muteUser(String displayName) {
    return '$displayName ਨੂੰ ਮਿਊਟ ਕਰੋ';
  }

  @override
  String timeoutUser(String displayName) {
    return '$displayName ਨੂੰ ਟਾਈਮ-ਆਊਟ ਕਰੋ';
  }

  @override
  String banUser(String displayName) {
    return '$displayName ਨੂੰ ਬੈਨ ਕਰੋ';
  }

  @override
  String unbanUser(String displayName) {
    return '$displayName ਨੂੰ ਅਨਬੈਨ ਕਰੋ';
  }

  @override
  String viewProfile(String displayName) {
    return '$displayName ਦੀ ਪ੍ਰੋਫਾਈਲ ਦੇਖੋ';
  }

  @override
  String get copyMessage => 'ਸੁਨੇਹਾ ਕਾਪੀ ਕਰੋ';

  @override
  String get deleteMessage => 'ਸੁਨੇਹਾ ਮਿਟਾਓ';

  @override
  String get longScrollNotification =>
      'ਤੁਸੀਂ ਕਾਫ਼ੀ ਦੂਰ ਤੱਕ ਸਕ੍ਰੌਲ ਕਰ ਰਹੇ ਹੋ, ਕੀ ਤੁਹਾਨੂੰ ਨਹੀਂ ਲੱਗਦਾ?';

  @override
  String get stfu => 'ਚੁੱਪ ਕਰੋ';

  @override
  String get globalEmotes => 'ਗਲੋਬਲ ਇਮੋਟਸ';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ਫੌਲੋਅਰ',
      one: '1 ਫੌਲੋਅਰ',
      zero: '0 ਫੌਲੋਅਰ',
    );
    return '$_temp0';
  }

  @override
  String viewerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ਦਰਸ਼ਕ',
      one: '1 ਦਰਸ਼ਕ',
      zero: '0 ਦਰਸ਼ਕ',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'ਸਤ ਸ੍ਰੀ ਅਕਾਲ! ਖੁਸ਼ੀ ਹੈ ਕਿ ਤੁਹਾਨੂੰ ਸਟ੍ਰੀਮ ਪੂਰਵਦਰਸ਼ਨ ਵਰਤਣਾ ਪਸੰਦ ਹੈ, ਪਰ ਧਿਆਨ ਰੱਖੋ ਕਿ ਇਹ ਬਹੁਤ ਬੈਟਰੀ ਵਰਤਦਾ ਹੈ। ਇਸ ਤੋਂ ਬਿਨਾਂ ਚੈਟ ਪੜ੍ਹਨ ਨਾਲ ਤੁਹਾਡੀ ਬੈਟਰੀ ਦੀ ਉਮਰ ਵਧੇਗੀ।';

  @override
  String get okay => 'ਠੀਕ ਹੈ';

  @override
  String get streamPreviewLoading =>
      'ਲੋਡ ਹੋ ਰਿਹਾ ਹੈ (ਜਾਂ ਸਟ੍ਰੀਮ ਆਫ਼ਲਾਈਨ ਹੈ)...';

  @override
  String get copiedToClipboard => 'ਕਲਿੱਪਬੋਰਡ \'ਤੇ ਕਾਪੀ ਕੀਤਾ ਗਿਆ';

  @override
  String get audioSourcesRequirePermissions =>
      'ਆਡੀਓ ਸਰੋਤਾਂ ਲਈ ਇਜਾਜ਼ਤਾਂ ਦੀ ਲੋੜ ਹੈ';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'ਆਡੀਓ ਸਰੋਤਾਂ ਦੀ ਵਰਤੋਂ ਕਰਨ ਲਈ RealtimeChat ਨੂੰ ਹੋਰ ਐਪਾਂ ਦੇ ਉੱਪਰ ਦਿਖਾਈ ਦੇਣ ਦੀ ਇਜਾਜ਼ਤ ਦਿਓ।';

  @override
  String get audioSourcesRemoveButton => 'ਆਡੀਓ ਸਰੋਤ ਹਟਾਓ';

  @override
  String get audioSourcesOpenSettingsButton => 'ਸੈਟਿੰਗਾਂ ਖੋਲ੍ਹੋ';

  @override
  String get flashOn => 'ਫਲੈਸ਼ ਚਾਲੂ';

  @override
  String get flashOff => 'ਫਲੈਸ਼ ਬੰਦ';

  @override
  String get durationOneSecond => '1 ਸਕਿੰਟ';

  @override
  String get durationOneMinute => '1 ਮਿੰਟ';

  @override
  String get durationTenMinutes => '10 ਮਿੰਟ';

  @override
  String get durationOneHour => '1 ਘੰਟਾ';

  @override
  String get durationSixHours => '6 ਘੰਟੇ';

  @override
  String get durationOneDay => '1 ਦਿਨ';

  @override
  String get durationTwoDays => '2 ਦਿਨ';

  @override
  String get durationOneWeek => '1 ਹਫ਼ਤਾ';

  @override
  String get durationTwoWeeks => '2 ਹਫ਼ਤੇ';

  @override
  String get durationOneSecondTimeoutPrompt => '1 ਸਕਿੰਟ ਲਈ ਟਾਈਮ-ਆਊਟ ਕਰੋ';

  @override
  String get durationOneMinuteTimeoutPrompt => '1 ਮਿੰਟ ਲਈ ਟਾਈਮ-ਆਊਟ ਕਰੋ';

  @override
  String get durationTenMinutesTimeoutPrompt => '10 ਮਿੰਟ ਲਈ ਟਾਈਮ-ਆਊਟ ਕਰੋ';

  @override
  String get durationOneHourTimeoutPrompt => '1 ਘੰਟੇ ਲਈ ਟਾਈਮ-ਆਊਟ ਕਰੋ';

  @override
  String get durationSixHoursTimeoutPrompt => '6 ਘੰਟਿਆਂ ਲਈ ਟਾਈਮ-ਆਊਟ ਕਰੋ';

  @override
  String get durationOneDayTimeoutPrompt => '1 ਦਿਨ ਲਈ ਟਾਈਮ-ਆਊਟ ਕਰੋ';

  @override
  String get durationTwoDaysTimeoutPrompt => '2 ਦਿਨਾਂ ਲਈ ਟਾਈਮ-ਆਊਟ ਕਰੋ';

  @override
  String get durationOneWeekTimeoutPrompt => '1 ਹਫ਼ਤੇ ਲਈ ਟਾਈਮ-ਆਊਟ ਕਰੋ';

  @override
  String get durationTwoWeeksTimeoutPrompt => '2 ਹਫ਼ਤਿਆਂ ਲਈ ਟਾਈਮ-ਆਊਟ ਕਰੋ';

  @override
  String get errorFetchingViewerList =>
      'ਅਸੀਂ ਇਸ ਚੈਨਲ ਲਈ ਦਰਸ਼ਕਾਂ ਦੀ ਸੂਚੀ ਪ੍ਰਾਪਤ ਨਹੀਂ ਕਰ ਸਕੇ';

  @override
  String get eventsTitle => 'ਈਵੈਂਟ';

  @override
  String get followEventConfigTitle => 'ਫੌਲੋ ਈਵੈਂਟ';

  @override
  String get customizeYourFollowEvent => 'ਆਪਣੇ ਫੌਲੋ ਈਵੈਂਟ ਨੂੰ ਕਸਟਮਾਈਜ਼ ਕਰੋ';

  @override
  String get subscribeEventConfigTitle => 'ਸਬਸਕ੍ਰਾਈਬ ਈਵੈਂਟ';

  @override
  String get customizeYourSubscriptionEvent =>
      'ਆਪਣੇ ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਈਵੈਂਟ ਨੂੰ ਕਸਟਮਾਈਜ਼ ਕਰੋ';

  @override
  String get cheerEventConfigTitle => 'ਚੀਅਰ ਈਵੈਂਟ';

  @override
  String get customizeYourCheerEvent => 'ਆਪਣੇ ਚੀਅਰ ਈਵੈਂਟ ਨੂੰ ਕਸਟਮਾਈਜ਼ ਕਰੋ';

  @override
  String get raidEventConfigTitle => 'ਰੇਡ ਈਵੈਂਟ';

  @override
  String get customizeYourRaidEvent => 'ਆਪਣੇ ਰੇਡ ਈਵੈਂਟ ਨੂੰ ਕਸਟਮਾਈਜ਼ ਕਰੋ';

  @override
  String get hostEventConfigTitle => 'ਹੋਸਟ ਈਵੈਂਟ';

  @override
  String get customizeYourHostEvent => 'ਆਪਣੇ ਹੋਸਟ ਈਵੈਂਟ ਨੂੰ ਕਸਟਮਾਈਜ਼ ਕਰੋ';

  @override
  String get hypetrainEventConfigTitle => 'ਹਾਈਪ ਟ੍ਰੇਨ ਈਵੈਂਟ';

  @override
  String get customizeYourHypetrainEvent =>
      'ਆਪਣੇ ਹਾਈਪ ਟ੍ਰੇਨ ਈਵੈਂਟ ਨੂੰ ਕਸਟਮਾਈਜ਼ ਕਰੋ';

  @override
  String get pollEventConfigTitle => 'ਪੋਲ ਈਵੈਂਟ';

  @override
  String get customizeYourPollEvent => 'ਆਪਣੇ ਪੋਲ ਈਵੈਂਟ ਨੂੰ ਕਸਟਮਾਈਜ਼ ਕਰੋ';

  @override
  String get predictionEventConfigTitle => 'ਭਵਿੱਖਬਾਣੀ ਈਵੈਂਟ';

  @override
  String get customizeYourPredictionEvent =>
      'ਆਪਣੇ ਭਵਿੱਖਬਾਣੀ ਈਵੈਂਟ ਨੂੰ ਕਸਟਮਾਈਜ਼ ਕਰੋ';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'ਚੈਨਲ ਪੁਆਇੰਟ ਰੀਡੈਂਪਸ਼ਨ ਈਵੈਂਟ';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'ਆਪਣੇ ਚੈਨਲ ਪੁਆਇੰਟ ਰੀਡੈਂਪਸ਼ਨ ਈਵੈਂਟ ਨੂੰ ਕਸਟਮਾਈਜ਼ ਕਰੋ';

  @override
  String get outgoingRaidEventConfigTitle => 'ਆਊਟਗੋਇੰਗ ਰੇਡ ਈਵੈਂਟ';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'ਆਪਣੇ ਆਊਟਗੋਇੰਗ ਰੇਡ ਈਵੈਂਟ ਨੂੰ ਕਸਟਮਾਈਜ਼ ਕਰੋ';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> <b>$viewerCountString</b> ਦਰਸ਼ਕਾਂ ਨਾਲ ਰੇਡ ਕਰ ਰਿਹਾ ਹੈ!';
  }

  @override
  String get shoutout => 'ਸ਼ਾਊਟਆਊਟ';

  @override
  String raidingEventRaiding(String displayName) {
    return '<b>$displayName</b> \'ਤੇ ਰੇਡ ਕੀਤੀ ਜਾ ਰਹੀ ਹੈ...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString ਸਕਿੰਟ';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> ਨੇ ਰੇਡ ਕੀਤੀ ਹੈ!';
  }

  @override
  String get raidingEventJoin => 'ਸ਼ਾਮਲ ਹੋਵੋ';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b> ਦੀ ਰੇਡ ਰੱਦ ਕਰ ਦਿੱਤੀ ਗਈ।';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> ਨੇ ਟੀਅਰ $tier \'ਤੇ ਸਬਸਕ੍ਰਾਈਬ ਕੀਤਾ ਹੈ!';
  }

  @override
  String subscriptionGiftEvent(
    String gifterUserName,
    int total,
    String tier,
    int cumulativeTotal,
  ) {
    final intl.NumberFormat totalNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat cumulativeTotalNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String cumulativeTotalString = cumulativeTotalNumberFormat.format(
      cumulativeTotal,
    );

    return '<b>$gifterUserName</b> ਨੇ $totalString ਟੀਅਰ $tier ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਤੋਹਫ਼ੇ ਵਜੋਂ ਦਿੱਤੇ ਹਨ, ਕੁੱਲ ਮਿਲਾ ਕੇ $cumulativeTotalString!';
  }

  @override
  String subscriptionMessageEvent(
    String subscriberUserName,
    int cumulativeMonths,
    String tier,
  ) {
    final intl.NumberFormat cumulativeMonthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString = cumulativeMonthsNumberFormat.format(
      cumulativeMonths,
    );

    return '<b>$subscriberUserName</b> ਨੇ ਟੀਅਰ $tier \'ਤੇ $cumulativeMonthsString ਮਹੀਨਿਆਂ ਲਈ ਸਬਸਕ੍ਰਾਈਬ ਕੀਤਾ ਹੈ!';
  }

  @override
  String subscriptionMessageMultiMonthEvent(
    String subscriberUserName,
    String tier,
    int durationMonths,
    int cumulativeMonths,
  ) {
    final intl.NumberFormat durationMonthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String durationMonthsString = durationMonthsNumberFormat.format(
      durationMonths,
    );
    final intl.NumberFormat cumulativeMonthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString = cumulativeMonthsNumberFormat.format(
      cumulativeMonths,
    );

    return '<b>$subscriberUserName</b> ਨੇ ਟੀਅਰ $tier \'ਤੇ $durationMonthsString ਮਹੀਨਿਆਂ ਲਈ ਪਹਿਲਾਂ ਹੀ ਸਬਸਕ੍ਰਾਈਬ ਕੀਤਾ ਹੈ, ਕੁੱਲ $cumulativeMonthsString ਮਹੀਨੇ!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> ਨੇ <b>$value $currency</b> ਟਿੱਪ ਦਿੱਤੀ।';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'ਅਣਪਛਾਤੇ ਨੇ <b>$value $currency</b> ਟਿੱਪ ਦਿੱਤੀ।';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ਨੇ StreamElements \'ਤੇ <b>$formattedAmount</b> ਟਿੱਪ ਦਿੱਤੀ।';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ਨੇ Streamlabs \'ਤੇ <b>$formattedAmount</b> ਟਿੱਪ ਦਿੱਤੀ।';
  }

  @override
  String channelPointRedemptionWithUserInput(
    String redeemerUsername,
    String rewardName,
    int rewardCost,
    String userInput,
  ) {
    final intl.NumberFormat rewardCostNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> ਨੇ <b>$rewardCostString</b> ਪੁਆਇੰਟਾਂ ਵਿੱਚ <b>$rewardName</b> ਰੀਡੀਮ ਕੀਤਾ। $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
    String redeemerUsername,
    String rewardName,
    int rewardCost,
  ) {
    final intl.NumberFormat rewardCostNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> ਨੇ <b>$rewardCostString</b> ਪੁਆਇੰਟਾਂ ਵਿੱਚ <b>$rewardName</b> ਰੀਡੀਮ ਕੀਤਾ।';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> ਨੇ <b>$bitsString</b> ਬਿੱਟਸ ਨਾਲ ਚੀਅਰ ਕੀਤਾ। $cheerMessage';
  }

  @override
  String get anonymous => 'ਅਣਪਛਾਤਾ';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> <b>$viewersString</b> ਦਰਸ਼ਕਾਂ ਨਾਲ ਹੋਸਟ ਕਰ ਰਿਹਾ ਹੈ।';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'ਹਾਈਪ ਟ੍ਰੇਨ ਲੈਵਲ <b>$level</b> ਜਾਰੀ ਹੈ! <b>$progressPercent%</b> ਪੂਰਾ ਹੋਇਆ!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'ਹਾਈਪ ਟ੍ਰੇਨ ਲੈਵਲ <b>$levelString</b> ਸਫਲ ਰਿਹਾ।';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'ਹਾਈਪ ਟ੍ਰੇਨ ਲੈਵਲ <b>$levelString</b> ਅਸਫਲ ਰਿਹਾ।';
  }

  @override
  String get sampleMessage =>
      'ਇਹ ਲਿਖਤ ਨੂੰ ਆਵਾਜ਼ ਵਿੱਚ ਬਦਲਣ ਲਈ ਇੱਕ ਨਮੂਨਾ ਸੁਨੇਹਾ ਹੈ।';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author ਨੇ ਕਿਹਾ: $text';
  }

  @override
  String get textToSpeechEnabled => 'ਟੈਕਸਟ ਟੂ ਸਪੀਚ ਚਾਲੂ ਕੀਤਾ ਗਿਆ';

  @override
  String get textToSpeechDisabled => 'ਟੈਕਸਟ ਟੂ ਸਪੀਚ ਬੰਦ ਕੀਤਾ ਗਿਆ';

  @override
  String get alertsEnabled => 'ਸਿਰਫ਼ ਅਲਰਟ';

  @override
  String get pinDuration => 'ਪਿੰਨ ਦੀ ਮਿਆਦ';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds ਸਕਿੰਟ',
      one: '1 ਸਕਿੰਟ',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes ਮਿੰਟ',
      one: '1 ਮਿੰਟ',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'ਈਵੈਂਟ ਚਾਲੂ ਕਰੋ';

  @override
  String get showEventInChatHistory => 'ਚੈਟ ਇਤਿਹਾਸ ਵਿੱਚ ਈਵੈਂਟ ਦਿਖਾਓ';

  @override
  String get enableShoutouts => 'ਸ਼ਾਊਟਆਊਟ ਚਾਲੂ ਕਰੋ';

  @override
  String get enableShoutoutsSubtitle =>
      'ਰੇਡ ਕਰਨ ਵਾਲੇ ਚੈਨਲ ਦਾ ਲਿੰਕ ਚੈਟ ਵਿੱਚ ਭੇਜੋ';

  @override
  String get raidConfigurationTitle => 'ਰੇਡ ਕੌਂਫਿਗਰੇਸ਼ਨ';

  @override
  String get cheerConfigurationTitle => 'ਚੀਅਰ ਕੌਂਫਿਗਰੇਸ਼ਨ';

  @override
  String get followConfigurationTitle => 'ਫੌਲੋ ਕੌਂਫਿਗਰੇਸ਼ਨ';

  @override
  String get outgoingRaidConfigurationTitle => 'ਆਊਟਗੋਇੰਗ ਰੇਡ ਕੌਂਫਿਗਰੇਸ਼ਨ';

  @override
  String get hostConfigurationTitle => 'ਹੋਸਟ ਕੌਂਫਿਗਰੇਸ਼ਨ';

  @override
  String get channelPointConfigurationTitle => 'ਚੈਨਲ ਪੁਆਇੰਟ ਕੌਂਫਿਗਰੇਸ਼ਨ';

  @override
  String get pollConfigurationTitle => 'ਪੋਲ ਕੌਂਫਿਗਰੇਸ਼ਨ';

  @override
  String get hypetrainConfigurationTitle => 'ਹਾਈਪ ਟ੍ਰੇਨ ਕੌਂਫਿਗਰੇਸ਼ਨ';

  @override
  String get subscriptionConfigurationTitle => 'ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਕੌਂਫਿਗਰੇਸ਼ਨ';

  @override
  String get predictionConfigurationTitle => 'ਭਵਿੱਖਬਾਣੀ ਕੌਂਫਿਗਰੇਸ਼ਨ';

  @override
  String get unfulfilledRewardsPinDuration => 'ਅਧੂਰੇ ਇਨਾਮਾਂ ਲਈ ਵਾਧੂ ਪਿੰਨ ਮਿਆਦ';

  @override
  String get pollPinDuration => 'ਨਤੀਜਾ ਅੰਤਿਮ ਹੋਣ ਤੋਂ ਬਾਅਦ ਪਿੰਨ ਦੀ ਮਿਆਦ';

  @override
  String get hypetrainPinDuration => 'ਹਾਈਪ ਟ੍ਰੇਨ ਖਤਮ ਹੋਣ ਤੋਂ ਬਾਅਦ ਪਿੰਨ ਦੀ ਮਿਆਦ';

  @override
  String get enableGiftedSubscriptions =>
      'ਵੱਖ-ਵੱਖ ਤੋਹਫ਼ੇ ਵਜੋਂ ਮਿਲੇ ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਚਾਲੂ ਕਰੋ';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'ਤੋਹਫ਼ੇ ਵਜੋਂ ਦਿੱਤਾ ਗਿਆ ਹਰੇਕ ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਦਿਖਾਓ';

  @override
  String get settingsBackupTitle => 'ਸੈਟਿੰਗਾਂ ਦਾ ਬੈਕਅੱਪ ਅਤੇ ਰੀਸਟੋਰ';

  @override
  String get cloudBackup => 'ਕਲਾਊਡ ਬੈਕਅੱਪ';

  @override
  String get lastBackupNever => 'ਆਖਰੀ ਬੈਕਅੱਪ: ਕਦੇ ਨਹੀਂ';

  @override
  String get backUp => 'ਬੈਕਅੱਪ ਲਓ';

  @override
  String get restore => 'ਰੀਸਟੋਰ ਕਰੋ';

  @override
  String get localBackup => 'ਲੋਕਲ ਬੈਕਅੱਪ';

  @override
  String get exportSettings => 'ਐਕਸਪੋਰਟ ਕਰੋ';

  @override
  String get importSettings => 'ਇੰਪੋਰਟ ਕਰੋ';

  @override
  String get showViewerAndFollowerCount =>
      'ਦਰਸ਼ਕਾਂ ਅਤੇ ਫੌਲੋਅਰਾਂ ਦੀ ਗਿਣਤੀ ਦਿਖਾਓ';

  @override
  String get screenOrientation => 'ਸਕ੍ਰੀਨ ਓਰੀਐਂਟੇਸ਼ਨ';

  @override
  String get appTheme => 'ਐਪ ਥੀਮ';

  @override
  String get systemDefault => 'ਸਿਸਟਮ';

  @override
  String get portrait => 'ਪੋਰਟਰੇਟ';

  @override
  String get landscape => 'ਲੈਂਡਸਕੇਪ';

  @override
  String get lightTheme => 'ਲਾਈਟ';

  @override
  String get darkTheme => 'ਡਾਰਕ';

  @override
  String get openSourceTitle => 'RealtimeChat ਓਪਨ ਸੋਰਸ ਹੈ';

  @override
  String get openSourceSubtitle => 'ਸਾਨੂੰ GitHub \'ਤੇ ਲੱਭੋ!';

  @override
  String get discordSubtitle => 'Muxable Discord ਵਿੱਚ ਸ਼ਾਮਲ ਹੋਵੋ!';

  @override
  String get earlyTestersThanks =>
      'ਬੱਗ ਰਿਪੋਰਟਾਂ ਭੇਜਣ ਵਾਲੇ ਸਾਰੇ ਸ਼ੁਰੂਆਤੀ ਟੈਸਟਰਾਂ ਦਾ ਧੰਨਵਾਦ!';

  @override
  String get discoModeEnabled => '🕺 ਡਿਸਕੋ ਮੋਡ ਚਾਲੂ ਹੋ ਗਿਆ! :D';

  @override
  String get discoModeDisabled => '🕺 ਡਿਸਕੋ ਮੋਡ ਬੰਦ ਹੋ ਗਿਆ D:';

  @override
  String get playSampleMessage => 'ਨਮੂਨਾ ਸੁਨੇਹਾ ਚਲਾਓ';

  @override
  String get textToSpeechRate => 'ਟੈਕਸਟ ਟੂ ਸਪੀਚ ਦੀ ਗਤੀ';

  @override
  String get textToSpeechPitch => 'ਟੈਕਸਟ ਟੂ ਸਪੀਚ ਦੀ ਪਿੱਚ';

  @override
  String get muteBots => 'ਬੌਟਸ ਲਈ ਟੈਕਸਟ ਟੂ ਸਪੀਚ ਮਿਊਟ ਕਰੋ';

  @override
  String get muteEmotes => 'ਟੈਕਸਟ ਟੂ ਸਪੀਚ ਵਿੱਚ ਸਾਰੇ ਇਮੋਟਸ ਮਿਊਟ ਕਰੋ';

  @override
  String get muteViewerNames => 'ਟੈਕਸਟ ਟੂ ਸਪੀਚ ਵਿੱਚ ਦਰਸ਼ਕਾਂ ਦੇ ਨਾਮ ਮਿਊਟ ਕਰੋ';

  @override
  String get subscribersOnly => 'ਸਿਰਫ਼ ਸਬਸਕ੍ਰਾਈਬਰ';

  @override
  String get fontSize => 'ਫ਼ੌਂਟ ਦਾ ਆਕਾਰ';

  @override
  String get usernameContrastBoost => 'ਯੂਜ਼ਰਨੇਮ ਕੰਟ੍ਰਾਸਟ ਬੂਸਟ';

  @override
  String get twitchBadgeSettings => 'Twitch ਬੈਜ ਸੈਟਿੰਗਾਂ';

  @override
  String get twitchBadgeSettingsSubtitle => 'ਕੰਟਰੋਲ ਕਰੋ ਕਿ ਕਿਹੜੇ ਬੈਜ ਦਿਖਾਈ ਦੇਣ';

  @override
  String get showDeletedMessages => 'ਮਿਟਾਏ ਗਏ ਸੁਨੇਹੇ ਦਿਖਾਓ';

  @override
  String get deletedMessagesGreyedOut =>
      'ਮਿਟਾਏ ਗਏ ਸੁਨੇਹੇ ਫਿੱਕੇ (ਗ੍ਰੇ) ਦਿਖਾਈ ਦੇਣਗੇ';

  @override
  String get deletedMessagesRemoved => 'ਮਿਟਾਏ ਗਏ ਸੁਨੇਹੇ ਹਟਾ ਦਿੱਤੇ ਜਾਣਗੇ';

  @override
  String get showLoginNames => 'ਲੌਗਇਨ ਨਾਮ ਦਿਖਾਓ';

  @override
  String get loginNamesShown =>
      'ਜੇਕਰ ਲੌਗਇਨ ਨਾਮ ਡਿਸਪਲੇ ਨਾਮ ਤੋਂ ਵੱਖਰੇ ਹਨ ਤਾਂ ਉਹ ਦਿਖਾਏ ਜਾਣਗੇ';

  @override
  String get loginNamesHidden => 'ਲੌਗਇਨ ਨਾਮ ਲੁਕਾਏ ਜਾਣਗੇ';

  @override
  String get compactMessages => 'ਸੁਨੇਹੇ ਸੰਖੇਪ ਕਰੋ';

  @override
  String get dontCompactMessages => 'ਸੁਨੇਹਿਆਂ ਨੂੰ ਸੰਖੇਪ ਨਾ ਕਰੋ';

  @override
  String get dontCompactMessagesSubtitle =>
      'ਸੁਨੇਹੇ ਬਿਨਾਂ ਕਿਸੇ ਬਦਲਾਅ ਦੇ ਦਿਖਾਏ ਜਾਂਦੇ ਹਨ';

  @override
  String get compactIndividualMessages => 'ਵੱਖ-ਵੱਖ ਸੁਨੇਹਿਆਂ ਨੂੰ ਸੰਖੇਪ ਕਰੋ';

  @override
  String get compactIndividualMessagesSubtitle =>
      'ਸੁਨੇਹਿਆਂ ਵਿੱਚ ਵਾਰ-ਵਾਰ ਆਉਣ ਵਾਲੀ ਲਿਖਤ ਨੂੰ ਛੋਟਾ ਕੀਤਾ ਜਾਂਦਾ ਹੈ';

  @override
  String get announcementPinDuration => 'ਘੋਸ਼ਣਾ ਪਿੰਨ ਦੀ ਮਿਆਦ';

  @override
  String get idleMessageAlertDuration => 'ਨਿਸ਼ਕਿਰਿਆ ਸੁਨੇਹਾ ਅਲਰਟ ਦੀ ਮਿਆਦ';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'ਜੇਕਰ ਇਸ ਸਮੇਂ ਦੌਰਾਨ ਕੋਈ ਸੁਨੇਹਾ ਨਹੀਂ ਆਉਂਦਾ ਅਤੇ ਫਿਰ ਕੋਈ ਨਵਾਂ ਸੁਨੇਹਾ ਆਉਂਦਾ ਹੈ, ਤਾਂ ਅਲਰਟ ਆਵਾਜ਼ ਵੱਜੇਗੀ।';

  @override
  String get realtimeCashSubtitle => 'ETH ਜਾਂ MATIC ਵਾਲਿਟ ਕਨੈਕਟ ਕਰੋ';

  @override
  String get walletAddress => 'ਵਾਲਿਟ ਪਤਾ';

  @override
  String get streamlabsSubtitle => 'ਆਪਣੇ Streamlabs ਡੋਨੇਸ਼ਨ ਦੇਖੋ';

  @override
  String get streamElementsSubtitle => 'ਆਪਣੇ StreamElements ਡੋਨੇਸ਼ਨ ਦੇਖੋ';

  @override
  String get thirdPartyAuthError =>
      'ਹਮਮ, ਇਹ ਕੰਮ ਨਹੀਂ ਕੀਤਾ। ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ, ਜਾਂ Discord \'ਤੇ ਪੁੱਛੋ?';

  @override
  String get companionAuthBrowserTooOld =>
      'ਤੁਹਾਡਾ ਬ੍ਰਾਊਜ਼ਰ ਸਿੱਧੇ ਸਾਈਨ ਇਨ ਕਰਨ ਲਈ ਬਹੁਤ ਪੁਰਾਣਾ ਹੈ। ਕਿਸੇ ਹੋਰ ਡਿਵਾਈਸ \'ਤੇ ਸਾਈਨ ਇਨ ਕਰਨ ਲਈ ਆਪਣੇ ਫ਼ੋਨ ਨਾਲ ਇਸ QR ਕੋਡ ਨੂੰ ਸਕੈਨ ਕਰੋ।';

  @override
  String get companionAuthScanQrCode =>
      'ਕਿਸੇ ਹੋਰ ਡਿਵਾਈਸ \'ਤੇ ਸਾਈਨ ਇਨ ਕਰਨ ਲਈ ਆਪਣੇ ਫ਼ੋਨ ਨਾਲ ਇਸ QR ਕੋਡ ਨੂੰ ਸਕੈਨ ਕਰੋ।';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> ਨੇ ਸਬਸਕ੍ਰਾਈਬ ਕੀਤਾ ਹੈ!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> ਨੇ $monthsString ਮਹੀਨਿਆਂ ਲਈ ਦੁਬਾਰਾ ਸਬਸਕ੍ਰਾਈਬ ਕੀਤਾ ਹੈ!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> ਨੇ $countString ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਤੋਹਫ਼ੇ ਵਜੋਂ ਦਿੱਤੇ ਹਨ!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> ਨੇ $amountString Kicks ਭੇਜੇ!';
  }

  @override
  String get signInWithKick => 'Kick ਨਾਲ ਸਾਈਨ ਇਨ ਕਰੋ';

  @override
  String get textToSpeechTooManyMessages =>
      'ਬਹੁਤ ਜ਼ਿਆਦਾ ਸੁਨੇਹੇ ਹਨ। ਟੈਕਸਟ ਟੂ ਸਪੀਚ ਬੰਦ ਕਰ ਦਿੱਤਾ ਗਿਆ ਹੈ';

  @override
  String get turnOffTextToSpeech => 'ਬੰਦ ਕਰੋ';

  @override
  String get addToChat => 'ਚੈਟ ਵਿੱਚ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get inChat => 'ਚੈਟ ਵਿੱਚ';

  @override
  String get removeFromChat => 'ਚੈਟ ਤੋਂ ਹਟਾਓ';

  @override
  String cantChatWithAccount(String provider) {
    return 'ਤੁਹਾਡਾ $provider ਖਾਤਾ ਇੱਥੇ ਚੈਟ ਨਹੀਂ ਕਰ ਸਕਦਾ';
  }

  @override
  String get cantChatWithAccounts => 'ਤੁਹਾਡੇ ਖਾਤੇ ਇੱਥੇ ਚੈਟ ਨਹੀਂ ਕਰ ਸਕਦੇ';

  @override
  String sendAMessageTo(String channel) {
    return '$channel ਨੂੰ ਸੁਨੇਹਾ ਭੇਜੋ...';
  }

  @override
  String replaceChannel(String channel) {
    return '$channel ਨੂੰ ਬਦਲੋ';
  }

  @override
  String get voicePacks => 'ਵੌਇਸ ਪੈਕ';

  @override
  String get voicePacksDescription =>
      'ਵੌਇਸ ਪੈਕ ਕੁਦਰਤੀ ਲੱਗਣ ਵਾਲੀਆਂ ਆਵਾਜ਼ਾਂ ਨਾਲ ਚੈਟ ਪੜ੍ਹਦੇ ਹਨ ਜੋ ਇੱਕ ਵਾਰ ਡਾਊਨਲੋਡ ਹੋਣ ਤੋਂ ਬਾਅਦ ਤੁਹਾਡੇ ਡਿਵਾਈਸ \'ਤੇ ਆਫ਼ਲਾਈਨ ਚੱਲਦੇ ਹਨ। ਇਹ ਆਵਾਜ਼ਾਂ ਕਿਸੇ ਵਿਅਕਤੀ ਵੱਲੋਂ ਰਿਕਾਰਡ ਨਹੀਂ ਕੀਤੀਆਂ ਗਈਆਂ, ਸਗੋਂ AI ਦੁਆਰਾ ਮਸ਼ੀਨ ਨਾਲ ਤਿਆਰ ਕੀਤੀਆਂ ਗਈਆਂ ਹਨ।';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices ਆਵਾਜ਼ਾਂ',
      one: '1 ਆਵਾਜ਼',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ਭਾਸ਼ਾਵਾਂ',
      one: '1 ਭਾਸ਼ਾ',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'ਇਸ ਮਾਡਲ ਦਾ ਲਾਇਸੈਂਸ (OpenRAIL-M) ਨੁਕਸਾਨਦੇਹ ਵਰਤੋਂ, ਜਿਵੇਂ ਕਿ ਲੋਕਾਂ ਦੀ ਨਕਲ ਕਰਨਾ ਜਾਂ ਗਲਤ ਜਾਣਕਾਰੀ ਫੈਲਾਉਣਾ, ਦੀ ਮਨਾਹੀ ਕਰਦਾ ਹੈ ਅਤੇ ਇਹ ਪਾਬੰਦੀਆਂ ਤੁਹਾਡੇ \'ਤੇ ਵੀ ਲਾਗੂ ਹੁੰਦੀਆਂ ਹਨ।';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'ਕੀ $pack ਨੂੰ ਮਿਟਾਉਣਾ ਹੈ? ਇਸ ਨਾਲ $size ਥਾਂ ਖਾਲੀ ਹੋਵੇਗੀ।';
  }

  @override
  String get voicePackDownload => 'ਡਾਊਨਲੋਡ ਕਰੋ';

  @override
  String get voicePackUpdate => 'ਅੱਪਡੇਟ ਕਰੋ';

  @override
  String get voicePackWaitingForWifi => 'Wi-Fi ਦੀ ਉਡੀਕ ਕੀਤੀ ਜਾ ਰਹੀ ਹੈ';

  @override
  String get voicePackUseMobileData => 'ਮੋਬਾਈਲ ਡਾਟਾ ਵਰਤੋ';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'ਡਾਊਨਲੋਡ ਹੋ ਰਿਹਾ ਹੈ: $total ਵਿੱਚੋਂ $downloaded';
  }

  @override
  String get voicePackInstalling => 'ਇੰਸਟੌਲ ਹੋ ਰਿਹਾ ਹੈ';

  @override
  String voicePackInstallFailed(String pack) {
    return '$pack ਇੰਸਟੌਲ ਨਹੀਂ ਹੋ ਸਕਿਆ। ਆਪਣਾ ਕਨੈਕਸ਼ਨ ਚੈੱਕ ਕਰੋ ਅਤੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';
  }

  @override
  String get voices => 'ਆਵਾਜ਼ਾਂ';

  @override
  String get perViewerVoice => 'ਹਰ ਦਰਸ਼ਕ ਲਈ ਵੱਖਰੀ ਆਵਾਜ਼';

  @override
  String get perViewerVoiceSubtitle =>
      'ਹਰੇਕ ਦਰਸ਼ਕ ਨੂੰ ਆਪਣੀ ਵੱਖਰੀ ਆਵਾਜ਼ ਮਿਲਦੀ ਹੈ। ਤੁਹਾਡੇ ਵੱਲੋਂ ਚੁਣੀ ਗਈ ਆਵਾਜ਼ ਅਲਰਟ ਪੜ੍ਹਦੀ ਹੈ, ਜਾਂ ਇਸ ਦੇ ਬੰਦ ਹੋਣ \'ਤੇ ਸਭ ਕੁਝ ਪੜ੍ਹਦੀ ਹੈ।';

  @override
  String get streamLanguage => 'ਸਟ੍ਰੀਮ ਦੀ ਭਾਸ਼ਾ';

  @override
  String get ttsEngineNeural => 'ਨਿਊਰਲ ਆਵਾਜ਼ (ਡਿਵਾਈਸ \'ਤੇ)';

  @override
  String get ttsEngineSystem => 'ਸਿਸਟਮ ਆਵਾਜ਼';

  @override
  String languageUnsupported(String language) {
    return 'ਤੁਹਾਡੇ ਵੌਇਸ ਪੈਕਾਂ ਵੱਲੋਂ $language ਸਮਰਥਿਤ ਨਹੀਂ ਹੈ; ਸਿਸਟਮ ਆਵਾਜ਼ ਵਰਤੀ ਜਾਵੇਗੀ';
  }

  @override
  String get neuralFallbackLowMemory =>
      'ਇਸ ਡਿਵਾਈਸ ਵਿੱਚ ਨਿਊਰਲ ਆਵਾਜ਼ਾਂ ਲਈ ਲੋੜੀਂਦੀ ਮੈਮੋਰੀ ਨਹੀਂ ਹੈ, ਇਸ ਲਈ ਚੈਟ ਸਿਸਟਮ ਆਵਾਜ਼ ਨਾਲ ਪੜ੍ਹੀ ਜਾਂਦੀ ਹੈ।';

  @override
  String get neuralFallbackLoadFailed =>
      'ਨਿਊਰਲ ਆਵਾਜ਼ ਲੋਡ ਨਹੀਂ ਹੋ ਸਕੀ, ਇਸ ਲਈ ਚੈਟ ਸਿਸਟਮ ਆਵਾਜ਼ ਨਾਲ ਪੜ੍ਹੀ ਜਾਂਦੀ ਹੈ।';

  @override
  String get accounts => 'ਖਾਤੇ';

  @override
  String get accountsSubtitle =>
      'ਜਿਸ ਵੀ ਪਲੇਟਫਾਰਮ \'ਤੇ ਤੁਸੀਂ ਸਟ੍ਰੀਮ ਕਰਦੇ ਹੋ, ਉਸ ਵਿੱਚ ਸਾਈਨ ਇਨ ਕਰੋ';

  @override
  String addProviderAccount(String provider) {
    return '$provider ਖਾਤਾ ਸ਼ਾਮਲ ਕਰੋ';
  }

  @override
  String signInWithProvider(String provider) {
    return '$provider ਨਾਲ ਸਾਈਨ ਇਨ ਕਰੋ';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'ਕੀ $provider \'ਤੇ $channel ਤੋਂ ਸਾਈਨ ਆਊਟ ਕਰਨਾ ਹੈ?';
  }

  @override
  String get signOutOfAll => 'ਸਾਰੇ ਖਾਤਿਆਂ ਤੋਂ ਸਾਈਨ ਆਊਟ ਕਰੋ';
}
