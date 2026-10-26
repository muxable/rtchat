// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get sendAMessage => 'સંદેશ મોકલો...';

  @override
  String get writeSomething => 'કંઈક લખો...';

  @override
  String get speakToTheCrowds => 'ભીડ સાથે વાત કરો...';

  @override
  String get shareYourThoughts => 'તમારા વિચારો શેર કરો...';

  @override
  String get saySomethingYouLittleBitch => 'કંઈક તો બોલ, નાલાયક...';

  @override
  String get search => 'શોધો';

  @override
  String get notSignedIn => 'સાઇન ઇન નથી';

  @override
  String get searchChannels => 'શોધો';

  @override
  String get raidAChannel => 'રેઇડ';

  @override
  String get noMessagesEmptyState => 'અહીં બધું શાંત છે.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count નવા સંદેશા',
      one: '1 નવો સંદેશ',
      zero: 'કોઈ નવા સંદેશા નથી',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Twitch વડે સાઇન ઇન કરો';

  @override
  String get signInError =>
      'સાઇન ઇન કરતી વખતે ભૂલ થઈ. કૃપા કરીને ફરી પ્રયાસ કરો.';

  @override
  String get continueAsGuest => 'મહેમાન તરીકે ચાલુ રાખો';

  @override
  String get signInToSendMessages => 'સંદેશા મોકલવા માટે સાઇન ઇન કરો';

  @override
  String get currentViewers => 'હાલના દર્શકો';

  @override
  String get textToSpeech => 'ટેક્સ્ટ ટુ સ્પીચ';

  @override
  String get streamPreview => 'સ્ટ્રીમ પૂર્વાવલોકન';

  @override
  String get activityFeed => 'પ્રવૃત્તિ ફીડ';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString વાગ્યે સ્ટ્રીમ ઓનલાઇન થઈ';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString વાગ્યે સ્ટ્રીમ ઓફલાઇન થઈ';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString વાગ્યે ચેટ સાફ કરવામાં આવી';
  }

  @override
  String get configureQuickLinks => 'ક્વિક લિંક્સ ગોઠવો';

  @override
  String get disableRainMode => 'રેઇન મોડ બંધ કરો';

  @override
  String get enableRainMode => 'રેઇન મોડ ચાલુ કરો';

  @override
  String get disableRainModeSubtitle => 'ઇન્ટરેક્શન ચાલુ થશે';

  @override
  String get enableRainModeSubtitle => 'ઇન્ટરેક્શન બંધ થશે';

  @override
  String get refreshAudioSources => 'ઓડિયો સ્ત્રોતો રિફ્રેશ કરો';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ઓડિયો સ્ત્રોતો રિફ્રેશ થયા',
      one: '1 ઓડિયો સ્ત્રોત રિફ્રેશ થયો',
      zero: 'કોઈ ઓડિયો સ્ત્રોત રિફ્રેશ થયો નથી',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'સેટિંગ્સ';

  @override
  String get signOut => 'સાઇન આઉટ કરો';

  @override
  String get cancel => 'રદ કરો';

  @override
  String get signOutConfirmation => 'શું તમે ખરેખર સાઇન આઉટ કરવા માંગો છો?';

  @override
  String get broadcaster => 'બ્રોડકાસ્ટર';

  @override
  String get moderators => 'મોડરેટર્સ';

  @override
  String get viewers => 'દર્શકો';

  @override
  String get communityVips => 'કમ્યુનિટી VIPs';

  @override
  String get searchViewers => 'દર્શકો શોધો';

  @override
  String get reconnecting => 'ફરીથી કનેક્ટ થઈ રહ્યું છે...';

  @override
  String get twitchBadges => 'Twitch બેજ';

  @override
  String get selectAll => 'બધું પસંદ કરો';

  @override
  String get quickLinks => 'ક્વિક લિંક્સ';

  @override
  String get swipeToDeleteQuickLinks =>
      'ક્વિક લિંક કાઢી નાખવા માટે ડાબે કે જમણે સ્વાઇપ કરો';

  @override
  String get quickLinksLabelHint => 'લેબલ';

  @override
  String get invalidUrlErrorText => 'આ માન્ય URL લાગતું નથી';

  @override
  String get duplicateUrlErrorText => 'આ લિંક પહેલેથી જ અસ્તિત્વમાં છે';

  @override
  String get or => 'અથવા';

  @override
  String get clearCookies => 'કૂકીઝ સાફ કરો';

  @override
  String get disabled => 'બંધ';

  @override
  String get twitchActivityFeed => 'Twitch પ્રવૃત્તિ ફીડ';

  @override
  String get signInToEnable => 'આને સક્ષમ કરવા માટે તમારે સાઇન ઇન કરવું પડશે';

  @override
  String get customUrl => 'કસ્ટમ URL';

  @override
  String get preview => 'પૂર્વાવલોકન';

  @override
  String get audioSources => 'ઓડિયો સ્ત્રોતો';

  @override
  String get enableOffStreamSwitchTitle =>
      'ઓફ-સ્ટ્રીમ ચાલુ કરો (વધુ બેટરી વપરાય છે)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'જ્યારે તમે ઓફલાઇન હોવ ત્યારે પણ ઓડિયો વાગશે';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'જ્યારે તમે લાઇવ હોવ ત્યારે જ ઓડિયો વાગશે';

  @override
  String get iosOggWarningTitle => 'અરે! સાંભળો!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS *.ogg મીડિયા ફાઇલોને સપોર્ટ કરતું નથી, જે Streamlabs પર ડિફોલ્ટ ફાઇલો હોય છે. ખાતરી કરો કે તમારા ઓડિયો સ્ત્રોતો અન્ય ફોર્મેટનો ઉપયોગ કરે છે, નહીં તો તે વાગશે નહીં.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'તમારી પ્રવૃત્તિ ફીડને કસ્ટમાઇઝ કરો';

  @override
  String get audioSourcesSubtitle => 'એલર્ટ અવાજો માટે વેબ સ્ત્રોતો ઉમેરો';

  @override
  String get quickLinksSubtitle =>
      'સામાન્ય રીતે વપરાતા ટૂલ્સ માટે શોર્ટકટ્સ ઉમેરો';

  @override
  String get chatHistory => 'ચેટ ઇતિહાસ';

  @override
  String get chatHistorySubtitle => 'ચેટનો દેખાવ બદલો';

  @override
  String get textToSpeechSubtitle => 'ટેક્સ્ટ ટુ સ્પીચ સેટિંગ્સ બદલો';

  @override
  String get events => 'ઇવેન્ટ્સ';

  @override
  String get eventsSubtitle => 'Twitch ઇવેન્ટ્સ ગોઠવો';

  @override
  String get thirdPartyServices => 'થર્ડ-પાર્ટી સેવાઓ';

  @override
  String get thirdPartyServicesSubtitle => 'થર્ડ-પાર્ટી સેવા સાથે કનેક્ટ થાઓ';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> તમને ફોલો કરી રહ્યા છે';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> અને <b>$displayNameTwo</b> તમને ફોલો કરી રહ્યા છે';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> અને અન્ય $numOthersString લોકો તમને ફોલો કરી રહ્યા છે';
  }

  @override
  String unmuteUser(String displayName) {
    return '$displayName ને અનમ્યૂટ કરો';
  }

  @override
  String muteUser(String displayName) {
    return '$displayName ને મ્યૂટ કરો';
  }

  @override
  String timeoutUser(String displayName) {
    return '$displayName ને ટાઇમ-આઉટ કરો';
  }

  @override
  String banUser(String displayName) {
    return '$displayName ને બેન કરો';
  }

  @override
  String unbanUser(String displayName) {
    return '$displayName ને અનબેન કરો';
  }

  @override
  String viewProfile(String displayName) {
    return '$displayName ની પ્રોફાઇલ જુઓ';
  }

  @override
  String get copyMessage => 'સંદેશ કોપી કરો';

  @override
  String get deleteMessage => 'સંદેશ કાઢી નાખો';

  @override
  String get longScrollNotification =>
      'તમે ઘણું બધું સ્ક્રોલ કરી રહ્યા છો, તમને નથી લાગતું?';

  @override
  String get stfu => 'ચૂપ રહો';

  @override
  String get globalEmotes => 'ગ્લોબલ ઇમોટ્સ';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ફોલોઅર્સ',
      one: '1 ફોલોઅર',
      zero: '0 ફોલોઅર્સ',
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
      other: '$countString દર્શકો',
      one: '1 દર્શક',
      zero: '0 દર્શકો',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'નમસ્તે! આનંદ થયો કે તમને સ્ટ્રીમ પૂર્વાવલોકન વાપરવું ગમે છે, પરંતુ ધ્યાન રાખજો કે તેમાં ઘણી બેટરી વપરાય છે. તેના વિના ચેટ વાંચવાથી તમારી બેટરી લાઇફ વધશે.';

  @override
  String get okay => 'ઠીક છે';

  @override
  String get streamPreviewLoading =>
      'લોડ થઈ રહ્યું છે (અથવા સ્ટ્રીમ ઓફલાઇન છે)...';

  @override
  String get copiedToClipboard => 'ક્લિપબોર્ડ પર કોપી કર્યું';

  @override
  String get audioSourcesRequirePermissions =>
      'ઓડિયો સ્ત્રોતો માટે પરવાનગીઓ જરૂરી છે';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'ઓડિયો સ્ત્રોતોનો ઉપયોગ કરવા માટે RealtimeChat ને અન્ય એપ્સ પર દેખાવાની મંજૂરી આપો.';

  @override
  String get audioSourcesRemoveButton => 'ઓડિયો સ્ત્રોતો દૂર કરો';

  @override
  String get audioSourcesOpenSettingsButton => 'સેટિંગ્સ ખોલો';

  @override
  String get flashOn => 'ફ્લેશ ચાલુ';

  @override
  String get flashOff => 'ફ્લેશ બંધ';

  @override
  String get durationOneSecond => '1 સેકન્ડ';

  @override
  String get durationOneMinute => '1 મિનિટ';

  @override
  String get durationTenMinutes => '10 મિનિટ';

  @override
  String get durationOneHour => '1 કલાક';

  @override
  String get durationSixHours => '6 કલાક';

  @override
  String get durationOneDay => '1 દિવસ';

  @override
  String get durationTwoDays => '2 દિવસ';

  @override
  String get durationOneWeek => '1 અઠવાડિયું';

  @override
  String get durationTwoWeeks => '2 અઠવાડિયા';

  @override
  String get durationOneSecondTimeoutPrompt => '1 સેકન્ડ માટે ટાઇમ-આઉટ કરો';

  @override
  String get durationOneMinuteTimeoutPrompt => '1 મિનિટ માટે ટાઇમ-આઉટ કરો';

  @override
  String get durationTenMinutesTimeoutPrompt => '10 મિનિટ માટે ટાઇમ-આઉટ કરો';

  @override
  String get durationOneHourTimeoutPrompt => '1 કલાક માટે ટાઇમ-આઉટ કરો';

  @override
  String get durationSixHoursTimeoutPrompt => '6 કલાક માટે ટાઇમ-આઉટ કરો';

  @override
  String get durationOneDayTimeoutPrompt => '1 દિવસ માટે ટાઇમ-આઉટ કરો';

  @override
  String get durationTwoDaysTimeoutPrompt => '2 દિવસ માટે ટાઇમ-આઉટ કરો';

  @override
  String get durationOneWeekTimeoutPrompt => '1 અઠવાડિયા માટે ટાઇમ-આઉટ કરો';

  @override
  String get durationTwoWeeksTimeoutPrompt => '2 અઠવાડિયા માટે ટાઇમ-આઉટ કરો';

  @override
  String get errorFetchingViewerList =>
      'અમે આ ચેનલ માટે દર્શકોની યાદી મેળવી શક્યા નથી';

  @override
  String get eventsTitle => 'ઇવેન્ટ્સ';

  @override
  String get followEventConfigTitle => 'ફોલો ઇવેન્ટ';

  @override
  String get customizeYourFollowEvent => 'તમારી ફોલો ઇવેન્ટને કસ્ટમાઇઝ કરો';

  @override
  String get subscribeEventConfigTitle => 'સબ્સ્ક્રાઇબ ઇવેન્ટ';

  @override
  String get customizeYourSubscriptionEvent =>
      'તમારી સબ્સ્ક્રિપ્શન ઇવેન્ટને કસ્ટમાઇઝ કરો';

  @override
  String get cheerEventConfigTitle => 'ચીયર ઇવેન્ટ';

  @override
  String get customizeYourCheerEvent => 'તમારી ચીયર ઇવેન્ટને કસ્ટમાઇઝ કરો';

  @override
  String get raidEventConfigTitle => 'રેઇડ ઇવેન્ટ';

  @override
  String get customizeYourRaidEvent => 'તમારી રેઇડ ઇવેન્ટને કસ્ટમાઇઝ કરો';

  @override
  String get hostEventConfigTitle => 'હોસ્ટ ઇવેન્ટ';

  @override
  String get customizeYourHostEvent => 'તમારી હોસ્ટ ઇવેન્ટને કસ્ટમાઇઝ કરો';

  @override
  String get hypetrainEventConfigTitle => 'હાઇપ ટ્રેન ઇવેન્ટ';

  @override
  String get customizeYourHypetrainEvent =>
      'તમારી હાઇપ ટ્રેન ઇવેન્ટને કસ્ટમાઇઝ કરો';

  @override
  String get pollEventConfigTitle => 'પોલ ઇવેન્ટ';

  @override
  String get customizeYourPollEvent => 'તમારી પોલ ઇવેન્ટને કસ્ટમાઇઝ કરો';

  @override
  String get predictionEventConfigTitle => 'પ્રેડિક્શન ઇવેન્ટ';

  @override
  String get customizeYourPredictionEvent =>
      'તમારી પ્રેડિક્શન ઇવેન્ટને કસ્ટમાઇઝ કરો';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'ચેનલ પોઇન્ટ રિડેમ્પશન ઇવેન્ટ';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'તમારી ચેનલ પોઇન્ટ રિડેમ્પશન ઇવેન્ટને કસ્ટમાઇઝ કરો';

  @override
  String get outgoingRaidEventConfigTitle => 'આઉટગોઇંગ રેઇડ ઇવેન્ટ';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'તમારી આઉટગોઇંગ રેઇડ ઇવેન્ટને કસ્ટમાઇઝ કરો';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> <b>$viewerCountString</b> દર્શકો સાથે રેઇડ કરી રહ્યા છે!';
  }

  @override
  String get shoutout => 'શાઉટઆઉટ';

  @override
  String raidingEventRaiding(String displayName) {
    return '<b>$displayName</b> પર રેઇડ થઈ રહી છે...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString સે.';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> એ રેઇડ કરી છે!';
  }

  @override
  String get raidingEventJoin => 'જોડાઓ';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b> ની રેઇડ રદ કરવામાં આવી હતી.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> એ ટિયર $tier પર સબ્સ્ક્રાઇબ કર્યું છે!';
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

    return '<b>$gifterUserName</b> એ $totalString ટિયર $tier સબ્સ્ક્રિપ્શન ભેટમાં આપ્યા છે, કુલ મળીને $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> એ ટિયર $tier પર $cumulativeMonthsString મહિના માટે સબ્સ્ક્રાઇબ કર્યું છે!';
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

    return '<b>$subscriberUserName</b> એ ટિયર $tier પર $durationMonthsString મહિના માટે અગાઉથી સબ્સ્ક્રાઇબ કર્યું છે, કુલ $cumulativeMonthsString મહિના!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> એ <b>$value $currency</b> ની ટિપ આપી.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'અજ્ઞાત વ્યક્તિએ <b>$value $currency</b> ની ટિપ આપી.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> એ StreamElements પર <b>$formattedAmount</b> ની ટિપ આપી.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> એ Streamlabs પર <b>$formattedAmount</b> ની ટિપ આપી.';
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

    return '<b>$redeemerUsername</b> એ <b>$rewardCostString</b> પોઇન્ટ્સમાં <b>$rewardName</b> રિડીમ કર્યું. $userInput';
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

    return '<b>$redeemerUsername</b> એ <b>$rewardCostString</b> પોઇન્ટ્સમાં <b>$rewardName</b> રિડીમ કર્યું.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> એ <b>$bitsString</b> બિટ્સ ચીયર કર્યા. $cheerMessage';
  }

  @override
  String get anonymous => 'અજ્ઞાત';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> <b>$viewersString</b> ના ગ્રુપ સાથે હોસ્ટ કરી રહ્યા છે.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'હાઇપ ટ્રેન લેવલ <b>$level</b> ચાલુ છે! <b>$progressPercent%</b> પૂર્ણ!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'હાઇપ ટ્રેન લેવલ <b>$levelString</b> સફળ રહ્યું.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'હાઇપ ટ્રેન લેવલ <b>$levelString</b> નિષ્ફળ રહ્યું.';
  }

  @override
  String get sampleMessage => 'આ લખાણને વાણીમાં ફેરવવા માટેનો નમૂના સંદેશ છે.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$authorએ કહ્યું: $text';
  }

  @override
  String get textToSpeechEnabled => 'ટેક્સ્ટ ટુ સ્પીચ ચાલુ કર્યું';

  @override
  String get textToSpeechDisabled => 'ટેક્સ્ટ ટુ સ્પીચ બંધ કર્યું';

  @override
  String get alertsEnabled => 'માત્ર એલર્ટ્સ';

  @override
  String get pinDuration => 'પિન કરવાનો સમયગાળો';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds સેકન્ડ',
      one: '1 સેકન્ડ',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes મિનિટ',
      one: '1 મિનિટ',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'ઇવેન્ટ ચાલુ કરો';

  @override
  String get showEventInChatHistory => 'ચેટ ઇતિહાસમાં ઇવેન્ટ બતાવો';

  @override
  String get enableShoutouts => 'શાઉટઆઉટ્સ ચાલુ કરો';

  @override
  String get enableShoutoutsSubtitle => 'રેઇડ કરનાર ચેનલની લિંક ચેટમાં મોકલો';

  @override
  String get raidConfigurationTitle => 'રેઇડ ગોઠવણી';

  @override
  String get cheerConfigurationTitle => 'ચીયર ગોઠવણી';

  @override
  String get followConfigurationTitle => 'ફોલો ગોઠવણી';

  @override
  String get outgoingRaidConfigurationTitle => 'આઉટગોઇંગ રેઇડ ગોઠવણી';

  @override
  String get hostConfigurationTitle => 'હોસ્ટ ગોઠવણી';

  @override
  String get channelPointConfigurationTitle => 'ચેનલ પોઇન્ટ ગોઠવણી';

  @override
  String get pollConfigurationTitle => 'પોલ ગોઠવણી';

  @override
  String get hypetrainConfigurationTitle => 'હાઇપ ટ્રેન ગોઠવણી';

  @override
  String get subscriptionConfigurationTitle => 'સબ્સ્ક્રિપ્શન ગોઠવણી';

  @override
  String get predictionConfigurationTitle => 'પ્રેડિક્શન ગોઠવણી';

  @override
  String get unfulfilledRewardsPinDuration =>
      'અપૂર્ણ રિવોર્ડ્સ માટે વધારાનો પિન સમયગાળો';

  @override
  String get pollPinDuration => 'પરિણામ નક્કી થયા પછી પિન કરવાનો સમયગાળો';

  @override
  String get hypetrainPinDuration =>
      'હાઇપ ટ્રેન પૂરી થયા પછી પિન કરવાનો સમયગાળો';

  @override
  String get enableGiftedSubscriptions =>
      'વ્યક્તિગત ભેટમાં મળેલા સબ્સ્ક્રિપ્શન ચાલુ કરો';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'ભેટમાં મળેલું દરેક સબ્સ્ક્રિપ્શન બતાવો';

  @override
  String get settingsBackupTitle => 'સેટિંગ્સ બેકઅપ અને રિસ્ટોર';

  @override
  String get cloudBackup => 'ક્લાઉડ બેકઅપ';

  @override
  String get lastBackupNever => 'છેલ્લું બેકઅપ: ક્યારેય નહીં';

  @override
  String get backUp => 'બેકઅપ લો';

  @override
  String get restore => 'રિસ્ટોર કરો';

  @override
  String get localBackup => 'લોકલ બેકઅપ';

  @override
  String get exportSettings => 'નિકાસ કરો';

  @override
  String get importSettings => 'આયાત કરો';

  @override
  String get showViewerAndFollowerCount => 'દર્શકો અને ફોલોઅર્સની સંખ્યા બતાવો';

  @override
  String get screenOrientation => 'સ્ક્રીન ઓરિએન્ટેશન';

  @override
  String get appTheme => 'એપ થીમ';

  @override
  String get systemDefault => 'સિસ્ટમ';

  @override
  String get portrait => 'પોર્ટ્રેટ';

  @override
  String get landscape => 'લેન્ડસ્કેપ';

  @override
  String get lightTheme => 'લાઇટ';

  @override
  String get darkTheme => 'ડાર્ક';

  @override
  String get openSourceTitle => 'RealtimeChat ઓપન સોર્સ છે';

  @override
  String get openSourceSubtitle => 'અમને GitHub પર શોધો!';

  @override
  String get discordSubtitle => 'Muxable Discord માં જોડાઓ!';

  @override
  String get earlyTestersThanks =>
      'બગ રિપોર્ટ્સ મોકલનાર તમામ પ્રારંભિક ટેસ્ટર્સનો આભાર!';

  @override
  String get discoModeEnabled => '🕺 ડિસ્કો મોડ ચાલુ થયો! :D';

  @override
  String get discoModeDisabled => '🕺 ડિસ્કો મોડ બંધ થયો D:';

  @override
  String get playSampleMessage => 'નમૂના સંદેશ વગાડો';

  @override
  String get textToSpeechRate => 'ટેક્સ્ટ ટુ સ્પીચની ઝડપ';

  @override
  String get textToSpeechPitch => 'ટેક્સ્ટ ટુ સ્પીચની પિચ';

  @override
  String get muteBots => 'બોટ્સ માટે ટેક્સ્ટ ટુ સ્પીચ મ્યૂટ કરો';

  @override
  String get muteEmotes => 'ટેક્સ્ટ ટુ સ્પીચમાં બધા ઇમોટ્સ મ્યૂટ કરો';

  @override
  String get muteViewerNames => 'ટેક્સ્ટ ટુ સ્પીચમાં દર્શકોના નામ મ્યૂટ કરો';

  @override
  String get subscribersOnly => 'માત્ર સબ્સ્ક્રાઇબર્સ';

  @override
  String get fontSize => 'ફોન્ટનું કદ';

  @override
  String get usernameContrastBoost => 'યુઝરનેમ કોન્ટ્રાસ્ટ બૂસ્ટ';

  @override
  String get twitchBadgeSettings => 'Twitch બેજ સેટિંગ્સ';

  @override
  String get twitchBadgeSettingsSubtitle => 'કયા બેજ દેખાય તે નિયંત્રિત કરો';

  @override
  String get showDeletedMessages => 'કાઢી નાખેલા સંદેશા બતાવો';

  @override
  String get deletedMessagesGreyedOut =>
      'કાઢી નાખેલા સંદેશા ઝાંખા (ગ્રે) દેખાશે';

  @override
  String get deletedMessagesRemoved => 'કાઢી નાખેલા સંદેશા દૂર કરવામાં આવશે';

  @override
  String get showLoginNames => 'લોગિન નામ બતાવો';

  @override
  String get loginNamesShown =>
      'જો લોગિન નામ ડિસ્પ્લે નામ કરતા અલગ હશે તો તે બતાવવામાં આવશે';

  @override
  String get loginNamesHidden => 'લોગિન નામ છુપાવવામાં આવશે';

  @override
  String get compactMessages => 'સંદેશા સંક્ષિપ્ત કરો';

  @override
  String get dontCompactMessages => 'સંદેશા સંક્ષિપ્ત ન કરો';

  @override
  String get dontCompactMessagesSubtitle =>
      'સંદેશા કોઈપણ ફેરફાર વિના બતાવવામાં આવે છે';

  @override
  String get compactIndividualMessages => 'વ્યક્તિગત સંદેશા સંક્ષિપ્ત કરો';

  @override
  String get compactIndividualMessagesSubtitle =>
      'સંદેશામાં વારંવાર આવતા લખાણને ટૂંકું કરવામાં આવે છે';

  @override
  String get announcementPinDuration => 'જાહેરાત પિન કરવાનો સમયગાળો';

  @override
  String get idleMessageAlertDuration => 'નિષ્ક્રિય સંદેશ એલર્ટનો સમયગાળો';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'જો આ સમયગાળા દરમિયાન કોઈ સંદેશ ન આવે અને પછી નવો સંદેશ આવે, તો એલર્ટ અવાજ વાગશે.';

  @override
  String get realtimeCashSubtitle => 'ETH અથવા MATIC વોલેટ કનેક્ટ કરો';

  @override
  String get walletAddress => 'વોલેટ સરનામું';

  @override
  String get streamlabsSubtitle => 'તમારા Streamlabs ડોનેશન જુઓ';

  @override
  String get streamElementsSubtitle => 'તમારા StreamElements ડોનેશન જુઓ';

  @override
  String get thirdPartyAuthError =>
      'હમ્મ, તે કામ ન કર્યું. ફરી પ્રયાસ કરો, અથવા Discord પર પૂછો?';

  @override
  String get companionAuthBrowserTooOld =>
      'તમારું બ્રાઉઝર સીધા સાઇન ઇન કરવા માટે ઘણું જૂનું છે. બીજા ડિવાઇસ પર સાઇન ઇન કરવા માટે તમારા ફોનથી આ QR કોડ સ્કેન કરો.';

  @override
  String get companionAuthScanQrCode =>
      'બીજા ડિવાઇસ પર સાઇન ઇન કરવા માટે તમારા ફોનથી આ QR કોડ સ્કેન કરો.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> એ સબ્સ્ક્રાઇબ કર્યું છે!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> એ $monthsString મહિના માટે ફરીથી સબ્સ્ક્રાઇબ કર્યું છે!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> એ $countString સબ્સ્ક્રિપ્શન ભેટમાં આપ્યા છે!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> એ $amountString Kicks મોકલ્યા!';
  }

  @override
  String get signInWithKick => 'Kick વડે સાઇન ઇન કરો';

  @override
  String get textToSpeechTooManyMessages =>
      'ઘણા બધા સંદેશા છે. ટેક્સ્ટ ટુ સ્પીચ બંધ કરવામાં આવ્યું છે';

  @override
  String get turnOffTextToSpeech => 'બંધ કરો';

  @override
  String get addToChat => 'ચેટમાં ઉમેરો';

  @override
  String get inChat => 'ચેટમાં';

  @override
  String get removeFromChat => 'ચેટમાંથી દૂર કરો';

  @override
  String cantChatWithAccount(String provider) {
    return 'તમારું $provider એકાઉન્ટ અહીં ચેટ કરી શકતું નથી';
  }

  @override
  String get cantChatWithAccounts => 'તમારા એકાઉન્ટ્સ અહીં ચેટ કરી શકતા નથી';

  @override
  String sendAMessageTo(String channel) {
    return '$channel ને સંદેશ મોકલો...';
  }

  @override
  String replaceChannel(String channel) {
    return '$channel ને બદલો';
  }

  @override
  String get voicePacks => 'વોઇસ પેક્સ';

  @override
  String get voicePacksDescription =>
      'વોઇસ પેક્સ કુદરતી લાગતા અવાજોમાં ચેટ વાંચે છે જે એકવાર ડાઉનલોડ થયા પછી તમારા ડિવાઇસ પર ઓફલાઇન ચાલે છે. આ અવાજો કોઈ વ્યક્તિ દ્વારા રેકોર્ડ કરવામાં આવ્યા નથી, પરંતુ AI દ્વારા મશીનથી જનરેટ કરવામાં આવ્યા છે.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices અવાજો',
      one: '1 અવાજ',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ભાષાઓ',
      one: '1 ભાષા',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'આ મોડેલનું લાઇસન્સ (OpenRAIL-M) હાનિકારક ઉપયોગો, જેમ કે લોકોની નકલ કરવી અથવા ખોટી માહિતી ફેલાવવી, પર પ્રતિબંધ મૂકે છે અને આ નિયંત્રણો તમને પણ લાગુ પડે છે.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return '$pack કાઢી નાખવું છે? આનાથી $size જગ્યા ખાલી થશે.';
  }

  @override
  String get voicePackDownload => 'ડાઉનલોડ કરો';

  @override
  String get voicePackUpdate => 'અપડેટ કરો';

  @override
  String get voicePackWaitingForWifi => 'Wi-Fi ની રાહ જોઈ રહ્યું છે';

  @override
  String get voicePackUseMobileData => 'મોબાઇલ ડેટાનો ઉપયોગ કરો';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'ડાઉનલોડ થઈ રહ્યું છે: $total માંથી $downloaded';
  }

  @override
  String get voicePackInstalling => 'ઇન્સ્ટોલ થઈ રહ્યું છે';

  @override
  String voicePackInstallFailed(String pack) {
    return '$pack ઇન્સ્ટોલ થઈ શક્યું નહીં. તમારું કનેક્શન તપાસો અને ફરી પ્રયાસ કરો.';
  }

  @override
  String get voices => 'અવાજો';

  @override
  String get perViewerVoice => 'દરેક દર્શક દીઠ અવાજ';

  @override
  String get perViewerVoiceSubtitle =>
      'દરેક દર્શકને પોતાનો અલગ અવાજ મળે છે. તમે પસંદ કરેલો અવાજ એલર્ટ્સ વાંચે છે, અથવા જ્યારે આ બંધ હોય ત્યારે બધું જ વાંચે છે.';

  @override
  String get streamLanguage => 'સ્ટ્રીમની ભાષા';

  @override
  String get ttsEngineNeural => 'ન્યુરલ અવાજ (ડિવાઇસ પર)';

  @override
  String get ttsEngineSystem => 'સિસ્ટમ અવાજ';

  @override
  String languageUnsupported(String language) {
    return 'તમારા વોઇસ પેક્સ દ્વારા $language સપોર્ટેડ નથી; સિસ્ટમ અવાજનો ઉપયોગ કરવામાં આવશે';
  }

  @override
  String get neuralFallbackLowMemory =>
      'આ ડિવાઇસમાં ન્યુરલ અવાજો માટે પૂરતી મેમરી નથી, તેથી ચેટ સિસ્ટમ અવાજથી વાંચવામાં આવે છે.';

  @override
  String get neuralFallbackLoadFailed =>
      'ન્યુરલ અવાજ લોડ થઈ શક્યો નહીં, તેથી ચેટ સિસ્ટમ અવાજથી વાંચવામાં આવે છે.';

  @override
  String get accounts => 'એકાઉન્ટ્સ';

  @override
  String get accountsSubtitle =>
      'તમે જે પ્લેટફોર્મ પર સ્ટ્રીમ કરો છો તે દરેકમાં સાઇન ઇન કરો';

  @override
  String addProviderAccount(String provider) {
    return '$provider એકાઉન્ટ ઉમેરો';
  }

  @override
  String signInWithProvider(String provider) {
    return '$provider વડે સાઇન ઇન કરો';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return '$provider પર $channel માંથી સાઇન આઉટ કરવું છે?';
  }

  @override
  String get signOutOfAll => 'બધા એકાઉન્ટ્સમાંથી સાઇન આઉટ કરો';
}
