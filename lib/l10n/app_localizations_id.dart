// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'package:rtchat/l10n/app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get sendAMessage => 'Kirim pesan...';

  @override
  String get writeSomething => 'Tulis sesuatu...';

  @override
  String get speakToTheCrowds => 'Sapa para penonton...';

  @override
  String get shareYourThoughts => 'Bagikan pikiranmu...';

  @override
  String get saySomethingYouLittleBitch => 'Katakan sesuatu, dasar pengecut...';

  @override
  String get search => 'Cari';

  @override
  String get notSignedIn => 'Belum masuk';

  @override
  String get searchChannels => 'Cari';

  @override
  String get raidAChannel => 'Serbu Kanal';

  @override
  String get noMessagesEmptyState => 'Sepi sekali di sini.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pesan baru',
      one: '1 pesan baru',
      zero: 'Tidak ada pesan baru',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Masuk dengan Twitch';

  @override
  String get signInError => 'Terjadi kesalahan saat masuk. Silakan coba lagi.';

  @override
  String get continueAsGuest => 'Lanjutkan sebagai Tamu';

  @override
  String get signInToSendMessages => 'Masuk untuk mengirim pesan';

  @override
  String get currentViewers => 'Penonton saat ini';

  @override
  String get textToSpeech => 'Teks ke suara';

  @override
  String get streamPreview => 'Pratinjau siaran';

  @override
  String get activityFeed => 'Umpan aktivitas';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Siaran dimulai pada $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Siaran berakhir pada $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Obrolan dibersihkan pada $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Atur tautan cepat';

  @override
  String get disableRainMode => 'Nonaktifkan mode hujan';

  @override
  String get enableRainMode => 'Aktifkan mode hujan';

  @override
  String get disableRainModeSubtitle => 'Interaksi akan diaktifkan';

  @override
  String get enableRainModeSubtitle => 'Interaksi akan dinonaktifkan';

  @override
  String get refreshAudioSources => 'Segarkan sumber audio';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sumber audio disegarkan',
      one: '1 sumber audio disegarkan',
      zero: 'Tidak ada sumber audio yang disegarkan',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Pengaturan';

  @override
  String get signOut => 'Keluar';

  @override
  String get cancel => 'Batal';

  @override
  String get signOutConfirmation => 'Yakin ingin keluar?';

  @override
  String get broadcaster => 'Penyiar';

  @override
  String get moderators => 'Moderator';

  @override
  String get viewers => 'Penonton';

  @override
  String get communityVips => 'VIP Komunitas';

  @override
  String get searchViewers => 'Cari Penonton';

  @override
  String get reconnecting => 'Menyambungkan kembali...';

  @override
  String get twitchBadges => 'Lencana Twitch';

  @override
  String get selectAll => 'Pilih semua';

  @override
  String get quickLinks => 'Tautan cepat';

  @override
  String get swipeToDeleteQuickLinks =>
      'Geser ke kiri atau kanan untuk menghapus tautan cepat';

  @override
  String get quickLinksLabelHint => 'Nama label';

  @override
  String get invalidUrlErrorText => 'URL ini tampaknya tidak valid';

  @override
  String get duplicateUrlErrorText => 'Tautan ini sudah ada';

  @override
  String get or => 'atau';

  @override
  String get clearCookies => 'Hapus cookie';

  @override
  String get disabled => 'Nonaktif';

  @override
  String get twitchActivityFeed => 'Umpan aktivitas Twitch';

  @override
  String get signInToEnable => 'Anda harus masuk untuk mengaktifkan fitur ini';

  @override
  String get customUrl => 'URL Kustom';

  @override
  String get preview => 'Pratinjau';

  @override
  String get audioSources => 'Sumber audio';

  @override
  String get enableOffStreamSwitchTitle =>
      'Aktifkan saat di luar siaran (menggunakan lebih banyak baterai)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Audio juga akan diputar saat Anda sedang offline';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Audio hanya akan diputar saat Anda sedang siaran langsung';

  @override
  String get iosOggWarningTitle => 'Hei! Perhatian!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS tidak mendukung file media *.ogg, yang merupakan format bawaan di Streamlabs. Pastikan sumber audio Anda menggunakan format lain agar dapat diputar.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Sesuaikan umpan aktivitas Anda';

  @override
  String get audioSourcesSubtitle =>
      'Tambahkan sumber web untuk suara peringatan';

  @override
  String get quickLinksSubtitle =>
      'Tambahkan pintasan ke alat yang sering digunakan';

  @override
  String get chatHistory => 'Riwayat obrolan';

  @override
  String get chatHistorySubtitle => 'Ubah tampilan obrolan';

  @override
  String get textToSpeechSubtitle => 'Ubah pengaturan teks ke suara';

  @override
  String get events => 'Peristiwa';

  @override
  String get eventsSubtitle => 'Konfigurasikan peristiwa Twitch';

  @override
  String get thirdPartyServices => 'Layanan pihak ketiga';

  @override
  String get thirdPartyServicesSubtitle => 'Hubungkan ke layanan pihak ketiga';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> mengikuti Anda';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> dan <b>$displayNameTwo</b> mengikuti Anda';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b>, dan $numOthersString lainnya mengikuti Anda';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Bunyikan $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Bisukan $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Tangguhkan $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Blokir $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Buka blokir $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Lihat profil $displayName';
  }

  @override
  String get copyMessage => 'Salin Pesan';

  @override
  String get deleteMessage => 'Hapus Pesan';

  @override
  String get longScrollNotification => 'Anda menggulir cukup jauh, bukan?';

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
      'Halo! Senang melihat Anda menggunakan pratinjau siaran, tetapi fitur ini menguras banyak baterai. Membaca obrolan tanpanya akan menghemat masa pakai baterai Anda.';

  @override
  String get okay => 'Oke';

  @override
  String get streamPreviewLoading => 'Memuat (atau siaran sedang offline)...';

  @override
  String get copiedToClipboard => 'Disalin ke papan klip';

  @override
  String get audioSourcesRequirePermissions => 'Sumber audio memerlukan izin';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Izinkan RealtimeChat tampil di atas aplikasi lain untuk menggunakan sumber audio.';

  @override
  String get audioSourcesRemoveButton => 'Hapus sumber audio';

  @override
  String get audioSourcesOpenSettingsButton => 'Buka pengaturan';

  @override
  String get flashOn => 'Lampu kilat aktif';

  @override
  String get flashOff => 'Lampu kilat mati';

  @override
  String get durationOneSecond => '1 detik';

  @override
  String get durationOneMinute => '1 menit';

  @override
  String get durationTenMinutes => '10 menit';

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
  String get durationOneSecondTimeoutPrompt => 'Tangguhkan selama 1 detik';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Tangguhkan selama 1 menit';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Tangguhkan selama 10 menit';

  @override
  String get durationOneHourTimeoutPrompt => 'Tangguhkan selama 1 jam';

  @override
  String get durationSixHoursTimeoutPrompt => 'Tangguhkan selama 6 jam';

  @override
  String get durationOneDayTimeoutPrompt => 'Tangguhkan selama 1 hari';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Tangguhkan selama 2 hari';

  @override
  String get durationOneWeekTimeoutPrompt => 'Tangguhkan selama 1 minggu';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Tangguhkan selama 2 minggu';

  @override
  String get errorFetchingViewerList =>
      'Kami tidak dapat mengambil daftar penonton untuk kanal ini';

  @override
  String get eventsTitle => 'Peristiwa';

  @override
  String get followEventConfigTitle => 'Peristiwa Ikuti';

  @override
  String get customizeYourFollowEvent => 'Sesuaikan peristiwa ikuti Anda';

  @override
  String get subscribeEventConfigTitle => 'Peristiwa Langganan';

  @override
  String get customizeYourSubscriptionEvent =>
      'Sesuaikan peristiwa langganan Anda';

  @override
  String get cheerEventConfigTitle => 'Peristiwa Cheer';

  @override
  String get customizeYourCheerEvent => 'Sesuaikan peristiwa cheer Anda';

  @override
  String get raidEventConfigTitle => 'Peristiwa Raid';

  @override
  String get customizeYourRaidEvent => 'Sesuaikan peristiwa raid Anda';

  @override
  String get hostEventConfigTitle => 'Peristiwa Host';

  @override
  String get customizeYourHostEvent => 'Sesuaikan peristiwa host Anda';

  @override
  String get hypetrainEventConfigTitle => 'Peristiwa Hype Train';

  @override
  String get customizeYourHypetrainEvent =>
      'Sesuaikan peristiwa Hype Train Anda';

  @override
  String get pollEventConfigTitle => 'Peristiwa Jajak Pendapat';

  @override
  String get customizeYourPollEvent =>
      'Sesuaikan peristiwa jajak pendapat Anda';

  @override
  String get predictionEventConfigTitle => 'Peristiwa Prediksi';

  @override
  String get customizeYourPredictionEvent =>
      'Sesuaikan peristiwa prediksi Anda';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Peristiwa Penukaran Poin Kanal';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Sesuaikan peristiwa penukaran poin kanal Anda';

  @override
  String get outgoingRaidEventConfigTitle => 'Peristiwa Raid Keluar';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Sesuaikan peristiwa raid keluar Anda';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> menyerbu dengan <b>$viewerCountString</b> penonton!';
  }

  @override
  String get shoutout => 'Beri Sapaan';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Menyerbu <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString dtk';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> telah menyerbu!';
  }

  @override
  String get raidingEventJoin => 'Gabung';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Raid <b>$displayName</b> dibatalkan.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> telah berlangganan di Tier $tier!';
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

    return '<b>$gifterUserName</b> telah menghadiahkan $totalString langganan Tier $tier, dengan total $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> telah berlangganan selama $cumulativeMonthsString bulan di Tier $tier!';
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

    return '<b>$subscriberUserName</b> telah berlangganan di Tier $tier untuk $durationMonthsString bulan ke depan, total $cumulativeMonthsString bulan!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> memberi tip sebesar <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonim memberi tip sebesar <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> memberi tip sebesar <b>$formattedAmount</b> di StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> memberi tip sebesar <b>$formattedAmount</b> di Streamlabs.';
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

    return '<b>$redeemerUsername</b> menukarkan <b>$rewardName</b> dengan <b>$rewardCostString</b> poin. $userInput';
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

    return '<b>$redeemerUsername</b> menukarkan <b>$rewardName</b> dengan <b>$rewardCostString</b> poin.';
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
  String get anonymous => 'Anonim';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> melakukan host dengan <b>$viewersString</b> penonton.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train level <b>$level</b> sedang berlangsung! <b>$progressPercent%</b> selesai!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train level <b>$levelString</b> berhasil.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train level <b>$levelString</b> gagal.';
  }

  @override
  String get sampleMessage =>
      'Ini adalah contoh pesan untuk mengubah teks menjadi suara.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author berkata: $text';
  }

  @override
  String get textToSpeechEnabled => 'Teks ke suara diaktifkan';

  @override
  String get textToSpeechDisabled => 'Teks ke suara dinonaktifkan';

  @override
  String get alertsEnabled => 'Hanya peringatan';

  @override
  String get pinDuration => 'Durasi Sematan';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds detik',
      one: '1 detik',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes menit',
      one: '1 menit',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Aktifkan peristiwa';

  @override
  String get showEventInChatHistory => 'Tampilkan peristiwa di riwayat obrolan';

  @override
  String get enableShoutouts => 'Aktifkan sapaan';

  @override
  String get enableShoutoutsSubtitle =>
      'Kirim tautan kanal yang menyerbu ke obrolan';

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
  String get channelPointConfigurationTitle => 'Konfigurasi Poin Kanal';

  @override
  String get pollConfigurationTitle => 'Konfigurasi Jajak Pendapat';

  @override
  String get hypetrainConfigurationTitle => 'Konfigurasi Hype Train';

  @override
  String get subscriptionConfigurationTitle => 'Konfigurasi Langganan';

  @override
  String get predictionConfigurationTitle => 'Konfigurasi Prediksi';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Durasi Sematan Tambahan untuk Hadiah yang Belum Terpenuhi';

  @override
  String get pollPinDuration => 'Durasi sematan setelah hasil ditetapkan';

  @override
  String get hypetrainPinDuration =>
      'Durasi sematan setelah Hype Train berakhir';

  @override
  String get enableGiftedSubscriptions =>
      'Aktifkan langganan hadiah individual';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Tampilkan setiap langganan yang dihadiahkan';

  @override
  String get settingsBackupTitle => 'Cadangkan dan pulihkan pengaturan';

  @override
  String get cloudBackup => 'Cadangan cloud';

  @override
  String get lastBackupNever => 'Cadangan terakhir: belum pernah';

  @override
  String get backUp => 'Cadangkan';

  @override
  String get restore => 'Pulihkan';

  @override
  String get localBackup => 'Cadangan lokal';

  @override
  String get exportSettings => 'Ekspor';

  @override
  String get importSettings => 'Impor';

  @override
  String get showViewerAndFollowerCount =>
      'Tampilkan jumlah penonton dan pengikut';

  @override
  String get screenOrientation => 'Orientasi layar';

  @override
  String get appTheme => 'Tema aplikasi';

  @override
  String get systemDefault => 'Sistem';

  @override
  String get portrait => 'Potret';

  @override
  String get landscape => 'Lanskap';

  @override
  String get lightTheme => 'Terang';

  @override
  String get darkTheme => 'Gelap';

  @override
  String get openSourceTitle => 'RealtimeChat bersifat sumber terbuka';

  @override
  String get openSourceSubtitle => 'Temukan kami di GitHub!';

  @override
  String get discordSubtitle => 'Bergabunglah ke Discord Muxable!';

  @override
  String get earlyTestersThanks =>
      'Terima kasih kepada semua penguji awal yang telah mengirimkan laporan bug!';

  @override
  String get discoModeEnabled => '🕺 Mode disko diaktifkan! :D';

  @override
  String get discoModeDisabled => '🕺 Mode disko dinonaktifkan D:';

  @override
  String get playSampleMessage => 'Putar pesan contoh';

  @override
  String get textToSpeechRate => 'Kecepatan Teks ke Suara';

  @override
  String get textToSpeechPitch => 'Nada Teks ke Suara';

  @override
  String get muteBots => 'Bisukan teks ke suara untuk bot';

  @override
  String get muteEmotes => 'Bisukan semua emote di teks ke suara';

  @override
  String get muteViewerNames => 'Bisukan nama penonton di teks ke suara';

  @override
  String get subscribersOnly => 'Khusus pelanggan';

  @override
  String get fontSize => 'Ukuran font';

  @override
  String get usernameContrastBoost => 'Peningkatan kontras nama pengguna';

  @override
  String get twitchBadgeSettings => 'Pengaturan lencana Twitch';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Atur lencana mana saja yang ditampilkan';

  @override
  String get showDeletedMessages => 'Tampilkan pesan yang dihapus';

  @override
  String get deletedMessagesGreyedOut =>
      'Pesan yang dihapus akan ditampilkan berwarna abu-abu';

  @override
  String get deletedMessagesRemoved => 'Pesan yang dihapus akan dihilangkan';

  @override
  String get showLoginNames => 'Tampilkan nama login';

  @override
  String get loginNamesShown =>
      'Nama login akan ditampilkan jika berbeda dari nama tampilan';

  @override
  String get loginNamesHidden => 'Nama login akan disembunyikan';

  @override
  String get compactMessages => 'Padatkan pesan';

  @override
  String get dontCompactMessages => 'Jangan padatkan pesan';

  @override
  String get dontCompactMessagesSubtitle => 'Pesan ditampilkan apa adanya';

  @override
  String get compactIndividualMessages => 'Padatkan pesan satu per satu';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Teks berulang dalam pesan akan disingkat';

  @override
  String get announcementPinDuration => 'Durasi sematan pengumuman';

  @override
  String get idleMessageAlertDuration => 'Durasi peringatan obrolan senyap';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Jika tidak ada pesan selama waktu ini lalu ada pesan baru masuk, suara peringatan akan diputar.';

  @override
  String get realtimeCashSubtitle => 'Hubungkan dompet ETH atau MATIC';

  @override
  String get walletAddress => 'Alamat dompet';

  @override
  String get streamlabsSubtitle => 'Lihat donasi Streamlabs Anda';

  @override
  String get streamElementsSubtitle => 'Lihat donasi StreamElements Anda';

  @override
  String get thirdPartyAuthError =>
      'Hmm, tidak berhasil. Coba lagi, atau tanyakan di Discord?';

  @override
  String get companionAuthBrowserTooOld =>
      'Browser Anda terlalu lama untuk mendukung masuk secara langsung. Pindai kode QR ini dengan ponsel Anda untuk masuk di perangkat lain.';

  @override
  String get companionAuthScanQrCode =>
      'Pindai kode QR ini dengan ponsel Anda untuk masuk di perangkat lain.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> telah berlangganan!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> telah berlangganan kembali selama $monthsString bulan!';
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

    return '<b>$senderName</b> mengirim $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Masuk dengan Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Terlalu banyak pesan. Teks ke suara dinonaktifkan';

  @override
  String get turnOffTextToSpeech => 'Matikan';

  @override
  String get addToChat => 'Tambahkan ke obrolan';

  @override
  String get inChat => 'Di obrolan';

  @override
  String get removeFromChat => 'Hapus dari obrolan';

  @override
  String cantChatWithAccount(String provider) {
    return 'Akun $provider Anda tidak dapat mengobrol di sini';
  }

  @override
  String get cantChatWithAccounts => 'Akun Anda tidak dapat mengobrol di sini';

  @override
  String sendAMessageTo(String channel) {
    return 'Kirim pesan ke $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Ganti $channel';
  }

  @override
  String get voicePacks => 'Paket suara';

  @override
  String get voicePacksDescription =>
      'Paket suara membacakan obrolan dengan suara alami yang berjalan di perangkat Anda secara offline setelah diunduh. Suara tersebut dihasilkan oleh mesin AI, bukan direkam oleh manusia.';

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
      'Lisensi model ini (OpenRAIL-M) melarang penggunaan yang membahayakan, seperti meniru identitas orang lain atau menyebarkan disinformasi, dan batasan ini juga berlaku bagi Anda.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Hapus $pack? Ini akan mengosongkan ruang sebesar $size.';
  }

  @override
  String get voicePackDownload => 'Unduh';

  @override
  String get voicePackUpdate => 'Perbarui';

  @override
  String get voicePackWaitingForWifi => 'Menunggu Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Gunakan data seluler';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Mengunduh: $downloaded dari $total';
  }

  @override
  String get voicePackInstalling => 'Memasang';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Gagal memasang $pack. Periksa koneksi Anda dan coba lagi.';
  }

  @override
  String get voices => 'Suara';

  @override
  String get perViewerVoice => 'Suara per penonton';

  @override
  String get perViewerVoiceSubtitle =>
      'Setiap penonton mendapatkan suaranya sendiri. Suara yang Anda pilih akan membacakan peringatan, atau membacakan semuanya saat fitur ini mati.';

  @override
  String get streamLanguage => 'Bahasa siaran';

  @override
  String get ttsEngineNeural => 'Suara neural (di perangkat)';

  @override
  String get ttsEngineSystem => 'Suara sistem';

  @override
  String languageUnsupported(String language) {
    return '$language tidak didukung oleh paket suara Anda; suara sistem akan digunakan';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Perangkat ini tidak memiliki cukup memori untuk suara neural, sehingga obrolan dibacakan dengan suara sistem.';

  @override
  String get neuralFallbackLoadFailed =>
      'Suara neural gagal dimuat, sehingga obrolan dibacakan dengan suara sistem.';

  @override
  String get accounts => 'Akun';

  @override
  String get accountsSubtitle =>
      'Masuk ke setiap platform tempat Anda melakukan siaran';

  @override
  String addProviderAccount(String provider) {
    return 'Tambahkan akun $provider';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Masuk dengan $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Keluar dari $channel di $provider?';
  }

  @override
  String get signOutOfAll => 'Keluar dari semua akun';
}
