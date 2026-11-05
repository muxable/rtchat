// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get sendAMessage => 'செய்தியை அனுப்பு...';

  @override
  String get writeSomething => 'ஏதாவது எழுதுங்கள்...';

  @override
  String get speakToTheCrowds => 'கூட்டத்தினரிடம் பேசுங்கள்...';

  @override
  String get shareYourThoughts => 'உங்கள் எண்ணங்களைப் பகிருங்கள்...';

  @override
  String get saySomethingYouLittleBitch => 'ஏதாவது சொல்லுடா சின்ன நாயே...';

  @override
  String get search => 'தேடு';

  @override
  String get notSignedIn => 'உள்நுழையவில்லை';

  @override
  String get searchChannels => 'தேடு';

  @override
  String get raidAChannel => 'ரெய்டு';

  @override
  String get noMessagesEmptyState => 'இங்கே மிகவும் அமைதியாக உள்ளது.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count புதிய செய்திகள்',
      one: '1 புதிய செய்தி',
      zero: 'புதிய செய்திகள் இல்லை',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Twitch மூலம் உள்நுழையவும்';

  @override
  String get signInError =>
      'உள்நுழையும்போது பிழை ஏற்பட்டது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get continueAsGuest => 'விருந்தினராகத் தொடரவும்';

  @override
  String get signInToSendMessages => 'செய்திகளை அனுப்ப உள்நுழையவும்';

  @override
  String get currentViewers => 'தற்போதைய பார்வையாளர்கள்';

  @override
  String get textToSpeech => 'உரையிலிருந்து பேச்சு';

  @override
  String get streamPreview => 'ஸ்ட்ரீம் முன்னோட்டம்';

  @override
  String get activityFeed => 'செயல்பாட்டு ஊட்டம்';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString மணிக்கு ஸ்ட்ரீம் ஆன்லைனில் வந்தது';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString மணிக்கு ஸ்ட்ரீம் ஆஃப்லைனானது';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString மணிக்கு அரட்டை அழிக்கப்பட்டது';
  }

  @override
  String get configureQuickLinks => 'விரைவு இணைப்புகளை உள்ளமை';

  @override
  String get disableRainMode => 'மழைப் பயன்முறையை முடக்கு';

  @override
  String get enableRainMode => 'மழைப் பயன்முறையை இயக்கு';

  @override
  String get disableRainModeSubtitle => 'தொடர்பாடல் இயக்கப்படும்';

  @override
  String get enableRainModeSubtitle => 'தொடர்பாடல் முடக்கப்படும்';

  @override
  String get refreshAudioSources => 'ஆடியோ ஆதாரங்களைப் புதுப்பி';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ஆடியோ ஆதாரங்கள் புதுப்பிக்கப்பட்டன',
      one: '1 ஆடியோ ஆதாரம் புதுப்பிக்கப்பட்டது',
      zero: 'ஆடியோ ஆதாரங்கள் எதுவும் புதுப்பிக்கப்படவில்லை',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get signOut => 'வெளியேறு';

  @override
  String get cancel => 'ரத்துசெய்';

  @override
  String get signOutConfirmation => 'நிச்சயமாக வெளியேற விரும்புகிறீர்களா?';

  @override
  String get broadcaster => 'ஒளிபரப்பாளர்';

  @override
  String get moderators => 'மதிப்பீட்டாளர்கள்';

  @override
  String get viewers => 'பார்வையாளர்கள்';

  @override
  String get communityVips => 'சமூக VIP-கள்';

  @override
  String get searchViewers => 'பார்வையாளர்களைத் தேடு';

  @override
  String get reconnecting => 'மீண்டும் இணைக்கிறது...';

  @override
  String get twitchBadges => 'Twitch பேட்ஜ்கள்';

  @override
  String get selectAll => 'அனைத்தையும் தேர்ந்தெடு';

  @override
  String get quickLinks => 'விரைவு இணைப்புகள்';

  @override
  String get swipeToDeleteQuickLinks =>
      'விரைவு இணைப்பை நீக்க இடது அல்லது வலதுபுறமாக ஸ்வைப் செய்யவும்';

  @override
  String get quickLinksLabelHint => 'லேபிள்';

  @override
  String get invalidUrlErrorText => 'இது சரியான URL ஆகத் தெரியவில்லை';

  @override
  String get duplicateUrlErrorText => 'இந்த இணைப்பு ஏற்கனவே உள்ளது';

  @override
  String get or => 'அல்லது';

  @override
  String get clearCookies => 'குக்கீகளை அழி';

  @override
  String get disabled => 'முடக்கப்பட்டது';

  @override
  String get twitchActivityFeed => 'Twitch செயல்பாட்டு ஊட்டம்';

  @override
  String get signInToEnable => 'இதை இயக்க நீங்கள் உள்நுழைந்திருக்க வேண்டும்';

  @override
  String get customUrl => 'தனிப்பயன் URL';

  @override
  String get preview => 'முன்னோட்டம்';

  @override
  String get audioSources => 'ஆடியோ ஆதாரங்கள்';

  @override
  String get enableOffStreamSwitchTitle =>
      'ஆஃப்-ஸ்ட்ரீமை இயக்கு (அதிக பேட்டரியைப் பயன்படுத்தும்)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'நீங்கள் ஆஃப்லைனில் இருக்கும்போதும் ஆடியோ ஒலிக்கும்';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'நீங்கள் நேரலையில் இருக்கும்போது மட்டுமே ஆடியோ ஒலிக்கும்';

  @override
  String get iosOggWarningTitle => 'ஏய்! இங்கே கவனியுங்கள்!';

  @override
  String get iosOggWarningSubtitle =>
      'Streamlabs இல் இயல்புநிலை கோப்புகளாக உள்ள *.ogg மீடியா கோப்புகளை iOS ஆதரிக்காது. உங்கள் ஆடியோ ஆதாரங்கள் வேறு வடிவத்தைப் பயன்படுத்துவதை உறுதிசெய்யவும், இல்லையெனில் அவை ஒலிக்காது.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle =>
      'உங்கள் செயல்பாட்டு ஊட்டத்தைத் தனிப்பயனாக்குங்கள்';

  @override
  String get audioSourcesSubtitle =>
      'விழிப்பூட்டல் ஒலிகளுக்கான இணைய ஆதாரங்களைச் சேர்க்கவும்';

  @override
  String get quickLinksSubtitle =>
      'அடிக்கடி பயன்படுத்தப்படும் கருவிகளுக்கு குறுக்குவழிகளைச் சேர்க்கவும்';

  @override
  String get chatHistory => 'அரட்டை வரலாறு';

  @override
  String get chatHistorySubtitle => 'அரட்டையின் தோற்றத்தை மாற்றவும்';

  @override
  String get textToSpeechSubtitle =>
      'உரையிலிருந்து பேச்சு அமைப்புகளை மாற்றவும்';

  @override
  String get events => 'நிகழ்வுகள்';

  @override
  String get eventsSubtitle => 'Twitch நிகழ்வுகளை உள்ளமைக்கவும்';

  @override
  String get thirdPartyServices => 'மூன்றாம் தரப்பு சேவைகள்';

  @override
  String get thirdPartyServicesSubtitle =>
      'மூன்றாம் தரப்பு சேவையுடன் இணைக்கவும்';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> உங்களைப் பின்தொடர்கிறார்';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> மற்றும் <b>$displayNameTwo</b> உங்களைப் பின்தொடர்கிறார்கள்';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> மற்றும் $numOthersString பேர் உங்களைப் பின்தொடர்கிறார்கள்';
  }

  @override
  String unmuteUser(String displayName) {
    return '$displayName இன் ஒலிமறைப்பை நீக்கு';
  }

  @override
  String muteUser(String displayName) {
    return '$displayName ஐ ஒலிமறை';
  }

  @override
  String timeoutUser(String displayName) {
    return '$displayName ஐத் தற்காலிகமாகத் தடைசெய்';
  }

  @override
  String banUser(String displayName) {
    return '$displayName ஐத் தடைசெய்';
  }

  @override
  String unbanUser(String displayName) {
    return '$displayName இன் தடையை நீக்கு';
  }

  @override
  String viewProfile(String displayName) {
    return '$displayName இன் சுயவிவரத்தைக் காட்டு';
  }

  @override
  String get copyMessage => 'செய்தியை நகலெடு';

  @override
  String get deleteMessage => 'செய்தியை நீக்கு';

  @override
  String get longScrollNotification =>
      'நீங்கள் வெகுதூரம் ஸ்க்ரோல் செய்கிறீர்கள், இல்லையா?';

  @override
  String get stfu => 'வாயை மூடு';

  @override
  String get globalEmotes => 'உலகளாவிய எமோட்கள்';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString பின்தொடர்பவர்கள்',
      one: '1 பின்தொடர்பவர்',
      zero: '0 பின்தொடர்பவர்கள்',
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
      other: '$countString பார்வையாளர்கள்',
      one: '1 பார்வையாளர்',
      zero: '0 பார்வையாளர்கள்',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'வணக்கம்! நீங்கள் ஸ்ட்ரீம் முன்னோட்டத்தைப் பயன்படுத்துவது மகிழ்ச்சி, ஆனால் இது அதிக பேட்டரியைப் பயன்படுத்துகிறது என்பதை நினைவில் கொள்ளுங்கள். இது இல்லாமல் அரட்டையைப் படிப்பது உங்கள் பேட்டரி ஆயுளை நீட்டிக்கும்.';

  @override
  String get okay => 'சரி';

  @override
  String get streamPreviewLoading =>
      'ஏற்றுகிறது (அல்லது ஸ்ட்ரீம் ஆஃப்லைனில் உள்ளது)...';

  @override
  String get copiedToClipboard => 'கிளிப்போர்டுக்கு நகலெடுக்கப்பட்டது';

  @override
  String get audioSourcesRequirePermissions =>
      'ஆடியோ ஆதாரங்களுக்கு அனுமதிகள் தேவை';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'ஆடியோ ஆதாரங்களைப் பயன்படுத்த பிற செயலிகளின் மேல் காண்பிக்க RealtimeChat-க்கு அனுமதி அளிக்கவும்.';

  @override
  String get audioSourcesRemoveButton => 'ஆடியோ ஆதாரங்களை அகற்று';

  @override
  String get audioSourcesOpenSettingsButton => 'அமைப்புகளைத் திற';

  @override
  String get flashOn => 'ஃபிளாஷ் ஆன்';

  @override
  String get flashOff => 'ஃபிளாஷ் ஆஃப்';

  @override
  String get durationOneSecond => '1 வினாடி';

  @override
  String get durationOneMinute => '1 நிமிடம்';

  @override
  String get durationTenMinutes => '10 நிமிடங்கள்';

  @override
  String get durationOneHour => '1 மணிநேரம்';

  @override
  String get durationSixHours => '6 மணிநேரம்';

  @override
  String get durationOneDay => '1 நாள்';

  @override
  String get durationTwoDays => '2 நாட்கள்';

  @override
  String get durationOneWeek => '1 வாரம்';

  @override
  String get durationTwoWeeks => '2 வாரங்கள்';

  @override
  String get durationOneSecondTimeoutPrompt =>
      '1 வினாடிக்குத் தற்காலிகமாகத் தடைசெய்';

  @override
  String get durationOneMinuteTimeoutPrompt =>
      '1 நிமிடத்திற்குத் தற்காலிகமாகத் தடைசெய்';

  @override
  String get durationTenMinutesTimeoutPrompt =>
      '10 நிமிடங்களுக்குத் தற்காலிகமாகத் தடைசெய்';

  @override
  String get durationOneHourTimeoutPrompt =>
      '1 மணிநேரத்திற்குத் தற்காலிகமாகத் தடைசெய்';

  @override
  String get durationSixHoursTimeoutPrompt =>
      '6 மணிநேரத்திற்குத் தற்காலிகமாகத் தடைசெய்';

  @override
  String get durationOneDayTimeoutPrompt =>
      '1 நாளுக்குத் தற்காலிகமாகத் தடைசெய்';

  @override
  String get durationTwoDaysTimeoutPrompt =>
      '2 நாட்களுக்குத் தற்காலிகமாகத் தடைசெய்';

  @override
  String get durationOneWeekTimeoutPrompt =>
      '1 வாரத்திற்குத் தற்காலிகமாகத் தடைசெய்';

  @override
  String get durationTwoWeeksTimeoutPrompt =>
      '2 வாரங்களுக்குத் தற்காலிகமாகத் தடைசெய்';

  @override
  String get errorFetchingViewerList =>
      'இந்தச் சேனலுக்கான பார்வையாளர் பட்டியலைப் பெற முடியவில்லை';

  @override
  String get eventsTitle => 'நிகழ்வுகள்';

  @override
  String get followEventConfigTitle => 'பின்தொடர்தல் நிகழ்வு';

  @override
  String get customizeYourFollowEvent =>
      'உங்கள் பின்தொடர்தல் நிகழ்வைத் தனிப்பயனாக்குங்கள்';

  @override
  String get subscribeEventConfigTitle => 'சந்தா நிகழ்வு';

  @override
  String get customizeYourSubscriptionEvent =>
      'உங்கள் சந்தா நிகழ்வைத் தனிப்பயனாக்குங்கள்';

  @override
  String get cheerEventConfigTitle => 'சியர் நிகழ்வு';

  @override
  String get customizeYourCheerEvent =>
      'உங்கள் சியர் நிகழ்வைத் தனிப்பயனாக்குங்கள்';

  @override
  String get raidEventConfigTitle => 'ரெய்டு நிகழ்வு';

  @override
  String get customizeYourRaidEvent =>
      'உங்கள் ரெய்டு நிகழ்வைத் தனிப்பயனாக்குங்கள்';

  @override
  String get hostEventConfigTitle => 'ஹோஸ்ட் நிகழ்வு';

  @override
  String get customizeYourHostEvent =>
      'உங்கள் ஹோஸ்ட் நிகழ்வைத் தனிப்பயனாக்குங்கள்';

  @override
  String get hypetrainEventConfigTitle => 'ஹைப் டிரெயின் நிகழ்வு';

  @override
  String get customizeYourHypetrainEvent =>
      'உங்கள் ஹைப் டிரெயின் நிகழ்வைத் தனிப்பயனாக்குங்கள்';

  @override
  String get pollEventConfigTitle => 'வாக்கெடுப்பு நிகழ்வு';

  @override
  String get customizeYourPollEvent =>
      'உங்கள் வாக்கெடுப்பு நிகழ்வைத் தனிப்பயனாக்குங்கள்';

  @override
  String get predictionEventConfigTitle => 'கணிப்பு நிகழ்வு';

  @override
  String get customizeYourPredictionEvent =>
      'உங்கள் கணிப்பு நிகழ்வைத் தனிப்பயனாக்குங்கள்';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'சேனல் புள்ளிகள் மீட்பு நிகழ்வு';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'உங்கள் சேனல் புள்ளிகள் மீட்பு நிகழ்வைத் தனிப்பயனாக்குங்கள்';

  @override
  String get outgoingRaidEventConfigTitle => 'வெளிச்செல்லும் ரெய்டு நிகழ்வு';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'உங்கள் வெளிச்செல்லும் ரெய்டு நிகழ்வைத் தனிப்பயனாக்குங்கள்';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b>, <b>$viewerCountString</b> பார்வையாளர்களுடன் ரெய்டு செய்கிறார்!';
  }

  @override
  String get shoutout => 'ஷவுட்அவுட்';

  @override
  String raidingEventRaiding(String displayName) {
    return '<b>$displayName</b> ஐ ரெய்டு செய்கிறது...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString வி';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> ரெய்டு செய்துள்ளார்!';
  }

  @override
  String get raidingEventJoin => 'இணை';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b> இன் ரெய்டு ரத்துசெய்யப்பட்டது.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> நிலை $tier இல் சந்தா செலுத்தியுள்ளார்!';
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

    return '<b>$gifterUserName</b> நிலை $tier இல் $totalString சந்தாக்களைப் பரிசளித்துள்ளார், மொத்தம் $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> நிலை $tier இல் $cumulativeMonthsString மாதங்களுக்குச் சந்தா செலுத்தியுள்ளார்!';
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

    return '<b>$subscriberUserName</b> நிலை $tier இல் முன்கூட்டியே $durationMonthsString மாதங்களுக்குச் சந்தா செலுத்தியுள்ளார், மொத்தம் $cumulativeMonthsString மாதங்கள்!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> <b>$value $currency</b> டிப் வழங்கியுள்ளார்.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'பெயர் வெளியிடாதவர் <b>$value $currency</b> டிப் வழங்கியுள்ளார்.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return 'StreamElements இல் <b>$name</b> <b>$formattedAmount</b> டிப் வழங்கியுள்ளார்.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return 'Streamlabs இல் <b>$name</b> <b>$formattedAmount</b> டிப் வழங்கியுள்ளார்.';
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

    return '<b>$redeemerUsername</b> <b>$rewardCostString</b> புள்ளிகளுக்கு <b>$rewardName</b> ஐ மீட்டுள்ளார். $userInput';
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

    return '<b>$redeemerUsername</b> <b>$rewardCostString</b> புள்ளிகளுக்கு <b>$rewardName</b> ஐ மீட்டுள்ளார்.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> <b>$bitsString</b> பிட்களை சியர் செய்துள்ளார். $cheerMessage';
  }

  @override
  String get anonymous => 'பெயர் வெளியிடாதவர்';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b>, <b>$viewersString</b> பேர் கொண்ட குழுவுடன் ஹோஸ்ட் செய்கிறார்.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'ஹைப் டிரெயின் நிலை <b>$level</b> நடைபெறுகிறது! <b>$progressPercent%</b> முடிந்தது!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'ஹைப் டிரெயின் நிலை <b>$levelString</b> வெற்றி பெற்றது.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'ஹைப் டிரெயின் நிலை <b>$levelString</b> தோல்வியடைந்தது.';
  }

  @override
  String get sampleMessage =>
      'இது உரையைப் பேச்சாக மாற்றுவதற்கான மாதிரி செய்தி.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author கூறினார்: $text';
  }

  @override
  String get textToSpeechEnabled => 'உரையிலிருந்து பேச்சு இயக்கப்பட்டது';

  @override
  String get textToSpeechDisabled => 'உரையிலிருந்து பேச்சு முடக்கப்பட்டது';

  @override
  String get alertsEnabled => 'விழிப்பூட்டல்கள் மட்டும்';

  @override
  String get pinDuration => 'பின் கால அளவு';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds வினாடிகள்',
      one: '1 வினாடி',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes நிமிடங்கள்',
      one: '1 நிமிடம்',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'நிகழ்வை இயக்கு';

  @override
  String get showEventInChatHistory => 'அரட்டை வரலாற்றில் நிகழ்வைக் காட்டு';

  @override
  String get enableShoutouts => 'ஷவுட்அவுட்களை இயக்கு';

  @override
  String get enableShoutoutsSubtitle =>
      'ரெய்டு செய்யும் சேனலின் இணைப்பை அரட்டைக்கு அனுப்பு';

  @override
  String get raidConfigurationTitle => 'ரெய்டு உள்ளமைவு';

  @override
  String get cheerConfigurationTitle => 'சியர் உள்ளமைவு';

  @override
  String get followConfigurationTitle => 'பின்தொடர்தல் உள்ளமைவு';

  @override
  String get outgoingRaidConfigurationTitle => 'வெளிச்செல்லும் ரெய்டு உள்ளமைவு';

  @override
  String get hostConfigurationTitle => 'ஹோஸ்ட் உள்ளமைவு';

  @override
  String get channelPointConfigurationTitle => 'சேனல் புள்ளிகள் உள்ளமைவு';

  @override
  String get pollConfigurationTitle => 'வாக்கெடுப்பு உள்ளமைவு';

  @override
  String get hypetrainConfigurationTitle => 'ஹைப் டிரெயின் உள்ளமைவு';

  @override
  String get subscriptionConfigurationTitle => 'சந்தா உள்ளமைவு';

  @override
  String get predictionConfigurationTitle => 'கணிப்பு உள்ளமைவு';

  @override
  String get unfulfilledRewardsPinDuration =>
      'நிறைவேற்றப்படாத வெகுமதிகளுக்கான கூடுதல் பின் கால அளவு';

  @override
  String get pollPinDuration => 'முடிவு இறுதி செய்யப்பட்ட பிறகு பின் கால அளவு';

  @override
  String get hypetrainPinDuration =>
      'ஹைப் டிரெயின் முடிந்த பிறகு பின் கால அளவு';

  @override
  String get enableGiftedSubscriptions =>
      'தனிப்பட்ட பரிசளிக்கப்பட்ட சந்தாக்களை இயக்கு';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'பரிசளிக்கப்படும் ஒவ்வொரு சந்தாவையும் காட்டு';

  @override
  String get settingsBackupTitle =>
      'அமைப்புகள் காப்புப்பிரதி மற்றும் மீட்டமைப்பு';

  @override
  String get cloudBackup => 'கிளவுட் காப்புப்பிரதி';

  @override
  String get lastBackupNever => 'கடைசி காப்புப்பிரதி: ஒருபோதும் இல்லை';

  @override
  String get backUp => 'காப்புப்பிரதி எடு';

  @override
  String get restore => 'மீட்டமை';

  @override
  String get localBackup => 'உள்ளூர் காப்புப்பிரதி';

  @override
  String get exportSettings => 'ஏற்றுமதி செய்';

  @override
  String get importSettings => 'இறக்குமதி செய்';

  @override
  String get showViewerAndFollowerCount =>
      'பார்வையாளர் மற்றும் பின்தொடர்பவர் எண்ணிக்கையைக் காட்டு';

  @override
  String get screenOrientation => 'திரை திசையமைப்பு';

  @override
  String get appTheme => 'செயலி தீம்';

  @override
  String get systemDefault => 'சிஸ்டம்';

  @override
  String get portrait => 'செங்குத்து';

  @override
  String get landscape => 'கிடைமட்டம்';

  @override
  String get lightTheme => 'வெளிச்சம்';

  @override
  String get darkTheme => 'இருள்';

  @override
  String get openSourceTitle => 'RealtimeChat ஒரு திறந்த மூல மென்பொருளாகும்';

  @override
  String get openSourceSubtitle => 'GitHub இல் எங்களைக் கண்டறியுங்கள்!';

  @override
  String get discordSubtitle => 'Muxable Discord இல் இணையுங்கள்!';

  @override
  String get earlyTestersThanks =>
      'பிழை அறிக்கைகளை அனுப்பிய அனைத்து ஆரம்பகால சோதனையாளர்களுக்கும் நன்றி!';

  @override
  String get discoModeEnabled => '🕺 டிஸ்கோ பயன்முறை இயக்கப்பட்டது! :D';

  @override
  String get discoModeDisabled => '🕺 டிஸ்கோ பயன்முறை முடக்கப்பட்டது D:';

  @override
  String get playSampleMessage => 'மாதிரி செய்தியை இயக்கு';

  @override
  String get textToSpeechRate => 'உரையிலிருந்து பேச்சு வேகம்';

  @override
  String get textToSpeechPitch => 'உரையிலிருந்து பேச்சு சுருதி';

  @override
  String get muteBots => 'பாட்களுக்கான உரையிலிருந்து பேச்சை ஒலிமறை';

  @override
  String get muteEmotes => 'உரையிலிருந்து பேச்சில் அனைத்து எமோட்களையும் ஒலிமறை';

  @override
  String get muteViewerNames =>
      'உரையிலிருந்து பேச்சில் பார்வையாளர் பெயர்களை ஒலிமறை';

  @override
  String get subscribersOnly => 'சந்தாதாரர்கள் மட்டும்';

  @override
  String get fontSize => 'எழுத்துரு அளவு';

  @override
  String get usernameContrastBoost => 'பயனர்பெயர் மாறுபாடு அதிகரிப்பு';

  @override
  String get twitchBadgeSettings => 'Twitch பேட்ஜ் அமைப்புகள்';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'எந்த பேட்ஜ்கள் தெரிய வேண்டும் என்பதைக் கட்டுப்படுத்துங்கள்';

  @override
  String get showDeletedMessages => 'நீக்கப்பட்ட செய்திகளைக் காட்டு';

  @override
  String get deletedMessagesGreyedOut =>
      'நீக்கப்பட்ட செய்திகள் சாம்பல் நிறத்தில் காட்டப்படும்';

  @override
  String get deletedMessagesRemoved => 'நீக்கப்பட்ட செய்திகள் அகற்றப்படும்';

  @override
  String get showLoginNames => 'உள்நுழைவுப் பெயர்களைக் காட்டு';

  @override
  String get loginNamesShown =>
      'காட்சிப் பெயரிலிருந்து வேறுபட்டால் உள்நுழைவுப் பெயர்கள் காட்டப்படும்';

  @override
  String get loginNamesHidden => 'உள்நுழைவுப் பெயர்கள் மறைக்கப்படும்';

  @override
  String get compactMessages => 'செய்திகளைச் சுருக்கு';

  @override
  String get dontCompactMessages => 'செய்திகளைச் சுருக்க வேண்டாம்';

  @override
  String get dontCompactMessagesSubtitle =>
      'செய்திகள் மாற்றமின்றி காட்டப்படும்';

  @override
  String get compactIndividualMessages => 'தனிப்பட்ட செய்திகளைச் சுருக்கு';

  @override
  String get compactIndividualMessagesSubtitle =>
      'செய்திகளில் திரும்பத் திரும்ப வரும் உரை சுருக்கப்படும்';

  @override
  String get announcementPinDuration => 'அறிவிப்பு பின் கால அளவு';

  @override
  String get idleMessageAlertDuration =>
      'செயலற்ற செய்தி விழிப்பூட்டல் கால அளவு';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'இந்த நேரத்திற்கு எந்தச் செய்தியும் வராமல் இருந்து புதிய செய்தி வந்தால், விழிப்பூட்டல் ஒலி ஒலிக்கும்.';

  @override
  String get realtimeCashSubtitle => 'ETH அல்லது MATIC வாலட்டை இணைக்கவும்';

  @override
  String get walletAddress => 'வாலட் முகவரி';

  @override
  String get streamlabsSubtitle => 'உங்கள் Streamlabs நன்கொடைகளைப் பார்க்கவும்';

  @override
  String get streamElementsSubtitle =>
      'உங்கள் StreamElements நன்கொடைகளைப் பார்க்கவும்';

  @override
  String get thirdPartyAuthError =>
      'ம்ம், அது வேலை செய்யவில்லை. மீண்டும் முயற்சிக்கவும் அல்லது Discord இல் கேட்கவும்?';

  @override
  String get companionAuthBrowserTooOld =>
      'நேரடியாக உள்நுழைவதை ஆதரிக்க உங்கள் உலாவி மிகவும் பழையது. மற்றொரு சாதனத்தில் உள்நுழைய உங்கள் தொலைபேசி மூலம் இந்த QR குறியீட்டை ஸ்கேன் செய்யவும்.';

  @override
  String get companionAuthScanQrCode =>
      'மற்றொரு சாதனத்தில் உள்நுழைய உங்கள் தொலைபேசி மூலம் இந்த QR குறியீட்டை ஸ்கேன் செய்யவும்.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> சந்தா செலுத்தியுள்ளார்!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> $monthsString மாதங்களுக்கு மீண்டும் சந்தா செலுத்தியுள்ளார்!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> $countString சந்தாக்களைப் பரிசளித்துள்ளார்!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> $amountString Kicks அனுப்பியுள்ளார்!';
  }

  @override
  String get signInWithKick => 'Kick மூலம் உள்நுழையவும்';

  @override
  String get textToSpeechTooManyMessages =>
      'மிக அதிகமான செய்திகள் உள்ளன. உரையிலிருந்து பேச்சு முடக்கப்பட்டது';

  @override
  String get turnOffTextToSpeech => 'ஆஃப் செய்';

  @override
  String get addToChat => 'அரட்டையில் சேர்';

  @override
  String get inChat => 'அரட்டையில்';

  @override
  String get removeFromChat => 'அரட்டையிலிருந்து அகற்று';

  @override
  String cantChatWithAccount(String provider) {
    return 'உங்கள் $provider கணக்கால் இங்கே அரட்டையடிக்க முடியாது';
  }

  @override
  String get cantChatWithAccounts =>
      'உங்கள் கணக்குகளால் இங்கே அரட்டையடிக்க முடியாது';

  @override
  String sendAMessageTo(String channel) {
    return '$channel க்கு செய்தியை அனுப்பு...';
  }

  @override
  String replaceChannel(String channel) {
    return '$channel ஐ மாற்று';
  }

  @override
  String get voicePacks => 'குரல் தொகுப்புகள்';

  @override
  String get voicePacksDescription =>
      'குரல் தொகுப்புகள் பதிவிறக்கப்பட்டவுடன் ஆஃப்லைனில் உங்கள் சாதனத்தில் இயங்கும் இயற்கையான குரல்களுடன் அரட்டையைப் படிக்கின்றன. இந்தக் குரல்கள் AI மூலம் இயந்திரத்தால் உருவாக்கப்பட்டவை, மனிதரால் பதிவு செய்யப்பட்டவை அல்ல.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices குரல்கள்',
      one: '1 குரல்',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மொழிகள்',
      one: '1 மொழி',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'இந்த மாதிரியின் உரிமம் (OpenRAIL-M) ஆள்மாறாட்டம் செய்வது அல்லது தவறான தகவல்களைப் பரப்புவது போன்ற தீங்கு விளைவிக்கும் பயன்பாடுகளைத் தடைசெய்கிறது, மேலும் இந்தக் கட்டுப்பாடுகள் உங்களுக்கும் பொருந்தும்.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return '$pack ஐ நீக்கவா? இதனால் $size இடம் காலியாகும்.';
  }

  @override
  String get voicePackDownload => 'பதிவிறக்கு';

  @override
  String get voicePackUpdate => 'புதுப்பி';

  @override
  String get voicePackWaitingForWifi => 'Wi-Fi க்காகக் காத்திருக்கிறது';

  @override
  String get voicePackUseMobileData => 'மொபைல் டேட்டாவைப் பயன்படுத்து';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'பதிவிறக்குகிறது: $total இல் $downloaded';
  }

  @override
  String get voicePackInstalling => 'நிறுவுகிறது';

  @override
  String voicePackInstallFailed(String pack) {
    return '$pack ஐ நிறுவ முடியவில்லை. உங்கள் இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';
  }

  @override
  String get voices => 'குரல்கள்';

  @override
  String get perViewerVoice => 'ஒவ்வொரு பார்வையாளருக்கும் தனி குரல்';

  @override
  String get perViewerVoiceSubtitle =>
      'ஒவ்வொரு பார்வையாளருக்கும் தனி குரல் கிடைக்கும். நீங்கள் தேர்ந்தெடுக்கும் குரல் விழிப்பூட்டல்களையோ அல்லது இது ஆஃப் செய்யப்பட்டிருக்கும்போது அனைத்தையுமோ படிக்கும்.';

  @override
  String get streamLanguage => 'ஸ்ட்ரீம் மொழி';

  @override
  String get ttsEngineNeural => 'நியூரல் குரல் (சாதனத்தில்)';

  @override
  String get ttsEngineSystem => 'சிஸ்டம் குரல்';

  @override
  String languageUnsupported(String language) {
    return 'உங்கள் குரல் தொகுப்புகளால் $language ஆதரிக்கப்படவில்லை; சிஸ்டம் குரல் பயன்படுத்தப்படும்';
  }

  @override
  String get neuralFallbackLowMemory =>
      'இந்தச் சாதனத்தில் நியூரல் குரல்களுக்குப் போதுமான நினைவகம் இல்லை, எனவே அரட்டை சிஸ்டம் குரல் மூலம் படிக்கப்படுகிறது.';

  @override
  String get neuralFallbackLoadFailed =>
      'நியூரல் குரலை ஏற்ற முடியவில்லை, எனவே அரட்டை சிஸ்டம் குரல் மூலம் படிக்கப்படுகிறது.';

  @override
  String get accounts => 'கணக்குகள்';

  @override
  String get accountsSubtitle =>
      'நீங்கள் ஸ்ட்ரீம் செய்யும் ஒவ்வொரு தளத்திலும் உள்நுழையவும்';

  @override
  String addProviderAccount(String provider) {
    return '$provider கணக்கைச் சேர்';
  }

  @override
  String signInWithProvider(String provider) {
    return '$provider மூலம் உள்நுழையவும்';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return '$provider இல் உள்ள $channel இலிருந்து வெளியேறவா?';
  }

  @override
  String get signOutOfAll => 'அனைத்துக் கணக்குகளிலிருந்தும் வெளியேறு';
}
