// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get sendAMessage => 'Send a message...';

  @override
  String get writeSomething => 'Write something...';

  @override
  String get speakToTheCrowds => 'Speak to the crowds...';

  @override
  String get shareYourThoughts => 'Share your thoughts...';

  @override
  String get saySomethingYouLittleBitch => 'Say something, you little bitch...';

  @override
  String get search => 'Search';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get searchChannels => 'Search';

  @override
  String get raidAChannel => 'Raid';

  @override
  String get noMessagesEmptyState => 'It\'s quiet in here.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new messages',
      one: '1 new message',
      zero: 'No new messages',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Sign in with Twitch';

  @override
  String get signInError =>
      'An error occurred when signing in. Please try again.';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get signInToSendMessages => 'Sign in to send messages';

  @override
  String get currentViewers => 'Current viewers';

  @override
  String get textToSpeech => 'Text to speech';

  @override
  String get streamPreview => 'Stream preview';

  @override
  String get activityFeed => 'Activity feed';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream online at $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream offline at $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Chat cleared at $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Configure quick links';

  @override
  String get disableRainMode => 'Disable rain mode';

  @override
  String get enableRainMode => 'Enable rain mode';

  @override
  String get disableRainModeSubtitle => 'Interaction will be enabled';

  @override
  String get enableRainModeSubtitle => 'Interaction will be disabled';

  @override
  String get refreshAudioSources => 'Refresh audio sources';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count audio sources refreshed',
      one: '1 audio source refreshed',
      zero: 'No audio sources refreshed',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Settings';

  @override
  String get signOut => 'Sign out';

  @override
  String get cancel => 'Cancel';

  @override
  String get signOutConfirmation => 'Are you sure you want to sign out?';

  @override
  String get broadcaster => 'Broadcaster';

  @override
  String get moderators => 'Moderators';

  @override
  String get viewers => 'Viewers';

  @override
  String get communityVips => 'Community VIPs';

  @override
  String get searchViewers => 'Search Viewers';

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String get twitchBadges => 'Twitch badges';

  @override
  String get selectAll => 'Select all';

  @override
  String get quickLinks => 'Quick links';

  @override
  String get swipeToDeleteQuickLinks =>
      'Swipe left or right to delete quick link';

  @override
  String get quickLinksLabelHint => 'Label';

  @override
  String get invalidUrlErrorText => 'This doesn\'t look like a valid URL';

  @override
  String get duplicateUrlErrorText => 'This link already exists';

  @override
  String get or => 'or';

  @override
  String get clearCookies => 'Clear cookies';

  @override
  String get disabled => 'Disabled';

  @override
  String get twitchActivityFeed => 'Twitch activity feed';

  @override
  String get signInToEnable => 'You must be signed in to enable this';

  @override
  String get customUrl => 'Custom URL';

  @override
  String get preview => 'Preview';

  @override
  String get audioSources => 'Audio sources';

  @override
  String get enableOffStreamSwitchTitle =>
      'Enable off-stream (uses more battery)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Audio will also play when you\'re offline';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Audio will only play when you\'re live';

  @override
  String get iosOggWarningTitle => 'Hey! Listen!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS doesn\'t support *.ogg media files, which are the default files on Streamlabs. Ensure your audio sources use another format, otherwise they won\'t play.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Customize your activity feed';

  @override
  String get audioSourcesSubtitle => 'Add web sources for alert sounds';

  @override
  String get quickLinksSubtitle => 'Add shortcuts to commonly used tools';

  @override
  String get chatHistory => 'Chat history';

  @override
  String get chatHistorySubtitle => 'Change the chat appearance';

  @override
  String get textToSpeechSubtitle => 'Change text to speech settings';

  @override
  String get events => 'Events';

  @override
  String get eventsSubtitle => 'Configure Twitch events';

  @override
  String get thirdPartyServices => 'Third-party services';

  @override
  String get thirdPartyServicesSubtitle => 'Connect to a third-party service';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> is following you';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> and <b>$displayNameTwo</b> are following you';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b>, and $numOthersString others are following you';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Unmute $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Mute $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Timeout $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Ban $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Unban $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'View $displayName\'s profile';
  }

  @override
  String get copyMessage => 'Copy Message';

  @override
  String get deleteMessage => 'Delete Message';

  @override
  String get longScrollNotification =>
      'You\'re scrolling kind of far, don\'t you think?';

  @override
  String get stfu => 'stfu';

  @override
  String get globalEmotes => 'Global Emotes';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString followers',
      one: '1 follower',
      zero: '0 followers',
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
      other: '$countString viewers',
      one: '1 viewer',
      zero: '0 viewers',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Hey there! Glad you like using stream preview but heads up it uses a lot of battery. Reading chat without it will extend your battery life.';

  @override
  String get okay => 'Okay';

  @override
  String get streamPreviewLoading => 'Loading (or stream is offline)...';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get audioSourcesRequirePermissions =>
      'Audio sources require permissions';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Approve RealtimeChat to draw over other apps to use audio sources.';

  @override
  String get audioSourcesRemoveButton => 'Remove audio sources';

  @override
  String get audioSourcesOpenSettingsButton => 'Open settings';

  @override
  String get flashOn => 'Flash on';

  @override
  String get flashOff => 'Flash off';

  @override
  String get durationOneSecond => '1 second';

  @override
  String get durationOneMinute => '1 minute';

  @override
  String get durationTenMinutes => '10 minutes';

  @override
  String get durationOneHour => '1 hour';

  @override
  String get durationSixHours => '6 hours';

  @override
  String get durationOneDay => '1 day';

  @override
  String get durationTwoDays => '2 days';

  @override
  String get durationOneWeek => '1 week';

  @override
  String get durationTwoWeeks => '2 weeks';

  @override
  String get durationOneSecondTimeoutPrompt => 'Timeout for 1 second';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Timeout for 1 minute';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Timeout for 10 minutes';

  @override
  String get durationOneHourTimeoutPrompt => 'Timeout for 1 hour';

  @override
  String get durationSixHoursTimeoutPrompt => 'Timeout for 6 hours';

  @override
  String get durationOneDayTimeoutPrompt => 'Timeout for 1 day';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Timeout for 2 days';

  @override
  String get durationOneWeekTimeoutPrompt => 'Timeout for 1 week';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Timeout for 2 weeks';

  @override
  String get errorFetchingViewerList =>
      'We couldn\'t fetch the viewer list for this channel';

  @override
  String get eventsTitle => 'Events';

  @override
  String get followEventConfigTitle => 'Follow Event';

  @override
  String get customizeYourFollowEvent => 'Customize your follow event';

  @override
  String get subscribeEventConfigTitle => 'Subscribe Event';

  @override
  String get customizeYourSubscriptionEvent =>
      'Customize your subscription event';

  @override
  String get cheerEventConfigTitle => 'Cheer Event';

  @override
  String get customizeYourCheerEvent => 'Customize your cheer event';

  @override
  String get raidEventConfigTitle => 'Raid Event';

  @override
  String get customizeYourRaidEvent => 'Customize your raid event';

  @override
  String get hostEventConfigTitle => 'Host Event';

  @override
  String get customizeYourHostEvent => 'Customize your host event';

  @override
  String get hypetrainEventConfigTitle => 'Hype Train Event';

  @override
  String get customizeYourHypetrainEvent => 'Customize your hype train event';

  @override
  String get pollEventConfigTitle => 'Poll Event';

  @override
  String get customizeYourPollEvent => 'Customize your poll event';

  @override
  String get predictionEventConfigTitle => 'Prediction Event';

  @override
  String get customizeYourPredictionEvent => 'Customize your prediction event';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Channel Point Redemption Event';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Customize your channel point redemption event';

  @override
  String get outgoingRaidEventConfigTitle => 'Outgoing Raid Event';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Customize your outgoing raid event';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> is raiding with <b>$viewerCountString</b> viewers!';
  }

  @override
  String get shoutout => 'Shoutout';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Raiding <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '${secondsString}s';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> has raided!';
  }

  @override
  String get raidingEventJoin => 'Join';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b>\'s raid was canceled.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> has subscribed at Tier $tier!';
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

    return '<b>$gifterUserName</b> has gifted $totalString Tier $tier subs, totaling $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> has subscribed for $cumulativeMonthsString months at Tier $tier!';
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

    return '<b>$subscriberUserName</b> has subscribed at Tier $tier for $durationMonthsString months in advance, $cumulativeMonthsString months in total!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> tipped <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonymous tipped <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> tipped <b>$formattedAmount</b> on StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> tipped <b>$formattedAmount</b> on Streamlabs.';
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

    return '<b>$redeemerUsername</b> redeemed <b>$rewardName</b> for <b>$rewardCostString</b> points. $userInput';
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

    return '<b>$redeemerUsername</b> redeemed <b>$rewardName</b> for <b>$rewardCostString</b> points.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> cheered <b>$bitsString</b> bits. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonymous';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> is hosting with a party of <b>$viewersString</b>.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train level <b>$level</b> in progress! <b>$progressPercent%</b> completed!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train level <b>$levelString</b> succeeded.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train level <b>$levelString</b> failed.';
  }

  @override
  String get sampleMessage => 'This is a sample message for text to speech.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author said: $text';
  }

  @override
  String get textToSpeechEnabled => 'Text to speech enabled';

  @override
  String get textToSpeechDisabled => 'Text to speech disabled';

  @override
  String get alertsEnabled => 'Alerts only';

  @override
  String get pinDuration => 'Pin Duration';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Enable event';

  @override
  String get showEventInChatHistory => 'Show event in chat history';

  @override
  String get enableShoutouts => 'Enable shoutouts';

  @override
  String get enableShoutoutsSubtitle =>
      'Send a link to the raiding channel to chat';

  @override
  String get raidConfigurationTitle => 'Raid Configuration';

  @override
  String get cheerConfigurationTitle => 'Cheer Configuration';

  @override
  String get followConfigurationTitle => 'Follow Configuration';

  @override
  String get outgoingRaidConfigurationTitle => 'Outgoing Raid Configuration';

  @override
  String get hostConfigurationTitle => 'Host Configuration';

  @override
  String get channelPointConfigurationTitle => 'Channel Point Configuration';

  @override
  String get pollConfigurationTitle => 'Poll Configuration';

  @override
  String get hypetrainConfigurationTitle => 'Hypetrain Configuration';

  @override
  String get subscriptionConfigurationTitle => 'Subscription Configuration';

  @override
  String get predictionConfigurationTitle => 'Prediction Configuration';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Additional Pin Duration for Unfulfilled Rewards';

  @override
  String get pollPinDuration => 'Pin duration after the result is finalized';

  @override
  String get hypetrainPinDuration => 'Pin duration after hypetrain is over';

  @override
  String get enableGiftedSubscriptions =>
      'Enable individual gifted subscriptions';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Show every subscription that is gifted';

  @override
  String get settingsBackupTitle => 'Settings backup and restore';

  @override
  String get cloudBackup => 'Cloud backup';

  @override
  String get lastBackupNever => 'Last backup: never';

  @override
  String get backUp => 'Back up';

  @override
  String get restore => 'Restore';

  @override
  String get localBackup => 'Local backup';

  @override
  String get exportSettings => 'Export';

  @override
  String get importSettings => 'Import';

  @override
  String get showViewerAndFollowerCount => 'Show viewer and follower count';

  @override
  String get screenOrientation => 'Screen orientation';

  @override
  String get appTheme => 'App theme';

  @override
  String get systemDefault => 'System';

  @override
  String get portrait => 'Portrait';

  @override
  String get landscape => 'Landscape';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get openSourceTitle => 'RealtimeChat is open source';

  @override
  String get openSourceSubtitle => 'Find us on GitHub!';

  @override
  String get discordSubtitle => 'Join the Muxable Discord!';

  @override
  String get earlyTestersThanks =>
      'Thanks to all the early testers who sent bug reports!';

  @override
  String get discoModeEnabled => '🕺 Disco mode enabled! :D';

  @override
  String get discoModeDisabled => '🕺 Disco mode disabled D:';

  @override
  String get playSampleMessage => 'Play sample message';

  @override
  String get textToSpeechRate => 'Text to Speech Rate';

  @override
  String get textToSpeechPitch => 'Text to Speech Pitch';

  @override
  String get muteBots => 'Mute text to speech for bots';

  @override
  String get muteEmotes => 'Mute all emotes in text to speech';

  @override
  String get muteViewerNames => 'Mute viewer names in text to speech';

  @override
  String get subscribersOnly => 'Subscribers only';

  @override
  String get fontSize => 'Font size';

  @override
  String get usernameContrastBoost => 'Username contrast boost';

  @override
  String get twitchBadgeSettings => 'Twitch badge settings';

  @override
  String get twitchBadgeSettingsSubtitle => 'Control which badges are visible';

  @override
  String get showDeletedMessages => 'Show deleted messages';

  @override
  String get deletedMessagesGreyedOut => 'Deleted messages will be greyed out';

  @override
  String get deletedMessagesRemoved => 'Deleted messages will be removed';

  @override
  String get showLoginNames => 'Show login names';

  @override
  String get loginNamesShown =>
      'Login names will be shown if they are different from the display name';

  @override
  String get loginNamesHidden => 'Login names will be hidden';

  @override
  String get compactMessages => 'Compact messages';

  @override
  String get dontCompactMessages => 'Don\'t compact messages';

  @override
  String get dontCompactMessagesSubtitle => 'Messages are shown unchanged';

  @override
  String get compactIndividualMessages => 'Compact individual messages';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Repetitive text in messages is shortened';

  @override
  String get announcementPinDuration => 'Announcement pin duration';

  @override
  String get idleMessageAlertDuration => 'Idle message alert duration';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'If there aren\'t any messages for this amount of time and a new one comes in, an alert sound will play.';

  @override
  String get realtimeCashSubtitle => 'Connect an ETH or MATIC wallet';

  @override
  String get walletAddress => 'Wallet address';

  @override
  String get streamlabsSubtitle => 'See your Streamlabs donations';

  @override
  String get streamElementsSubtitle => 'See your StreamElements donations';

  @override
  String get thirdPartyAuthError =>
      'Hmm, that didn\'t work. Try again, or ask on Discord?';

  @override
  String get companionAuthBrowserTooOld =>
      'Your browser is too old to support signing in directly. Scan this QR code with your phone to sign in on another device.';

  @override
  String get companionAuthScanQrCode =>
      'Scan this QR code with your phone to sign in on another device.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> has subscribed!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> has resubscribed for $monthsString months!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> has gifted $countString subs!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> sent $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Sign in with Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'There are too many messages. Text to speech disabled';

  @override
  String get turnOffTextToSpeech => 'Turn off';

  @override
  String get addChannel => 'Add channel';

  @override
  String get addToChat => 'Add to chat';

  @override
  String get defaultChannels => 'Default channels';

  @override
  String get defaultChannelsSubtitle => 'The channels shown when the app opens';

  @override
  String get save => 'Save';

  @override
  String get resetToMyChannel => 'Reset to my channel';

  @override
  String get inChat => 'In chat';

  @override
  String get removeFromChat => 'Remove from chat';

  @override
  String cantChatWithAccount(String provider) {
    return 'Your $provider account can\'t chat here';
  }

  @override
  String replaceChannel(String channel) {
    return 'Replace $channel';
  }

  @override
  String get removeChannel => 'Remove';

  @override
  String get voicePacks => 'Voice packs';

  @override
  String get voicePacksDescription =>
      'Voice packs read chat with natural-sounding voices that run on your device, offline once downloaded. The voices are machine-generated by AI, not recorded by a person.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices voices',
      one: '1 voice',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count languages',
      one: '1 language',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'This model\'s license (OpenRAIL-M) forbids harmful uses, such as impersonating people or spreading disinformation, and these restrictions apply to you too.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Delete $pack? This frees $size.';
  }

  @override
  String get voicePackDownload => 'Download';

  @override
  String get voicePackUpdate => 'Update';

  @override
  String get voicePackWaitingForWifi => 'Waiting for Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Use mobile data';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Downloading: $downloaded of $total';
  }

  @override
  String get voicePackInstalling => 'Installing';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Couldn\'t install $pack. Check your connection and try again.';
  }

  @override
  String get voices => 'Voices';

  @override
  String get perViewerVoice => 'Per-viewer voice';

  @override
  String get perViewerVoiceSubtitle =>
      'Each viewer gets their own voice. The voice you pick reads alerts, or everything when this is off.';

  @override
  String get streamLanguage => 'Stream language';

  @override
  String get ttsEngineNeural => 'Neural voice (on-device)';

  @override
  String get ttsEngineSystem => 'System voice';

  @override
  String languageUnsupported(String language) {
    return '$language isn\'t supported by your voice packs; the system voice will be used';
  }

  @override
  String get neuralFallbackLowMemory =>
      'This device doesn\'t have enough memory for neural voices, so chat is read with the system voice.';

  @override
  String get neuralFallbackLoadFailed =>
      'The neural voice couldn\'t load, so chat is read with the system voice.';

  @override
  String get accounts => 'Accounts';

  @override
  String get accountsSubtitle => 'Sign in to each platform you stream on';

  @override
  String addProviderAccount(String provider) {
    return 'Add $provider account';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Sign in with $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Sign out of $channel on $provider?';
  }

  @override
  String get signOutOfAll => 'Sign out of all accounts';
}
