// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

  @override
  String get sendAMessage => 'ಸಂದೇಶವನ್ನು ಕಳುಹಿಸಿ...';

  @override
  String get writeSomething => 'ಏನಾದರೂ ಬರೆಯಿರಿ...';

  @override
  String get speakToTheCrowds => 'ಜನಸಮೂಹದೊಂದಿಗೆ ಮಾತನಾಡಿ...';

  @override
  String get shareYourThoughts => 'ನಿಮ್ಮ ಆಲೋಚನೆಗಳನ್ನು ಹಂಚಿಕೊಳ್ಳಿ...';

  @override
  String get saySomethingYouLittleBitch => 'ಏನಾದರೂ ಹೇಳು, ಪುಟ್ಟ ನಾಯಿಮರಿ...';

  @override
  String get search => 'ಹುಡುಕಿ';

  @override
  String get notSignedIn => 'ಸೈನ್ ಇನ್ ಆಗಿಲ್ಲ';

  @override
  String get searchChannels => 'ಹುಡುಕಿ';

  @override
  String get raidAChannel => 'ರೇಡ್';

  @override
  String get noMessagesEmptyState => 'ಇಲ್ಲಿ ತುಂಬಾ ನಿಶ್ಯಬ್ದವಾಗಿದೆ.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ಹೊಸ ಸಂದೇಶಗಳು',
      one: '1 ಹೊಸ ಸಂದೇಶ',
      zero: 'ಯಾವುದೇ ಹೊಸ ಸಂದೇಶಗಳಿಲ್ಲ',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Twitch ಮೂಲಕ ಸೈನ್ ಇನ್ ಮಾಡಿ';

  @override
  String get signInError =>
      'ಸೈನ್ ಇನ್ ಮಾಡುವಾಗ ದೋಷ ಸಂಭವಿಸಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get continueAsGuest => 'ಅತಿಥಿಯಾಗಿ ಮುಂದುವರಿಯಿರಿ';

  @override
  String get signInToSendMessages => 'ಸಂದೇಶಗಳನ್ನು ಕಳುಹಿಸಲು ಸೈನ್ ಇನ್ ಮಾಡಿ';

  @override
  String get currentViewers => 'ಪ್ರಸ್ತುತ ವೀಕ್ಷಕರು';

  @override
  String get textToSpeech => 'ಪಠ್ಯದಿಂದ ಧ್ವನಿ';

  @override
  String get streamPreview => 'ಸ್ಟ್ರೀಮ್ ಪೂರ್ವವೀಕ್ಷಣೆ';

  @override
  String get activityFeed => 'ಚಟುವಟಿಕೆ ಫೀಡ್';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString ಕ್ಕೆ ಸ್ಟ್ರೀಮ್ ಆನ್‌ಲೈನ್ ಆಗಿದೆ';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString ಕ್ಕೆ ಸ್ಟ್ರೀಮ್ ಆಫ್‌ಲೈನ್ ಆಗಿದೆ';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString ಕ್ಕೆ ಚಾಟ್ ತೆರವುಗೊಳಿಸಲಾಗಿದೆ';
  }

  @override
  String get configureQuickLinks => 'ತ್ವರಿತ ಲಿಂಕ್‌ಗಳನ್ನು ಕಾನ್ಫಿಗರ್ ಮಾಡಿ';

  @override
  String get disableRainMode => 'ರೇನ್ ಮೋಡ್ ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಿ';

  @override
  String get enableRainMode => 'ರೇನ್ ಮೋಡ್ ಸಕ್ರಿಯಗೊಳಿಸಿ';

  @override
  String get disableRainModeSubtitle => 'ಸಂವಹನವನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಲಾಗುತ್ತದೆ';

  @override
  String get enableRainModeSubtitle => 'ಸಂವಹನವನ್ನು ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗುತ್ತದೆ';

  @override
  String get refreshAudioSources => 'ಆಡಿಯೋ ಮೂಲಗಳನ್ನು ರಿಫ್ರೆಶ್ ಮಾಡಿ';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ಆಡಿಯೋ ಮೂಲಗಳನ್ನು ರಿಫ್ರೆಶ್ ಮಾಡಲಾಗಿದೆ',
      one: '1 ಆಡಿಯೋ ಮೂಲವನ್ನು ರಿಫ್ರೆಶ್ ಮಾಡಲಾಗಿದೆ',
      zero: 'ಯಾವುದೇ ಆಡಿಯೋ ಮೂಲಗಳನ್ನು ರಿಫ್ರೆಶ್ ಮಾಡಲಾಗಿಲ್ಲ',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು';

  @override
  String get signOut => 'ಸೈನ್ ಔಟ್';

  @override
  String get cancel => 'ರದ್ದುಮಾಡಿ';

  @override
  String get signOutConfirmation => 'ನೀವು ಖಚಿತವಾಗಿಯೂ ಸೈನ್ ಔಟ್ ಮಾಡಲು ಬಯಸುವಿರಾ?';

  @override
  String get broadcaster => 'ಪ್ರಸಾರಕರು';

  @override
  String get moderators => 'ಮಾಡರೇಟರ್‌ಗಳು';

  @override
  String get viewers => 'ವೀಕ್ಷಕರು';

  @override
  String get communityVips => 'ಸಮುದಾಯದ VIP ಗಳು';

  @override
  String get searchViewers => 'ವೀಕ್ಷಕರನ್ನು ಹುಡುಕಿ';

  @override
  String get reconnecting => 'ಮರುಸಂಪರ್ಕಿಸಲಾಗುತ್ತಿದೆ...';

  @override
  String get twitchBadges => 'Twitch ಬ್ಯಾಡ್ಜ್‌ಗಳು';

  @override
  String get selectAll => 'ಎಲ್ಲವನ್ನೂ ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get quickLinks => 'ತ್ವರಿತ ಲಿಂಕ್‌ಗಳು';

  @override
  String get swipeToDeleteQuickLinks =>
      'ತ್ವರಿತ ಲಿಂಕ್ ಅಳಿಸಲು ಎಡಕ್ಕೆ ಅಥವಾ ಬಲಕ್ಕೆ ಸ್ವೈಪ್ ಮಾಡಿ';

  @override
  String get quickLinksLabelHint => 'ಲೇಬಲ್';

  @override
  String get invalidUrlErrorText => 'ಇದು ಮಾನ್ಯವಾದ URL ನಂತೆ ಕಾಣುತ್ತಿಲ್ಲ';

  @override
  String get duplicateUrlErrorText => 'ಈ ಲಿಂಕ್ ಈಗಾಗಲೇ ಅಸ್ತಿತ್ವದಲ್ಲಿದೆ';

  @override
  String get or => 'ಅಥವಾ';

  @override
  String get clearCookies => 'ಕುಕೀಗಳನ್ನು ತೆರವುಗೊಳಿಸಿ';

  @override
  String get disabled => 'ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ';

  @override
  String get twitchActivityFeed => 'Twitch ಚಟುವಟಿಕೆ ಫೀಡ್';

  @override
  String get signInToEnable => 'ಇದನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಲು ನೀವು ಸೈನ್ ಇನ್ ಆಗಿರಬೇಕು';

  @override
  String get customUrl => 'ಕಸ್ಟಮ್ URL';

  @override
  String get preview => 'ಪೂರ್ವವೀಕ್ಷಣೆ';

  @override
  String get audioSources => 'ಆಡಿಯೋ ಮೂಲಗಳು';

  @override
  String get enableOffStreamSwitchTitle =>
      'ಆಫ್-ಸ್ಟ್ರೀಮ್ ಸಕ್ರಿಯಗೊಳಿಸಿ (ಹೆಚ್ಚು ಬ್ಯಾಟರಿ ಬಳಸುತ್ತದೆ)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'ನೀವು ಆಫ್‌ಲೈನ್‌ನಲ್ಲಿರುವಾಗಲೂ ಆಡಿಯೋ ಪ್ಲೇ ಆಗುತ್ತದೆ';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'ನೀವು ಲೈವ್ ಇದ್ದಾಗ ಮಾತ್ರ ಆಡಿಯೋ ಪ್ಲೇ ಆಗುತ್ತದೆ';

  @override
  String get iosOggWarningTitle => 'ಹೇಯ್! ಇಲ್ಲಿ ಕೇಳಿ!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS ನಲ್ಲಿ *.ogg ಮೀಡಿಯಾ ಫೈಲ್‌ಗಳಿಗೆ ಬೆಂಬಲವಿಲ್ಲ, ಅವು Streamlabs ನಲ್ಲಿ ಡೀಫಾಲ್ಟ್ ಫೈಲ್‌ಗಳಾಗಿವೆ. ನಿಮ್ಮ ಆಡಿಯೋ ಮೂಲಗಳು ಬೇರೆ ಫಾರ್ಮ್ಯಾಟ್ ಬಳಸುತ್ತಿರುವುದನ್ನು ಖಚಿತಪಡಿಸಿಕೊಳ್ಳಿ, ಇಲ್ಲದಿದ್ದರೆ ಅವು ಪ್ಲೇ ಆಗುವುದಿಲ್ಲ.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'ನಿಮ್ಮ ಚಟುವಟಿಕೆ ಫೀಡ್ ಅನ್ನು ಕಸ್ಟಮೈಸ್ ಮಾಡಿ';

  @override
  String get audioSourcesSubtitle => 'ಅಲರ್ಟ್ ಶಬ್ದಗಳಿಗಾಗಿ ವೆಬ್ ಮೂಲಗಳನ್ನು ಸೇರಿಸಿ';

  @override
  String get quickLinksSubtitle =>
      'ಸಾಮಾನ್ಯವಾಗಿ ಬಳಸುವ ಸಾಧನಗಳಿಗೆ ಶಾರ್ಟ್‌ಕಟ್‌ಗಳನ್ನು ಸೇರಿಸಿ';

  @override
  String get chatHistory => 'ಚಾಟ್ ಇತಿಹಾಸ';

  @override
  String get chatHistorySubtitle => 'ಚಾಟ್ ವಿನ್ಯಾಸವನ್ನು ಬದಲಾಯಿಸಿ';

  @override
  String get textToSpeechSubtitle => 'ಪಠ್ಯದಿಂದ ಧ್ವನಿ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಬದಲಾಯಿಸಿ';

  @override
  String get events => 'ಈವೆಂಟ್‌ಗಳು';

  @override
  String get eventsSubtitle => 'Twitch ಈವೆಂಟ್‌ಗಳನ್ನು ಕಾನ್ಫಿಗರ್ ಮಾಡಿ';

  @override
  String get thirdPartyServices => 'ಥರ್ಡ್-ಪಾರ್ಟಿ ಸೇವೆಗಳು';

  @override
  String get thirdPartyServicesSubtitle => 'ಥರ್ಡ್-ಪಾರ್ಟಿ ಸೇವೆಗೆ ಸಂಪರ್ಕಪಡಿಸಿ';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> ನಿಮ್ಮನ್ನು ಫಾಲೋ ಮಾಡುತ್ತಿದ್ದಾರೆ';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> ಮತ್ತು <b>$displayNameTwo</b> ನಿಮ್ಮನ್ನು ಫಾಲೋ ಮಾಡುತ್ತಿದ್ದಾರೆ';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b>, ಮತ್ತು ಇತರ $numOthersString ಜನರು ನಿಮ್ಮನ್ನು ಫಾಲೋ ಮಾಡುತ್ತಿದ್ದಾರೆ';
  }

  @override
  String unmuteUser(String displayName) {
    return '$displayName ಅವರ ಮ್ಯೂಟ್ ತೆಗೆದುಹಾಕಿ';
  }

  @override
  String muteUser(String displayName) {
    return '$displayName ಅವರನ್ನು ಮ್ಯೂಟ್ ಮಾಡಿ';
  }

  @override
  String timeoutUser(String displayName) {
    return '$displayName ಅವರನ್ನು ತಾತ್ಕಾಲಿಕವಾಗಿ ನಿರ್ಬಂಧಿಸಿ';
  }

  @override
  String banUser(String displayName) {
    return '$displayName ಅವರನ್ನು ನಿರ್ಬಂಧಿಸಿ';
  }

  @override
  String unbanUser(String displayName) {
    return '$displayName ಅವರ ನಿರ್ಬಂಧ ತೆಗೆದುಹಾಕಿ';
  }

  @override
  String viewProfile(String displayName) {
    return '$displayName ಅವರ ಪ್ರೊಫೈಲ್ ವೀಕ್ಷಿಸಿ';
  }

  @override
  String get copyMessage => 'ಸಂದೇಶವನ್ನು ಪ್ರತಿಮಾಡಿ';

  @override
  String get deleteMessage => 'ಸಂದೇಶವನ್ನು ಅಳಿಸಿ';

  @override
  String get longScrollNotification =>
      'ನೀವು ತುಂಬಾ ದೂರ ಸ್ಕ್ರಾಲ್ ಮಾಡುತ್ತಿದ್ದೀರಿ, ಅಲ್ಲವೇ?';

  @override
  String get stfu => 'ಬಾಯಿ ಮುಚ್ಚು';

  @override
  String get globalEmotes => 'ಗ್ಲೋಬಲ್ ಇಮೋಟ್‌ಗಳು';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ಫಾಲೋವರ್‌ಗಳು',
      one: '1 ಫಾಲೋವರ್',
      zero: '0 ಫಾಲೋವರ್‌ಗಳು',
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
      other: '$countString ವೀಕ್ಷಕರು',
      one: '1 ವೀಕ್ಷಕ',
      zero: '0 ವೀಕ್ಷಕರು',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'ನಮಸ್ಕಾರ! ನಿಮಗೆ ಸ್ಟ್ರೀಮ್ ಪೂರ್ವವೀಕ್ಷಣೆ ಇಷ್ಟವಾಗಿರುವುದಕ್ಕೆ ಸಂತೋಷ, ಆದರೆ ಇದು ಸಾಕಷ್ಟು ಬ್ಯಾಟರಿಯನ್ನು ಬಳಸುತ್ತದೆ ಎಂಬುದನ್ನು ಗಮನಿಸಿ. ಇದಿಲ್ಲದೆ ಚಾಟ್ ಓದುವುದರಿಂದ ನಿಮ್ಮ ಬ್ಯಾಟರಿ ಬಾಳಿಕೆ ಹೆಚ್ಚುತ್ತದೆ.';

  @override
  String get okay => 'ಸರಿ';

  @override
  String get streamPreviewLoading =>
      'ಲೋಡ್ ಆಗುತ್ತಿದೆ (ಅಥವಾ ಸ್ಟ್ರೀಮ್ ಆಫ್‌ಲೈನ್ ಆಗಿದೆ)...';

  @override
  String get copiedToClipboard => 'ಕ್ಲಿಪ್‌ಬೋರ್ಡ್‌ಗೆ ಪ್ರತಿಮಾಡಲಾಗಿದೆ';

  @override
  String get audioSourcesRequirePermissions =>
      'ಆಡಿಯೋ ಮೂಲಗಳಿಗೆ ಅನುಮತಿಗಳ ಅಗತ್ಯವಿದೆ';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'ಆಡಿಯೋ ಮೂಲಗಳನ್ನು ಬಳಸಲು ಇತರ ಆ್ಯಪ್‌ಗಳ ಮೇಲೆ ಪ್ರದರ್ಶಿಸಲು RealtimeChat ಗೆ ಅನುಮತಿ ನೀಡಿ.';

  @override
  String get audioSourcesRemoveButton => 'ಆಡಿಯೋ ಮೂಲಗಳನ್ನು ತೆಗೆದುಹಾಕಿ';

  @override
  String get audioSourcesOpenSettingsButton => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಿರಿ';

  @override
  String get flashOn => 'ಫ್ಲ್ಯಾಶ್ ಆನ್';

  @override
  String get flashOff => 'ಫ್ಲ್ಯಾಶ್ ಆಫ್';

  @override
  String get durationOneSecond => '1 ಸೆಕೆಂಡ್';

  @override
  String get durationOneMinute => '1 ನಿಮಿಷ';

  @override
  String get durationTenMinutes => '10 ನಿಮಿಷಗಳು';

  @override
  String get durationOneHour => '1 ಗಂಟೆ';

  @override
  String get durationSixHours => '6 ಗಂಟೆಗಳು';

  @override
  String get durationOneDay => '1 ದಿನ';

  @override
  String get durationTwoDays => '2 ದಿನಗಳು';

  @override
  String get durationOneWeek => '1 ವಾರ';

  @override
  String get durationTwoWeeks => '2 ವಾರಗಳು';

  @override
  String get durationOneSecondTimeoutPrompt =>
      '1 ಸೆಕೆಂಡ್ ತಾತ್ಕಾಲಿಕವಾಗಿ ನಿರ್ಬಂಧಿಸಿ';

  @override
  String get durationOneMinuteTimeoutPrompt =>
      '1 ನಿಮಿಷ ತಾತ್ಕಾಲಿಕವಾಗಿ ನಿರ್ಬಂಧಿಸಿ';

  @override
  String get durationTenMinutesTimeoutPrompt =>
      '10 ನಿಮಿಷಗಳ ಕಾಲ ತಾತ್ಕಾಲಿಕವಾಗಿ ನಿರ್ಬಂಧಿಸಿ';

  @override
  String get durationOneHourTimeoutPrompt => '1 ಗಂಟೆ ತಾತ್ಕಾಲಿಕವಾಗಿ ನಿರ್ಬಂಧಿಸಿ';

  @override
  String get durationSixHoursTimeoutPrompt =>
      '6 ಗಂಟೆಗಳ ಕಾಲ ತಾತ್ಕಾಲಿಕವಾಗಿ ನಿರ್ಬಂಧಿಸಿ';

  @override
  String get durationOneDayTimeoutPrompt => '1 ದಿನ ತಾತ್ಕಾಲಿಕವಾಗಿ ನಿರ್ಬಂಧಿಸಿ';

  @override
  String get durationTwoDaysTimeoutPrompt =>
      '2 ದಿನಗಳ ಕಾಲ ತಾತ್ಕಾಲಿಕವಾಗಿ ನಿರ್ಬಂಧಿಸಿ';

  @override
  String get durationOneWeekTimeoutPrompt => '1 ವಾರ ತಾತ್ಕಾಲಿಕವಾಗಿ ನಿರ್ಬಂಧಿಸಿ';

  @override
  String get durationTwoWeeksTimeoutPrompt =>
      '2 ವಾರಗಳ ಕಾಲ ತಾತ್ಕಾಲಿಕವಾಗಿ ನಿರ್ಬಂಧಿಸಿ';

  @override
  String get errorFetchingViewerList =>
      'ಈ ಚಾನಲ್‌ನ ವೀಕ್ಷಕರ ಪಟ್ಟಿಯನ್ನು ತರಲು ನಮಗೆ ಸಾಧ್ಯವಾಗಲಿಲ್ಲ';

  @override
  String get eventsTitle => 'ಈವೆಂಟ್‌ಗಳು';

  @override
  String get followEventConfigTitle => 'ಫಾಲೋ ಈವೆಂಟ್';

  @override
  String get customizeYourFollowEvent =>
      'ನಿಮ್ಮ ಫಾಲೋ ಈವೆಂಟ್ ಅನ್ನು ಕಸ್ಟಮೈಸ್ ಮಾಡಿ';

  @override
  String get subscribeEventConfigTitle => 'ಚಂದಾದಾರಿಕೆ ಈವೆಂಟ್';

  @override
  String get customizeYourSubscriptionEvent =>
      'ನಿಮ್ಮ ಚಂದಾದಾರಿಕೆ ಈವೆಂಟ್ ಅನ್ನು ಕಸ್ಟಮೈಸ್ ಮಾಡಿ';

  @override
  String get cheerEventConfigTitle => 'ಚಿಯರ್ ಈವೆಂಟ್';

  @override
  String get customizeYourCheerEvent =>
      'ನಿಮ್ಮ ಚಿಯರ್ ಈವೆಂಟ್ ಅನ್ನು ಕಸ್ಟಮೈಸ್ ಮಾಡಿ';

  @override
  String get raidEventConfigTitle => 'ರೇಡ್ ಈವೆಂಟ್';

  @override
  String get customizeYourRaidEvent => 'ನಿಮ್ಮ ರೇಡ್ ಈವೆಂಟ್ ಅನ್ನು ಕಸ್ಟಮೈಸ್ ಮಾಡಿ';

  @override
  String get hostEventConfigTitle => 'ಹೋಸ್ಟ್ ಈವೆಂಟ್';

  @override
  String get customizeYourHostEvent =>
      'ನಿಮ್ಮ ಹೋಸ್ಟ್ ಈವೆಂಟ್ ಅನ್ನು ಕಸ್ಟಮೈಸ್ ಮಾಡಿ';

  @override
  String get hypetrainEventConfigTitle => 'ಹೈಪ್ ಟ್ರೈನ್ ಈವೆಂಟ್';

  @override
  String get customizeYourHypetrainEvent =>
      'ನಿಮ್ಮ ಹೈಪ್ ಟ್ರೈನ್ ಈವೆಂಟ್ ಅನ್ನು ಕಸ್ಟಮೈಸ್ ಮಾಡಿ';

  @override
  String get pollEventConfigTitle => 'ಪೋಲ್ ಈವೆಂಟ್';

  @override
  String get customizeYourPollEvent => 'ನಿಮ್ಮ ಪೋಲ್ ಈವೆಂಟ್ ಅನ್ನು ಕಸ್ಟಮೈಸ್ ಮಾಡಿ';

  @override
  String get predictionEventConfigTitle => 'ಭವಿಷ್ಯವಾಣಿ ಈವೆಂಟ್';

  @override
  String get customizeYourPredictionEvent =>
      'ನಿಮ್ಮ ಭವಿಷ್ಯವಾಣಿ ಈವೆಂಟ್ ಅನ್ನು ಕಸ್ಟಮೈಸ್ ಮಾಡಿ';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'ಚಾನಲ್ ಪಾಯಿಂಟ್ ರಿಡೆಂಪ್ಶನ್ ಈವೆಂಟ್';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'ನಿಮ್ಮ ಚಾನಲ್ ಪಾಯಿಂಟ್ ರಿಡೆಂಪ್ಶನ್ ಈವೆಂಟ್ ಅನ್ನು ಕಸ್ಟಮೈಸ್ ಮಾಡಿ';

  @override
  String get outgoingRaidEventConfigTitle => 'ಹೊರಹೋಗುವ ರೇಡ್ ಈವೆಂಟ್';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'ನಿಮ್ಮ ಹೊರಹೋಗುವ ರೇಡ್ ಈವೆಂಟ್ ಅನ್ನು ಕಸ್ಟಮೈಸ್ ಮಾಡಿ';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> ಅವರು <b>$viewerCountString</b> ವೀಕ್ಷಕರೊಂದಿಗೆ ರೇಡ್ ಮಾಡುತ್ತಿದ್ದಾರೆ!';
  }

  @override
  String get shoutout => 'ಶೌಟ್‌ಔಟ್';

  @override
  String raidingEventRaiding(String displayName) {
    return '<b>$displayName</b> ಅವರನ್ನು ರೇಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString ಸೆ';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> ಅವರು ರೇಡ್ ಮಾಡಿದ್ದಾರೆ!';
  }

  @override
  String get raidingEventJoin => 'ಸೇರಿಕೊಳ್ಳಿ';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b> ಅವರ ರೇಡ್ ಅನ್ನು ರದ್ದುಗೊಳಿಸಲಾಗಿದೆ.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> ಅವರು ಟಿಯರ್ $tier ನಲ್ಲಿ ಚಂದಾದಾರರಾಗಿದ್ದಾರೆ!';
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

    return '<b>$gifterUserName</b> ಅವರು $totalString ಟಿಯರ್ $tier ಚಂದಾದಾರಿಕೆಗಳನ್ನು ಉಡುಗೊರೆಯಾಗಿ ನೀಡಿದ್ದಾರೆ, ಒಟ್ಟು $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> ಅವರು ಟಿಯರ್ $tier ನಲ್ಲಿ $cumulativeMonthsString ತಿಂಗಳುಗಳ ಕಾಲ ಚಂದಾದಾರರಾಗಿದ್ದಾರೆ!';
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

    return '<b>$subscriberUserName</b> ಅವರು ಟಿಯರ್ $tier ನಲ್ಲಿ ಮುಂಚಿತವಾಗಿ $durationMonthsString ತಿಂಗಳುಗಳ ಕಾಲ ಚಂದಾದಾರರಾಗಿದ್ದಾರೆ, ಒಟ್ಟು $cumulativeMonthsString ತಿಂಗಳುಗಳು!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> ಅವರು <b>$value $currency</b> ಟಿಪ್ ನೀಡಿದ್ದಾರೆ.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'ಅನಾಮಧೇಯರು <b>$value $currency</b> ಟಿಪ್ ನೀಡಿದ್ದಾರೆ.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ಅವರು StreamElements ನಲ್ಲಿ <b>$formattedAmount</b> ಟಿಪ್ ನೀಡಿದ್ದಾರೆ.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ಅವರು Streamlabs ನಲ್ಲಿ <b>$formattedAmount</b> ಟಿಪ್ ನೀಡಿದ್ದಾರೆ.';
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

    return '<b>$redeemerUsername</b> ಅವರು <b>$rewardCostString</b> ಪಾಯಿಂಟ್‌ಗಳಿಗೆ <b>$rewardName</b> ಅನ್ನು ರಿಡೀಮ್ ಮಾಡಿದ್ದಾರೆ. $userInput';
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

    return '<b>$redeemerUsername</b> ಅವರು <b>$rewardCostString</b> ಪಾಯಿಂಟ್‌ಗಳಿಗೆ <b>$rewardName</b> ಅನ್ನು ರಿಡೀಮ್ ಮಾಡಿದ್ದಾರೆ.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> ಅವರು <b>$bitsString</b> ಬಿಟ್‌ಗಳನ್ನು ಚಿಯರ್ ಮಾಡಿದ್ದಾರೆ. $cheerMessage';
  }

  @override
  String get anonymous => 'ಅನಾಮಧೇಯ';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> ಅವರು <b>$viewersString</b> ಜನರ ಗುಂಪಿನೊಂದಿಗೆ ಹೋಸ್ಟ್ ಮಾಡುತ್ತಿದ್ದಾರೆ.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'ಹೈಪ್ ಟ್ರೈನ್ ಲೆವೆಲ್ <b>$level</b> ಪ್ರಗತಿಯಲ್ಲಿದೆ! <b>$progressPercent%</b> ಪೂರ್ಣಗೊಂಡಿದೆ!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'ಹೈಪ್ ಟ್ರೈನ್ ಲೆವೆಲ್ <b>$levelString</b> ಯಶಸ್ವಿಯಾಗಿದೆ.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'ಹೈಪ್ ಟ್ರೈನ್ ಲೆವೆಲ್ <b>$levelString</b> ವಿಫಲವಾಗಿದೆ.';
  }

  @override
  String get sampleMessage =>
      'ಇದು ಪಠ್ಯವನ್ನು ಧ್ವನಿಗೆ ಪರಿವರ್ತಿಸುವ ಮಾದರಿ ಸಂದೇಶವಾಗಿದೆ.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author ಹೇಳಿದರು: $text';
  }

  @override
  String get textToSpeechEnabled => 'ಪಠ್ಯದಿಂದ ಧ್ವನಿ ಸಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ';

  @override
  String get textToSpeechDisabled => 'ಪಠ್ಯದಿಂದ ಧ್ವನಿ ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ';

  @override
  String get alertsEnabled => 'ಅಲರ್ಟ್‌ಗಳು ಮಾತ್ರ';

  @override
  String get pinDuration => 'ಪಿನ್ ಅವಧಿ';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds ಸೆಕೆಂಡ್‌ಗಳು',
      one: '1 ಸೆಕೆಂಡ್',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes ನಿಮಿಷಗಳು',
      one: '1 ನಿಮಿಷ',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'ಈವೆಂಟ್ ಸಕ್ರಿಯಗೊಳಿಸಿ';

  @override
  String get showEventInChatHistory => 'ಚಾಟ್ ಇತಿಹಾಸದಲ್ಲಿ ಈವೆಂಟ್ ತೋರಿಸಿ';

  @override
  String get enableShoutouts => 'ಶೌಟ್‌ಔಟ್‌ಗಳನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ';

  @override
  String get enableShoutoutsSubtitle =>
      'ರೇಡ್ ಮಾಡುವ ಚಾನಲ್‌ನ ಲಿಂಕ್ ಅನ್ನು ಚಾಟ್‌ಗೆ ಕಳುಹಿಸಿ';

  @override
  String get raidConfigurationTitle => 'ರೇಡ್ ಕಾನ್ಫಿಗರೇಶನ್';

  @override
  String get cheerConfigurationTitle => 'ಚಿಯರ್ ಕಾನ್ಫಿಗರೇಶನ್';

  @override
  String get followConfigurationTitle => 'ಫಾಲೋ ಕಾನ್ಫಿಗರೇಶನ್';

  @override
  String get outgoingRaidConfigurationTitle => 'ಹೊರಹೋಗುವ ರೇಡ್ ಕಾನ್ಫಿಗರೇಶನ್';

  @override
  String get hostConfigurationTitle => 'ಹೋಸ್ಟ್ ಕಾನ್ಫಿಗರೇಶನ್';

  @override
  String get channelPointConfigurationTitle => 'ಚಾನಲ್ ಪಾಯಿಂಟ್ ಕಾನ್ಫಿಗರೇಶನ್';

  @override
  String get pollConfigurationTitle => 'ಪೋಲ್ ಕಾನ್ಫಿಗರೇಶನ್';

  @override
  String get hypetrainConfigurationTitle => 'ಹೈಪ್ ಟ್ರೈನ್ ಕಾನ್ಫಿಗರೇಶನ್';

  @override
  String get subscriptionConfigurationTitle => 'ಚಂದಾದಾರಿಕೆ ಕಾನ್ಫಿಗರೇಶನ್';

  @override
  String get predictionConfigurationTitle => 'ಭವಿಷ್ಯವಾಣಿ ಕಾನ್ಫಿಗರೇಶನ್';

  @override
  String get unfulfilledRewardsPinDuration =>
      'ಪೂರೈಸದ ರಿವಾರ್ಡ್‌ಗಳಿಗಾಗಿ ಹೆಚ್ಚುವರಿ ಪಿನ್ ಅವಧಿ';

  @override
  String get pollPinDuration => 'ಫಲಿತಾಂಶ ಅಂತಿಮಗೊಂಡ ನಂತರ ಪಿನ್ ಅವಧಿ';

  @override
  String get hypetrainPinDuration => 'ಹೈಪ್ ಟ್ರೈನ್ ಮುಗಿದ ನಂತರ ಪಿನ್ ಅವಧಿ';

  @override
  String get enableGiftedSubscriptions =>
      'ವೈಯಕ್ತಿಕ ಉಡುಗೊರೆ ಚಂದಾದಾರಿಕೆಗಳನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'ಉಡುಗೊರೆಯಾಗಿ ನೀಡಲಾದ ಪ್ರತಿಯೊಂದು ಚಂದಾದಾರಿಕೆಯನ್ನು ತೋರಿಸಿ';

  @override
  String get settingsBackupTitle => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳ ಬ್ಯಾಕಪ್ ಮತ್ತು ಮರುಸ್ಥಾಪನೆ';

  @override
  String get cloudBackup => 'ಕ್ಲೌಡ್ ಬ್ಯಾಕಪ್';

  @override
  String get lastBackupNever => 'ಕೊನೆಯ ಬ್ಯಾಕಪ್: ಎಂದಿಗೂ ಇಲ್ಲ';

  @override
  String get backUp => 'ಬ್ಯಾಕಪ್ ಮಾಡಿ';

  @override
  String get restore => 'ಮರುಸ್ಥಾಪಿಸಿ';

  @override
  String get localBackup => 'ಸ್ಥಳೀಯ ಬ್ಯಾಕಪ್';

  @override
  String get exportSettings => 'ರಫ್ತು ಮಾಡಿ';

  @override
  String get importSettings => 'ಆಮದು ಮಾಡಿ';

  @override
  String get showViewerAndFollowerCount =>
      'ವೀಕ್ಷಕರು ಮತ್ತು ಫಾಲೋವರ್‌ಗಳ ಸಂಖ್ಯೆಯನ್ನು ತೋರಿಸಿ';

  @override
  String get screenOrientation => 'ಪರದೆಯ ಓರಿಯಂಟೇಶನ್';

  @override
  String get appTheme => 'ಆ್ಯಪ್ ಥೀಮ್';

  @override
  String get systemDefault => 'ಸಿಸ್ಟಮ್';

  @override
  String get portrait => 'ಪೋರ್ಟ್ರೇಟ್';

  @override
  String get landscape => 'ಲ್ಯಾಂಡ್‌ಸ್ಕೇಪ್';

  @override
  String get lightTheme => 'ಲೈಟ್';

  @override
  String get darkTheme => 'ಡಾರ್ಕ್';

  @override
  String get openSourceTitle => 'RealtimeChat ಒಂದು ಓಪನ್ ಸೋರ್ಸ್ ಆಗಿದೆ';

  @override
  String get openSourceSubtitle => 'GitHub ನಲ್ಲಿ ನಮ್ಮನ್ನು ಹುಡುಕಿ!';

  @override
  String get discordSubtitle => 'Muxable Discord ಗೆ ಸೇರಿಕೊಳ್ಳಿ!';

  @override
  String get earlyTestersThanks =>
      'ಬಗ್ ವರದಿಗಳನ್ನು ಕಳುಹಿಸಿದ ಎಲ್ಲಾ ಆರಂಭಿಕ ಪರೀಕ್ಷಕರಿಗೆ ಧನ್ಯವಾದಗಳು!';

  @override
  String get discoModeEnabled => '🕺 ಡಿಸ್ಕೋ ಮೋಡ್ ಸಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ! :D';

  @override
  String get discoModeDisabled => '🕺 ಡಿಸ್ಕೋ ಮೋಡ್ ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ D:';

  @override
  String get playSampleMessage => 'ಮಾದರಿ ಸಂದೇಶವನ್ನು ಪ್ಲೇ ಮಾಡಿ';

  @override
  String get textToSpeechRate => 'ಪಠ್ಯದಿಂದ ಧ್ವನಿ ವೇಗ';

  @override
  String get textToSpeechPitch => 'ಪಠ್ಯದಿಂದ ಧ್ವನಿ ಪಿಚ್';

  @override
  String get muteBots => 'ಬಾಟ್‌ಗಳಿಗಾಗಿ ಪಠ್ಯದಿಂದ ಧ್ವನಿಯನ್ನು ಮ್ಯೂಟ್ ಮಾಡಿ';

  @override
  String get muteEmotes => 'ಪಠ್ಯದಿಂದ ಧ್ವನಿಯಲ್ಲಿ ಎಲ್ಲಾ ಇಮೋಟ್‌ಗಳನ್ನು ಮ್ಯೂಟ್ ಮಾಡಿ';

  @override
  String get muteViewerNames =>
      'ಪಠ್ಯದಿಂದ ಧ್ವನಿಯಲ್ಲಿ ವೀಕ್ಷಕರ ಹೆಸರುಗಳನ್ನು ಮ್ಯೂಟ್ ಮಾಡಿ';

  @override
  String get subscribersOnly => 'ಚಂದಾದಾರರಿಗೆ ಮಾತ್ರ';

  @override
  String get fontSize => 'ಫಾಂಟ್ ಗಾತ್ರ';

  @override
  String get usernameContrastBoost => 'ಬಳಕೆದಾರರ ಹೆಸರಿನ ಕಾಂಟ್ರಾಸ್ಟ್ ಬೂಸ್ಟ್';

  @override
  String get twitchBadgeSettings => 'Twitch ಬ್ಯಾಡ್ಜ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳು';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'ಯಾವ ಬ್ಯಾಡ್ಜ್‌ಗಳು ಕಾಣಿಸಬೇಕು ಎಂಬುದನ್ನು ನಿಯಂತ್ರಿಸಿ';

  @override
  String get showDeletedMessages => 'ಅಳಿಸಿದ ಸಂದೇಶಗಳನ್ನು ತೋರಿಸಿ';

  @override
  String get deletedMessagesGreyedOut =>
      'ಅಳಿಸಿದ ಸಂದೇಶಗಳು ಬೂದು ಬಣ್ಣದಲ್ಲಿ ಕಾಣಿಸುತ್ತವೆ';

  @override
  String get deletedMessagesRemoved => 'ಅಳಿಸಿದ ಸಂದೇಶಗಳನ್ನು ತೆಗೆದುಹಾಕಲಾಗುತ್ತದೆ';

  @override
  String get showLoginNames => 'ಲಾಗಿನ್ ಹೆಸರುಗಳನ್ನು ತೋರಿಸಿ';

  @override
  String get loginNamesShown =>
      'ಲಾಗಿನ್ ಹೆಸರುಗಳು ಪ್ರದರ್ಶನ ಹೆಸರಿಗಿಂತ ಭಿನ್ನವಾಗಿದ್ದರೆ ಅವುಗಳನ್ನು ತೋರಿಸಲಾಗುತ್ತದೆ';

  @override
  String get loginNamesHidden => 'ಲಾಗಿನ್ ಹೆಸರುಗಳನ್ನು ಮರೆಮಾಡಲಾಗುತ್ತದೆ';

  @override
  String get compactMessages => 'ಸಂದೇಶಗಳನ್ನು ಸಂಕ್ಷಿಪ್ತಗೊಳಿಸಿ';

  @override
  String get dontCompactMessages => 'ಸಂದೇಶಗಳನ್ನು ಸಂಕ್ಷಿಪ್ತಗೊಳಿಸಬೇಡಿ';

  @override
  String get dontCompactMessagesSubtitle =>
      'ಸಂದೇಶಗಳನ್ನು ಯಾವುದೇ ಬದಲಾವಣೆಯಿಲ್ಲದೆ ತೋರಿಸಲಾಗುತ್ತದೆ';

  @override
  String get compactIndividualMessages =>
      'ವೈಯಕ್ತಿಕ ಸಂದೇಶಗಳನ್ನು ಸಂಕ್ಷಿಪ್ತಗೊಳಿಸಿ';

  @override
  String get compactIndividualMessagesSubtitle =>
      'ಸಂದೇಶಗಳಲ್ಲಿ ಪುನರಾವರ್ತಿತ ಪಠ್ಯವನ್ನು ಚಿಕ್ಕದಾಗಿಸಲಾಗುತ್ತದೆ';

  @override
  String get announcementPinDuration => 'ಪ್ರಕಟಣೆ ಪಿನ್ ಅವಧಿ';

  @override
  String get idleMessageAlertDuration => 'ನಿಷ್ಕ್ರಿಯ ಸಂದೇಶ ಅಲರ್ಟ್ ಅವಧಿ';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'ಇಷ್ಟು ಸಮಯದವರೆಗೆ ಯಾವುದೇ ಸಂದೇಶಗಳು ಬರದಿದ್ದು, ನಂತರ ಹೊಸ ಸಂದೇಶ ಬಂದರೆ ಅಲರ್ಟ್ ಶಬ್ದ ಪ್ಲೇ ಆಗುತ್ತದೆ.';

  @override
  String get realtimeCashSubtitle => 'ETH ಅಥವಾ MATIC ವಾಲೆಟ್ ಸಂಪರ್ಕಿಸಿ';

  @override
  String get walletAddress => 'ವಾಲೆಟ್ ವಿಳಾಸ';

  @override
  String get streamlabsSubtitle => 'ನಿಮ್ಮ Streamlabs ದೇಣಿಗೆಗಳನ್ನು ನೋಡಿ';

  @override
  String get streamElementsSubtitle => 'ನಿಮ್ಮ StreamElements ದೇಣಿಗೆಗಳನ್ನು ನೋಡಿ';

  @override
  String get thirdPartyAuthError =>
      'ಹ್ಮ್, ಅದು ಕೆಲಸ ಮಾಡಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ, ಅಥವಾ Discord ನಲ್ಲಿ ಕೇಳಿ?';

  @override
  String get companionAuthBrowserTooOld =>
      'ನೇರವಾಗಿ ಸೈನ್ ಇನ್ ಮಾಡುವುದನ್ನು ಬೆಂಬಲಿಸಲು ನಿಮ್ಮ ಬ್ರೌಸರ್ ತುಂಬಾ ಹಳೆಯದಾಗಿದೆ. ಇನ್ನೊಂದು ಸಾಧನದಲ್ಲಿ ಸೈನ್ ಇನ್ ಮಾಡಲು ನಿಮ್ಮ ಫೋನ್ ಮೂಲಕ ಈ QR ಕೋಡ್ ಅನ್ನು ಸ್ಕ್ಯಾನ್ ಮಾಡಿ.';

  @override
  String get companionAuthScanQrCode =>
      'ಇನ್ನೊಂದು ಸಾಧನದಲ್ಲಿ ಸೈನ್ ಇನ್ ಮಾಡಲು ನಿಮ್ಮ ಫೋನ್ ಮೂಲಕ ಈ QR ಕೋಡ್ ಅನ್ನು ಸ್ಕ್ಯಾನ್ ಮಾಡಿ.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> ಅವರು ಚಂದಾದಾರರಾಗಿದ್ದಾರೆ!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> ಅವರು $monthsString ತಿಂಗಳುಗಳ ಕಾಲ ಮರುಚಂದಾದಾರರಾಗಿದ್ದಾರೆ!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> ಅವರು $countString ಚಂದಾದಾರಿಕೆಗಳನ್ನು ಉಡುಗೊರೆಯಾಗಿ ನೀಡಿದ್ದಾರೆ!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> ಅವರು $amountString Kicks ಕಳುಹಿಸಿದ್ದಾರೆ!';
  }

  @override
  String get signInWithKick => 'Kick ಮೂಲಕ ಸೈನ್ ಇನ್ ಮಾಡಿ';

  @override
  String get textToSpeechTooManyMessages =>
      'ತುಂಬಾ ಸಂದೇಶಗಳಿವೆ. ಪಠ್ಯದಿಂದ ಧ್ವನಿ ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ';

  @override
  String get turnOffTextToSpeech => 'ಆಫ್ ಮಾಡಿ';

  @override
  String get addToChat => 'ಚಾಟ್‌ಗೆ ಸೇರಿಸಿ';

  @override
  String get inChat => 'ಚಾಟ್‌ನಲ್ಲಿ';

  @override
  String get removeFromChat => 'ಚಾಟ್‌ನಿಂದ ತೆಗೆದುಹಾಕಿ';

  @override
  String cantChatWithAccount(String provider) {
    return 'ನಿಮ್ಮ $provider ಖಾತೆಯು ಇಲ್ಲಿ ಚಾಟ್ ಮಾಡಲು ಸಾಧ್ಯವಿಲ್ಲ';
  }

  @override
  String get cantChatWithAccounts =>
      'ನಿಮ್ಮ ಖಾತೆಗಳು ಇಲ್ಲಿ ಚಾಟ್ ಮಾಡಲು ಸಾಧ್ಯವಿಲ್ಲ';

  @override
  String sendAMessageTo(String channel) {
    return '$channel ಗೆ ಸಂದೇಶ ಕಳುಹಿಸಿ...';
  }

  @override
  String replaceChannel(String channel) {
    return '$channel ಬದಲಾಯಿಸಿ';
  }

  @override
  String get voicePacks => 'ಧ್ವನಿ ಪ್ಯಾಕ್‌ಗಳು';

  @override
  String get voicePacksDescription =>
      'ಧ್ವನಿ ಪ್ಯಾಕ್‌ಗಳು ನಿಮ್ಮ ಸಾಧನದಲ್ಲಿ ಕಾರ್ಯನಿರ್ವಹಿಸುವ ನೈಸರ್ಗಿಕ ಧ್ವನಿಗಳೊಂದಿಗೆ ಚಾಟ್ ಅನ್ನು ಓದುತ್ತವೆ, ಒಮ್ಮೆ ಡೌನ್‌ಲೋಡ್ ಮಾಡಿದ ನಂತರ ಆಫ್‌ಲೈನ್‌ನಲ್ಲಿ ಕಾರ್ಯನಿರ್ವಹಿಸುತ್ತವೆ. ಈ ಧ್ವನಿಗಳನ್ನು AI ಮೂಲಕ ಯಂತ್ರದಿಂದ ರಚಿಸಲಾಗಿದೆ, ಯಾವುದೇ ವ್ಯಕ್ತಿಯಿಂದ ಧ್ವನಿಮುದ್ರಿಸಲಾಗಿಲ್ಲ.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices ಧ್ವನಿಗಳು',
      one: '1 ಧ್ವನಿ',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ಭಾಷೆಗಳು',
      one: '1 ಭಾಷೆ',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'ಈ ಮಾಡೆಲ್‌ನ ಪರವಾನಗಿಯು (OpenRAIL-M) ವ್ಯಕ್ತಿಗಳಂತೆ ನಟಿಸುವುದು ಅಥವಾ ತಪ್ಪು ಮಾಹಿತಿಯನ್ನು ಹರಡುವಂತಹ ಹಾನಿಕಾರಕ ಬಳಕೆಗಳನ್ನು ನಿಷೇಧಿಸುತ್ತದೆ ಮತ್ತು ಈ ನಿರ್ಬಂಧಗಳು ನಿಮಗೂ ಅನ್ವಯಿಸುತ್ತವೆ.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return '$pack ಅಳಿಸಬೇಕೆ? ಇದರಿಂದ $size ಜಾಗ ಮುಕ್ತವಾಗುತ್ತದೆ.';
  }

  @override
  String get voicePackDownload => 'ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ';

  @override
  String get voicePackUpdate => 'ಅಪ್‌ಡೇಟ್ ಮಾಡಿ';

  @override
  String get voicePackWaitingForWifi => 'Wi-Fi ಗಾಗಿ ಕಾಯಲಾಗುತ್ತಿದೆ';

  @override
  String get voicePackUseMobileData => 'ಮೊಬೈಲ್ ಡೇಟಾ ಬಳಸಿ';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'ಡೌನ್‌ಲೋಡ್ ಆಗುತ್ತಿದೆ: $total ರಲ್ಲಿ $downloaded';
  }

  @override
  String get voicePackInstalling => 'ಇನ್‌ಸ್ಟಾಲ್ ಆಗುತ್ತಿದೆ';

  @override
  String voicePackInstallFailed(String pack) {
    return '$pack ಇನ್‌ಸ್ಟಾಲ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ನಿಮ್ಮ ಸಂಪರ್ಕವನ್ನು ಪರಿಶೀಲಿಸಿ ಮತ್ತು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';
  }

  @override
  String get voices => 'ಧ್ವನಿಗಳು';

  @override
  String get perViewerVoice => 'ಪ್ರತಿ ವೀಕ್ಷಕರಿಗೆ ಪ್ರತ್ಯೇಕ ಧ್ವನಿ';

  @override
  String get perViewerVoiceSubtitle =>
      'ಪ್ರತಿಯೊಬ್ಬ ವೀಕ್ಷಕರು ತಮ್ಮದೇ ಆದ ಧ್ವನಿಯನ್ನು ಪಡೆಯುತ್ತಾರೆ. ನೀವು ಆಯ್ಕೆ ಮಾಡಿದ ಧ್ವನಿಯು ಅಲರ್ಟ್‌ಗಳನ್ನು ಓದುತ್ತದೆ, ಅಥವಾ ಇದು ಆಫ್ ಆಗಿರುವಾಗ ಎಲ್ಲವನ್ನೂ ಓದುತ್ತದೆ.';

  @override
  String get streamLanguage => 'ಸ್ಟ್ರೀಮ್ ಭಾಷೆ';

  @override
  String get ttsEngineNeural => 'ನ್ಯೂರಲ್ ಧ್ವನಿ (ಸಾಧನದಲ್ಲಿ)';

  @override
  String get ttsEngineSystem => 'ಸಿಸ್ಟಮ್ ಧ್ವನಿ';

  @override
  String languageUnsupported(String language) {
    return 'ನಿಮ್ಮ ಧ್ವನಿ ಪ್ಯಾಕ್‌ಗಳಿಂದ $language ಬೆಂಬಲಿತವಾಗಿಲ್ಲ; ಸಿಸ್ಟಮ್ ಧ್ವನಿಯನ್ನು ಬಳಸಲಾಗುತ್ತದೆ';
  }

  @override
  String get neuralFallbackLowMemory =>
      'ನ್ಯೂರಲ್ ಧ್ವನಿಗಳಿಗಾಗಿ ಈ ಸಾಧನದಲ್ಲಿ ಸಾಕಷ್ಟು ಮೆಮೊರಿ ಇಲ್ಲ, ಆದ್ದರಿಂದ ಚಾಟ್ ಅನ್ನು ಸಿಸ್ಟಮ್ ಧ್ವನಿಯೊಂದಿಗೆ ಓದಲಾಗುತ್ತದೆ.';

  @override
  String get neuralFallbackLoadFailed =>
      'ನ್ಯೂರಲ್ ಧ್ವನಿಯನ್ನು ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ, ಆದ್ದರಿಂದ ಚಾಟ್ ಅನ್ನು ಸಿಸ್ಟಮ್ ಧ್ವನಿಯೊಂದಿಗೆ ಓದಲಾಗುತ್ತದೆ.';

  @override
  String get accounts => 'ಖಾತೆಗಳು';

  @override
  String get accountsSubtitle =>
      'ನೀವು ಸ್ಟ್ರೀಮ್ ಮಾಡುವ ಪ್ರತಿಯೊಂದು ಪ್ಲಾಟ್‌ಫಾರ್ಮ್‌ಗೆ ಸೈನ್ ಇನ್ ಮಾಡಿ';

  @override
  String addProviderAccount(String provider) {
    return '$provider ಖಾತೆಯನ್ನು ಸೇರಿಸಿ';
  }

  @override
  String signInWithProvider(String provider) {
    return '$provider ಮೂಲಕ ಸೈನ್ ಇನ್ ಮಾಡಿ';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return '$provider ನಲ್ಲಿ $channel ನಿಂದ ಸೈನ್ ಔಟ್ ಮಾಡಬೇಕೆ?';
  }

  @override
  String get signOutOfAll => 'ಎಲ್ಲಾ ಖಾತೆಗಳಿಂದ ಸೈನ್ ಔಟ್ ಮಾಡಿ';
}
