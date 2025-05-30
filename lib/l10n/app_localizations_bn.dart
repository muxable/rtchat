// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get sendAMessage => 'একটি বার্তা পাঠান...';

  @override
  String get writeSomething => 'কিছু লিখুন...';

  @override
  String get speakToTheCrowds => 'জনতার সাথে কথা বলুন...';

  @override
  String get shareYourThoughts => 'আপনার মতামত জানান...';

  @override
  String get saySomethingYouLittleBitch => 'তুমি কিছু বল...';

  @override
  String get search => 'অনুসন্ধান';

  @override
  String get notSignedIn => 'সাইন ইন করা হয়নি';

  @override
  String get searchChannels => 'চ্যানেল খুঁজুন';

  @override
  String get raidAChannel => 'একটি চ্যানেলে অভিযান চালান';

  @override
  String get noMessagesEmptyState => 'কোন মেসেজ নেই, খালি...';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count টি নতুন বার্তা',
      one: '1টি নতুন বার্তা',
      zero: 'কোন নতুন বার্তা নেই',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'টুইচ দিয়ে সাইন ইন করুন';

  @override
  String get signInError => 'সাইন-ইন এর সমস্যা হচ্ছে আবার চেষ্টা করুন';

  @override
  String get continueAsGuest => 'অতিথি হিসাবে চালিয়ে যান';

  @override
  String get signInToSendMessages => 'মেসেজ পাঠাতে সাইন ইন করুন';

  @override
  String get currentViewers => 'বর্তমান দর্শক';

  @override
  String get textToSpeech => 'লেখা থেকে মুখে বলা';

  @override
  String get streamPreview => 'সরাসরি সম্প্রচারের প্রিভিউ';

  @override
  String get activityFeed => 'অ্যাক্টিভিটি ফিড';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'এখন সরাসরি সম্প্রচার হচ্ছে $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'সরাসরি সম্প্রচার শেষ $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'সম্পূর্ণ চ্যাট মুছে ফেলা হলো $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'দ্রুত লিঙ্ক কনফিগার করুন';

  @override
  String get disableRainMode => 'বৃষ্টি মোড অক্ষম করুন';

  @override
  String get enableRainMode => 'বৃষ্টি মোড সক্ষম করুন';

  @override
  String get disableRainModeSubtitle => 'বৃষ্টি মোড এর সাবটাইটেল অক্ষম করুন';

  @override
  String get enableRainModeSubtitle => 'বৃষ্টি মোড এর সাবটাইটেল সক্ষম করুন';

  @override
  String get refreshAudioSources => 'শব্দের উৎস রিফ্রেশ করুন';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count শব্দের উৎস রিফ্রেশ করা হয়েছে',
      one: '1টি অডিও উত্স রিফ্রেশ করা হয়েছে৷',
      zero: 'কোনো শব্দের উৎস রিফ্রেশ করা হয়নি',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'সেটিংস';

  @override
  String get signOut => 'সাইন আউট';

  @override
  String get cancel => 'বাতিল';

  @override
  String get signOutConfirmation => 'আপনি সাইন আউট করতে চান?';

  @override
  String get broadcaster => 'সম্প্রচারক';

  @override
  String get moderators => 'মডারেটর';

  @override
  String get viewers => 'দর্শক';

  @override
  String get communityVips => 'কমিউনিটির ভিআইপি';

  @override
  String get searchViewers => 'দর্শক খুঁজুন';

  @override
  String get reconnecting => 'পুনর সংযোগের চেষ্টা হচ্ছে...';

  @override
  String get twitchBadges => 'টুইচ ব্যাজ';

  @override
  String get selectAll => 'সব সিলেক্ট করুন';

  @override
  String get quickLinks => 'দ্রুত লিঙ্ক';

  @override
  String get swipeToDeleteQuickLinks => 'দ্রুত লিঙ্ক মুছে ফেলতে সোয়াইপ করুন';

  @override
  String get quickLinksLabelHint => 'দ্রুত লিঙ্ক লেবেল ইঙ্গিত';

  @override
  String get invalidUrlErrorText => 'অবৈধ URL এর ত্রুটি টেক্সট';

  @override
  String get duplicateUrlErrorText => 'ডুপ্লিকেট URL ত্রুটি টেক্সট';

  @override
  String get or => 'অথবা';

  @override
  String get clearCookies => 'কুকিজ ক্লিয়ার করুন';

  @override
  String get disabled => 'অক্ষম';

  @override
  String get twitchActivityFeed => 'টুইচ এর একটিভিটি ফিড';

  @override
  String get signInToEnable => 'সক্ষম সাইন ইন করুন';

  @override
  String get customUrl => 'কাস্টম URL';

  @override
  String get preview => 'প্রিভিউ';

  @override
  String get audioSources => 'অডিও উত্স';

  @override
  String get enableOffStreamSwitchTitle =>
      'স্ট্রিম এর বাইরে থাকা অবস্থায় সক্রিয় করুন (বেশি ব্যাটারি ব্যবহার করে)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'স্ট্রিম এর বাইরে থাকা অবস্থায় সাবটাইটেল সক্রিয় করুন';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'স্ট্রিম এর বাইরে থাকা অবস্থায় সাবটাইটেল নিষ্ক্রিয় করুন';

  @override
  String get iosOggWarningTitle => 'এই শোনো';

  @override
  String get iosOggWarningSubtitle =>
      'iOS *.ogg ফর্ম্যাট সাপোর্ট করে না, যা স্ট্রিমল্যাবস এ ডিফল্টরূপে ব্যবহৃত হয়। অ্যালার্ট প্লে হওয়ার জন্য অন্য ফরম্যাট ব্যবহার করুন।';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'আপনার একটিভিটি ফিড কাস্টমাইজ করুন';

  @override
  String get audioSourcesSubtitle => 'সতর্কতা শব্দের জন্য ওয়েব উৎস যোগ করুন';

  @override
  String get quickLinksSubtitle =>
      'সাধারণত ব্যবহৃত টুল গুলোর জন্য শর্টকাট যোগ করুন';

  @override
  String get chatHistory => 'চ্যাট ইতিহাস';

  @override
  String get chatHistorySubtitle => 'চ্যাটের চেহারা পরিবর্তন করুন';

  @override
  String get textToSpeechSubtitle => 'টেক্সট টু স্পিচ সেটিংস পরিবর্তন করুন';

  @override
  String get events => 'ইভেন্টস';

  @override
  String get eventsSubtitle => 'টুইচ ইভেন্ট কনফিগার করুন';

  @override
  String get thirdPartyServices => 'থার্ড পার্টি সার্ভিসেস';

  @override
  String get thirdPartyServicesSubtitle =>
      'থার্ড পার্টি সার্ভিসেসের সাথে কানেক্ট করুন';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> আপনাকে অনুসরন করছে';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> এবং <b>$displayNameTwo</b> আপনাকে অনুসরন করছে';
  }

  @override
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>, <b>$displayNameTwo</b>, এবং $numOthersString জন আপনাকে অনুসরণ করছে';
  }

  @override
  String unmuteUser(String displayName) {
    return 'আনমিউট $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'মিউট $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'টাইমআউট  $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'ব্যান $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'আনব্যান $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'প্রোফাইল দেখুন $displayName';
  }

  @override
  String get copyMessage => 'মেসেজ কপি করুন';

  @override
  String get deleteMessage => 'মেসেজ ডিলিট করুন';

  @override
  String get longScrollNotification =>
      'আপনি অনেক দূরে স্ক্রোল করছেন, আপনি কি মনে করেন না?';

  @override
  String get stfu => 'চুপ করুন';

  @override
  String get globalEmotes => 'গ্লোবাল ইমোটস';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString অনুসারী',
      one: '1 অনুগামী',
      zero: '0 অনুসারী',
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
      other: '$countString দর্শক',
      one: '1 দর্শক',
      zero: '0 দর্শক',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'এই যে! আপনি স্ট্রীম প্রিভিউ ব্যবহার করতে পছন্দ করেন বলে খুশি কিন্তু জেনে রাখুন যে এটি অনেক ব্যাটারি ব্যবহার করে। এটি ছাড়া চ্যাট পড়া আপনার ব্যাটারির আয়ু বাড়িয়ে দেবে।';

  @override
  String get okay => 'ঠিক আছে';

  @override
  String get streamPreviewLoading => 'লোড হচ্ছে (বা স্ট্রিম অফলাইন)...';

  @override
  String get copiedToClipboard => 'ক্লিপবোর্ডে কপি করা হয়েছে';

  @override
  String get audioSourcesRequirePermissions => 'অডিও উত্স অনুমতি প্রয়োজন';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'অডিও সোর্স ব্যবহার করার জন্য অন্য অ্যাপের উপর আঁকতে RealtimeChat অনুমোদন করুন।';

  @override
  String get audioSourcesRemoveButton => 'অডিও উত্স সরান';

  @override
  String get audioSourcesOpenSettingsButton => 'ওপেন সেটিংস';

  @override
  String get flashOn => 'ফ্ল্যাশ অন';

  @override
  String get flashOff => 'ফ্ল্যাশ বন্ধ';

  @override
  String get durationOneSecond => '1 সেকেন্ড';

  @override
  String get durationOneMinute => '1 মিনিট';

  @override
  String get durationTenMinutes => '10 মিনিট';

  @override
  String get durationOneHour => '1 ঘন্টা';

  @override
  String get durationSixHours => '6 ঘন্টা';

  @override
  String get durationOneDay => '1 দিন';

  @override
  String get durationTwoDays => '২ দিন';

  @override
  String get durationOneWeek => '1 সপ্তাহ';

  @override
  String get durationTwoWeeks => '২ সপ্তাহ';

  @override
  String get durationOneSecondTimeoutPrompt => '1 সেকেন্ডের জন্য সময়সীমা';

  @override
  String get durationOneMinuteTimeoutPrompt => '1 মিনিটের জন্য টাইমআউট';

  @override
  String get durationTenMinutesTimeoutPrompt => '10 মিনিটের জন্য টাইমআউট';

  @override
  String get durationOneHourTimeoutPrompt => '1 ঘন্টার জন্য সময়সীমা';

  @override
  String get durationSixHoursTimeoutPrompt => '6 ঘন্টার জন্য সময়সীমা';

  @override
  String get durationOneDayTimeoutPrompt => '1 দিনের জন্য সময়সীমা';

  @override
  String get durationTwoDaysTimeoutPrompt => '2 দিনের জন্য সময়সীমা';

  @override
  String get durationOneWeekTimeoutPrompt => '1 সপ্তাহের জন্য সময়সীমা';

  @override
  String get durationTwoWeeksTimeoutPrompt => '2 সপ্তাহের জন্য সময়সীমা';

  @override
  String get errorFetchingViewerList =>
      'এই চ্যানেলের জন্য দর্শকের তালিকা আনা যায়নি';

  @override
  String get eventsTitle => 'ইভেন্টস';

  @override
  String get followEventConfigTitle => 'অনুসরণ ইভেন্ট';

  @override
  String get customizeYourFollowEvent => 'আপনার অনুসরণ ইভেন্ট কাস্টমাইজ করুন';

  @override
  String get subscribeEventConfigTitle => 'সাবস্ক্রাইব ইভেন্ট';

  @override
  String get customizeYourSubscriptionEvent =>
      'আপনার সাবস্ক্রিপশন ইভেন্ট কাস্টমাইজ করুন';

  @override
  String get cheerEventConfigTitle => 'চিয়ার ইভেন্ট';

  @override
  String get customizeYourCheerEvent => 'আপনার চিয়ার ইভেন্ট কাস্টমাইজ করুন';

  @override
  String get raidEventConfigTitle => 'রেইড ইভেন্ট';

  @override
  String get customizeYourRaidEvent => 'আপনার রেইড ইভেন্ট কাস্টমাইজ করুন';

  @override
  String get hostEventConfigTitle => 'হোস্ট ইভেন্ট';

  @override
  String get customizeYourHostEvent => 'আপনার হোস্ট ইভেন্ট কাস্টমাইজ করুন';

  @override
  String get hypetrainEventConfigTitle => 'হাইপ ট্রেন ইভেন্ট';

  @override
  String get customizeYourHypetrainEvent =>
      'আপনার হাইপ ট্রেন ইভেন্ট কাস্টমাইজ করুন';

  @override
  String get pollEventConfigTitle => 'পোল ইভেন্ট';

  @override
  String get customizeYourPollEvent => 'আপনার পোল ইভেন্ট কাস্টমাইজ করুন';

  @override
  String get predictionEventConfigTitle => 'ভবিষ্যদ্বাণী ইভেন্ট';

  @override
  String get customizeYourPredictionEvent =>
      'আপনার ভবিষ্যদ্বাণী ইভেন্ট কাস্টমাইজ করুন';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'চ্যানেল পয়েন্ট রিডেম্পশন ইভেন্ট';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'আপনার চ্যানেল পয়েন্ট রিডেম্পশন ইভেন্ট কাস্টমাইজ করুন';

  @override
  String get outgoingRaidEventConfigTitle => 'আউটগোয়িং রেইড ইভেন্ট';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'আপনার আউটগোয়িং রেইড ইভেন্ট কাস্টমাইজ করুন';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

    return '<b>$displayName</b> $viewerCountString দর্শক নিয়ে রেইড করছে!';
  }

  @override
  String get shoutout => 'শাউটআউট';

  @override
  String raidingEventRaiding(String displayName) {
    return 'রেইডিং <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString সেকেন্ড বাকি';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> রেইড করেছে!';
  }

  @override
  String get raidingEventJoin => 'যোগদান করুন';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b> এর রেইড বাতিল করা হয়েছে।';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> টিয়ার $tier এ সাবস্ক্রাইব করেছে!';
  }

  @override
  String subscriptionGiftEvent(
      String gifterUserName, int total, String tier, int cumulativeTotal) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat cumulativeTotalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeTotalString =
        cumulativeTotalNumberFormat.format(cumulativeTotal);

    return '<b>$gifterUserName</b> $totalString টি টিয়ার $tier সাব উপহার দিয়েছে, মোট $cumulativeTotalString!';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b> টিয়ার $tier এ $cumulativeMonthsString মাসের জন্য সাবস্ক্রাইব করেছে!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> টিপ দিয়েছে। <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'বেনামী টিপ দিয়েছে। <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> StreamElements এ <b>$formattedAmount</b> টিপ দিয়েছে।';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> Streamlabs এ <b>$formattedAmount</b> টিপ দিয়েছে।';
  }

  @override
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> <b>$rewardName</b> <b>$rewardCostString</b> পয়েন্টের জন্য রিডিম করেছে। $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> <b>$rewardName</b> <b>$rewardCostString</b> পয়েন্টের জন্য রিডিম করেছে।';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> <b>$bitsString</b> বিটস চিয়ার করেছে। $cheerMessage';
  }

  @override
  String get anonymous => 'বেনামী';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> <b>$viewersString</b> জনের পার্টি নিয়ে হোস্ট করছে।';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'হাইপ ট্রেন লেভেল <b>$level</b> চলছে! <b>$progressPercent%</b> সম্পন্ন হয়েছে!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'হাইপ ট্রেন লেভেল <b>$levelString</b> সফল হয়েছে।';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'হাইপ ট্রেন লেভেল <b>$levelString</b> ব্যর্থ হয়েছে।';
  }

  @override
  String get sampleMessage => 'এটি পাঠ্য থেকে বক্তৃতার জন্য একটি নমুনা বার্তা।';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author বলেছেন: $text';
  }

  @override
  String get textToSpeechEnabled => 'টেক্সট টু স্পিচ সক্ষম';

  @override
  String get textToSpeechDisabled => 'টেক্সট টু স্পিচ অক্ষম';

  @override
  String get alertsEnabled => 'Alerts only';

  @override
  String get sidebarActions => 'Sidebar Actions';
}
