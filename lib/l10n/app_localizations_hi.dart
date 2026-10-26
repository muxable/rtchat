// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get sendAMessage => 'संदेश भेजें...';

  @override
  String get writeSomething => 'कुछ लिखें...';

  @override
  String get speakToTheCrowds => 'भीड़ से बात करें...';

  @override
  String get shareYourThoughts => 'अपने विचार साझा करें...';

  @override
  String get saySomethingYouLittleBitch => 'कुछ तो बोल, कमीने...';

  @override
  String get search => 'खोजें';

  @override
  String get notSignedIn => 'साइन इन नहीं है';

  @override
  String get searchChannels => 'खोजें';

  @override
  String get raidAChannel => 'रेड';

  @override
  String get noMessagesEmptyState => 'यहाँ सन्नाटा है।';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नए संदेश',
      one: '1 नया संदेश',
      zero: 'कोई नया संदेश नहीं',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Twitch से साइन इन करें';

  @override
  String get signInError =>
      'साइन इन करते समय एक त्रुटि हुई। कृपया पुनः प्रयास करें।';

  @override
  String get continueAsGuest => 'अतिथि के रूप में जारी रखें';

  @override
  String get signInToSendMessages => 'संदेश भेजने के लिए साइन इन करें';

  @override
  String get currentViewers => 'वर्तमान दर्शक';

  @override
  String get textToSpeech => 'टेक्स्ट टू स्पीच';

  @override
  String get streamPreview => 'स्ट्रीम पूर्वावलोकन';

  @override
  String get activityFeed => 'गतिविधि फ़ीड';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString पर स्ट्रीम ऑनलाइन हुई';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString पर स्ट्रीम ऑफ़लाइन हुई';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString पर चैट साफ़ की गई';
  }

  @override
  String get configureQuickLinks => 'त्वरित लिंक कॉन्फ़िगर करें';

  @override
  String get disableRainMode => 'रेन मोड बंद करें';

  @override
  String get enableRainMode => 'रेन मोड चालू करें';

  @override
  String get disableRainModeSubtitle => 'इंटरैक्शन चालू हो जाएगा';

  @override
  String get enableRainModeSubtitle => 'इंटरैक्शन बंद हो जाएगा';

  @override
  String get refreshAudioSources => 'ऑडियो स्रोत रीफ़्रेश करें';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ऑडियो स्रोत रीफ़्रेश किए गए',
      one: '1 ऑडियो स्रोत रीफ़्रेश किया गया',
      zero: 'कोई ऑडियो स्रोत रीफ़्रेश नहीं किया गया',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get signOut => 'साइन आउट करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get signOutConfirmation => 'क्या आप वाकई साइन आउट करना चाहते हैं?';

  @override
  String get broadcaster => 'ब्रॉडकास्टर';

  @override
  String get moderators => 'मॉडरेटर';

  @override
  String get viewers => 'दर्शक';

  @override
  String get communityVips => 'कम्युनिटी VIPs';

  @override
  String get searchViewers => 'दर्शक खोजें';

  @override
  String get reconnecting => 'पुनः कनेक्ट हो रहा है...';

  @override
  String get twitchBadges => 'Twitch बैज';

  @override
  String get selectAll => 'सभी चुनें';

  @override
  String get quickLinks => 'त्वरित लिंक';

  @override
  String get swipeToDeleteQuickLinks =>
      'त्वरित लिंक हटाने के लिए बाएँ या दाएँ स्वाइप करें';

  @override
  String get quickLinksLabelHint => 'लेबल';

  @override
  String get invalidUrlErrorText => 'यह एक मान्य URL नहीं लगता है';

  @override
  String get duplicateUrlErrorText => 'यह लिंक पहले से मौजूद है';

  @override
  String get or => 'या';

  @override
  String get clearCookies => 'कुकीज़ साफ़ करें';

  @override
  String get disabled => 'अक्षम';

  @override
  String get twitchActivityFeed => 'Twitch गतिविधि फ़ीड';

  @override
  String get signInToEnable =>
      'इसे सक्षम करने के लिए आपका साइन इन होना आवश्यक है';

  @override
  String get customUrl => 'कस्टम URL';

  @override
  String get preview => 'पूर्वावलोकन';

  @override
  String get audioSources => 'ऑडियो स्रोत';

  @override
  String get enableOffStreamSwitchTitle =>
      'ऑफ़-स्ट्रीम चालू करें (अधिक बैटरी खर्च होती है)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'जब आप ऑफ़लाइन होंगे तब भी ऑडियो चलेगा';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'ऑडियो केवल तभी चलेगा जब आप लाइव होंगे';

  @override
  String get iosOggWarningTitle => 'अरे! सुनिए!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS *.ogg मीडिया फ़ाइलों का समर्थन नहीं करता है, जो Streamlabs पर डिफ़ॉल्ट फ़ाइलें होती हैं। सुनिश्चित करें कि आपके ऑडियो स्रोत किसी अन्य फ़ॉर्मेट का उपयोग करें, अन्यथा वे नहीं चलेंगे।';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'अपनी गतिविधि फ़ीड कस्टमाइज़ करें';

  @override
  String get audioSourcesSubtitle => 'अलर्ट ध्वनियों के लिए वेब स्रोत जोड़ें';

  @override
  String get quickLinksSubtitle =>
      'अक्सर उपयोग किए जाने वाले टूल्स के लिए शॉर्टकट जोड़ें';

  @override
  String get chatHistory => 'चैट इतिहास';

  @override
  String get chatHistorySubtitle => 'चैट का रंग-रूप बदलें';

  @override
  String get textToSpeechSubtitle => 'टेक्स्ट टू स्पीच सेटिंग्स बदलें';

  @override
  String get events => 'इवेंट';

  @override
  String get eventsSubtitle => 'Twitch इवेंट कॉन्फ़िगर करें';

  @override
  String get thirdPartyServices => 'तृतीय-पक्ष सेवाएँ';

  @override
  String get thirdPartyServicesSubtitle => 'किसी तृतीय-पक्ष सेवा से जुड़ें';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> आपको फ़ॉलो कर रहे हैं';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> और <b>$displayNameTwo</b> आपको फ़ॉलो कर रहे हैं';
  }

  @override
  String followingEvent3(
    String displayName,
    String displayNameTwo,
    int numOthers,
  ) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>, <b>$displayNameTwo</b> और $numOthersString अन्य आपको फ़ॉलो कर रहे हैं';
  }

  @override
  String unmuteUser(String displayName) {
    return '$displayName को अनम्यूट करें';
  }

  @override
  String muteUser(String displayName) {
    return '$displayName को म्यूट करें';
  }

  @override
  String timeoutUser(String displayName) {
    return '$displayName को टाइम-आउट करें';
  }

  @override
  String banUser(String displayName) {
    return '$displayName को बैन करें';
  }

  @override
  String unbanUser(String displayName) {
    return '$displayName को अनबैन करें';
  }

  @override
  String viewProfile(String displayName) {
    return '$displayName की प्रोफ़ाइल देखें';
  }

  @override
  String get copyMessage => 'संदेश कॉपी करें';

  @override
  String get deleteMessage => 'संदेश हटाएँ';

  @override
  String get longScrollNotification =>
      'आप काफ़ी पीछे तक स्क्रॉल कर रहे हैं, क्या आपको नहीं लगता?';

  @override
  String get stfu => 'चुप रहो';

  @override
  String get globalEmotes => 'ग्लोबल इमोट्स';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString फ़ॉलोअर',
      one: '1 फ़ॉलोअर',
      zero: '0 फ़ॉलोअर',
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
      other: '$countString दर्शक',
      one: '1 दर्शक',
      zero: '0 दर्शक',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'नमस्ते! खुशी है कि आपको स्ट्रीम पूर्वावलोकन पसंद है, लेकिन ध्यान रहे कि इससे बहुत बैटरी खर्च होती है। इसके बिना चैट पढ़ने से आपकी बैटरी ज़्यादा चलेगी।';

  @override
  String get okay => 'ठीक है';

  @override
  String get streamPreviewLoading => 'लोड हो रहा है (या स्ट्रीम ऑफ़लाइन है)...';

  @override
  String get copiedToClipboard => 'क्लिपबोर्ड पर कॉपी किया गया';

  @override
  String get audioSourcesRequirePermissions =>
      'ऑडियो स्रोतों के लिए अनुमति आवश्यक है';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'ऑडियो स्रोतों का उपयोग करने के लिए RealtimeChat को अन्य ऐप्स के ऊपर दिखने की अनुमति दें।';

  @override
  String get audioSourcesRemoveButton => 'ऑडियो स्रोत हटाएँ';

  @override
  String get audioSourcesOpenSettingsButton => 'सेटिंग्स खोलें';

  @override
  String get flashOn => 'फ़्लैश चालू';

  @override
  String get flashOff => 'फ़्लैश बंद';

  @override
  String get durationOneSecond => '1 सेकंड';

  @override
  String get durationOneMinute => '1 मिनट';

  @override
  String get durationTenMinutes => '10 मिनट';

  @override
  String get durationOneHour => '1 घंटा';

  @override
  String get durationSixHours => '6 घंटे';

  @override
  String get durationOneDay => '1 दिन';

  @override
  String get durationTwoDays => '2 दिन';

  @override
  String get durationOneWeek => '1 सप्ताह';

  @override
  String get durationTwoWeeks => '2 सप्ताह';

  @override
  String get durationOneSecondTimeoutPrompt => '1 सेकंड के लिए टाइम-आउट करें';

  @override
  String get durationOneMinuteTimeoutPrompt => '1 मिनट के लिए टाइम-आउट करें';

  @override
  String get durationTenMinutesTimeoutPrompt => '10 मिनट के लिए टाइम-आउट करें';

  @override
  String get durationOneHourTimeoutPrompt => '1 घंटे के लिए टाइम-आउट करें';

  @override
  String get durationSixHoursTimeoutPrompt => '6 घंटे के लिए टाइम-आउट करें';

  @override
  String get durationOneDayTimeoutPrompt => '1 दिन के लिए टाइम-आउट करें';

  @override
  String get durationTwoDaysTimeoutPrompt => '2 दिन के लिए टाइम-आउट करें';

  @override
  String get durationOneWeekTimeoutPrompt => '1 सप्ताह के लिए टाइम-आउट करें';

  @override
  String get durationTwoWeeksTimeoutPrompt => '2 सप्ताह के लिए टाइम-आउट करें';

  @override
  String get errorFetchingViewerList =>
      'हम इस चैनल के लिए दर्शकों की सूची प्राप्त नहीं कर सके';

  @override
  String get eventsTitle => 'इवेंट';

  @override
  String get followEventConfigTitle => 'फ़ॉलो इवेंट';

  @override
  String get customizeYourFollowEvent => 'अपने फ़ॉलो इवेंट को कस्टमाइज़ करें';

  @override
  String get subscribeEventConfigTitle => 'सब्सक्राइब इवेंट';

  @override
  String get customizeYourSubscriptionEvent =>
      'अपने सब्सक्रिप्शन इवेंट को कस्टमाइज़ करें';

  @override
  String get cheerEventConfigTitle => 'चीयर इवेंट';

  @override
  String get customizeYourCheerEvent => 'अपने चीयर इवेंट को कस्टमाइज़ करें';

  @override
  String get raidEventConfigTitle => 'रेड इवेंट';

  @override
  String get customizeYourRaidEvent => 'अपने रेड इवेंट को कस्टमाइज़ करें';

  @override
  String get hostEventConfigTitle => 'होस्ट इवेंट';

  @override
  String get customizeYourHostEvent => 'अपने होस्ट इवेंट को कस्टमाइज़ करें';

  @override
  String get hypetrainEventConfigTitle => 'हाइप ट्रेन इवेंट';

  @override
  String get customizeYourHypetrainEvent =>
      'अपने हाइप ट्रेन इवेंट को कस्टमाइज़ करें';

  @override
  String get pollEventConfigTitle => 'पोल इवेंट';

  @override
  String get customizeYourPollEvent => 'अपने पोल इवेंट को कस्टमाइज़ करें';

  @override
  String get predictionEventConfigTitle => 'प्रेडिक्शन इवेंट';

  @override
  String get customizeYourPredictionEvent =>
      'अपने प्रेडिक्शन इवेंट को कस्टमाइज़ करें';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'चैनल पॉइंट रिडेम्पशन इवेंट';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'अपने चैनल पॉइंट रिडेम्पशन इवेंट को कस्टमाइज़ करें';

  @override
  String get outgoingRaidEventConfigTitle => 'आउटगोइंग रेड इवेंट';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'अपने आउटगोइंग रेड इवेंट को कस्टमाइज़ करें';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> <b>$viewerCountString</b> दर्शकों के साथ रेड कर रहे हैं!';
  }

  @override
  String get shoutout => 'शाउटआउट';

  @override
  String raidingEventRaiding(String displayName) {
    return '<b>$displayName</b> पर रेड की जा रही है...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString से.';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> ने रेड किया है!';
  }

  @override
  String get raidingEventJoin => 'शामिल हों';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b> की रेड रद्द कर दी गई।';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> ने टियर $tier पर सब्सक्राइब किया है!';
  }

  @override
  String subscriptionGiftEvent(
    String gifterUserName,
    int total,
    String tier,
    int cumulativeTotal,
  ) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat cumulativeTotalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeTotalString = cumulativeTotalNumberFormat.format(
      cumulativeTotal,
    );

    return '<b>$gifterUserName</b> ने $totalString टियर $tier सब्सक्रिप्शन उपहार में दिए हैं, कुल मिलाकर $cumulativeTotalString!';
  }

  @override
  String subscriptionMessageEvent(
    String subscriberUserName,
    int cumulativeMonths,
    String tier,
  ) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString = cumulativeMonthsNumberFormat.format(
      cumulativeMonths,
    );

    return '<b>$subscriberUserName</b> ने टियर $tier पर $cumulativeMonthsString महीनों के लिए सब्सक्राइब किया है!';
  }

  @override
  String subscriptionMessageMultiMonthEvent(
    String subscriberUserName,
    String tier,
    int durationMonths,
    int cumulativeMonths,
  ) {
    final intl.NumberFormat durationMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String durationMonthsString = durationMonthsNumberFormat.format(
      durationMonths,
    );
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString = cumulativeMonthsNumberFormat.format(
      cumulativeMonths,
    );

    return '<b>$subscriberUserName</b> ने टियर $tier पर $durationMonthsString महीनों के लिए अग्रिम सब्सक्राइब किया है, कुल $cumulativeMonthsString महीने!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> ने <b>$value $currency</b> टिप दी।';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'अज्ञात ने <b>$value $currency</b> टिप दी।';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ने StreamElements पर <b>$formattedAmount</b> टिप दी।';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ने Streamlabs पर <b>$formattedAmount</b> टिप दी।';
  }

  @override
  String channelPointRedemptionWithUserInput(
    String redeemerUsername,
    String rewardName,
    int rewardCost,
    String userInput,
  ) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> ने <b>$rewardCostString</b> पॉइंट्स में <b>$rewardName</b> रिडीम किया। $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
    String redeemerUsername,
    String rewardName,
    int rewardCost,
  ) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> ने <b>$rewardCostString</b> पॉइंट्स में <b>$rewardName</b> रिडीम किया।';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> ने <b>$bitsString</b> बिट्स के साथ चीयर किया। $cheerMessage';
  }

  @override
  String get anonymous => 'अज्ञात';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> <b>$viewersString</b> दर्शकों के साथ होस्ट कर रहे हैं।';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'हाइप ट्रेन लेवल <b>$level</b> जारी है! <b>$progressPercent%</b> पूरा हुआ!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'हाइप ट्रेन लेवल <b>$levelString</b> सफल रहा।';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'हाइप ट्रेन लेवल <b>$levelString</b> विफल रहा।';
  }

  @override
  String get sampleMessage =>
      'यह टेक्स्ट को आवाज़ में बदलने के लिए एक नमूना संदेश है।';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author ने कहा: $text';
  }

  @override
  String get textToSpeechEnabled => 'टेक्स्ट टू स्पीच चालू किया गया';

  @override
  String get textToSpeechDisabled => 'टेक्स्ट टू स्पीच बंद किया गया';

  @override
  String get alertsEnabled => 'केवल अलर्ट';

  @override
  String get pinDuration => 'पिन की अवधि';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds सेकंड',
      one: '1 सेकंड',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes मिनट',
      one: '1 मिनट',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'इवेंट चालू करें';

  @override
  String get showEventInChatHistory => 'चैट इतिहास में इवेंट दिखाएँ';

  @override
  String get enableShoutouts => 'शाउटआउट चालू करें';

  @override
  String get enableShoutoutsSubtitle =>
      'रेड करने वाले चैनल का लिंक चैट में भेजें';

  @override
  String get raidConfigurationTitle => 'रेड कॉन्फ़िगरेशन';

  @override
  String get cheerConfigurationTitle => 'चीयर कॉन्फ़िगरेशन';

  @override
  String get followConfigurationTitle => 'फ़ॉलो कॉन्फ़िगरेशन';

  @override
  String get outgoingRaidConfigurationTitle => 'आउटगोइंग रेड कॉन्फ़िगरेशन';

  @override
  String get hostConfigurationTitle => 'होस्ट कॉन्फ़िगरेशन';

  @override
  String get channelPointConfigurationTitle => 'चैनल पॉइंट कॉन्फ़िगरेशन';

  @override
  String get pollConfigurationTitle => 'पोल कॉन्फ़िगरेशन';

  @override
  String get hypetrainConfigurationTitle => 'हाइप ट्रेन कॉन्फ़िगरेशन';

  @override
  String get subscriptionConfigurationTitle => 'सब्सक्रिप्शन कॉन्फ़िगरेशन';

  @override
  String get predictionConfigurationTitle => 'प्रेडिक्शन कॉन्फ़िगरेशन';

  @override
  String get unfulfilledRewardsPinDuration =>
      'अधूरे रिवॉर्ड्स के लिए अतिरिक्त पिन अवधि';

  @override
  String get pollPinDuration => 'परिणाम घोषित होने के बाद पिन की अवधि';

  @override
  String get hypetrainPinDuration =>
      'हाइप ट्रेन समाप्त होने के बाद पिन की अवधि';

  @override
  String get enableGiftedSubscriptions =>
      'अलग-अलग गिफ़्ट किए गए सब्सक्रिप्शन चालू करें';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'गिफ़्ट किया गया प्रत्येक सब्सक्रिप्शन दिखाएँ';

  @override
  String get settingsBackupTitle => 'सेटिंग्स बैकअप और रीस्टोर';

  @override
  String get cloudBackup => 'क्लाउड बैकअप';

  @override
  String get lastBackupNever => 'अंतिम बैकअप: कभी नहीं';

  @override
  String get backUp => 'बैकअप लें';

  @override
  String get restore => 'रीस्टोर करें';

  @override
  String get localBackup => 'लोकल बैकअप';

  @override
  String get exportSettings => 'एक्सपोर्ट करें';

  @override
  String get importSettings => 'इम्पोर्ट करें';

  @override
  String get showViewerAndFollowerCount =>
      'दर्शकों और फ़ॉलोअर की संख्या दिखाएँ';

  @override
  String get screenOrientation => 'स्क्रीन ओरिएंटेशन';

  @override
  String get appTheme => 'ऐप थीम';

  @override
  String get systemDefault => 'सिस्टम';

  @override
  String get portrait => 'पोर्ट्रेट';

  @override
  String get landscape => 'लैंडस्केप';

  @override
  String get lightTheme => 'लाइट';

  @override
  String get darkTheme => 'डार्क';

  @override
  String get openSourceTitle => 'RealtimeChat ओपन सोर्स है';

  @override
  String get openSourceSubtitle => 'हमें GitHub पर खोजें!';

  @override
  String get discordSubtitle => 'Muxable Discord से जुड़ें!';

  @override
  String get earlyTestersThanks =>
      'बग रिपोर्ट भेजने वाले सभी शुरुआती टेस्टर्स का धन्यवाद!';

  @override
  String get discoModeEnabled => '🕺 डिस्को मोड चालू हो गया! :D';

  @override
  String get discoModeDisabled => '🕺 डिस्को मोड बंद हो गया D:';

  @override
  String get playSampleMessage => 'नमूना संदेश चलाएँ';

  @override
  String get textToSpeechRate => 'टेक्स्ट टू स्पीच की गति';

  @override
  String get textToSpeechPitch => 'टेक्स्ट टू स्पीच की पिच';

  @override
  String get muteBots => 'बॉट्स के लिए टेक्स्ट टू स्पीच म्यूट करें';

  @override
  String get muteEmotes => 'टेक्स्ट टू स्पीच में सभी इमोट्स म्यूट करें';

  @override
  String get muteViewerNames =>
      'टेक्स्ट टू स्पीच में दर्शकों के नाम म्यूट करें';

  @override
  String get subscribersOnly => 'केवल सब्सक्राइबर';

  @override
  String get fontSize => 'फ़ॉन्ट आकार';

  @override
  String get usernameContrastBoost => 'यूज़रनेम कंट्रास्ट बूस्ट';

  @override
  String get twitchBadgeSettings => 'Twitch बैज सेटिंग्स';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'नियंत्रित करें कि कौन-से बैज दिखाई दें';

  @override
  String get showDeletedMessages => 'हटाए गए संदेश दिखाएँ';

  @override
  String get deletedMessagesGreyedOut =>
      'हटाए गए संदेश धुंधले (ग्रे) दिखाई देंगे';

  @override
  String get deletedMessagesRemoved => 'हटाए गए संदेश पूरी तरह हटा दिए जाएंगे';

  @override
  String get showLoginNames => 'लॉगिन नाम दिखाएँ';

  @override
  String get loginNamesShown =>
      'यदि लॉगिन नाम डिस्प्ले नाम से अलग हैं तो वे दिखाए जाएंगे';

  @override
  String get loginNamesHidden => 'लॉगिन नाम छिपाए जाएंगे';

  @override
  String get compactMessages => 'संदेश संक्षिप्त करें';

  @override
  String get dontCompactMessages => 'संदेशों को संक्षिप्त न करें';

  @override
  String get dontCompactMessagesSubtitle =>
      'संदेश बिना किसी बदलाव के दिखाए जाते हैं';

  @override
  String get compactIndividualMessages => 'अलग-अलग संदेशों को संक्षिप्त करें';

  @override
  String get compactIndividualMessagesSubtitle =>
      'संदेशों में बार-बार आने वाले टेक्स्ट को छोटा कर दिया जाता है';

  @override
  String get announcementPinDuration => 'घोषणा पिन की अवधि';

  @override
  String get idleMessageAlertDuration => 'निष्क्रिय संदेश अलर्ट की अवधि';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'यदि इस अवधि तक कोई संदेश नहीं आता है और फिर एक नया संदेश आता है, तो अलर्ट ध्वनि बजेगी।';

  @override
  String get realtimeCashSubtitle => 'ETH या MATIC वॉलेट कनेक्ट करें';

  @override
  String get walletAddress => 'वॉलेट पता';

  @override
  String get streamlabsSubtitle => 'अपने Streamlabs डोनेशन देखें';

  @override
  String get streamElementsSubtitle => 'अपने StreamElements डोनेशन देखें';

  @override
  String get thirdPartyAuthError =>
      'हम्म, यह काम नहीं किया। पुनः प्रयास करें, या Discord पर पूछें?';

  @override
  String get companionAuthBrowserTooOld =>
      'आपका ब्राउज़र सीधे साइन इन करने के लिए बहुत पुराना है। किसी अन्य डिवाइस पर साइन इन करने के लिए अपने फ़ोन से इस QR कोड को स्कैन करें।';

  @override
  String get companionAuthScanQrCode =>
      'किसी अन्य डिवाइस पर साइन इन करने के लिए अपने फ़ोन से इस QR कोड को स्कैन करें।';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> ने सब्सक्राइब किया है!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> ने $monthsString महीनों के लिए फिर से सब्सक्राइब किया है!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> ने $countString सब्सक्रिप्शन गिफ़्ट किए हैं!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> ने $amountString Kicks भेजे!';
  }

  @override
  String get signInWithKick => 'Kick से साइन इन करें';

  @override
  String get textToSpeechTooManyMessages =>
      'यहाँ बहुत सारे संदेश हैं। टेक्स्ट टू स्पीच बंद कर दिया गया है';

  @override
  String get turnOffTextToSpeech => 'बंद करें';

  @override
  String get addToChat => 'चैट में जोड़ें';

  @override
  String get inChat => 'चैट में';

  @override
  String get removeFromChat => 'चैट से हटाएँ';

  @override
  String cantChatWithAccount(String provider) {
    return 'आपका $provider खाता यहाँ चैट नहीं कर सकता';
  }

  @override
  String get cantChatWithAccounts => 'आपके खाते यहाँ चैट नहीं कर सकते';

  @override
  String sendAMessageTo(String channel) {
    return '$channel को संदेश भेजें...';
  }

  @override
  String replaceChannel(String channel) {
    return '$channel को बदलें';
  }

  @override
  String get voicePacks => 'वॉइस पैक';

  @override
  String get voicePacksDescription =>
      'वॉइस पैक प्राकृतिक लगने वाली आवाज़ों में चैट पढ़ते हैं जो एक बार डाउनलोड होने के बाद आपके डिवाइस पर ऑफ़लाइन चलते हैं। ये आवाज़ें किसी व्यक्ति द्वारा रिकॉर्ड नहीं की गई हैं, बल्कि AI द्वारा मशीन से जनरेट की गई हैं।';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices आवाज़ें',
      one: '1 आवाज़',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count भाषाएँ',
      one: '1 भाषा',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'इस मॉडल का लाइसेंस (OpenRAIL-M) हानिकारक उपयोगों, जैसे लोगों की नकल करना या गलत जानकारी फैलाना, को प्रतिबंधित करता है, और ये प्रतिबंध आप पर भी लागू होते हैं।';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return '$pack को हटाएँ? इससे $size जगह खाली होगी।';
  }

  @override
  String get voicePackDownload => 'डाउनलोड करें';

  @override
  String get voicePackUpdate => 'अपडेट करें';

  @override
  String get voicePackWaitingForWifi => 'Wi-Fi की प्रतीक्षा हो रही है';

  @override
  String get voicePackUseMobileData => 'मोबाइल डेटा का उपयोग करें';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'डाउनलोड हो रहा है: $total में से $downloaded';
  }

  @override
  String get voicePackInstalling => 'इंस्टॉल हो रहा है';

  @override
  String voicePackInstallFailed(String pack) {
    return '$pack इंस्टॉल नहीं हो सका। अपना कनेक्शन जाँचें और पुनः प्रयास करें।';
  }

  @override
  String get voices => 'आवाज़ें';

  @override
  String get perViewerVoice => 'प्रत्येक दर्शक के लिए अलग आवाज़';

  @override
  String get perViewerVoiceSubtitle =>
      'प्रत्येक दर्शक को अपनी अलग आवाज़ मिलती है। आपके द्वारा चुनी गई आवाज़ अलर्ट पढ़ती है, या इसके बंद होने पर सब कुछ पढ़ती है।';

  @override
  String get streamLanguage => 'स्ट्रीम की भाषा';

  @override
  String get ttsEngineNeural => 'न्यूरल आवाज़ (डिवाइस पर)';

  @override
  String get ttsEngineSystem => 'सिस्टम आवाज़';

  @override
  String languageUnsupported(String language) {
    return 'आपके वॉइस पैक द्वारा $language समर्थित नहीं है; सिस्टम आवाज़ का उपयोग किया जाएगा';
  }

  @override
  String get neuralFallbackLowMemory =>
      'इस डिवाइस में न्यूरल आवाज़ों के लिए पर्याप्त मेमोरी नहीं है, इसलिए चैट सिस्टम आवाज़ से पढ़ी जाती है।';

  @override
  String get neuralFallbackLoadFailed =>
      'न्यूरल आवाज़ लोड नहीं हो सकी, इसलिए चैट सिस्टम आवाज़ से पढ़ी जाती है।';

  @override
  String get accounts => 'खाते';

  @override
  String get accountsSubtitle =>
      'जिस भी प्लेटफ़ॉर्म पर आप स्ट्रीम करते हैं उस पर साइन इन करें';

  @override
  String addProviderAccount(String provider) {
    return '$provider खाता जोड़ें';
  }

  @override
  String signInWithProvider(String provider) {
    return '$provider से साइन इन करें';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return '$provider पर $channel से साइन आउट करें?';
  }

  @override
  String get signOutOfAll => 'सभी खातों से साइन आउट करें';
}
