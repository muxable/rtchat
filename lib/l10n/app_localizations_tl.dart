// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tagalog (`tl`).
class AppLocalizationsTl extends AppLocalizations {
  AppLocalizationsTl([String locale = 'tl']) : super(locale);

  @override
  String get sendAMessage => 'Magpadala ng mensahe...';

  @override
  String get writeSomething => 'Magsulat ng kung ano...';

  @override
  String get speakToTheCrowds => 'Magsalita sa madla...';

  @override
  String get shareYourThoughts => 'Ibahagi ang iyong naiisip...';

  @override
  String get saySomethingYouLittleBitch => 'Magsalita ka naman, duwag...';

  @override
  String get search => 'Maghanap';

  @override
  String get notSignedIn => 'Hindi naka-sign in';

  @override
  String get searchChannels => 'Maghanap';

  @override
  String get raidAChannel => 'Mag-raid';

  @override
  String get noMessagesEmptyState => 'Tahimik dito.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count na bagong mensahe',
      one: '1 bagong mensahe',
      zero: 'Walang bagong mensahe',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Mag-sign in gamit ang Twitch';

  @override
  String get signInError =>
      'Nagkaroon ng error sa pag-sign in. Pakisubukang muli.';

  @override
  String get continueAsGuest => 'Magpatuloy bilang Bisita';

  @override
  String get signInToSendMessages =>
      'Mag-sign in para makapagpadala ng mga mensahe';

  @override
  String get currentViewers => 'Kasalukuyang mga manonood';

  @override
  String get textToSpeech => 'Pagbigkas ng teksto';

  @override
  String get streamPreview => 'Preview ng stream';

  @override
  String get activityFeed => 'Feed ng aktibidad';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Online ang stream noong $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Offline ang stream noong $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Na-clear ang chat noong $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'I-configure ang mga quick link';

  @override
  String get disableRainMode => 'I-disable ang rain mode';

  @override
  String get enableRainMode => 'I-enable ang rain mode';

  @override
  String get disableRainModeSubtitle => 'Mae-enable ang interaksyon';

  @override
  String get enableRainModeSubtitle => 'Madi-disable ang interaksyon';

  @override
  String get refreshAudioSources => 'I-refresh ang mga source ng audio';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count na source ng audio ang na-refresh',
      one: '1 source ng audio ang na-refresh',
      zero: 'Walang na-refresh na source ng audio',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Mga Setting';

  @override
  String get signOut => 'Mag-sign out';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get signOutConfirmation => 'Sigurado ka bang gusto mong mag-sign out?';

  @override
  String get broadcaster => 'Tagapag-broadcast';

  @override
  String get moderators => 'Mga Moderator';

  @override
  String get viewers => 'Mga Manonood';

  @override
  String get communityVips => 'Mga VIP ng Komunidad';

  @override
  String get searchViewers => 'Maghanap ng mga Manonood';

  @override
  String get reconnecting => 'Kumokonekta muli...';

  @override
  String get twitchBadges => 'Mga badge ng Twitch';

  @override
  String get selectAll => 'Piliin lahat';

  @override
  String get quickLinks => 'Mga quick link';

  @override
  String get swipeToDeleteQuickLinks =>
      'Mag-swipe pakaliwa o pakanan para burahin ang quick link';

  @override
  String get quickLinksLabelHint => 'Pangalan ng label';

  @override
  String get invalidUrlErrorText => 'Mukhang hindi ito valid na URL';

  @override
  String get duplicateUrlErrorText => 'Umiiral na ang link na ito';

  @override
  String get or => 'o';

  @override
  String get clearCookies => 'I-clear ang mga cookie';

  @override
  String get disabled => 'Naka-disable';

  @override
  String get twitchActivityFeed => 'Feed ng aktibidad sa Twitch';

  @override
  String get signInToEnable => 'Kailangan mong mag-sign in para ma-enable ito';

  @override
  String get customUrl => 'Custom na URL';

  @override
  String get preview => 'Paunang tingin';

  @override
  String get audioSources => 'Mga source ng audio';

