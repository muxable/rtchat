// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get sendAMessage => 'సందేశం పంపండి...';

  @override
  String get writeSomething => 'ఏదైనా రాయండి...';

  @override
  String get speakToTheCrowds => 'ప్రేక్షకులతో మాట్లాడండి...';

  @override
  String get shareYourThoughts => 'మీ ఆలోచనలను పంచుకోండి...';

  @override
  String get saySomethingYouLittleBitch => 'ఏదైనా చెప్పు, చిన్న వెధవ...';

  @override
  String get search => 'వెతకండి';

  @override
  String get notSignedIn => 'సైన్ ఇన్ చేయలేదు';

  @override
  String get searchChannels => 'వెతకండి';

  @override
  String get raidAChannel => 'రైడ్';

  @override
  String get noMessagesEmptyState => 'ఇక్కడ అంతా నిశ్శబ్దంగా ఉంది.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count కొత్త సందేశాలు',
      one: '1 కొత్త సందేశం',
      zero: 'కొత్త సందేశాలు లేవు',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Twitchతో సైన్ ఇన్ చేయండి';

  @override
  String get signInError =>
      'సైన్ ఇన్ చేసేటప్పుడు లోపం ఏర్పడింది. దయచేసి మళ్లీ ప్రయత్నించండి.';

  @override
  String get continueAsGuest => 'అతిథిగా కొనసాగండి';

  @override
  String get signInToSendMessages => 'సందేశాలు పంపడానికి సైన్ ఇన్ చేయండి';

  @override
  String get currentViewers => 'ప్రస్తుత వీక్షకులు';

  @override
  String get textToSpeech => 'వచనం నుండి మాట';

  @override
  String get streamPreview => 'స్ట్రీమ్ ప్రివ్యూ';

  @override
  String get activityFeed => 'యాక్టివిటీ ఫీడ్';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeStringకి స్ట్రీమ్ ఆన్‌లైన్‌లోకి వచ్చింది';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeStringకి స్ట్రీమ్ ఆఫ్‌లైన్‌లోకి వెళ్లింది';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeStringకి చాట్ క్లియర్ చేయబడింది';
  }

  @override
  String get configureQuickLinks => 'క్విక్ లింక్‌లను కాన్ఫిగర్ చేయండి';

  @override
  String get disableRainMode => 'రెయిన్ మోడ్‌ను నిలిపివేయండి';

  @override
  String get enableRainMode => 'రెయిన్ మోడ్‌ను ప్రారంభించండి';

  @override
  String get disableRainModeSubtitle => 'పరస్పర చర్య ప్రారంభించబడుతుంది';

  @override
  String get enableRainModeSubtitle => 'పరస్పర చర్య నిలిపివేయబడుతుంది';

  @override
  String get refreshAudioSources => 'ఆడియో వనరులను రిఫ్రెష్ చేయండి';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ఆడియో వనరులు రిఫ్రెష్ చేయబడ్డాయి',
      one: '1 ఆడియో వనరు రిఫ్రెష్ చేయబడింది',
      zero: 'ఆడియో వనరులు ఏవీ రిఫ్రెష్ కాలేదు',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'సెట్టింగ్‌లు';

  @override
  String get signOut => 'సైన్ అవుట్';

  @override
  String get cancel => 'రద్దు చేయండి';

  @override
  String get signOutConfirmation =>
      'మీరు ఖచ్చితంగా సైన్ అవుట్ చేయాలనుకుంటున్నారా?';

  @override
  String get broadcaster => 'బ్రాడ్‌కాస్టర్';

  @override
  String get moderators => 'మోడరేటర్లు';

  @override
  String get viewers => 'వీక్షకులు';

  @override
  String get communityVips => 'కమ్యూనిటీ VIPలు';

  @override
  String get searchViewers => 'వీక్షకులను వెతకండి';

  @override
  String get reconnecting => 'మళ్లీ కనెక్ట్ అవుతోంది...';

  @override
  String get twitchBadges => 'Twitch బ్యాడ్జ్‌లు';

  @override
  String get selectAll => 'అన్నీ ఎంచుకోండి';

  @override
  String get quickLinks => 'క్విక్ లింక్‌లు';

  @override
  String get swipeToDeleteQuickLinks =>
      'క్విక్ లింక్‌ను తొలగించడానికి ఎడమ లేదా కుడి వైపుకు స్వైప్ చేయండి';

  @override
  String get quickLinksLabelHint => 'లేబుల్';

  @override
  String get invalidUrlErrorText =>
      'ఇది చెల్లుబాటు అయ్యే URL లాగా కనిపించడం లేదు';

  @override
  String get duplicateUrlErrorText => 'ఈ లింక్ ఇప్పటికే ఉంది';

  @override
  String get or => 'లేదా';

  @override
  String get clearCookies => 'కుకీలను క్లియర్ చేయండి';

  @override
  String get disabled => 'నిలిపివేయబడింది';

  @override
  String get twitchActivityFeed => 'Twitch యాక్టివిటీ ఫీడ్';

  @override
  String get signInToEnable =>
      'దీన్ని ప్రారంభించడానికి మీరు తప్పనిసరిగా సైన్ ఇన్ చేయాలి';

  @override
  String get customUrl => 'కస్టమ్ URL';

  @override
  String get preview => 'ప్రివ్యూ';

  @override
  String get audioSources => 'ఆడియో వనరులు';

  @override
  String get enableOffStreamSwitchTitle =>
      'ఆఫ్-స్ట్రీమ్‌లో ప్రారంభించండి (ఎక్కువ బ్యాటరీని ఉపయోగిస్తుంది)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'మీరు ఆఫ్‌లైన్‌లో ఉన్నప్పుడు కూడా ఆడియో ప్లే అవుతుంది';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'మీరు లైవ్‌లో ఉన్నప్పుడు మాత్రమే ఆడియో ప్లే అవుతుంది';

  @override
  String get iosOggWarningTitle => 'అయ్యో! వినండి!';

  @override
  String get iosOggWarningSubtitle =>
      'Streamlabsలో డిఫాల్ట్ ఫైళ్లుగా ఉండే *.ogg మీడియా ఫైళ్లకు iOS మద్దతు ఇవ్వదు. మీ ఆడియో వనరులు వేరొక ఫార్మాట్‌ను ఉపయోగిస్తున్నాయని నిర్ధారించుకోండి, లేకపోతే అవి ప్లే కావు.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'మీ యాక్టివిటీ ఫీడ్‌ను అనుకూలీకరించండి';

  @override
  String get audioSourcesSubtitle =>
      'అలర్ట్ సౌండ్‌ల కోసం వెబ్ వనరులను జోడించండి';

  @override
  String get quickLinksSubtitle =>
      'తరచుగా ఉపయోగించే సాధనాలకు షార్ట్‌కట్‌లను జోడించండి';

  @override
  String get chatHistory => 'చాట్ చరిత్ర';

  @override
  String get chatHistorySubtitle => 'చాట్ రూపాన్ని మార్చండి';

  @override
  String get textToSpeechSubtitle => 'వచనం నుండి మాట సెట్టింగ్‌లను మార్చండి';

  @override
  String get events => 'ఈవెంట్‌లు';

  @override
  String get eventsSubtitle => 'Twitch ఈవెంట్‌లను కాన్ఫిగర్ చేయండి';

  @override
  String get thirdPartyServices => 'థర్డ్-పార్టీ సేవలు';

  @override
  String get thirdPartyServicesSubtitle => 'థర్డ్-పార్టీ సేవకు కనెక్ట్ అవ్వండి';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> మిమ్మల్ని ఫాలో అవుతున్నారు';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> మరియు <b>$displayNameTwo</b> మిమ్మల్ని ఫాలో అవుతున్నారు';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b>, మరియు మరో $numOthersString మంది మిమ్మల్ని ఫాలో అవుతున్నారు';
  }

  @override
  String unmuteUser(String displayName) {
    return '$displayNameని అన్‌మ్యూట్ చేయండి';
  }

  @override
  String muteUser(String displayName) {
    return '$displayNameని మ్యూట్ చేయండి';
  }

  @override
  String timeoutUser(String displayName) {
    return '$displayNameని టైమ్-అవుట్ చేయండి';
  }

  @override
  String banUser(String displayName) {
    return '$displayNameని బ్యాన్ చేయండి';
  }

  @override
  String unbanUser(String displayName) {
    return '$displayNameపై బ్యాన్ తొలగించండి';
  }

  @override
  String viewProfile(String displayName) {
    return '$displayName ప్రొఫైల్‌ను చూడండి';
  }

  @override
  String get copyMessage => 'సందేశాన్ని కాపీ చేయండి';

  @override
  String get deleteMessage => 'సందేశాన్ని తొలగించండి';

  @override
  String get longScrollNotification =>
      'మీరు చాలా దూరం స్క్రోల్ చేస్తున్నారని మీకు అనిపించడం లేదా?';

  @override
  String get stfu => 'నోరు మూయ్';

  @override
  String get globalEmotes => 'గ్లోబల్ ఎమోట్‌లు';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ఫాలోవర్లు',
      one: '1 ఫాలోవర్',
      zero: '0 ఫాలోవర్లు',
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
      other: '$countString వీక్షకులు',
      one: '1 వీక్షకుడు',
      zero: '0 వీక్షకులు',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'నమస్కారం! మీరు స్ట్రీమ్ ప్రివ్యూను ఉపయోగించడం మాకు సంతోషంగా ఉంది, కానీ ఇది చాలా బ్యాటరీని ఉపయోగిస్తుందని గమనించండి. ఇది లేకుండా చాట్ చదవడం వల్ల మీ బ్యాటరీ లైఫ్ పెరుగుతుంది.';

  @override
  String get okay => 'సరే';

  @override
  String get streamPreviewLoading =>
      'లోడ్ అవుతోంది (లేదా స్ట్రీమ్ ఆఫ్‌లైన్‌లో ఉంది)...';

  @override
  String get copiedToClipboard => 'క్లిప్‌బోర్డ్‌కు కాపీ చేయబడింది';

  @override
  String get audioSourcesRequirePermissions => 'ఆడియో వనరులకు అనుమతులు అవసరం';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'ఆడియో వనరులను ఉపయోగించడానికి ఇతర యాప్‌ల పైన కనిపించేందుకు RealtimeChatకు అనుమతి ఇవ్వండి.';

  @override
  String get audioSourcesRemoveButton => 'ఆడియో వనరులను తీసివేయండి';

  @override
  String get audioSourcesOpenSettingsButton => 'సెట్టింగ్‌లను తెరవండి';

  @override
  String get flashOn => 'ఫ్లాష్ ఆన్';

  @override
  String get flashOff => 'ఫ్లాష్ ఆఫ్';

  @override
  String get durationOneSecond => '1 సెకను';

  @override
  String get durationOneMinute => '1 నిమిషం';

  @override
  String get durationTenMinutes => '10 నిమిషాలు';

  @override
  String get durationOneHour => '1 గంట';

  @override
  String get durationSixHours => '6 గంటలు';

  @override
  String get durationOneDay => '1 రోజు';

  @override
  String get durationTwoDays => '2 రోజులు';

  @override
  String get durationOneWeek => '1 వారం';

  @override
  String get durationTwoWeeks => '2 వారాలు';

  @override
  String get durationOneSecondTimeoutPrompt => '1 సెకను పాటు టైమ్-అవుట్ చేయండి';

  @override
  String get durationOneMinuteTimeoutPrompt =>
      '1 నిమిషం పాటు టైమ్-అవుట్ చేయండి';

  @override
  String get durationTenMinutesTimeoutPrompt =>
      '10 నిమిషాల పాటు టైమ్-అవుట్ చేయండి';

  @override
  String get durationOneHourTimeoutPrompt => '1 గంట పాటు టైమ్-అవుట్ చేయండి';

  @override
  String get durationSixHoursTimeoutPrompt => '6 గంటల పాటు టైమ్-అవుట్ చేయండి';

  @override
  String get durationOneDayTimeoutPrompt => '1 రోజు పాటు టైమ్-అవుట్ చేయండి';

  @override
  String get durationTwoDaysTimeoutPrompt => '2 రోజుల పాటు టైమ్-అవుట్ చేయండి';

  @override
  String get durationOneWeekTimeoutPrompt => '1 వారం పాటు టైమ్-అవుట్ చేయండి';

  @override
  String get durationTwoWeeksTimeoutPrompt => '2 వారాల పాటు టైమ్-అవుట్ చేయండి';

  @override
  String get errorFetchingViewerList =>
      'ఈ ఛానెల్ కోసం వీక్షకుల జాబితాను మేము పొందలేకపోయాము';

  @override
  String get eventsTitle => 'ఈవెంట్‌లు';

  @override
  String get followEventConfigTitle => 'ఫాలో ఈవెంట్';

  @override
  String get customizeYourFollowEvent => 'మీ ఫాలో ఈవెంట్‌ను అనుకూలీకరించండి';

  @override
  String get subscribeEventConfigTitle => 'సబ్‌స్క్రైబ్ ఈవెంట్';

  @override
  String get customizeYourSubscriptionEvent =>
      'మీ సబ్‌స్క్రిప్షన్ ఈవెంట్‌ను అనుకూలీకరించండి';

  @override
  String get cheerEventConfigTitle => 'చీర్ ఈవెంట్';

  @override
  String get customizeYourCheerEvent => 'మీ చీర్ ఈవెంట్‌ను అనుకూలీకరించండి';

  @override
  String get raidEventConfigTitle => 'రైడ్ ఈవెంట్';

  @override
  String get customizeYourRaidEvent => 'మీ రైడ్ ఈవెంట్‌ను అనుకూలీకరించండి';

  @override
  String get hostEventConfigTitle => 'హోస్ట్ ఈవెంట్';

  @override
  String get customizeYourHostEvent => 'మీ హోస్ట్ ఈవెంట్‌ను అనుకూలీకరించండి';

  @override
  String get hypetrainEventConfigTitle => 'హైప్ ట్రైన్ ఈవెంట్';

  @override
  String get customizeYourHypetrainEvent =>
      'మీ హైప్ ట్రైన్ ఈవెంట్‌ను అనుకూలీకరించండి';

  @override
  String get pollEventConfigTitle => 'పోల్ ఈవెంట్';

  @override
  String get customizeYourPollEvent => 'మీ పోల్ ఈవెంట్‌ను అనుకూలీకరించండి';

  @override
  String get predictionEventConfigTitle => 'ప్రెడిక్షన్ ఈవెంట్';

  @override
  String get customizeYourPredictionEvent =>
      'మీ ప్రెడిక్షన్ ఈవెంట్‌ను అనుకూలీకరించండి';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'ఛానెల్ పాయింట్ రిడెంప్షన్ ఈవెంట్';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'మీ ఛానెల్ పాయింట్ రిడెంప్షన్ ఈవెంట్‌ను అనుకూలీకరించండి';

  @override
  String get outgoingRaidEventConfigTitle => 'అవుట్‌గోయింగ్ రైడ్ ఈవెంట్';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'మీ అవుట్‌గోయింగ్ రైడ్ ఈవెంట్‌ను అనుకూలీకరించండి';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> <b>$viewerCountString</b> మంది వీక్షకులతో రైడ్ చేస్తున్నారు!';
  }

  @override
  String get shoutout => 'షౌట్‌అవుట్';

  @override
  String raidingEventRaiding(String displayName) {
    return '<b>$displayName</b>పై రైడ్ జరుగుతోంది...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsStringసె';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> రైడ్ చేశారు!';
  }

  @override
  String get raidingEventJoin => 'చేరండి';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b> రైడ్ రద్దు చేయబడింది.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> టియర్ $tier వద్ద సబ్‌స్క్రైబ్ చేసుకున్నారు!';
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

    return '<b>$gifterUserName</b> $totalString టియర్ $tier సబ్‌లను బహుమతిగా ఇచ్చారు, మొత్తం $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> టియర్ $tier వద్ద $cumulativeMonthsString నెలల పాటు సబ్‌స్క్రైబ్ చేసుకున్నారు!';
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

    return '<b>$subscriberUserName</b> టియర్ $tier వద్ద ముందుగానే $durationMonthsString నెలల పాటు సబ్‌స్క్రైబ్ చేసుకున్నారు, మొత్తం $cumulativeMonthsString నెలలు!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> <b>$value $currency</b> టిప్ ఇచ్చారు.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'అజ్ఞాత వ్యక్తి <b>$value $currency</b> టిప్ ఇచ్చారు.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return 'StreamElementsలో <b>$name</b> <b>$formattedAmount</b> టిప్ ఇచ్చారు.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return 'Streamlabsలో <b>$name</b> <b>$formattedAmount</b> టిప్ ఇచ్చారు.';
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

    return '<b>$redeemerUsername</b> <b>$rewardCostString</b> పాయింట్లతో <b>$rewardName</b>ను రిడీమ్ చేసుకున్నారు. $userInput';
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

    return '<b>$redeemerUsername</b> <b>$rewardCostString</b> పాయింట్లతో <b>$rewardName</b>ను రిడీమ్ చేసుకున్నారు.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> <b>$bitsString</b> బిట్‌లతో చీర్ చేశారు. $cheerMessage';
  }

  @override
  String get anonymous => 'అజ్ఞాత వ్యక్తి';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> <b>$viewersString</b> మంది బృందంతో హోస్ట్ చేస్తున్నారు.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'హైప్ ట్రైన్ లెవల్ <b>$level</b> కొనసాగుతోంది! <b>$progressPercent%</b> పూర్తయింది!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'హైప్ ట్రైన్ లెవల్ <b>$levelString</b> విజయవంతమైంది.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'హైప్ ట్రైన్ లెవల్ <b>$levelString</b> విఫలమైంది.';
  }

  @override
  String get sampleMessage => 'ఇది వచనాన్ని మాటగా మార్చడానికి ఒక నమూనా సందేశం.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author చెప్పారు: $text';
  }

  @override
  String get textToSpeechEnabled => 'వచనం నుండి మాట ప్రారంభించబడింది';

  @override
  String get textToSpeechDisabled => 'వచనం నుండి మాట నిలిపివేయబడింది';

  @override
  String get alertsEnabled => 'అలర్ట్‌లు మాత్రమే';

  @override
  String get pinDuration => 'పిన్ వ్యవధి';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds సెకన్లు',
      one: '1 సెకను',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes నిమిషాలు',
      one: '1 నిమిషం',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'ఈవెంట్‌ను ప్రారంభించండి';

  @override
  String get showEventInChatHistory => 'చాట్ చరిత్రలో ఈవెంట్‌ను చూపించండి';

  @override
  String get enableShoutouts => 'షౌట్‌అవుట్‌లను ప్రారంభించండి';

  @override
  String get enableShoutoutsSubtitle =>
      'రైడ్ చేస్తున్న ఛానెల్ లింక్‌ను చాట్‌కు పంపండి';

  @override
  String get raidConfigurationTitle => 'రైడ్ కాన్ఫిగరేషన్';

  @override
  String get cheerConfigurationTitle => 'చీర్ కాన్ఫిగరేషన్';

  @override
  String get followConfigurationTitle => 'ఫాలో కాన్ఫిగరేషన్';

  @override
  String get outgoingRaidConfigurationTitle =>
      'అవుట్‌గోయింగ్ రైడ్ కాన్ఫిగరేషన్';

  @override
  String get hostConfigurationTitle => 'హోస్ట్ కాన్ఫిగరేషన్';

  @override
  String get channelPointConfigurationTitle => 'ఛానెల్ పాయింట్ కాన్ఫిగరేషన్';

  @override
  String get pollConfigurationTitle => 'పోల్ కాన్ఫిగరేషన్';

  @override
  String get hypetrainConfigurationTitle => 'హైప్ ట్రైన్ కాన్ఫిగరేషన్';

  @override
  String get subscriptionConfigurationTitle => 'సబ్‌స్క్రిప్షన్ కాన్ఫిగరేషన్';

  @override
  String get predictionConfigurationTitle => 'ప్రెడిక్షన్ కాన్ఫిగరేషన్';

  @override
  String get unfulfilledRewardsPinDuration =>
      'పూర్తి కాని రివార్డ్‌ల కోసం అదనపు పిన్ వ్యవధి';

  @override
  String get pollPinDuration => 'ఫలితం ఖరారైన తర్వాత పిన్ వ్యవధి';

  @override
  String get hypetrainPinDuration => 'హైప్ ట్రైన్ ముగిసిన తర్వాత పిన్ వ్యవధి';

  @override
  String get enableGiftedSubscriptions =>
      'వ్యక్తిగత బహుమతి సబ్‌స్క్రిప్షన్‌లను ప్రారంభించండి';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'బహుమతిగా ఇచ్చిన ప్రతి సబ్‌స్క్రిప్షన్‌ను చూపించండి';

  @override
  String get settingsBackupTitle => 'సెట్టింగ్‌ల బ్యాకప్ మరియు పునరుద్ధరణ';

  @override
  String get cloudBackup => 'క్లౌడ్ బ్యాకప్';

  @override
  String get lastBackupNever => 'చివరి బ్యాకప్: ఎప్పుడూ లేదు';

  @override
  String get backUp => 'బ్యాకప్ చేయండి';

  @override
  String get restore => 'పునరుద్ధరించండి';

  @override
  String get localBackup => 'లోకల్ బ్యాకప్';

  @override
  String get exportSettings => 'ఎగుమతి';

  @override
  String get importSettings => 'దిగుమతి';

  @override
  String get showViewerAndFollowerCount =>
      'వీక్షకుల మరియు ఫాలోవర్ల సంఖ్యను చూపించండి';

  @override
  String get screenOrientation => 'స్క్రీన్ ఓరియంటేషన్';

  @override
  String get appTheme => 'యాప్ థీమ్';

  @override
  String get systemDefault => 'సిస్టమ్';

  @override
  String get portrait => 'పోర్ట్రెయిట్';

  @override
  String get landscape => 'ల్యాండ్‌స్కేప్';

  @override
  String get lightTheme => 'లైట్';

  @override
  String get darkTheme => 'డార్క్';

  @override
  String get openSourceTitle => 'RealtimeChat ఓపెన్ సోర్స్';

  @override
  String get openSourceSubtitle => 'GitHubలో మమ్మల్ని కనుగొనండి!';

  @override
  String get discordSubtitle => 'Muxable Discordలో చేరండి!';

  @override
  String get earlyTestersThanks =>
      'బగ్ రిపోర్ట్‌లను పంపిన ప్రారంభ టెస్టర్లందరికీ ధన్యవాదాలు!';

  @override
  String get discoModeEnabled => '🕺 డిస్కో మోడ్ ప్రారంభించబడింది! :D';

  @override
  String get discoModeDisabled => '🕺 డిస్కో మోడ్ నిలిపివేయబడింది D:';

  @override
  String get playSampleMessage => 'నమూనా సందేశాన్ని ప్లే చేయండి';

  @override
  String get textToSpeechRate => 'వచనం నుండి మాట వేగం';

  @override
  String get textToSpeechPitch => 'వచనం నుండి మాట పిచ్';

  @override
  String get muteBots => 'బాట్‌ల కోసం వచనం నుండి మాటను మ్యూట్ చేయండి';

  @override
  String get muteEmotes => 'వచనం నుండి మాటలో అన్ని ఎమోట్‌లను మ్యూట్ చేయండి';

  @override
  String get muteViewerNames =>
      'వచనం నుండి మాటలో వీక్షకుల పేర్లను మ్యూట్ చేయండి';

  @override
  String get subscribersOnly => 'సబ్‌స్క్రైబర్‌లు మాత్రమే';

  @override
  String get fontSize => 'ఫాంట్ పరిమాణం';

  @override
  String get usernameContrastBoost => 'యూజర్‌నేమ్ కాంట్రాస్ట్ బూస్ట్';

  @override
  String get twitchBadgeSettings => 'Twitch బ్యాడ్జ్ సెట్టింగ్‌లు';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'ఏ బ్యాడ్జ్‌లు కనిపించాలో నియంత్రించండి';

  @override
  String get showDeletedMessages => 'తొలగించిన సందేశాలను చూపించండి';

  @override
  String get deletedMessagesGreyedOut =>
      'తొలగించిన సందేశాలు బూడిద రంగులో కనిపిస్తాయి';

  @override
  String get deletedMessagesRemoved => 'తొలగించిన సందేశాలు తీసివేయబడతాయి';

  @override
  String get showLoginNames => 'లాగిన్ పేర్లను చూపించండి';

  @override
  String get loginNamesShown =>
      'ప్రదర్శన పేరు కంటే భిన్నంగా ఉంటే లాగిన్ పేర్లు చూపబడతాయి';

  @override
  String get loginNamesHidden => 'లాగిన్ పేర్లు దాచబడతాయి';

  @override
  String get compactMessages => 'సందేశాలను కుదించండి';

  @override
  String get dontCompactMessages => 'సందేశాలను కుదించవద్దు';

  @override
  String get dontCompactMessagesSubtitle => 'సందేశాలు మార్పు లేకుండా చూపబడతాయి';

  @override
  String get compactIndividualMessages => 'వ్యక్తిగత సందేశాలను కుదించండి';

  @override
  String get compactIndividualMessagesSubtitle =>
      'సందేశాలలో పునరావృతమయ్యే వచనం తగ్గించబడుతుంది';

  @override
  String get announcementPinDuration => 'ప్రకటన పిన్ వ్యవధి';

  @override
  String get idleMessageAlertDuration => 'నిష్క్రియ సందేశ అలర్ట్ వ్యవధి';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'ఈ సమయం వరకు ఎటువంటి సందేశాలు లేకుండా ఉండి, కొత్త సందేశం వచ్చినప్పుడు అలర్ట్ సౌండ్ ప్లే అవుతుంది.';

  @override
  String get realtimeCashSubtitle => 'ETH లేదా MATIC వాలెట్‌ను కనెక్ట్ చేయండి';

  @override
  String get walletAddress => 'వాలెట్ చిరునామా';

  @override
  String get streamlabsSubtitle => 'మీ Streamlabs విరాళాలను చూడండి';

  @override
  String get streamElementsSubtitle => 'మీ StreamElements విరాళాలను చూడండి';

  @override
  String get thirdPartyAuthError =>
      'అయ్యో, అది పని చేయలేదు. మళ్లీ ప్రయత్నించండి, లేదా Discordలో అడగండి?';

  @override
  String get companionAuthBrowserTooOld =>
      'నేరుగా సైన్ ఇన్ చేయడానికి మీ బ్రౌజర్ చాలా పాతది. మరొక పరికరంలో సైన్ ఇన్ చేయడానికి మీ ఫోన్‌తో ఈ QR కోడ్‌ను స్కాన్ చేయండి.';

  @override
  String get companionAuthScanQrCode =>
      'మరొక పరికరంలో సైన్ ఇన్ చేయడానికి మీ ఫోన్‌తో ఈ QR కోడ్‌ను స్కాన్ చేయండి.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> సబ్‌స్క్రైబ్ చేసుకున్నారు!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> $monthsString నెలల పాటు మళ్లీ సబ్‌స్క్రైబ్ చేసుకున్నారు!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> $countString సబ్‌లను బహుమతిగా ఇచ్చారు!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> $amountString Kicks పంపారు!';
  }

  @override
  String get signInWithKick => 'Kickతో సైన్ ఇన్ చేయండి';

  @override
  String get textToSpeechTooManyMessages =>
      'చాలా ఎక్కువ సందేశాలు ఉన్నాయి. వచనం నుండి మాట నిలిపివేయబడింది';

  @override
  String get turnOffTextToSpeech => 'ఆఫ్ చేయండి';

  @override
  String get addToChat => 'చాట్‌కు జోడించండి';

  @override
  String get inChat => 'చాట్‌లో';

  @override
  String get removeFromChat => 'చాట్ నుండి తీసివేయండి';

  @override
  String cantChatWithAccount(String provider) {
    return 'మీ $provider ఖాతా ఇక్కడ చాట్ చేయలేదు';
  }

  @override
  String get cantChatWithAccounts => 'మీ ఖాతాలు ఇక్కడ చాట్ చేయలేవు';

  @override
  String sendAMessageTo(String channel) {
    return '$channelకి సందేశం పంపండి...';
  }

  @override
  String replaceChannel(String channel) {
    return '$channelని భర్తీ చేయండి';
  }

  @override
  String get voicePacks => 'వాయిస్ ప్యాక్‌లు';

  @override
  String get voicePacksDescription =>
      'వాయిస్ ప్యాక్‌లు డౌన్‌లోడ్ చేసిన తర్వాత ఆఫ్‌లైన్‌లో మీ పరికరంలో నడిచే సహజమైన గొంతులతో చాట్‌ను చదువుతాయి. ఈ గొంతులు వ్యక్తి రికార్డ్ చేసినవి కావు, AI ద్వారా మెషీన్-జనరేట్ చేయబడినవి.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices గొంతులు',
      one: '1 గొంతు',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count భాషలు',
      one: '1 భాష',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'ఈ మోడల్ లైసెన్స్ (OpenRAIL-M) ఇతరులను అనుకరించడం లేదా తప్పుడు సమాచారాన్ని వ్యాప్తి చేయడం వంటి హానికరమైన ఉపయోగాలను నిషేధిస్తుంది, మరియు ఈ పరిమితులు మీకు కూడా వర్తిస్తాయి.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return '$packని తొలగించాలా? దీనివల్ల $size ఖాళీ అవుతుంది.';
  }

  @override
  String get voicePackDownload => 'డౌన్‌లోడ్';

  @override
  String get voicePackUpdate => 'అప్‌డేట్';

  @override
  String get voicePackWaitingForWifi => 'Wi-Fi కోసం వేచి ఉంది';

  @override
  String get voicePackUseMobileData => 'మొబైల్ డేటాను ఉపయోగించండి';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'డౌన్‌లోడ్ అవుతోంది: $totalలో $downloaded';
  }

  @override
  String get voicePackInstalling => 'ఇన్‌స్టాల్ అవుతోంది';

  @override
  String voicePackInstallFailed(String pack) {
    return '$packని ఇన్‌స్టాల్ చేయడం సాధ్యం కాలేదు. మీ కనెక్షన్‌ను తనిఖీ చేసి, మళ్లీ ప్రయత్నించండి.';
  }

  @override
  String get voices => 'గొంతులు';

  @override
  String get perViewerVoice => 'ప్రతి వీక్షకుడికి ప్రత్యేక గొంతు';

  @override
  String get perViewerVoiceSubtitle =>
      'ప్రతి వీక్షకుడికి వారి స్వంత గొంతు వస్తుంది. మీరు ఎంచుకున్న గొంతు అలర్ట్‌లను చదువుతుంది, లేదా ఇది ఆఫ్‌లో ఉన్నప్పుడు అన్నీ చదువుతుంది.';

  @override
  String get streamLanguage => 'స్ట్రీమ్ భాష';

  @override
  String get ttsEngineNeural => 'న్యూరల్ వాయిస్ (పరికరంలో)';

  @override
  String get ttsEngineSystem => 'సిస్టమ్ వాయిస్';

  @override
  String languageUnsupported(String language) {
    return 'మీ వాయిస్ ప్యాక్‌లలో $languageకి మద్దతు లేదు; సిస్టమ్ వాయిస్ ఉపయోగించబడుతుంది';
  }

  @override
  String get neuralFallbackLowMemory =>
      'న్యూరల్ వాయిస్‌ల కోసం ఈ పరికరంలో తగినంత మెమరీ లేదు, కాబట్టి చాట్ సిస్టమ్ వాయిస్‌తో చదవబడుతుంది.';

  @override
  String get neuralFallbackLoadFailed =>
      'న్యూరల్ వాయిస్ లోడ్ కాలేకపోయింది, కాబట్టి చాట్ సిస్టమ్ వాయిస్‌తో చదవబడుతుంది.';

  @override
  String get accounts => 'ఖాతాలు';

  @override
  String get accountsSubtitle =>
      'మీరు స్ట్రీమ్ చేసే ప్రతి ప్లాట్‌ఫారమ్‌కు సైన్ ఇన్ చేయండి';

  @override
  String addProviderAccount(String provider) {
    return '$provider ఖాతాను జోడించండి';
  }

  @override
  String signInWithProvider(String provider) {
    return '$providerతో సైన్ ఇన్ చేయండి';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return '$providerలో $channel నుండి సైన్ అవుట్ చేయాలా?';
  }

  @override
  String get signOutOfAll => 'అన్ని ఖాతాల నుండి సైన్ అవుట్ చేయండి';
}
