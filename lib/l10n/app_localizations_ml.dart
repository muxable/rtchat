// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get sendAMessage => 'ഒരു സന്ദേശം അയയ്ക്കുക...';

  @override
  String get writeSomething => 'എന്തെങ്കിലും എഴുതുക...';

  @override
  String get speakToTheCrowds => 'ജനക്കൂട്ടത്തോട് സംസാരിക്കുക...';

  @override
  String get shareYourThoughts => 'നിങ്ങളുടെ ചിന്തകൾ പങ്കുവെക്കുക...';

  @override
  String get saySomethingYouLittleBitch => 'എന്തെങ്കിലും പറയെടാ പട്ടി...';

  @override
  String get search => 'തിരയുക';

  @override
  String get notSignedIn => 'സൈൻ ഇൻ ചെയ്തിട്ടില്ല';

  @override
  String get searchChannels => 'തിരയുക';

  @override
  String get raidAChannel => 'റെയ്ഡ്';

  @override
  String get noMessagesEmptyState => 'ഇവിടെ വളരെ ശാന്തമാണ്.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count പുതിയ സന്ദേശങ്ങൾ',
      one: '1 പുതിയ സന്ദേശം',
      zero: 'പുതിയ സന്ദേശങ്ങളില്ല',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Twitch വഴി സൈൻ ഇൻ ചെയ്യുക';

  @override
  String get signInError =>
      'സൈൻ ഇൻ ചെയ്യുമ്പോൾ ഒരു പിശക് സംഭവിച്ചു. ദയവായി വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get continueAsGuest => 'അതിഥിയായി തുടരുക';

  @override
  String get signInToSendMessages => 'സന്ദേശങ്ങൾ അയയ്ക്കാൻ സൈൻ ഇൻ ചെയ്യുക';

  @override
  String get currentViewers => 'നിലവിലെ പ്രേക്ഷകർ';

  @override
  String get textToSpeech => 'വാചകം ശബ്ദമാക്കൽ';

  @override
  String get streamPreview => 'സ്ട്രീം പ്രിവ്യൂ';

  @override
  String get activityFeed => 'ആക്റ്റിവിറ്റി ഫീഡ്';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString-ന് സ്ട്രീം ഓൺലൈനായി';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString-ന് സ്ട്രീം ഓഫ്‌ലൈനായി';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString-ന് ചാറ്റ് മായ്ച്ചു';
  }

  @override
  String get configureQuickLinks => 'ക്വിക്ക് ലിങ്കുകൾ ക്രമീകരിക്കുക';

  @override
  String get disableRainMode => 'റെയിൻ മോഡ് പ്രവർത്തനരഹിതമാക്കുക';

  @override
  String get enableRainMode => 'റെയിൻ മോഡ് സജീവമാക്കുക';

  @override
  String get disableRainModeSubtitle => 'ഇടപെടൽ സജീവമാക്കും';

  @override
  String get enableRainModeSubtitle => 'ഇടപെടൽ പ്രവർത്തനരഹിതമാക്കും';

  @override
  String get refreshAudioSources => 'ഓഡിയോ ഉറവിടങ്ങൾ പുതുക്കുക';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഓഡിയോ ഉറവിടങ്ങൾ പുതുക്കി',
      one: '1 ഓഡിയോ ഉറവിടം പുതുക്കി',
      zero: 'ഓഡിയോ ഉറവിടങ്ങളൊന്നും പുതുക്കിയില്ല',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'ക്രമീകരണങ്ങൾ';

  @override
  String get signOut => 'സൈൻ ഔട്ട്';

  @override
  String get cancel => 'റദ്ദാക്കുക';

  @override
  String get signOutConfirmation => 'നിങ്ങൾക്ക് തീർച്ചയായും സൈൻ ഔട്ട് ചെയ്യണോ?';

  @override
  String get broadcaster => 'ബ്രോഡ്‌കാസ്റ്റർ';

  @override
  String get moderators => 'മോഡറേറ്റർമാർ';

  @override
  String get viewers => 'പ്രേക്ഷകർ';

  @override
  String get communityVips => 'കമ്മ്യൂണിറ്റി VIP-കൾ';

  @override
  String get searchViewers => 'പ്രേക്ഷകരെ തിരയുക';

  @override
  String get reconnecting => 'വീണ്ടും ബന്ധിപ്പിക്കുന്നു...';

  @override
  String get twitchBadges => 'Twitch ബാഡ്ജുകൾ';

  @override
  String get selectAll => 'എല്ലാം തിരഞ്ഞെടുക്കുക';

  @override
  String get quickLinks => 'ക്വിക്ക് ലിങ്കുകൾ';

  @override
  String get swipeToDeleteQuickLinks =>
      'ക്വിക്ക് ലിങ്ക് ഇല്ലാതാക്കാൻ ഇടത്തോട്ടോ വലത്തോട്ടോ സ്വൈപ്പ് ചെയ്യുക';

  @override
  String get quickLinksLabelHint => 'ലേബൽ';

  @override
  String get invalidUrlErrorText => 'ഇതൊരു സാധുവായ URL ആണെന്ന് തോന്നുന്നില്ല';

  @override
  String get duplicateUrlErrorText => 'ഈ ലിങ്ക് ഇതിനകം നിലവിലുണ്ട്';

  @override
  String get or => 'അല്ലെങ്കിൽ';

  @override
  String get clearCookies => 'കുക്കികൾ മായ്ക്കുക';

  @override
  String get disabled => 'പ്രവർത്തനരഹിതമാക്കി';

  @override
  String get twitchActivityFeed => 'Twitch ആക്റ്റിവിറ്റി ഫീഡ്';

  @override
  String get signInToEnable => 'ഇത് സജീവമാക്കാൻ നിങ്ങൾ സൈൻ ഇൻ ചെയ്തിരിക്കണം';

  @override
  String get customUrl => 'കസ്റ്റം URL';

  @override
  String get preview => 'പ്രിവ്യൂ';

  @override
  String get audioSources => 'ഓഡിയോ ഉറവിടങ്ങൾ';

  @override
  String get enableOffStreamSwitchTitle =>
      'ഓഫ്-സ്ട്രീം സജീവമാക്കുക (കൂടുതൽ ബാറ്ററി ഉപയോഗിക്കുന്നു)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'നിങ്ങൾ ഓഫ്‌ലൈനായിരിക്കുമ്പോഴും ഓഡിയോ പ്ലേ ചെയ്യും';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'നിങ്ങൾ ലൈവായിരിക്കുമ്പോൾ മാത്രമേ ഓഡിയോ പ്ലേ ചെയ്യൂ';

  @override
  String get iosOggWarningTitle => 'ഹേയ്! ശ്രദ്ധിക്കൂ!';

  @override
  String get iosOggWarningSubtitle =>
      'Streamlabs-ലെ ഡിഫോൾട്ട് ഫയലുകളായ *.ogg മീഡിയ ഫയലുകളെ iOS പിന്തുണയ്ക്കുന്നില്ല. നിങ്ങളുടെ ഓഡിയോ ഉറവിടങ്ങൾ മറ്റൊരു ഫോർമാറ്റാണ് ഉപയോഗിക്കുന്നതെന്ന് ഉറപ്പാക്കുക, അല്ലെങ്കിൽ അവ പ്ലേ ചെയ്യില്ല.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle =>
      'നിങ്ങളുടെ ആക്റ്റിവിറ്റി ഫീഡ് ഇഷ്ടാനുസൃതമാക്കുക';

  @override
  String get audioSourcesSubtitle =>
      'അലേർട്ട് ശബ്ദങ്ങൾക്കായി വെബ് ഉറവിടങ്ങൾ ചേർക്കുക';

  @override
  String get quickLinksSubtitle =>
      'സാധാരണയായി ഉപയോഗിക്കുന്ന ടൂളുകളിലേക്ക് ഷോർട്ട്കട്ടുകൾ ചേർക്കുക';

  @override
  String get chatHistory => 'ചാറ്റ് ചരിത്രം';

  @override
  String get chatHistorySubtitle => 'ചാറ്റിന്റെ രൂപം മാറ്റുക';

  @override
  String get textToSpeechSubtitle => 'വാചകം ശബ്ദമാക്കൽ ക്രമീകരണങ്ങൾ മാറ്റുക';

  @override
  String get events => 'ഇവന്റുകൾ';

  @override
  String get eventsSubtitle => 'Twitch ഇവന്റുകൾ ക്രമീകരിക്കുക';

  @override
  String get thirdPartyServices => 'തേർഡ്-പാർട്ടി സേവനങ്ങൾ';

  @override
  String get thirdPartyServicesSubtitle =>
      'ഒരു തേർഡ്-പാർട്ടി സേവനവുമായി ബന്ധിപ്പിക്കുക';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> നിങ്ങളെ ഫോളോ ചെയ്യുന്നു';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b>, <b>$displayNameTwo</b> എന്നിവർ നിങ്ങളെ ഫോളോ ചെയ്യുന്നു';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> എന്നിവരും മറ്റ് $numOthersString പേരും നിങ്ങളെ ഫോളോ ചെയ്യുന്നു';
  }

  @override
  String unmuteUser(String displayName) {
    return '$displayName എന്നയാളെ അൺമ്യൂട്ട് ചെയ്യുക';
  }

  @override
  String muteUser(String displayName) {
    return '$displayName എന്നയാളെ മ്യൂട്ട് ചെയ്യുക';
  }

  @override
  String timeoutUser(String displayName) {
    return '$displayName എന്നയാളെ താൽക്കാലികമായി വിലക്കുക';
  }

  @override
  String banUser(String displayName) {
    return '$displayName എന്നയാളെ വിലക്കുക';
  }

  @override
  String unbanUser(String displayName) {
    return '$displayName എന്നയാളുടെ വിലക്ക് നീക്കുക';
  }

  @override
  String viewProfile(String displayName) {
    return '$displayName എന്നയാളുടെ പ്രൊഫൈൽ കാണുക';
  }

  @override
  String get copyMessage => 'സന്ദേശം പകർത്തുക';

  @override
  String get deleteMessage => 'സന്ദേശം ഇല്ലാതാക്കുക';

  @override
  String get longScrollNotification =>
      'നിങ്ങൾ ഒരുപാട് ദൂരം സ്ക്രോൾ ചെയ്യുന്നുണ്ടല്ലോ, അല്ലേ?';

  @override
  String get stfu => 'മിണ്ടാതിരിക്ക്';

  @override
  String get globalEmotes => 'ഗ്ലോബൽ ഇമോട്ടുകൾ';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ഫോളോവേഴ്‌സ്',
      one: '1 ഫോളോവർ',
      zero: '0 ഫോളോവേഴ്‌സ്',
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
      other: '$countString പ്രേക്ഷകർ',
      one: '1 പ്രേക്ഷകൻ',
      zero: '0 പ്രേക്ഷകർ',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'ഹലോ! നിങ്ങൾക്ക് സ്ട്രീം പ്രിവ്യൂ ഇഷ്ടപ്പെട്ടതിൽ സന്തോഷം, പക്ഷേ ഇത് ധാരാളം ബാറ്ററി ഉപയോഗിക്കുന്നുവെന്ന് ഓർമ്മിക്കുക. ഇതില്ലാതെ ചാറ്റ് വായിക്കുന്നത് ബാറ്ററി ആയുസ്സ് വർദ്ധിപ്പിക്കും.';

  @override
  String get okay => 'ശരി';

  @override
  String get streamPreviewLoading =>
      'ലോഡ് ചെയ്യുന്നു (അല്ലെങ്കിൽ സ്ട്രീം ഓഫ്‌ലൈനാണ്)...';

  @override
  String get copiedToClipboard => 'ക്ലിപ്പ്ബോർഡിലേക്ക് പകർത്തി';

  @override
  String get audioSourcesRequirePermissions =>
      'ഓഡിയോ ഉറവിടങ്ങൾക്ക് അനുമതികൾ ആവശ്യമാണ്';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'ഓഡിയോ ഉറവിടങ്ങൾ ഉപയോഗിക്കാൻ മറ്റ് ആപ്പുകൾക്ക് മുകളിൽ പ്രദർശിപ്പിക്കുന്നതിന് RealtimeChat-ന് അനുമതി നൽകുക.';

  @override
  String get audioSourcesRemoveButton => 'ഓഡിയോ ഉറവിടങ്ങൾ നീക്കം ചെയ്യുക';

  @override
  String get audioSourcesOpenSettingsButton => 'ക്രമീകരണങ്ങൾ തുറക്കുക';

  @override
  String get flashOn => 'ഫ്ലാഷ് ഓൺ';

  @override
  String get flashOff => 'ഫ്ലാഷ് ഓഫ്';

  @override
  String get durationOneSecond => '1 സെക്കൻഡ്';

  @override
  String get durationOneMinute => '1 മിനിറ്റ്';

  @override
  String get durationTenMinutes => '10 മിനിറ്റ്';

  @override
  String get durationOneHour => '1 മണിക്കൂർ';

  @override
  String get durationSixHours => '6 മണിക്കൂർ';

  @override
  String get durationOneDay => '1 ദിവസം';

  @override
  String get durationTwoDays => '2 ദിവസം';

  @override
  String get durationOneWeek => '1 ആഴ്ച';

  @override
  String get durationTwoWeeks => '2 ആഴ്ച';

  @override
  String get durationOneSecondTimeoutPrompt =>
      '1 സെക്കൻഡ് താൽക്കാലികമായി വിലക്കുക';

  @override
  String get durationOneMinuteTimeoutPrompt =>
      '1 മിനിറ്റ് താൽക്കാലികമായി വിലക്കുക';

  @override
  String get durationTenMinutesTimeoutPrompt =>
      '10 മിനിറ്റ് താൽക്കാലികമായി വിലക്കുക';

  @override
  String get durationOneHourTimeoutPrompt =>
      '1 മണിക്കൂർ താൽക്കാലികമായി വിലക്കുക';

  @override
  String get durationSixHoursTimeoutPrompt =>
      '6 മണിക്കൂർ താൽക്കാലികമായി വിലക്കുക';

  @override
  String get durationOneDayTimeoutPrompt => '1 ദിവസം താൽക്കാലികമായി വിലക്കുക';

  @override
  String get durationTwoDaysTimeoutPrompt => '2 ദിവസം താൽക്കാലികമായി വിലക്കുക';

  @override
  String get durationOneWeekTimeoutPrompt => '1 ആഴ്ച താൽക്കാലികമായി വിലക്കുക';

  @override
  String get durationTwoWeeksTimeoutPrompt => '2 ആഴ്ച താൽക്കാലികമായി വിലക്കുക';

  @override
  String get errorFetchingViewerList =>
      'ഈ ചാനലിന്റെ പ്രേക്ഷകരുടെ പട്ടിക ലഭ്യമാക്കാൻ ഞങ്ങൾക്ക് കഴിഞ്ഞില്ല';

  @override
  String get eventsTitle => 'ഇവന്റുകൾ';

  @override
  String get followEventConfigTitle => 'ഫോളോ ഇവന്റ്';

  @override
  String get customizeYourFollowEvent =>
      'നിങ്ങളുടെ ഫോളോ ഇവന്റ് ഇഷ്ടാനുസൃതമാക്കുക';

  @override
  String get subscribeEventConfigTitle => 'സബ്‌സ്‌ക്രൈബ് ഇവന്റ്';

  @override
  String get customizeYourSubscriptionEvent =>
      'നിങ്ങളുടെ സബ്‌സ്‌ക്രിപ്‌ഷൻ ഇവന്റ് ഇഷ്ടാനുസൃതമാക്കുക';

  @override
  String get cheerEventConfigTitle => 'ചിയർ ഇവന്റ്';

  @override
  String get customizeYourCheerEvent =>
      'നിങ്ങളുടെ ചിയർ ഇവന്റ് ഇഷ്ടാനുസൃതമാക്കുക';

  @override
  String get raidEventConfigTitle => 'റെയ്ഡ് ഇവന്റ്';

  @override
  String get customizeYourRaidEvent =>
      'നിങ്ങളുടെ റെയ്ഡ് ഇവന്റ് ഇഷ്ടാനുസൃതമാക്കുക';

  @override
  String get hostEventConfigTitle => 'ഹോസ്റ്റ് ഇവന്റ്';

  @override
  String get customizeYourHostEvent =>
      'നിങ്ങളുടെ ഹോസ്റ്റ് ഇവന്റ് ഇഷ്ടാനുസൃതമാക്കുക';

  @override
  String get hypetrainEventConfigTitle => 'ഹൈപ്പ് ട്രെയിൻ ഇവന്റ്';

  @override
  String get customizeYourHypetrainEvent =>
      'നിങ്ങളുടെ ഹൈപ്പ് ട്രെയിൻ ഇവന്റ് ഇഷ്ടാനുസൃതമാക്കുക';

  @override
  String get pollEventConfigTitle => 'പോൾ ഇവന്റ്';

  @override
  String get customizeYourPollEvent => 'നിങ്ങളുടെ പോൾ ഇവന്റ് ഇഷ്ടാനുസൃതമാക്കുക';

  @override
  String get predictionEventConfigTitle => 'പ്രവചന ഇവന്റ്';

  @override
  String get customizeYourPredictionEvent =>
      'നിങ്ങളുടെ പ്രവചന ഇവന്റ് ഇഷ്ടാനുസൃതമാക്കുക';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'ചാനൽ പോയിന്റ് റിഡംപ്ഷൻ ഇവന്റ്';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'നിങ്ങളുടെ ചാനൽ പോയിന്റ് റിഡംപ്ഷൻ ഇവന്റ് ഇഷ്ടാനുസൃതമാക്കുക';

  @override
  String get outgoingRaidEventConfigTitle => 'ഔട്ട്‌ഗോയിംഗ് റെയ്ഡ് ഇവന്റ്';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'നിങ്ങളുടെ ഔട്ട്‌ഗോയിംഗ് റെയ്ഡ് ഇവന്റ് ഇഷ്ടാനുസൃതമാക്കുക';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b>, <b>$viewerCountString</b> പ്രേക്ഷകരുമായി റെയ്ഡ് ചെയ്യുന്നു!';
  }

  @override
  String get shoutout => 'ഷൗട്ട്ഔട്ട്';

  @override
  String raidingEventRaiding(String displayName) {
    return '<b>$displayName</b> എന്ന ചാനലിലേക്ക് റെയ്ഡ് ചെയ്യുന്നു...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString സെ';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> റെയ്ഡ് ചെയ്തു!';
  }

  @override
  String get raidingEventJoin => 'ചേരുക';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b> എന്നയാളുടെ റെയ്ഡ് റദ്ദാക്കി.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> ടിയർ $tier-ൽ സബ്‌സ്‌ക്രൈബ് ചെയ്തിരിക്കുന്നു!';
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

    return '<b>$gifterUserName</b>, $totalString ടിയർ $tier സബ്‌സ്‌ക്രിപ്‌ഷനുകൾ സമ്മാനിച്ചു, ആകെ $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> ടിയർ $tier-ൽ $cumulativeMonthsString മാസത്തേക്ക് സബ്‌സ്‌ക്രൈബ് ചെയ്തിരിക്കുന്നു!';
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

    return '<b>$subscriberUserName</b> ടിയർ $tier-ൽ $durationMonthsString മാസത്തേക്ക് മുൻകൂട്ടി സബ്‌സ്‌ക്രൈബ് ചെയ്തിരിക്കുന്നു, ആകെ $cumulativeMonthsString മാസം!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b>, <b>$value $currency</b> ടിപ്പ് നൽകി.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'അജ്ഞാതൻ <b>$value $currency</b> ടിപ്പ് നൽകി.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return 'StreamElements-ൽ <b>$name</b>, <b>$formattedAmount</b> ടിപ്പ് നൽകി.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return 'Streamlabs-ൽ <b>$name</b>, <b>$formattedAmount</b> ടിപ്പ് നൽകി.';
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

    return '<b>$redeemerUsername</b>, <b>$rewardCostString</b> പോയിന്റുകൾക്ക് <b>$rewardName</b> റിഡീം ചെയ്തു. $userInput';
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

    return '<b>$redeemerUsername</b>, <b>$rewardCostString</b> പോയിന്റുകൾക്ക് <b>$rewardName</b> റിഡീം ചെയ്തു.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b>, <b>$bitsString</b> ബിറ്റുകൾ നൽകി ചിയർ ചെയ്തു. $cheerMessage';
  }

  @override
  String get anonymous => 'അജ്ഞാതൻ';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b>, <b>$viewersString</b> പേരുടെ സംഘത്തോടൊപ്പം ഹോസ്റ്റ് ചെയ്യുന്നു.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'ഹൈപ്പ് ട്രെയിൻ ലെവൽ <b>$level</b> പുരോഗമിക്കുന്നു! <b>$progressPercent%</b> പൂർത്തിയായി!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'ഹൈപ്പ് ട്രെയിൻ ലെവൽ <b>$levelString</b> വിജയിച്ചു.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'ഹൈപ്പ് ട്രെയിൻ ലെവൽ <b>$levelString</b> പരാജയപ്പെട്ടു.';
  }

  @override
  String get sampleMessage =>
      'വാചകം ശബ്ദമാക്കുന്നതിനുള്ള ഒരു മാതൃകാ സന്ദേശമാണിത്.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author പറഞ്ഞു: $text';
  }

  @override
  String get textToSpeechEnabled => 'വാചകം ശബ്ദമാക്കൽ സജീവമാക്കി';

  @override
  String get textToSpeechDisabled => 'വാചകം ശബ്ദമാക്കൽ പ്രവർത്തനരഹിതമാക്കി';

  @override
  String get alertsEnabled => 'അലേർട്ടുകൾ മാത്രം';

  @override
  String get pinDuration => 'പിൻ ദൈർഘ്യം';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds സെക്കൻഡ്',
      one: '1 സെക്കൻഡ്',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes മിനിറ്റ്',
      one: '1 മിനിറ്റ്',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'ഇവന്റ് സജീവമാക്കുക';

  @override
  String get showEventInChatHistory => 'ചാറ്റ് ചരിത്രത്തിൽ ഇവന്റ് കാണിക്കുക';

  @override
  String get enableShoutouts => 'ഷൗട്ട്ഔട്ടുകൾ സജീവമാക്കുക';

  @override
  String get enableShoutoutsSubtitle =>
      'റെയ്ഡ് ചെയ്യുന്ന ചാനലിന്റെ ലിങ്ക് ചാറ്റിലേക്ക് അയയ്ക്കുക';

  @override
  String get raidConfigurationTitle => 'റെയ്ഡ് ക്രമീകരണം';

  @override
  String get cheerConfigurationTitle => 'ചിയർ ക്രമീകരണം';

  @override
  String get followConfigurationTitle => 'ഫോളോ ക്രമീകരണം';

  @override
  String get outgoingRaidConfigurationTitle => 'ഔട്ട്‌ഗോയിംഗ് റെയ്ഡ് ക്രമീകരണം';

  @override
  String get hostConfigurationTitle => 'ഹോസ്റ്റ് ക്രമീകരണം';

  @override
  String get channelPointConfigurationTitle => 'ചാനൽ പോയിന്റ് ക്രമീകരണം';

  @override
  String get pollConfigurationTitle => 'പോൾ ക്രമീകരണം';

  @override
  String get hypetrainConfigurationTitle => 'ഹൈപ്പ് ട്രെയിൻ ക്രമീകരണം';

  @override
  String get subscriptionConfigurationTitle => 'സബ്‌സ്‌ക്രിപ്‌ഷൻ ക്രമീകരണം';

  @override
  String get predictionConfigurationTitle => 'പ്രവചന ക്രമീകരണം';

  @override
  String get unfulfilledRewardsPinDuration =>
      'പൂർത്തിയാക്കാത്ത റിവാർഡുകൾക്കുള്ള അധിക പിൻ ദൈർഘ്യം';

  @override
  String get pollPinDuration => 'ഫലം അന്തിമമായതിന് ശേഷമുള്ള പിൻ ദൈർഘ്യം';

  @override
  String get hypetrainPinDuration =>
      'ഹൈപ്പ് ട്രെയിൻ അവസാനിച്ചതിന് ശേഷമുള്ള പിൻ ദൈർഘ്യം';

  @override
  String get enableGiftedSubscriptions =>
      'വ്യക്തിഗത സമ്മാന സബ്‌സ്‌ക്രിപ്‌ഷനുകൾ സജീവമാക്കുക';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'സമ്മാനമായി നൽകുന്ന ഓരോ സബ്‌സ്‌ക്രിപ്‌ഷനും കാണിക്കുക';

  @override
  String get settingsBackupTitle =>
      'ക്രമീകരണങ്ങളുടെ ബാക്കപ്പും പുനഃസ്ഥാപിക്കലും';

  @override
  String get cloudBackup => 'ക്ലൗഡ് ബാക്കപ്പ്';

  @override
  String get lastBackupNever => 'അവസാന ബാക്കപ്പ്: ഒരിക്കലുമില്ല';

  @override
  String get backUp => 'ബാക്കപ്പ് ചെയ്യുക';

  @override
  String get restore => 'പുനഃസ്ഥാപിക്കുക';

  @override
  String get localBackup => 'ലോക്കൽ ബാക്കപ്പ്';

  @override
  String get exportSettings => 'എക്‌സ്‌പോർട്ട് ചെയ്യുക';

  @override
  String get importSettings => 'ഇംപോർട്ട് ചെയ്യുക';

  @override
  String get showViewerAndFollowerCount =>
      'പ്രേക്ഷകരുടെയും ഫോളോവേഴ്‌സിന്റെയും എണ്ണം കാണിക്കുക';

  @override
  String get screenOrientation => 'സ്ക്രീൻ ഓറിയന്റേഷൻ';

  @override
  String get appTheme => 'ആപ്പ് തീം';

  @override
  String get systemDefault => 'സിസ്റ്റം';

  @override
  String get portrait => 'പോർട്രെയ്റ്റ്';

  @override
  String get landscape => 'ലാൻഡ്‌സ്‌കേപ്പ്';

  @override
  String get lightTheme => 'ലൈറ്റ്';

  @override
  String get darkTheme => 'ഡാർക്ക്';

  @override
  String get openSourceTitle => 'RealtimeChat ഒരു ഓപ്പൺ സോഴ്‌സ് ആണ്';

  @override
  String get openSourceSubtitle => 'ഞങ്ങളെ GitHub-ൽ കണ്ടെത്തൂ!';

  @override
  String get discordSubtitle => 'Muxable Discord-ൽ ചേരൂ!';

  @override
  String get earlyTestersThanks =>
      'ബഗ് റിപ്പോർട്ടുകൾ അയച്ച എല്ലാ ആദ്യകാല ടെസ്റ്റർമാർക്കും നന്ദി!';

  @override
  String get discoModeEnabled => '🕺 ഡിസ്കോ മോഡ് സജീവമാക്കി! :D';

  @override
  String get discoModeDisabled => '🕺 ഡിസ്കോ മോഡ് പ്രവർത്തനരഹിതമാക്കി D:';

  @override
  String get playSampleMessage => 'മാതൃകാ സന്ദേശം പ്ലേ ചെയ്യുക';

  @override
  String get textToSpeechRate => 'വാചകം ശബ്ദമാക്കൽ വേഗത';

  @override
  String get textToSpeechPitch => 'വാചകം ശബ്ദമാക്കൽ പിച്ച്';

  @override
  String get muteBots => 'ബോട്ടുകൾക്കായി വാചകം ശബ്ദമാക്കൽ മ്യൂട്ട് ചെയ്യുക';

  @override
  String get muteEmotes =>
      'വാചകം ശബ്ദമാക്കലിൽ എല്ലാ ഇമോട്ടുകളും മ്യൂട്ട് ചെയ്യുക';

  @override
  String get muteViewerNames =>
      'വാചകം ശബ്ദമാക്കലിൽ പ്രേക്ഷകരുടെ പേരുകൾ മ്യൂട്ട് ചെയ്യുക';

  @override
  String get subscribersOnly => 'സബ്‌സ്‌ക്രൈബർമാർക്ക് മാത്രം';

  @override
  String get fontSize => 'ഫോണ്ട് വലുപ്പം';

  @override
  String get usernameContrastBoost => 'ഉപയോക്തൃനാമ കോൺട്രാസ്റ്റ് ബൂസ്റ്റ്';

  @override
  String get twitchBadgeSettings => 'Twitch ബാഡ്ജ് ക്രമീകരണങ്ങൾ';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'ഏതൊക്കെ ബാഡ്ജുകൾ ദൃശ്യമാകണമെന്ന് നിയന്ത്രിക്കുക';

  @override
  String get showDeletedMessages => 'ഇല്ലാതാക്കിയ സന്ദേശങ്ങൾ കാണിക്കുക';

  @override
  String get deletedMessagesGreyedOut =>
      'ഇല്ലാതാക്കിയ സന്ദേശങ്ങൾ ചാരനിറത്തിൽ കാണിക്കും';

  @override
  String get deletedMessagesRemoved =>
      'ഇല്ലാതാക്കിയ സന്ദേശങ്ങൾ നീക്കം ചെയ്യപ്പെടും';

  @override
  String get showLoginNames => 'ലോഗിൻ പേരുകൾ കാണിക്കുക';

  @override
  String get loginNamesShown =>
      'ഡിസ്‌പ്ലേ പേരിൽ നിന്ന് വ്യത്യസ്തമാണെങ്കിൽ ലോഗിൻ പേരുകൾ കാണിക്കും';

  @override
  String get loginNamesHidden => 'ലോഗിൻ പേരുകൾ മറയ്ക്കും';

  @override
  String get compactMessages => 'സന്ദേശങ്ങൾ ചുരുക്കുക';

  @override
  String get dontCompactMessages => 'സന്ദേശങ്ങൾ ചുരുക്കരുത്';

  @override
  String get dontCompactMessagesSubtitle =>
      'സന്ദേശങ്ങൾ മാറ്റമില്ലാതെ കാണിക്കുന്നു';

  @override
  String get compactIndividualMessages => 'വ്യക്തിഗത സന്ദേശങ്ങൾ ചുരുക്കുക';

  @override
  String get compactIndividualMessagesSubtitle =>
      'സന്ദേശങ്ങളിലെ ആവർത്തിച്ചുള്ള വാചകങ്ങൾ ചുരുക്കുന്നു';

  @override
  String get announcementPinDuration => 'അറിയിപ്പ് പിൻ ദൈർഘ്യം';

  @override
  String get idleMessageAlertDuration => 'നിഷ്‌ക്രിയ സന്ദേശ അലേർട്ട് ദൈർഘ്യം';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'ഇത്രയും സമയത്തേക്ക് സന്ദേശങ്ങളൊന്നും ഇല്ലാതിരിക്കുകയും പുതിയൊരെണ്ണം വരികയും ചെയ്താൽ, ഒരു അലേർട്ട് ശബ്ദം കേൾക്കും.';

  @override
  String get realtimeCashSubtitle =>
      'ഒരു ETH അല്ലെങ്കിൽ MATIC വാലറ്റ് ബന്ധിപ്പിക്കുക';

  @override
  String get walletAddress => 'വാലറ്റ് വിലാസം';

  @override
  String get streamlabsSubtitle => 'നിങ്ങളുടെ Streamlabs സംഭാവനകൾ കാണുക';

  @override
  String get streamElementsSubtitle =>
      'നിങ്ങളുടെ StreamElements സംഭാവനകൾ കാണുക';

  @override
  String get thirdPartyAuthError =>
      'ഹും, അത് നടന്നില്ല. വീണ്ടും ശ്രമിക്കൂ, അല്ലെങ്കിൽ Discord-ൽ ചോദിക്കൂ?';

  @override
  String get companionAuthBrowserTooOld =>
      'നേരിട്ട് സൈൻ ഇൻ ചെയ്യുന്നതിനെ പിന്തുണയ്ക്കാൻ കഴിയാത്തവിധം നിങ്ങളുടെ ബ്രൗസർ പഴയതാണ്. മറ്റൊരു ഉപകരണത്തിൽ സൈൻ ഇൻ ചെയ്യാൻ നിങ്ങളുടെ ഫോൺ ഉപയോഗിച്ച് ഈ QR കോഡ് സ്കാൻ ചെയ്യുക.';

  @override
  String get companionAuthScanQrCode =>
      'മറ്റൊരു ഉപകരണത്തിൽ സൈൻ ഇൻ ചെയ്യാൻ നിങ്ങളുടെ ഫോൺ ഉപയോഗിച്ച് ഈ QR കോഡ് സ്കാൻ ചെയ്യുക.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> സബ്‌സ്‌ക്രൈബ് ചെയ്തിരിക്കുന്നു!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> $monthsString മാസത്തേക്ക് വീണ്ടും സബ്‌സ്‌ക്രൈബ് ചെയ്തിരിക്കുന്നു!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> $countString സബ്‌സ്‌ക്രിപ്‌ഷനുകൾ സമ്മാനിച്ചു!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> $amountString Kicks അയച്ചു!';
  }

  @override
  String get signInWithKick => 'Kick വഴി സൈൻ ഇൻ ചെയ്യുക';

  @override
  String get textToSpeechTooManyMessages =>
      'ഒരുപാട് സന്ദേശങ്ങളുണ്ട്. വാചകം ശബ്ദമാക്കൽ പ്രവർത്തനരഹിതമാക്കി';

  @override
  String get turnOffTextToSpeech => 'ഓഫ് ചെയ്യുക';

  @override
  String get addToChat => 'ചാറ്റിലേക്ക് ചേർക്കുക';

  @override
  String get inChat => 'ചാറ്റിൽ';

  @override
  String get removeFromChat => 'ചാറ്റിൽ നിന്ന് നീക്കം ചെയ്യുക';

  @override
  String cantChatWithAccount(String provider) {
    return 'നിങ്ങളുടെ $provider അക്കൗണ്ടിന് ഇവിടെ ചാറ്റ് ചെയ്യാനാകില്ല';
  }

  @override
  String get cantChatWithAccounts =>
      'നിങ്ങളുടെ അക്കൗണ്ടുകൾക്ക് ഇവിടെ ചാറ്റ് ചെയ്യാനാകില്ല';

  @override
  String sendAMessageTo(String channel) {
    return '$channel-ലേക്ക് ഒരു സന്ദേശം അയയ്ക്കുക...';
  }

  @override
  String replaceChannel(String channel) {
    return '$channel മാറ്റിസ്ഥാപിക്കുക';
  }

  @override
  String get voicePacks => 'വോയ്‌സ് പാക്കുകൾ';

  @override
  String get voicePacksDescription =>
      'വോയ്‌സ് പാക്കുകൾ നിങ്ങളുടെ ഉപകരണത്തിൽ പ്രവർത്തിക്കുന്ന സ്വാഭാവിക ശബ്ദങ്ങളോടെ ചാറ്റ് വായിക്കുന്നു, ഒരിക്കൽ ഡൗൺലോഡ് ചെയ്താൽ ഓഫ്‌ലൈനായി പ്രവർത്തിക്കും. ഈ ശബ്ദങ്ങൾ AI ഉപയോഗിച്ച് നിർമ്മിച്ചതാണ്, മനുഷ്യർ റെക്കോർഡ് ചെയ്തതല്ല.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices ശബ്ദങ്ങൾ',
      one: '1 ശബ്ദം',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഭാഷകൾ',
      one: '1 ഭാഷ',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'ഈ മോഡലിന്റെ ലൈസൻസ് (OpenRAIL-M) വ്യക്തികളായി ആൾമാറാട്ടം നടത്തുകയോ തെറ്റായ വിവരങ്ങൾ പ്രചരിപ്പിക്കുകയോ പോലുള്ള ദോഷകരമായ ഉപയോഗങ്ങൾ വിലക്കുന്നു, ഈ നിയന്ത്രണങ്ങൾ നിങ്ങൾക്കും ബാധകമാണ്.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return '$pack ഇല്ലാതാക്കണോ? ഇത് $size സ്ഥലം ഒഴിവാക്കും.';
  }

  @override
  String get voicePackDownload => 'ഡൗൺലോഡ് ചെയ്യുക';

  @override
  String get voicePackUpdate => 'അപ്‌ഡേറ്റ് ചെയ്യുക';

  @override
  String get voicePackWaitingForWifi => 'Wi-Fi-ക്കായി കാത്തിരിക്കുന്നു';

  @override
  String get voicePackUseMobileData => 'മൊബൈൽ ഡാറ്റ ഉപയോഗിക്കുക';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'ഡൗൺലോഡ് ചെയ്യുന്നു: $total-ൽ $downloaded';
  }

  @override
  String get voicePackInstalling => 'ഇൻസ്റ്റാൾ ചെയ്യുന്നു';

  @override
  String voicePackInstallFailed(String pack) {
    return '$pack ഇൻസ്റ്റാൾ ചെയ്യാനായില്ല. നിങ്ങളുടെ കണക്ഷൻ പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';
  }

  @override
  String get voices => 'ശബ്ദങ്ങൾ';

  @override
  String get perViewerVoice => 'ഓരോ പ്രേക്ഷകനും പ്രത്യേകം ശബ്ദം';

  @override
  String get perViewerVoiceSubtitle =>
      'ഓരോ പ്രേക്ഷകനും അവരവരുടെ ശബ്ദം ലഭിക്കുന്നു. നിങ്ങൾ തിരഞ്ഞെടുക്കുന്ന ശബ്ദം അലേർട്ടുകൾ വായിക്കുന്നു, അല്ലെങ്കിൽ ഇത് ഓഫായിരിക്കുമ്പോൾ എല്ലാം വായിക്കുന്നു.';

  @override
  String get streamLanguage => 'സ്ട്രീം ഭാഷ';

  @override
  String get ttsEngineNeural => 'ന്യൂറൽ ശബ്ദം (ഉപകരണത്തിൽ)';

  @override
  String get ttsEngineSystem => 'സിസ്റ്റം ശബ്ദം';

  @override
  String languageUnsupported(String language) {
    return 'നിങ്ങളുടെ വോയ്‌സ് പാക്കുകൾ $language പിന്തുണയ്ക്കുന്നില്ല; സിസ്റ്റം ശബ്ദം ഉപയോഗിക്കും';
  }

  @override
  String get neuralFallbackLowMemory =>
      'ന്യൂറൽ ശബ്ദങ്ങൾക്കായി ഈ ഉപകരണത്തിൽ മതിയായ മെമ്മറി ഇല്ലാത്തതിനാൽ സിസ്റ്റം ശബ്ദം ഉപയോഗിച്ച് ചാറ്റ് വായിക്കുന്നു.';

  @override
  String get neuralFallbackLoadFailed =>
      'ന്യൂറൽ ശബ്ദം ലോഡ് ചെയ്യാനാകാത്തതിനാൽ സിസ്റ്റം ശബ്ദം ഉപയോഗിച്ച് ചാറ്റ് വായിക്കുന്നു.';

  @override
  String get accounts => 'അക്കൗണ്ടുകൾ';

  @override
  String get accountsSubtitle =>
      'നിങ്ങൾ സ്ട്രീം ചെയ്യുന്ന ഓരോ പ്ലാറ്റ്‌ഫോമിലും സൈൻ ഇൻ ചെയ്യുക';

  @override
  String addProviderAccount(String provider) {
    return '$provider അക്കൗണ്ട് ചേർക്കുക';
  }

  @override
  String signInWithProvider(String provider) {
    return '$provider വഴി സൈൻ ഇൻ ചെയ്യുക';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return '$provider-ലെ $channel-ൽ നിന്ന് സൈൻ ഔട്ട് ചെയ്യണോ?';
  }

  @override
  String get signOutOfAll => 'എല്ലാ അക്കൗണ്ടുകളിൽ നിന്നും സൈൻ ഔട്ട് ചെയ്യുക';
}