  @override
  String get enableOffStreamSwitchTitle =>
      'I-enable kahit offline ang stream (mas malakas sa baterya)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Magpe-play din ang audio kahit offline ka';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Magpe-play lang ang audio kapag live ka';

  @override
  String get iosOggWarningTitle => 'Hoy! Pakinggan mo!';

  @override
  String get iosOggWarningSubtitle =>
      'Hindi sinusuportahan ng iOS ang mga *.ogg media file, na siyang default na file sa Streamlabs. Siguraduhing gumagamit ng ibang format ang iyong mga source ng audio, kung hindi ay hindi ito magpe-play.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'I-customize ang iyong feed ng aktibidad';

  @override
  String get audioSourcesSubtitle =>
      'Magdagdag ng mga web source para sa mga tunog ng alerto';

  @override
  String get quickLinksSubtitle =>
      'Magdagdag ng mga shortcut sa mga madalas gamiting tool';

  @override
  String get chatHistory => 'History ng chat';

  @override
  String get chatHistorySubtitle => 'Baguhin ang hitsura ng chat';

  @override
  String get textToSpeechSubtitle =>
      'Baguhin ang mga setting ng pagbigkas ng teksto';

  @override
  String get events => 'Mga Kaganapan';

  @override
  String get eventsSubtitle => 'I-configure ang mga kaganapan sa Twitch';

  @override
  String get thirdPartyServices => 'Mga third-party na serbisyo';

  @override
  String get thirdPartyServicesSubtitle =>
      'Kumonekta sa isang third-party na serbisyo';

  @override
  String followingEvent(String displayName) {
    return 'Sinusundan ka na ni <b>$displayName</b>';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return 'Sinusundan ka na nina <b>$displayName</b> at <b>$displayNameTwo</b>';
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

    return 'Sinusundan ka na nina <b>$displayName</b>, <b>$displayNameTwo</b>, at ng $numOthersString pang iba';
  }

  @override
  String unmuteUser(String displayName) {
    return 'I-unmute si $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'I-mute si $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Suspendihin si $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'I-ban si $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'I-unban si $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Tingnan ang profile ni $displayName';
  }

  @override
  String get copyMessage => 'Kopyahin ang Mensahe';

  @override
  String get deleteMessage => 'Burahin ang Mensahe';

  @override
  String get longScrollNotification =>
      'Medyo malayo na ang na-scroll mo, hindi ba?';

  @override
  String get stfu => 'tumahimik';

  @override
  String get globalEmotes => 'Mga Global na Emote';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString na tagasunod',
      one: '1 tagasunod',
      zero: '0 tagasunod',
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
      other: '$countString na manonood',
      one: '1 manonood',
      zero: '0 manonood',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Kumusta! Masaya kaming nagugustuhan mo ang preview ng stream, pero paalala lang na malakas ito sa baterya. Ang pagbabasa ng chat nang wala nito ay magpapahaba sa buhay ng iyong baterya.';

  @override
  String get okay => 'Sige';

  @override
  String get streamPreviewLoading => 'Naglo-load (o offline ang stream)...';

  @override
  String get copiedToClipboard => 'Nakopya sa clipboard';

  @override
  String get audioSourcesRequirePermissions =>
      'Kailangan ng pahintulot ng mga source ng audio';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Payagan ang RealtimeChat na lumitaw sa ibabaw ng ibang app para magamit ang mga source ng audio.';

  @override
  String get audioSourcesRemoveButton => 'Alisin ang mga source ng audio';

  @override
  String get audioSourcesOpenSettingsButton => 'Buksan ang mga setting';

  @override
  String get flashOn => 'Naka-on ang flash';

  @override
  String get flashOff => 'Naka-off ang flash';

  @override
  String get durationOneSecond => '1 segundo';

  @override
  String get durationOneMinute => '1 minuto';

  @override
  String get durationTenMinutes => '10 minuto';

  @override
  String get durationOneHour => '1 oras';

  @override
  String get durationSixHours => '6 na oras';

  @override
  String get durationOneDay => '1 araw';

