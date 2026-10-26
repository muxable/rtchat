// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get sendAMessage => 'Hantar mesej...';

  @override
  String get writeSomething => 'Tulis sesuatu...';

  @override
  String get speakToTheCrowds => 'Berbual dengan penonton...';

  @override
  String get shareYourThoughts => 'Kongsi pendapat anda...';

  @override
  String get saySomethingYouLittleBitch =>
      'Cakaplah sesuatu, dasar pengecut...';

  @override
  String get search => 'Cari';

  @override
  String get notSignedIn => 'Belum log masuk';

  @override
  String get searchChannels => 'Cari';

  @override
  String get raidAChannel => 'Serbu Saluran';

  @override
  String get noMessagesEmptyState => 'Sunyi sahaja di sini.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mesej baharu',
      one: '1 mesej baharu',
      zero: 'Tiada mesej baharu',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Log masuk dengan Twitch';

  @override
  String get signInError => 'Ralat berlaku semasa log masuk. Sila cuba lagi.';

  @override
  String get continueAsGuest => 'Teruskan sebagai Tetamu';

  @override
  String get signInToSendMessages => 'Log masuk untuk menghantar mesej';

  @override
  String get currentViewers => 'Penonton semasa';

  @override
  String get textToSpeech => 'Teks ke pertuturan';

  @override
  String get streamPreview => 'Pratonton strim';

  @override
  String get activityFeed => 'Suapan aktiviti';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Strim dalam talian pada $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Strim luar talian pada $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Sembang dikosongkan pada $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Konfigurasikan pautan pantas';

  @override
  String get disableRainMode => 'Lumpuhkan mod hujan';

  @override
  String get enableRainMode => 'Dayakan mod hujan';

  @override
  String get disableRainModeSubtitle => 'Interaksi akan didayakan';

  @override
  String get enableRainModeSubtitle => 'Interaksi akan dilumpuhkan';

  @override
  String get refreshAudioSources => 'Muat semula sumber audio';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sumber audio dimuat semula',
      one: '1 sumber audio dimuat semula',
      zero: 'Tiada sumber audio dimuat semula',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Tetapan';

  @override
  String get signOut => 'Log keluar';

  @override
  String get cancel => 'Batal';

  @override
  String get signOutConfirmation => 'Adakah anda pasti mahu log keluar?';

  @override
  String get broadcaster => 'Penyiar';

  @override
  String get moderators => 'Moderator';

  @override
  String get viewers => 'Penonton';

  @override
  String get communityVips => 'VIP Komuniti';

  @override
  String get searchViewers => 'Cari Penonton';

  @override
  String get reconnecting => 'Menyambung semula...';

  @override
  String get twitchBadges => 'Lencana Twitch';

  @override
  String get selectAll => 'Pilih semua';

  @override
  String get quickLinks => 'Pautan pantas';

  @override
  String get swipeToDeleteQuickLinks =>
      'Leret ke kiri atau kanan untuk memadamkan pautan pantas';

  @override
  String get quickLinksLabelHint => 'Nama label';

  @override
  String get invalidUrlErrorText => 'Ini tidak kelihatan seperti URL yang sah';

  @override
  String get duplicateUrlErrorText => 'Pautan ini sudah wujud';

  @override
  String get or => 'atau';

  @override
  String get clearCookies => 'Kosongkan kuki';

  @override
  String get disabled => 'Dilumpuhkan';

  @override
  String get twitchActivityFeed => 'Suapan aktiviti Twitch';

  @override
  String get signInToEnable => 'Anda mesti log masuk untuk mendayakan ciri ini';

  @override
  String get customUrl => 'URL Tersuai';

  @override
  String get preview => 'Pratonton';

  @override
  String get audioSources => 'Sumber audio';

  @override
  String get enableOffStreamSwitchTitle =>
      'Dayakan di luar strim (menggunakan lebih banyak bateri)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Audio juga akan dimainkan apabila anda berada di luar talian';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Audio hanya akan dimainkan apabila anda bersiaran langsung';

  @override
  String get iosOggWarningTitle => 'Hei! Dengar sini!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS tidak menyokong fail media *.ogg, iaitu fail lalai di Streamlabs. Pastikan sumber audio anda menggunakan format lain, jika tidak ia tidak akan dimainkan.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Sesuaikan suapan aktiviti anda';

  @override
  String get audioSourcesSubtitle => 'Tambah sumber web untuk bunyi makluman';

  @override
  String get quickLinksSubtitle =>
      'Tambah pintasan ke alatan yang kerap digunakan';

  @override
  String get chatHistory => 'Sejarah sembang';

  @override
  String get chatHistorySubtitle => 'Tukar penampilan sembang';

  @override
  String get textToSpeechSubtitle => 'Tukar tetapan teks ke pertuturan';

  @override
  String get events => 'Acara';

  @override
  String get eventsSubtitle => 'Konfigurasikan acara Twitch';

  @override
  String get thirdPartyServices => 'Perkhidmatan pihak ketiga';

  @override
  String get thirdPartyServicesSubtitle =>
      'Sambung ke perkhidmatan pihak ketiga';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> sedang mengikuti anda';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> dan <b>$displayNameTwo</b> sedang mengikuti anda';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b>, dan $numOthersString yang lain sedang mengikuti anda';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Nyahsenyapkan $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Senyapkan $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Gantung $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Sekat $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Nyahsekat $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Lihat profil $displayName';
  }

  @override
  String get copyMessage => 'Salin Mesej';

  @override
  String get deleteMessage => 'Padam Mesej';

  @override
  String get longScrollNotification => 'Jauh betul anda menatal, bukan?';

  @override
  String get stfu => 'diam';

  @override
  String get globalEmotes => 'Emote Global';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString pengikut',
      one: '1 pengikut',
      zero: '0 pengikut',
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
      other: '$countString penonton',
      one: '1 penonton',
      zero: '0 penonton',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Hai! Gembira melihat anda menggunakan pratonton strim, tetapi perlu diingat bahawa ia menggunakan banyak bateri. Membaca sembang tanpanya akan memanjangkan hayat bateri anda.';

  @override
  String get okay => 'Baik';

  @override
  String get streamPreviewLoading =>
      'Memuatkan (atau strim sedang luar talian)...';

  @override
  String get copiedToClipboard => 'Disalin ke papan keratan';

  @override
  String get audioSourcesRequirePermissions =>
      'Sumber audio memerlukan kebenaran';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Benarkan RealtimeChat dipaparkan di atas aplikasi lain untuk menggunakan sumber audio.';

  @override
  String get audioSourcesRemoveButton => 'Alih keluar sumber audio';

  @override
  String get audioSourcesOpenSettingsButton => 'Buka tetapan';

  @override
  String get flashOn => 'Denyar hidup';

  @override
  String get flashOff => 'Denyar mati';

  @override
  String get durationOneSecond => '1 saat';

  @override
  String get durationOneMinute => '1 minit';

  @override
  String get durationTenMinutes => '10 minit';

  @override
  String get durationOneHour => '1 jam';

  @override
  String get durationSixHours => '6 jam';

  @override
  String get durationOneDay => '1 hari';

  @override
  String get durationTwoDays => '2 hari';

  @override
  String get durationOneWeek => '1 minggu';

  @override
  String get durationTwoWeeks => '2 minggu';

  @override
  String get durationOneSecondTimeoutPrompt => 'Gantung selama 1 saat';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Gantung selama 1 minit';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Gantung selama 10 minit';

  @override
  String get durationOneHourTimeoutPrompt => 'Gantung selama 1 jam';

  @override
  String get durationSixHoursTimeoutPrompt => 'Gantung selama 6 jam';

  @override
  String get durationOneDayTimeoutPrompt => 'Gantung selama 1 hari';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Gantung selama 2 hari';

  @override
  String get durationOneWeekTimeoutPrompt => 'Gantung selama 1 minggu';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Gantung selama 2 minggu';

  @override
  String get errorFetchingViewerList =>
      'Kami tidak dapat mengambil senarai penonton untuk saluran ini';

  @override
  String get eventsTitle => 'Acara';

  @override
  String get followEventConfigTitle => 'Acara Ikuti';

  @override
  String get customizeYourFollowEvent => 'Sesuaikan acara ikuti anda';

  @override
  String get subscribeEventConfigTitle => 'Acara Langganan';

  @override
  String get customizeYourSubscriptionEvent => 'Sesuaikan acara langganan anda';

  @override
  String get cheerEventConfigTitle => 'Acara Cheer';

  @override
  String get customizeYourCheerEvent => 'Sesuaikan acara cheer anda';

  @override
  String get raidEventConfigTitle => 'Acara Raid';

  @override
  String get customizeYourRaidEvent => 'Sesuaikan acara raid anda';

  @override
  String get hostEventConfigTitle => 'Acara Host';

  @override
  String get customizeYourHostEvent => 'Sesuaikan acara host anda';

  @override
  String get hypetrainEventConfigTitle => 'Acara Hype Train';

  @override
  String get customizeYourHypetrainEvent => 'Sesuaikan acara Hype Train anda';

  @override
  String get pollEventConfigTitle => 'Acara Tinjauan';

  @override
  String get customizeYourPollEvent => 'Sesuaikan acara tinjauan anda';

  @override
  String get predictionEventConfigTitle => 'Acara Ramalan';

  @override
  String get customizeYourPredictionEvent => 'Sesuaikan acara ramalan anda';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Acara Penebusan Mata Saluran';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Sesuaikan acara penebusan mata saluran anda';

  @override
  String get outgoingRaidEventConfigTitle => 'Acara Raid Keluar';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Sesuaikan acara raid keluar anda';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> sedang menyerbu dengan <b>$viewerCountString</b> penonton!';
  }

  @override
  String get shoutout => 'Sebutan Khas';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Menyerbu <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString saat';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> telah menyerbu!';
  }

  @override
  String get raidingEventJoin => 'Sertai';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Raid <b>$displayName</b> telah dibatalkan.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> telah melanggan pada Tahap $tier!';
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

    return '<b>$gifterUserName</b> telah menghadiahkan $totalString langganan Tahap $tier, berjumlah $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> telah melanggan selama $cumulativeMonthsString bulan pada Tahap $tier!';
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

    return '<b>$subscriberUserName</b> telah melanggan pada Tahap $tier selama $durationMonthsString bulan lebih awal, berjumlah $cumulativeMonthsString bulan kesemuanya!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> memberi tip sebanyak <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Tanpa nama memberi tip sebanyak <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> memberi tip sebanyak <b>$formattedAmount</b> di StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> memberi tip sebanyak <b>$formattedAmount</b> di Streamlabs.';
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

    return '<b>$redeemerUsername</b> menebus <b>$rewardName</b> dengan <b>$rewardCostString</b> mata. $userInput';
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

    return '<b>$redeemerUsername</b> menebus <b>$rewardName</b> dengan <b>$rewardCostString</b> mata.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> melakukan cheer <b>$bitsString</b> bit. $cheerMessage';
  }

  @override
  String get anonymous => 'Tanpa Nama';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> sedang mengehos bersama <b>$viewersString</b> penonton.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train tahap <b>$level</b> sedang berlangsung! <b>$progressPercent%</b> selesai!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train tahap <b>$levelString</b> berjaya.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train tahap <b>$levelString</b> gagal.';
  }

  @override
  String get sampleMessage =>
      'Ini ialah contoh mesej untuk penukaran teks kepada pertuturan.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author berkata: $text';
  }

  @override
  String get textToSpeechEnabled => 'Teks ke pertuturan didayakan';

  @override
  String get textToSpeechDisabled => 'Teks ke pertuturan dilumpuhkan';

  @override
  String get alertsEnabled => 'Makluman sahaja';

  @override
  String get pinDuration => 'Tempoh Pin';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds saat',
      one: '1 saat',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minit',
      one: '1 minit',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Dayakan acara';

  @override
  String get showEventInChatHistory => 'Tunjukkan acara dalam sejarah sembang';

  @override
  String get enableShoutouts => 'Dayakan sebutan khas';

  @override
  String get enableShoutoutsSubtitle =>
      'Hantar pautan saluran yang menyerbu ke sembang';

  @override
  String get raidConfigurationTitle => 'Konfigurasi Raid';

  @override
  String get cheerConfigurationTitle => 'Konfigurasi Cheer';

  @override
  String get followConfigurationTitle => 'Konfigurasi Ikuti';

  @override
  String get outgoingRaidConfigurationTitle => 'Konfigurasi Raid Keluar';

  @override
  String get hostConfigurationTitle => 'Konfigurasi Host';

  @override
  String get channelPointConfigurationTitle => 'Konfigurasi Mata Saluran';

  @override
  String get pollConfigurationTitle => 'Konfigurasi Tinjauan';

  @override
  String get hypetrainConfigurationTitle => 'Konfigurasi Hype Train';

  @override
  String get subscriptionConfigurationTitle => 'Konfigurasi Langganan';

  @override
  String get predictionConfigurationTitle => 'Konfigurasi Ramalan';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Tempoh Pin Tambahan untuk Ganjaran yang Belum Ditunaikan';

  @override
  String get pollPinDuration => 'Tempoh pin selepas keputusan dimuktamadkan';

  @override
  String get hypetrainPinDuration => 'Tempoh pin selepas Hype Train tamat';

  @override
  String get enableGiftedSubscriptions => 'Dayakan langganan hadiah individu';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Tunjukkan setiap langganan yang dihadiahkan';

  @override
  String get settingsBackupTitle => 'Sandaran dan pemulihan tetapan';

  @override
  String get cloudBackup => 'Sandaran awan';

  @override
  String get lastBackupNever => 'Sandaran terakhir: tiada';

  @override
  String get backUp => 'Sandarkan';

  @override
  String get restore => 'Pulihkan';

  @override
  String get localBackup => 'Sandaran setempat';

  @override
  String get exportSettings => 'Eksport tetapan';

  @override
  String get importSettings => 'Import tetapan';

  @override
  String get showViewerAndFollowerCount =>
      'Tunjukkan bilangan penonton dan pengikut';

  @override
  String get screenOrientation => 'Orientasi skrin';

  @override
  String get appTheme => 'Tema aplikasi';

  @override
  String get systemDefault => 'Sistem';

  @override
  String get portrait => 'Potret';

  @override
  String get landscape => 'Landskap';

  @override
  String get lightTheme => 'Cerah';

  @override
  String get darkTheme => 'Gelap';

  @override
  String get openSourceTitle => 'RealtimeChat ialah sumber terbuka';

  @override
  String get openSourceSubtitle => 'Cari kami di GitHub!';

  @override
  String get discordSubtitle => 'Sertai Discord Muxable!';

  @override
  String get earlyTestersThanks =>
      'Terima kasih kepada semua penguji awal yang telah menghantar laporan pepijat!';

  @override
  String get discoModeEnabled => '🕺 Mod disko didayakan! :D';

  @override
  String get discoModeDisabled => '🕺 Mod disko dilumpuhkan D:';

  @override
  String get playSampleMessage => 'Mainkan mesej contoh';

  @override
  String get textToSpeechRate => 'Kelajuan Teks ke Pertuturan';

  @override
  String get textToSpeechPitch => 'Pic Teks ke Pertuturan';

  @override
  String get muteBots => 'Senyapkan teks ke pertuturan untuk bot';

  @override
  String get muteEmotes => 'Senyapkan semua emote dalam teks ke pertuturan';

  @override
  String get muteViewerNames =>
      'Senyapkan nama penonton dalam teks ke pertuturan';

  @override
  String get subscribersOnly => 'Pelanggan sahaja';

  @override
  String get fontSize => 'Saiz fon';

  @override
  String get usernameContrastBoost => 'Galakan kontras nama pengguna';

  @override
  String get twitchBadgeSettings => 'Tetapan lencana Twitch';

  @override
  String get twitchBadgeSettingsSubtitle => 'Kawal lencana yang kelihatan';

  @override
  String get showDeletedMessages => 'Tunjukkan mesej yang dipadamkan';

  @override
  String get deletedMessagesGreyedOut =>
      'Mesej yang dipadamkan akan dikelabukan';

  @override
  String get deletedMessagesRemoved =>
      'Mesej yang dipadamkan akan dialih keluar';

  @override
  String get showLoginNames => 'Tunjukkan nama log masuk';

  @override
  String get loginNamesShown =>
      'Nama log masuk akan ditunjukkan jika berbeza daripada nama paparan';

  @override
  String get loginNamesHidden => 'Nama log masuk akan disembunyikan';

  @override
  String get compactMessages => 'Padatkan mesej';

  @override
  String get dontCompactMessages => 'Jangan padatkan mesej';

  @override
  String get dontCompactMessagesSubtitle => 'Mesej ditunjukkan tanpa perubahan';

  @override
  String get compactIndividualMessages => 'Padatkan mesej individu';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Teks berulang dalam mesej akan dipendekkan';

  @override
  String get announcementPinDuration => 'Tempoh pin pengumuman';

  @override
  String get idleMessageAlertDuration => 'Tempoh makluman mesej melahu';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Jika tiada mesej untuk tempoh masa ini dan mesej baharu masuk, bunyi makluman akan dimainkan.';

  @override
  String get realtimeCashSubtitle => 'Sambungkan dompet ETH atau MATIC';

  @override
  String get walletAddress => 'Alamat dompet';

  @override
  String get streamlabsSubtitle => 'Lihat derma Streamlabs anda';

  @override
  String get streamElementsSubtitle => 'Lihat derma StreamElements anda';

  @override
  String get thirdPartyAuthError =>
      'Hmm, itu tidak berjaya. Cuba lagi, atau tanya di Discord?';

  @override
  String get companionAuthBrowserTooOld =>
      'Pelayar anda terlalu lama untuk menyokong log masuk secara terus. Imbas kod QR ini dengan telefon anda untuk log masuk pada peranti lain.';

  @override
  String get companionAuthScanQrCode =>
      'Imbas kod QR ini dengan telefon anda untuk log masuk pada peranti lain.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> telah melanggan!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> telah melanggan semula selama $monthsString bulan!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> telah menghadiahkan $countString langganan!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> menghantar $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Log masuk dengan Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Terdapat terlalu banyak mesej. Teks ke pertuturan dilumpuhkan';

  @override
  String get turnOffTextToSpeech => 'Matikan';

  @override
  String get addToChat => 'Tambah ke sembang';

  @override
  String get inChat => 'Dalam sembang';

  @override
  String get removeFromChat => 'Alih keluar daripada sembang';

  @override
  String cantChatWithAccount(String provider) {
    return 'Akaun $provider anda tidak boleh bersembang di sini';
  }

  @override
  String get cantChatWithAccounts =>
      'Akaun anda tidak boleh bersembang di sini';

  @override
  String sendAMessageTo(String channel) {
    return 'Hantar mesej kepada $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Gantikan $channel';
  }

  @override
  String get voicePacks => 'Pek suara';

  @override
  String get voicePacksDescription =>
      'Pek suara membacakan sembang dengan suara semula jadi yang dijalankan pada peranti anda, secara luar talian sebaik sahaja dimuat turun. Suara ini dijana oleh mesin menggunakan AI, bukan dirakam oleh manusia.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices suara',
      one: '1 suara',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bahasa',
      one: '1 bahasa',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Lesen model ini (OpenRAIL-M) melarang penggunaan berbahaya, seperti menyamar sebagai orang lain atau menyebarkan maklumat palsu, dan sekatan ini turut terpakai kepada anda.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Padam $pack? Ini akan mengosongkan ruang sebanyak $size.';
  }

  @override
  String get voicePackDownload => 'Muat turun';

  @override
  String get voicePackUpdate => 'Kemas kini';

  @override
  String get voicePackWaitingForWifi => 'Menunggu Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Gunakan data mudah alih';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Memuat turun: $downloaded daripada $total';
  }

  @override
  String get voicePackInstalling => 'Memasang';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Tidak dapat memasang $pack. Semak sambungan anda dan cuba lagi.';
  }

  @override
  String get voices => 'Suara';

  @override
  String get perViewerVoice => 'Suara mengikut penonton';

  @override
  String get perViewerVoiceSubtitle =>
      'Setiap penonton mendapat suara mereka sendiri. Suara yang anda pilih akan membacakan makluman, atau membacakan semuanya apabila ciri ini dimatikan.';

  @override
  String get streamLanguage => 'Bahasa strim';

  @override
  String get ttsEngineNeural => 'Suara neural (pada peranti)';

  @override
  String get ttsEngineSystem => 'Suara sistem';

  @override
  String languageUnsupported(String language) {
    return '$language tidak disokong oleh pek suara anda; suara sistem akan digunakan';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Peranti ini tidak mempunyai memori yang mencukupi untuk suara neural, jadi sembang dibacakan dengan suara sistem.';

  @override
  String get neuralFallbackLoadFailed =>
      'Suara neural tidak dapat dimuatkan, jadi sembang dibacakan dengan suara sistem.';

  @override
  String get accounts => 'Akaun';

  @override
  String get accountsSubtitle =>
      'Log masuk ke setiap platform tempat anda membuat strim';

  @override
  String addProviderAccount(String provider) {
    return 'Tambah akaun $provider';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Log masuk dengan $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Log keluar daripada $channel di $provider?';
  }

  @override
  String get signOutOfAll => 'Log keluar daripada semua akaun';
}
