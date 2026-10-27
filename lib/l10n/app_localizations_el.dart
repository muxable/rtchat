// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'package:rtchat/l10n/app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get sendAMessage => 'Στείλτε ένα μήνυμα...';

  @override
  String get writeSomething => 'Γράψτε κάτι...';

  @override
  String get speakToTheCrowds => 'Μιλήστε στο πλήθος...';

  @override
  String get shareYourThoughts => 'Μοιραστείτε τις σκέψεις σας...';

  @override
  String get saySomethingYouLittleBitch => 'Πες κάτι, ρε σκυλίτσα...';

  @override
  String get search => 'Αναζήτηση';

  @override
  String get notSignedIn => 'Χωρίς σύνδεση';

  @override
  String get searchChannels => 'Αναζήτηση';

  @override
  String get raidAChannel => 'Επιδρομή';

  @override
  String get noMessagesEmptyState => 'Επικρατεί ησυχία εδώ.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count νέα μηνύματα',
      one: '1 νέο μήνυμα',
      zero: 'Δεν υπάρχουν νέα μηνύματα',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Σύνδεση με Twitch';

  @override
  String get signInError =>
      'Παρουσιάστηκε σφάλμα κατά τη σύνδεση. Δοκιμάστε ξανά.';

  @override
  String get continueAsGuest => 'Συνέχεια ως επισκέπτης';

  @override
  String get signInToSendMessages => 'Συνδεθείτε για να στείλετε μηνύματα';

  @override
  String get currentViewers => 'Τρέχοντες θεατές';

  @override
  String get textToSpeech => 'Μετατροπή κειμένου σε ομιλία';

  @override
  String get streamPreview => 'Προεπισκόπηση ροής';

  @override
  String get activityFeed => 'Ροή δραστηριότητας';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Η ροή είναι ζωντανά στις $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Η ροή είναι εκτός σύνδεσης στις $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Η συνομιλία εκκαθαρίστηκε στις $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Διαμόρφωση γρήγορων συνδέσμων';

  @override
  String get disableRainMode => 'Απενεργοποίηση λειτουργίας βροχής';

  @override
  String get enableRainMode => 'Ενεργοποίηση λειτουργίας βροχής';

  @override
  String get disableRainModeSubtitle => 'Η αλληλεπίδραση θα ενεργοποιηθεί';

  @override
  String get enableRainModeSubtitle => 'Η αλληλεπίδραση θα απενεργοποιηθεί';

  @override
  String get refreshAudioSources => 'Ανανέωση πηγών ήχου';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ανανεώθηκαν $count πηγές ήχου',
      one: 'Ανανεώθηκε 1 πηγή ήχου',
      zero: 'Δεν ανανεώθηκαν πηγές ήχου',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Ρυθμίσεις';

  @override
  String get signOut => 'Αποσύνδεση';

  @override
  String get cancel => 'Ακύρωση';

  @override
  String get signOutConfirmation =>
      'Είστε βέβαιοι ότι θέλετε να αποσυνδεθείτε;';

  @override
  String get broadcaster => 'Δημιουργός μετάδοσης';

  @override
  String get moderators => 'Συντονιστές';

  @override
  String get viewers => 'Θεατές';

  @override
  String get communityVips => 'VIP κοινότητας';

  @override
  String get searchViewers => 'Αναζήτηση θεατών';

  @override
  String get reconnecting => 'Επανασύνδεση...';

  @override
  String get twitchBadges => 'Σήματα Twitch';

  @override
  String get selectAll => 'Επιλογή όλων';

  @override
  String get quickLinks => 'Γρήγοροι σύνδεσμοι';

  @override
  String get swipeToDeleteQuickLinks =>
      'Σύρετε αριστερά ή δεξιά για διαγραφή γρήγορου συνδέσμου';

  @override
  String get quickLinksLabelHint => 'Ετικέτα';

  @override
  String get invalidUrlErrorText => 'Αυτό δεν μοιάζει με έγκυρο URL';

  @override
  String get duplicateUrlErrorText => 'Αυτός ο σύνδεσμος υπάρχει ήδη';

  @override
  String get or => 'ή';

  @override
  String get clearCookies => 'Εκκαθάριση cookies';

  @override
  String get disabled => 'Απενεργοποιημένο';

  @override
  String get twitchActivityFeed => 'Ροή δραστηριότητας Twitch';

  @override
  String get signInToEnable => 'Πρέπει να συνδεθείτε για να το ενεργοποιήσετε';

  @override
  String get customUrl => 'Προσαρμοσμένο URL';

  @override
  String get preview => 'Προεπισκόπηση';

  @override
  String get audioSources => 'Πηγές ήχου';

  @override
  String get enableOffStreamSwitchTitle =>
      'Ενεργοποίηση εκτός ροής (καταναλώνει περισσότερη μπαταρία)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Ο ήχος θα αναπαράγεται επίσης όταν είστε εκτός σύνδεσης';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Ο ήχος θα αναπαράγεται μόνο όταν είστε ζωντανά';

  @override
  String get iosOggWarningTitle => 'Ε, ακούστε!';

  @override
  String get iosOggWarningSubtitle =>
      'Το iOS δεν υποστηρίζει αρχεία πολυμέσων *.ogg, τα οποία είναι τα προεπιλεγμένα αρχεία στο Streamlabs. Βεβαιωθείτε ότι οι πηγές ήχου σας χρησιμοποιούν άλλη μορφή, διαφορετικά δεν θα αναπαράγονται.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Προσαρμόστε τη ροή δραστηριότητάς σας';

  @override
  String get audioSourcesSubtitle =>
      'Προσθέστε πηγές ιστού για ήχους ειδοποιήσεων';

  @override
  String get quickLinksSubtitle =>
      'Προσθέστε συντομεύσεις σε εργαλεία που χρησιμοποιούνται συχνά';

  @override
  String get chatHistory => 'Ιστορικό συνομιλίας';

  @override
  String get chatHistorySubtitle => 'Αλλαγή της εμφάνισης της συνομιλίας';

  @override
  String get textToSpeechSubtitle =>
      'Αλλαγή ρυθμίσεων μετατροπής κειμένου σε ομιλία';

  @override
  String get events => 'Συμβάντα';

  @override
  String get eventsSubtitle => 'Διαμόρφωση συμβάντων Twitch';

  @override
  String get thirdPartyServices => 'Υπηρεσίες τρίτων';

  @override
  String get thirdPartyServicesSubtitle => 'Σύνδεση με υπηρεσία τρίτου μέρους';

  @override
  String followingEvent(String displayName) {
    return 'Ο/Η <b>$displayName</b> σας ακολουθεί';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return 'Οι <b>$displayName</b> και <b>$displayNameTwo</b> σας ακολουθούν';
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

    return 'Οι <b>$displayName</b>, <b>$displayNameTwo</b> και $numOthersString ακόμη σας ακολουθούν';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Κατάργηση σίγασης $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Σίγαση $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Προσωρινός αποκλεισμός $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Αποκλεισμός $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Άρση αποκλεισμού $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Προβολή προφίλ του/της $displayName';
  }

  @override
  String get copyMessage => 'Αντιγραφή μηνύματος';

  @override
  String get deleteMessage => 'Διαγραφή μηνύματος';

  @override
  String get longScrollNotification =>
      'Κάνετε κύλιση αρκετά πίσω, δεν νομίζετε;';

  @override
  String get stfu => 'σκάσε';

  @override
  String get globalEmotes => 'Καθολικά Emotes';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ακόλουθοι',
      one: '1 ακόλουθος',
      zero: '0 ακόλουθοι',
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
      other: '$countString θεατές',
      one: '1 θεατής',
      zero: '0 θεατές',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Γεια σας! Χαιρόμαστε που σας αρέσει η προεπισκόπηση ροής, αλλά έχετε υπόψη ότι καταναλώνει πολλή μπαταρία. Η ανάγνωση της συνομιλίας χωρίς αυτήν θα παρατείνει τη διάρκεια της μπαταρίας σας.';

  @override
  String get okay => 'Εντάξει';

  @override
  String get streamPreviewLoading =>
      'Φόρτωση (ή η ροή είναι εκτός σύνδεσης)...';

  @override
  String get copiedToClipboard => 'Αντιγράφηκε στο πρόχειρο';

  @override
  String get audioSourcesRequirePermissions =>
      'Οι πηγές ήχου απαιτούν δικαιώματα';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Εγκρίνετε το RealtimeChat να εμφανίζεται πάνω από άλλες εφαρμογές για να χρησιμοποιήσετε πηγές ήχου.';

  @override
  String get audioSourcesRemoveButton => 'Αφαίρεση πηγών ήχου';

  @override
  String get audioSourcesOpenSettingsButton => 'Άνοιγμα ρυθμίσεων';

  @override
  String get flashOn => 'Φλας ενεργό';

  @override
  String get flashOff => 'Φλας ανενεργό';

  @override
  String get durationOneSecond => '1 δευτερόλεπτο';

  @override
  String get durationOneMinute => '1 λεπτό';

  @override
  String get durationTenMinutes => '10 λεπτά';

  @override
  String get durationOneHour => '1 ώρα';

  @override
  String get durationSixHours => '6 ώρες';

  @override
  String get durationOneDay => '1 ημέρα';

  @override
  String get durationTwoDays => '2 ημέρες';

  @override
  String get durationOneWeek => '1 εβδομάδα';

  @override
  String get durationTwoWeeks => '2 εβδομάδες';

  @override
  String get durationOneSecondTimeoutPrompt =>
      'Προσωρινός αποκλεισμός για 1 δευτερόλεπτο';

  @override
  String get durationOneMinuteTimeoutPrompt =>
      'Προσωρινός αποκλεισμός για 1 λεπτό';

  @override
  String get durationTenMinutesTimeoutPrompt =>
      'Προσωρινός αποκλεισμός για 10 λεπτά';

  @override
  String get durationOneHourTimeoutPrompt => 'Προσωρινός αποκλεισμός για 1 ώρα';

  @override
  String get durationSixHoursTimeoutPrompt =>
      'Προσωρινός αποκλεισμός για 6 ώρες';

  @override
  String get durationOneDayTimeoutPrompt =>
      'Προσωρινός αποκλεισμός για 1 ημέρα';

  @override
  String get durationTwoDaysTimeoutPrompt =>
      'Προσωρινός αποκλεισμός για 2 ημέρες';

  @override
  String get durationOneWeekTimeoutPrompt =>
      'Προσωρινός αποκλεισμός για 1 εβδομάδα';

  @override
  String get durationTwoWeeksTimeoutPrompt =>
      'Προσωρινός αποκλεισμός για 2 εβδομάδες';

  @override
  String get errorFetchingViewerList =>
      'Δεν ήταν δυνατή η ανάκτηση της λίστας θεατών για αυτό το κανάλι';

  @override
  String get eventsTitle => 'Συμβάντα';

  @override
  String get followEventConfigTitle => 'Συμβάν παρακολούθησης';

  @override
  String get customizeYourFollowEvent => 'Προσαρμόστε το συμβάν παρακολούθησης';

  @override
  String get subscribeEventConfigTitle => 'Συμβάν εγγραφής';

  @override
  String get customizeYourSubscriptionEvent => 'Προσαρμόστε το συμβάν εγγραφής';

  @override
  String get cheerEventConfigTitle => 'Συμβάν Cheer';

  @override
  String get customizeYourCheerEvent => 'Προσαρμόστε το συμβάν Cheer';

  @override
  String get raidEventConfigTitle => 'Συμβάν επιδρομής';

  @override
  String get customizeYourRaidEvent => 'Προσαρμόστε το συμβάν επιδρομής';

  @override
  String get hostEventConfigTitle => 'Συμβάν φιλοξενίας';

  @override
  String get customizeYourHostEvent => 'Προσαρμόστε το συμβάν φιλοξενίας';

  @override
  String get hypetrainEventConfigTitle => 'Συμβάν Hype Train';

  @override
  String get customizeYourHypetrainEvent => 'Προσαρμόστε το συμβάν Hype Train';

  @override
  String get pollEventConfigTitle => 'Συμβάν ψηφοφορίας';

  @override
  String get customizeYourPollEvent => 'Προσαρμόστε το συμβάν ψηφοφορίας';

  @override
  String get predictionEventConfigTitle => 'Συμβάν πρόβλεψης';

  @override
  String get customizeYourPredictionEvent => 'Προσαρμόστε το συμβάν πρόβλεψης';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Συμβάν εξαργύρωσης πόντων καναλιού';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Προσαρμόστε το συμβάν εξαργύρωσης πόντων καναλιού';

  @override
  String get outgoingRaidEventConfigTitle => 'Συμβάν εξερχόμενης επιδρομής';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Προσαρμόστε το συμβάν εξερχόμενης επιδρομής';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return 'Ο/Η <b>$displayName</b> κάνει επιδρομή με <b>$viewerCountString</b> θεατές!';
  }

  @override
  String get shoutout => 'Μνεία';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Επιδρομή στο κανάλι <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString δευτ.';
  }

  @override
  String raidingEventRaided(String displayName) {
    return 'Ο/Η <b>$displayName</b> ολοκλήρωσε την επιδρομή!';
  }

  @override
  String get raidingEventJoin => 'Συμμετοχή';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Η επιδρομή του/της <b>$displayName</b> ακυρώθηκε.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return 'Ο/Η <b>$subscriberUserName</b> έκανε εγγραφή στη βαθμίδα $tier!';
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

    return 'Ο/Η <b>$gifterUserName</b> έκανε δώρο $totalString εγγραφές βαθμίδας $tier, συνολικά $cumulativeTotalString!';
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

    return 'Ο/Η <b>$subscriberUserName</b> έχει εγγραφεί για $cumulativeMonthsString μήνες στη βαθμίδα $tier!';
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

    return 'Ο/Η <b>$subscriberUserName</b> έκανε εγγραφή στη βαθμίδα $tier για $durationMonthsString μήνες προκαταβολικά, $cumulativeMonthsString μήνες συνολικά!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return 'Ο/Η <b>$donor</b> έδωσε φιλοδώρημα <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Ανώνυμος χρήστης έδωσε φιλοδώρημα <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return 'Ο/Η <b>$name</b> έδωσε φιλοδώρημα <b>$formattedAmount</b> στο StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return 'Ο/Η <b>$name</b> έδωσε φιλοδώρημα <b>$formattedAmount</b> στο Streamlabs.';
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

    return 'Ο/Η <b>$redeemerUsername</b> εξαργύρωσε το <b>$rewardName</b> για <b>$rewardCostString</b> πόντους. $userInput';
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

    return 'Ο/Η <b>$redeemerUsername</b> εξαργύρωσε το <b>$rewardName</b> για <b>$rewardCostString</b> πόντους.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return 'Ο/Η <b>$name</b> έστειλε Cheer με <b>$bitsString</b> bits. $cheerMessage';
  }

  @override
  String get anonymous => 'Ανώνυμος';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return 'Ο/Η <b>$fromDisplayName</b> φιλοξενεί με μια ομάδα <b>$viewersString</b> θεατών.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Το Hype Train επιπέδου <b>$level</b> βρίσκεται σε εξέλιξη! Ολοκληρώθηκε κατά <b>$progressPercent%</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Το Hype Train επιπέδου <b>$levelString</b> ολοκληρώθηκε με επιτυχία.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Το Hype Train επιπέδου <b>$levelString</b> απέτυχε.';
  }

  @override
  String get sampleMessage =>
      'Αυτό είναι ένα δείγμα μηνύματος για μετατροπή κειμένου σε ομιλία.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author είπε: $text';
  }

  @override
  String get textToSpeechEnabled =>
      'Η μετατροπή κειμένου σε ομιλία ενεργοποιήθηκε';

  @override
  String get textToSpeechDisabled =>
      'Η μετατροπή κειμένου σε ομιλία απενεργοποιήθηκε';

  @override
  String get alertsEnabled => 'Μόνο ειδοποιήσεις';

  @override
  String get pinDuration => 'Διάρκεια καρφιτσώματος';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds δευτερόλεπτα',
      one: '1 δευτερόλεπτο',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes λεπτά',
      one: '1 λεπτό',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Ενεργοποίηση συμβάντος';

  @override
  String get showEventInChatHistory =>
      'Εμφάνιση συμβάντος στο ιστορικό συνομιλίας';

  @override
  String get enableShoutouts => 'Ενεργοποίηση μνειών';

  @override
  String get enableShoutoutsSubtitle =>
      'Αποστολή συνδέσμου του καναλιού που κάνει επιδρομή στη συνομιλία';

  @override
  String get raidConfigurationTitle => 'Διαμόρφωση επιδρομής';

  @override
  String get cheerConfigurationTitle => 'Διαμόρφωση Cheer';

  @override
  String get followConfigurationTitle => 'Διαμόρφωση παρακολούθησης';

  @override
  String get outgoingRaidConfigurationTitle =>
      'Διαμόρφωση εξερχόμενης επιδρομής';

  @override
  String get hostConfigurationTitle => 'Διαμόρφωση φιλοξενίας';

  @override
  String get channelPointConfigurationTitle => 'Διαμόρφωση πόντων καναλιού';

  @override
  String get pollConfigurationTitle => 'Διαμόρφωση ψηφοφορίας';

  @override
  String get hypetrainConfigurationTitle => 'Διαμόρφωση Hype Train';

  @override
  String get subscriptionConfigurationTitle => 'Διαμόρφωση εγγραφής';

  @override
  String get predictionConfigurationTitle => 'Διαμόρφωση πρόβλεψης';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Πρόσθετη διάρκεια καρφιτσώματος για ανεκπλήρωτες ανταμοιβές';

  @override
  String get pollPinDuration =>
      'Διάρκεια καρφιτσώματος μετά την οριστικοποίηση του αποτελέσματος';

  @override
  String get hypetrainPinDuration =>
      'Διάρκεια καρφιτσώματος μετά τη λήξη του Hype Train';

  @override
  String get enableGiftedSubscriptions =>
      'Ενεργοποίηση μεμονωμένων εγγραφών δώρου';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Εμφάνιση κάθε εγγραφής που προσφέρεται ως δώρο';

  @override
  String get settingsBackupTitle =>
      'Δημιουργία αντιγράφων ασφαλείας και επαναφορά ρυθμίσεων';

  @override
  String get cloudBackup => 'Αντίγραφο ασφαλείας στο cloud';

  @override
  String get lastBackupNever => 'Τελευταίο αντίγραφο ασφαλείας: ποτέ';

  @override
  String get backUp => 'Δημιουργία αντιγράφου';

  @override
  String get restore => 'Επαναφορά';

  @override
  String get localBackup => 'Τοπικό αντίγραφο ασφαλείας';

  @override
  String get exportSettings => 'Εξαγωγή';

  @override
  String get importSettings => 'Εισαγωγή';

  @override
  String get showViewerAndFollowerCount =>
      'Εμφάνιση αριθμού θεατών και ακολούθων';

  @override
  String get screenOrientation => 'Προσανατολισμός οθόνης';

  @override
  String get appTheme => 'Θέμα εφαρμογής';

  @override
  String get systemDefault => 'Σύστημα';

  @override
  String get portrait => 'Κατακόρυφα';

  @override
  String get landscape => 'Οριζόντια';

  @override
  String get lightTheme => 'Φωτεινό';

  @override
  String get darkTheme => 'Σκοτεινό';

  @override
  String get openSourceTitle => 'Το RealtimeChat είναι ανοιχτού κώδικα';

  @override
  String get openSourceSubtitle => 'Βρείτε μας στο GitHub!';

  @override
  String get discordSubtitle => 'Γίνετε μέλος στο Discord της Muxable!';

  @override
  String get earlyTestersThanks =>
      'Ευχαριστούμε όλους τους πρώτους δοκιμαστές που έστειλαν αναφορές σφαλμάτων!';

  @override
  String get discoModeEnabled => '🕺 Η λειτουργία ντίσκο ενεργοποιήθηκε! :D';

  @override
  String get discoModeDisabled => '🕺 Η λειτουργία ντίσκο απενεργοποιήθηκε D:';

  @override
  String get playSampleMessage => 'Αναπαραγωγή δείγματος μηνύματος';

  @override
  String get textToSpeechRate => 'Ταχύτητα μετατροπής κειμένου σε ομιλία';

  @override
  String get textToSpeechPitch => 'Τόνος μετατροπής κειμένου σε ομιλία';

  @override
  String get muteBots => 'Σίγαση μετατροπής κειμένου σε ομιλία για bots';

  @override
  String get muteEmotes =>
      'Σίγαση όλων των emotes στη μετατροπή κειμένου σε ομιλία';

  @override
  String get muteViewerNames =>
      'Σίγαση ονομάτων θεατών στη μετατροπή κειμένου σε ομιλία';

  @override
  String get subscribersOnly => 'Μόνο συνδρομητές';

  @override
  String get fontSize => 'Μέγεθος γραμματοσειράς';

  @override
  String get usernameContrastBoost => 'Ενίσχυση αντίθεσης ονόματος χρήστη';

  @override
  String get twitchBadgeSettings => 'Ρυθμίσεις σημάτων Twitch';

  @override
  String get twitchBadgeSettingsSubtitle => 'Ελέγξτε ποια σήματα είναι ορατά';

  @override
  String get showDeletedMessages => 'Εμφάνιση διαγραμμένων μηνυμάτων';

  @override
  String get deletedMessagesGreyedOut =>
      'Τα διαγραμμένα μηνύματα θα εμφανίζονται με γκρι χρώμα';

  @override
  String get deletedMessagesRemoved => 'Τα διαγραμμένα μηνύματα θα αφαιρούνται';

  @override
  String get showLoginNames => 'Εμφάνιση ονομάτων σύνδεσης';

  @override
  String get loginNamesShown =>
      'Τα ονόματα σύνδεσης θα εμφανίζονται εάν διαφέρουν από το εμφανιζόμενο όνομα';

  @override
  String get loginNamesHidden => 'Τα ονόματα σύνδεσης θα αποκρύπτονται';

  @override
  String get compactMessages => 'Σύμπτυξη μηνυμάτων';

  @override
  String get dontCompactMessages => 'Χωρίς σύμπτυξη μηνυμάτων';

  @override
  String get dontCompactMessagesSubtitle =>
      'Τα μηνύματα εμφανίζονται χωρίς αλλαγές';

  @override
  String get compactIndividualMessages => 'Σύμπτυξη μεμονωμένων μηνυμάτων';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Το επαναλαμβανόμενο κείμενο στα μηνύματα συντομεύεται';

  @override
  String get announcementPinDuration => 'Διάρκεια καρφιτσώματος ανακοίνωσης';

  @override
  String get idleMessageAlertDuration =>
      'Διάρκεια ειδοποίησης αδράνειας μηνυμάτων';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Εάν δεν υπάρχουν μηνύματα για αυτό το χρονικό διάστημα και έρθει ένα νέο, θα αναπαραχθεί ένας ήχος ειδοποίησης.';

  @override
  String get realtimeCashSubtitle => 'Συνδέστε ένα πορτοφόλι ETH ή MATIC';

  @override
  String get walletAddress => 'Διεύθυνση πορτοφολιού';

  @override
  String get streamlabsSubtitle => 'Δείτε τις δωρεές σας στο Streamlabs';

  @override
  String get streamElementsSubtitle =>
      'Δείτε τις δωρεές σας στο StreamElements';

  @override
  String get thirdPartyAuthError =>
      'Χμμ, αυτό δεν λειτούργησε. Δοκιμάστε ξανά ή ρωτήστε στο Discord;';

  @override
  String get companionAuthBrowserTooOld =>
      'Το πρόγραμμα περιήγησής σας είναι πολύ παλιό για να υποστηρίξει την απευθείας σύνδεση. Σαρώστε αυτόν τον κωδικό QR με το τηλέφωνό σας για να συνδεθείτε σε άλλη συσκευή.';

  @override
  String get companionAuthScanQrCode =>
      'Σαρώστε αυτόν τον κωδικό QR με το τηλέφωνό σας για να συνδεθείτε σε άλλη συσκευή.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return 'Ο/Η <b>$subscriberName</b> έκανε εγγραφή!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return 'Ο/Η <b>$subscriberName</b> ανανέωσε την εγγραφή για $monthsString μήνες!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Ο/Η <b>$gifterName</b> έκανε δώρο $countString εγγραφές!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'Ο/Η <b>$senderName</b> έστειλε $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Σύνδεση με Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Υπάρχουν πάρα πολλά μηνύματα. Η μετατροπή κειμένου σε ομιλία απενεργοποιήθηκε';

  @override
  String get turnOffTextToSpeech => 'Απενεργοποίηση';

  @override
  String get addToChat => 'Προσθήκη στη συνομιλία';

  @override
  String get inChat => 'Στη συνομιλία';

  @override
  String get removeFromChat => 'Αφαίρεση από τη συνομιλία';

  @override
  String cantChatWithAccount(String provider) {
    return 'Ο λογαριασμός σας στο $provider δεν μπορεί να συνομιλήσει εδώ';
  }

  @override
  String get cantChatWithAccounts =>
      'Οι λογαριασμοί σας δεν μπορούν να συνομιλήσουν εδώ';

  @override
  String sendAMessageTo(String channel) {
    return 'Στείλτε ένα μήνυμα στο κανάλι $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Αντικατάσταση του $channel';
  }

  @override
  String get voicePacks => 'Πακέτα φωνής';

  @override
  String get voicePacksDescription =>
      'Τα πακέτα φωνής διαβάζουν τη συνομιλία με φυσικές φωνές που εκτελούνται στη συσκευή σας, εκτός σύνδεσης μετά τη λήψη. Οι φωνές δημιουργούνται μηχανικά από τεχνητή νοημοσύνη και δεν έχουν ηχογραφηθεί από άνθρωπο.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices φωνές',
      one: '1 φωνή',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count γλώσσες',
      one: '1 γλώσσα',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Η άδεια χρήσης αυτού του μοντέλου (OpenRAIL-M) απαγορεύει επιβλαβείς χρήσεις, όπως την πλαστοπροσωπία ατόμων ή τη διάδοση παραπληροφόρησης, και αυτοί οι περιορισμοί ισχύουν και για εσάς.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Διαγραφή του $pack; Αυτό ελευθερώνει $size.';
  }

  @override
  String get voicePackDownload => 'Λήψη';

  @override
  String get voicePackUpdate => 'Ενημέρωση';

  @override
  String get voicePackWaitingForWifi => 'Αναμονή για Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Χρήση δεδομένων κινητής τηλεφωνίας';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Λήψη: $downloaded από $total';
  }

  @override
  String get voicePackInstalling => 'Εγκατάσταση';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Δεν ήταν δυνατή η εγκατάσταση του $pack. Ελέγξτε τη σύνδεσή σας και δοκιμάστε ξανά.';
  }

  @override
  String get voices => 'Φωνές';

  @override
  String get perViewerVoice => 'Φωνή ανά θεατή';

  @override
  String get perViewerVoiceSubtitle =>
      'Κάθε θεατής αποκτά τη δική του φωνή. Η φωνή που επιλέγετε διαβάζει τις ειδοποιήσεις ή τα πάντα όταν αυτό είναι ανενεργό.';

  @override
  String get streamLanguage => 'Γλώσσα ροής';

  @override
  String get ttsEngineNeural => 'Νευρωνική φωνή (στη συσκευή)';

  @override
  String get ttsEngineSystem => 'Φωνή συστήματος';

  @override
  String languageUnsupported(String language) {
    return 'Η γλώσσα $language δεν υποστηρίζεται από τα πακέτα φωνής σας· θα χρησιμοποιηθεί η φωνή συστήματος';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Αυτή η συσκευή δεν διαθέτει αρκετή μνήμη για νευρωνικές φωνές, επομένως η συνομιλία διαβάζεται με τη φωνή συστήματος.';

  @override
  String get neuralFallbackLoadFailed =>
      'Δεν ήταν δυνατή η φόρτωση της νευρωνικής φωνής, επομένως η συνομιλία διαβάζεται με τη φωνή συστήματος.';

  @override
  String get accounts => 'Λογαριασμοί';

  @override
  String get accountsSubtitle =>
      'Συνδεθείτε σε κάθε πλατφόρμα στην οποία μεταδίδετε';

  @override
  String addProviderAccount(String provider) {
    return 'Προσθήκη λογαριασμού $provider';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Σύνδεση με $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Αποσύνδεση από το $channel στο $provider;';
  }

  @override
  String get signOutOfAll => 'Αποσύνδεση από όλους τους λογαριασμούς';
}