  @override
  String get durationTwoDays => '2 araw';

  @override
  String get durationOneWeek => '1 linggo';

  @override
  String get durationTwoWeeks => '2 linggo';

  @override
  String get durationOneSecondTimeoutPrompt => 'Suspendihin nang 1 segundo';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Suspendihin nang 1 minuto';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Suspendihin nang 10 minuto';

  @override
  String get durationOneHourTimeoutPrompt => 'Suspendihin nang 1 oras';

  @override
  String get durationSixHoursTimeoutPrompt => 'Suspendihin nang 6 na oras';

  @override
  String get durationOneDayTimeoutPrompt => 'Suspendihin nang 1 araw';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Suspendihin nang 2 araw';

  @override
  String get durationOneWeekTimeoutPrompt => 'Suspendihin nang 1 linggo';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Suspendihin nang 2 linggo';

  @override
  String get errorFetchingViewerList =>
      'Hindi namin makuha ang listahan ng mga manonood para sa channel na ito';

  @override
  String get eventsTitle => 'Mga Kaganapan';

  @override
  String get followEventConfigTitle => 'Kaganapan sa Follow';

  @override
  String get customizeYourFollowEvent => 'I-customize ang iyong follow event';

  @override
  String get subscribeEventConfigTitle => 'Kaganapan sa Pag-subscribe';

  @override
  String get customizeYourSubscriptionEvent =>
      'I-customize ang iyong subscription event';

  @override
  String get cheerEventConfigTitle => 'Kaganapan sa Cheer';

  @override
  String get customizeYourCheerEvent => 'I-customize ang iyong cheer event';

  @override
  String get raidEventConfigTitle => 'Kaganapan sa Raid';

  @override
  String get customizeYourRaidEvent => 'I-customize ang iyong raid event';

  @override
  String get hostEventConfigTitle => 'Kaganapan sa Host';

  @override
  String get customizeYourHostEvent => 'I-customize ang iyong host event';

  @override
  String get hypetrainEventConfigTitle => 'Kaganapan sa Hype Train';

  @override
  String get customizeYourHypetrainEvent =>
      'I-customize ang iyong Hype Train event';

  @override
  String get pollEventConfigTitle => 'Kaganapan sa Poll';

  @override
  String get customizeYourPollEvent => 'I-customize ang iyong poll event';

  @override
  String get predictionEventConfigTitle => 'Kaganapan sa Prediction';

  @override
  String get customizeYourPredictionEvent =>
      'I-customize ang iyong prediction event';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Kaganapan sa Pag-redeem ng Channel Point';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'I-customize ang iyong channel point redemption event';

  @override
  String get outgoingRaidEventConfigTitle => 'Kaganapan sa Papalabas na Raid';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'I-customize ang iyong outgoing raid event';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return 'Nag-raid si <b>$displayName</b> kasama ang <b>$viewerCountString</b> na manonood!';
  }

  @override
  String get shoutout => 'Bigyan ng Shoutout';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Nire-raid si <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString seg';
  }

  @override
  String raidingEventRaided(String displayName) {
    return 'Nakapag-raid na si <b>$displayName</b>!';
  }

  @override
  String get raidingEventJoin => 'Sumali';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Kinansela ang raid ni <b>$displayName</b>.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return 'Nag-subscribe si <b>$subscriberUserName</b> sa Tier $tier!';
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

    return 'Nagregalo si <b>$gifterUserName</b> ng $totalString na Tier $tier sub, na may kabuuang $cumulativeTotalString!';
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

    return 'Nag-subscribe si <b>$subscriberUserName</b> nang $cumulativeMonthsString buwan sa Tier $tier!';
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

    return 'Nag-subscribe nang maaga si <b>$subscriberUserName</b> sa Tier $tier para sa $durationMonthsString buwan, $cumulativeMonthsString buwan sa kabuuan!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return 'Nag-tip si <b>$donor</b> ng <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Nag-tip ang isang hindi nagpakilala ng <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return 'Nag-tip si <b>$name</b> ng <b>$formattedAmount</b> sa StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return 'Nag-tip si <b>$name</b> ng <b>$formattedAmount</b> sa Streamlabs.';
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

    return 'I-niredeem ni <b>$redeemerUsername</b> ang <b>$rewardName</b> sa halagang <b>$rewardCostString</b> puntos. $userInput';
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

    return 'I-niredeem ni <b>$redeemerUsername</b> ang <b>$rewardName</b> sa halagang <b>$rewardCostString</b> puntos.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return 'Nag-cheer si <b>$name</b> ng <b>$bitsString</b> bits. $cheerMessage';
  }

  @override
  String get anonymous => 'Hindi Nagpakilala';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return 'Nagho-host si <b>$fromDisplayName</b> kasama ang grupo ng <b>$viewersString</b>.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Kasalukuyang nagaganap ang Hype Train level <b>$level</b>! <b>$progressPercent%</b> na ang tapos!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Nagtagumpay ang Hype Train level <b>$levelString</b>.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Nabigo ang Hype Train level <b>$levelString</b>.';
  }

  @override
  String get sampleMessage =>
      'Ito ay isang halimbawang mensahe para sa pagbigkas ng teksto.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author ay nagsabi: $text';
  }

  @override
  String get textToSpeechEnabled => 'Na-enable ang pagbigkas ng teksto';

  @override
  String get textToSpeechDisabled => 'Na-disable ang pagbigkas ng teksto';

  @override
  String get alertsEnabled => 'Mga alerto lang';

  @override
  String get pinDuration => 'Tagal ng Pag-pin';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds segundo',
      one: '1 segundo',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuto',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'I-enable ang kaganapan';

  @override
  String get showEventInChatHistory =>
      'Ipakita ang kaganapan sa history ng chat';

  @override
  String get enableShoutouts => 'I-enable ang mga shoutout';

  @override
  String get enableShoutoutsSubtitle =>
      'Magpadala ng link ng nag-raid na channel sa chat';

  @override
  String get raidConfigurationTitle => 'Konpigurasyon ng Raid';

  @override
  String get cheerConfigurationTitle => 'Konpigurasyon ng Cheer';

  @override
  String get followConfigurationTitle => 'Konpigurasyon ng Follow';

  @override
  String get outgoingRaidConfigurationTitle =>
      'Konpigurasyon ng Papalabas na Raid';

  @override
  String get hostConfigurationTitle => 'Konpigurasyon ng Host';

  @override
  String get channelPointConfigurationTitle => 'Konpigurasyon ng Channel Point';

  @override
  String get pollConfigurationTitle => 'Konpigurasyon ng Poll';

  @override
  String get hypetrainConfigurationTitle => 'Konpigurasyon ng Hype Train';

  @override
  String get subscriptionConfigurationTitle => 'Konpigurasyon ng Subscription';

  @override
  String get predictionConfigurationTitle => 'Konpigurasyon ng Prediction';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Karagdagang Tagal ng Pag-pin para sa Hindi Pa Natutupad na mga Reward';

  @override
  String get pollPinDuration =>
      'Tagal ng pag-pin pagkatapos ma-finalize ang resulta';

  @override
  String get hypetrainPinDuration =>
      'Tagal ng pag-pin pagkatapos ng Hype Train';

  @override
  String get enableGiftedSubscriptions =>
      'I-enable ang indibidwal na mga regalong subscription';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Ipakita ang bawat subscription na iniregalo';

  @override
  String get settingsBackupTitle => 'Pag-backup at pag-restore ng mga setting';

  @override
  String get cloudBackup => 'Cloud na backup';

  @override
  String get lastBackupNever => 'Huling backup: hindi kailanman';

  @override
  String get backUp => 'I-back up';

  @override
  String get restore => 'I-restore';

  @override
  String get localBackup => 'Lokal na backup';

  @override
  String get exportSettings => 'I-export';

  @override
  String get importSettings => 'I-import';

  @override
  String get showViewerAndFollowerCount =>
      'Ipakita ang bilang ng manonood at tagasunod';

  @override
  String get screenOrientation => 'Oryentasyon ng screen';

  @override
  String get appTheme => 'Tema ng app';

  @override
  String get systemDefault => 'Sistema';

  @override
  String get portrait => 'Patayo';

  @override
  String get landscape => 'Pahiga';

  @override
  String get lightTheme => 'Maliwanag';

  @override
  String get darkTheme => 'Madilim';

  @override
  String get openSourceTitle => 'Open source ang RealtimeChat';

  @override
  String get openSourceSubtitle => 'Hanapin kami sa GitHub!';

  @override
  String get discordSubtitle => 'Sumali sa Muxable Discord!';

  @override
  String get earlyTestersThanks =>
      'Salamat sa lahat ng unang sumubok na nagpadala ng mga ulat ng bug!';

  @override
  String get discoModeEnabled => '🕺 Na-enable ang disco mode! :D';

  @override
  String get discoModeDisabled => '🕺 Na-disable ang disco mode D:';

  @override
  String get playSampleMessage => 'I-play ang halimbawang mensahe';

  @override
  String get textToSpeechRate => 'Bilis ng Pagbigkas ng Teksto';

  @override
  String get textToSpeechPitch => 'Tono ng Pagbigkas ng Teksto';

  @override
  String get muteBots => 'I-mute ang pagbigkas ng teksto para sa mga bot';

  @override
  String get muteEmotes => 'I-mute ang lahat ng emote sa pagbigkas ng teksto';

  @override
  String get muteViewerNames =>
      'I-mute ang mga pangalan ng manonood sa pagbigkas ng teksto';

  @override
  String get subscribersOnly => 'Para sa mga subscriber lang';

  @override
  String get fontSize => 'Laki ng font';

  @override
  String get usernameContrastBoost => 'Pagpapataas ng contrast ng username';

  @override
  String get twitchBadgeSettings => 'Mga setting ng badge sa Twitch';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Kontrolin kung aling mga badge ang makikita';

  @override
  String get showDeletedMessages => 'Ipakita ang mga binurang mensahe';

  @override
  String get deletedMessagesGreyedOut =>
      'Magiging kulay abo ang mga binurang mensahe';

  @override
  String get deletedMessagesRemoved => 'Aalisin ang mga binurang mensahe';

  @override
  String get showLoginNames => 'Ipakita ang mga pangalan sa pag-login';

  @override
  String get loginNamesShown =>
      'Ipapakita ang mga pangalan sa pag-login kung iba ang mga ito sa display name';

  @override
  String get loginNamesHidden => 'Itatago ang mga pangalan sa pag-login';

  @override
  String get compactMessages => 'Paikliin ang mga mensahe';

  @override
  String get dontCompactMessages => 'Huwag paikliin ang mga mensahe';

  @override
  String get dontCompactMessagesSubtitle =>
      'Ipapakita ang mga mensahe nang walang pagbabago';

  @override
  String get compactIndividualMessages => 'Paikliin ang bawat mensahe';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Paiikliin ang paulit-ulit na teksto sa mga mensahe';

  @override
  String get announcementPinDuration => 'Tagal ng pag-pin sa anunsyo';

  @override
  String get idleMessageAlertDuration => 'Tagal ng alerto sa idle na mensahe';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Kapag walang mensahe sa loob ng panahong ito at may dumating na bago, may tutunog na alerto.';

  @override
  String get realtimeCashSubtitle => 'Magkonekta ng ETH o MATIC wallet';

  @override
  String get walletAddress => 'Address ng wallet';

  @override
  String get streamlabsSubtitle =>
      'Tingnan ang iyong mga donasyon sa Streamlabs';

  @override
  String get streamElementsSubtitle =>
      'Tingnan ang iyong mga donasyon sa StreamElements';

  @override
  String get thirdPartyAuthError =>
      'Hmm, hindi iyon gumana. Subukan muli, o magtanong sa Discord?';

  @override
  String get companionAuthBrowserTooOld =>
      'Masyadong luma na ang iyong browser para suportahan ang direktang pag-sign in. I-scan ang QR code na ito gamit ang iyong telepono para mag-sign in sa ibang device.';

  @override
  String get companionAuthScanQrCode =>
      'I-scan ang QR code na ito gamit ang iyong telepono para mag-sign in sa ibang device.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return 'Nag-subscribe si <b>$subscriberName</b>!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return 'Nag-subscribe muli si <b>$subscriberName</b> nang $monthsString buwan!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Nagregalo si <b>$gifterName</b> ng $countString na sub!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'Nagpadala si <b>$senderName</b> ng $amountString na Kicks!';
  }

  @override
  String get signInWithKick => 'Mag-sign in gamit ang Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Masyadong maraming mensahe. Na-disable ang pagbigkas ng teksto';

  @override
  String get turnOffTextToSpeech => 'I-off';

  @override
  String get addToChat => 'Idagdag sa chat';

  @override
  String get inChat => 'Nasa chat';

  @override
  String get removeFromChat => 'Alisin sa chat';

  @override
  String cantChatWithAccount(String provider) {
    return 'Hindi makakapag-chat dito ang iyong $provider account';
  }

  @override
  String get cantChatWithAccounts =>
      'Hindi makakapag-chat dito ang iyong mga account';

  @override
  String sendAMessageTo(String channel) {
    return 'Magpadala ng mensahe sa $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Palitan ang $channel';
  }

  @override
  String get voicePacks => 'Mga voice pack';

  @override
  String get voicePacksDescription =>
      'Binabasa ng mga voice pack ang chat gamit ang natural na boses na gumagana sa iyong device, kahit offline kapag na-download na. Ang mga boses ay likha ng AI at hindi inirekord ng tao.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices na boses',
      one: '1 boses',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count na wika',
      one: '1 wika',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Ipinagbabawal ng lisensya ng modelong ito (OpenRAIL-M) ang mapaminsalang paggamit, tulad ng pagpapanggap bilang ibang tao o pagpapakalat ng maling impormasyon, at saklaw ka rin ng mga paghihigpit na ito.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Burahin ang $pack? Magpapalaya ito ng $size.';
  }

  @override
  String get voicePackDownload => 'I-download';

  @override
  String get voicePackUpdate => 'I-update';

  @override
  String get voicePackWaitingForWifi => 'Naghihintay ng Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Gamitin ang mobile data';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Nagda-download: $downloaded sa $total';
  }

  @override
  String get voicePackInstalling => 'Ini-install';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Hindi ma-install ang $pack. Suriin ang iyong koneksyon at subukang muli.';
  }

  @override
  String get voices => 'Mga Boses';

  @override
  String get perViewerVoice => 'Boses kada manonood';

  @override
  String get perViewerVoiceSubtitle =>
      'Magkakaroon ng sariling boses ang bawat manonood. Ang boses na pipiliin mo ang magbabasa ng mga alerto, o ng lahat kapag naka-off ito.';

  @override
  String get streamLanguage => 'Wika ng stream';

  @override
  String get ttsEngineNeural => 'Neural na boses (sa device)';

  @override
  String get ttsEngineSystem => 'Boses ng sistema';

  @override
  String languageUnsupported(String language) {
    return 'Hindi sinusuportahan ng iyong mga voice pack ang $language; gagamitin ang boses ng sistema';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Walang sapat na memory ang device na ito para sa mga neural na boses, kaya binabasa ang chat gamit ang boses ng sistema.';

  @override
  String get neuralFallbackLoadFailed =>
      'Hindi ma-load ang neural na boses, kaya binabasa ang chat gamit ang boses ng sistema.';

  @override
  String get accounts => 'Mga Account';

  @override
  String get accountsSubtitle =>
      'Mag-sign in sa bawat platform kung saan ka nag-i-stream';

  @override
  String addProviderAccount(String provider) {
    return 'Magdagdag ng $provider account';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Mag-sign in gamit ang $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Mag-sign out sa $channel sa $provider?';
  }

  @override
  String get signOutOfAll => 'Mag-sign out sa lahat ng account';
}
