// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get sendAMessage => 'Bir mesaj gönder...';

  @override
  String get writeSomething => 'Bir şeyler yaz...';

  @override
  String get speakToTheCrowds => 'Kalabalıklara seslen...';

  @override
  String get shareYourThoughts => 'Düşüncelerini paylaş...';

  @override
  String get saySomethingYouLittleBitch =>
      'Bir şey söyle, seni küçük korkak...';

  @override
  String get search => 'Ara';

  @override
  String get notSignedIn => 'Oturum açılmadı';

  @override
  String get searchChannels => 'Ara';

  @override
  String get raidAChannel => 'Baskın yap';

  @override
  String get noMessagesEmptyState => 'Burası çok sessiz.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yeni mesaj',
      one: '1 yeni mesaj',
      zero: 'Yeni mesaj yok',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Twitch ile oturum aç';

  @override
  String get signInError =>
      'Oturum açılırken bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get continueAsGuest => 'Misafir olarak devam et';

  @override
  String get signInToSendMessages => 'Mesaj göndermek için oturum açın';

  @override
  String get currentViewers => 'Mevcut izleyiciler';

  @override
  String get textToSpeech => 'Metin okuma';

  @override
  String get streamPreview => 'Yayın önizlemesi';

  @override
  String get activityFeed => 'Etkinlik akışı';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Yayın çevrimiçi: $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Yayın çevrimdışı: $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Sohbet temizlendi: $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Hızlı bağlantıları yapılandır';

  @override
  String get disableRainMode => 'Yağmur modunu devre dışı bırak';

  @override
  String get enableRainMode => 'Yağmur modunu etkinleştir';

  @override
  String get disableRainModeSubtitle => 'Etkileşim etkinleştirilecek';

  @override
  String get enableRainModeSubtitle => 'Etkileşim devre dışı bırakılacak';

  @override
  String get refreshAudioSources => 'Ses kaynaklarını yenile';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ses kaynağı yenilendi',
      one: '1 ses kaynağı yenilendi',
      zero: 'Hiçbir ses kaynağı yenilenmedi',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Ayarlar';

  @override
  String get signOut => 'Oturumu kapat';

  @override
  String get cancel => 'İptal';

  @override
  String get signOutConfirmation =>
      'Oturumu kapatmak istediğinizden emin misiniz?';

  @override
  String get broadcaster => 'Yayıncı';

  @override
  String get moderators => 'Moderatörler';

  @override
  String get viewers => 'İzleyiciler';

  @override
  String get communityVips => 'Topluluk VIP\'leri';

  @override
  String get searchViewers => 'İzleyici ara';

  @override
  String get reconnecting => 'Yeniden bağlanıyor...';

  @override
  String get twitchBadges => 'Twitch rozetleri';

  @override
  String get selectAll => 'Tümünü seç';

  @override
  String get quickLinks => 'Hızlı bağlantılar';

  @override
  String get swipeToDeleteQuickLinks =>
      'Hızlı bağlantıyı silmek için sola veya sağa kaydırın';

  @override
  String get quickLinksLabelHint => 'Etiket';

  @override
  String get invalidUrlErrorText => 'Bu geçerli bir URL gibi görünmüyor';

  @override
  String get duplicateUrlErrorText => 'Bu bağlantı zaten mevcut';

  @override
  String get or => 'veya';

  @override
  String get clearCookies => 'Çerezleri temizle';

  @override
  String get disabled => 'Devre dışı';

  @override
  String get twitchActivityFeed => 'Twitch etkinlik akışı';

  @override
  String get signInToEnable => 'Bunu etkinleştirmek için oturum açmalısınız';

  @override
  String get customUrl => 'Özel URL';

  @override
  String get preview => 'Önizleme';

  @override
  String get audioSources => 'Ses kaynakları';

  @override
  String get enableOffStreamSwitchTitle =>
      'Yayın dışında etkinleştir (daha fazla pil kullanır)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Çevrimdışı olduğunuzda da ses çalınır';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Yalnızca canlı yayındayken ses çalınır';

  @override
  String get iosOggWarningTitle => 'Hey! Dinle!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS, Streamlabs\'te varsayılan dosyalar olan *.ogg medya dosyalarını desteklemez. Ses kaynaklarınızın başka bir biçim kullandığından emin olun, aksi takdirde çalınmazlar.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Etkinlik akışınızı özelleştirin';

  @override
  String get audioSourcesSubtitle =>
      'Uyarı sesleri için web kaynakları ekleyin';

  @override
  String get quickLinksSubtitle => 'Sık kullanılan araçlara kısayollar ekleyin';

  @override
  String get chatHistory => 'Sohbet geçmişi';

  @override
  String get chatHistorySubtitle => 'Sohbet görünümünü değiştirin';

  @override
  String get textToSpeechSubtitle => 'Metin okuma ayarlarını değiştirin';

  @override
  String get events => 'Etkinlikler';

  @override
  String get eventsSubtitle => 'Twitch etkinliklerini yapılandırın';

  @override
  String get thirdPartyServices => 'Üçüncü taraf hizmetler';

  @override
  String get thirdPartyServicesSubtitle => 'Bir üçüncü taraf hizmete bağlanın';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> seni takip ediyor';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> ve <b>$displayNameTwo</b> seni takip ediyor';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> ve $numOthersString kişi daha seni takip ediyor';
  }

  @override
  String unmuteUser(String displayName) {
    return '$displayName kullanıcısının sesini aç';
  }

  @override
  String muteUser(String displayName) {
    return '$displayName kullanıcısını sessize al';
  }

  @override
  String timeoutUser(String displayName) {
    return '$displayName kullanıcısını geçici uzaklaştır';
  }

  @override
  String banUser(String displayName) {
    return '$displayName kullanıcısını yasakla';
  }

  @override
  String unbanUser(String displayName) {
    return '$displayName kullanıcısının yasağını kaldır';
  }

  @override
  String viewProfile(String displayName) {
    return '$displayName profilini görüntüle';
  }

  @override
  String get copyMessage => 'Mesajı kopyala';

  @override
  String get deleteMessage => 'Mesajı sil';

  @override
  String get longScrollNotification =>
      'Biraz fazla yukarı kaydırıyorsun, sence de öyle değil mi?';

  @override
  String get stfu => 'kapa çeneni';

  @override
  String get globalEmotes => 'Genel ifadeler';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString takipçi',
      one: '1 takipçi',
      zero: '0 takipçi',
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
      other: '$countString izleyici',
      one: '1 izleyici',
      zero: '0 izleyici',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Merhaba! Yayın önizlemesini beğenmene sevindik ancak çok fazla pil tükettiğini unutma. Önizleme olmadan sohbeti okumak pil ömrünü uzatacaktır.';

  @override
  String get okay => 'Tamam';

  @override
  String get streamPreviewLoading => 'Yükleniyor (veya yayın çevrimdışı)...';

  @override
  String get copiedToClipboard => 'Panoya kopyalandı';

  @override
  String get audioSourcesRequirePermissions =>
      'Ses kaynakları izin gerektiriyor';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Ses kaynaklarını kullanmak için RealtimeChat uygulamasının diğer uygulamaların üzerinde görüntülenmesine izin verin.';

  @override
  String get audioSourcesRemoveButton => 'Ses kaynaklarını kaldır';

  @override
  String get audioSourcesOpenSettingsButton => 'Ayarları aç';

  @override
  String get flashOn => 'Flaş açık';

  @override
  String get flashOff => 'Flaş kapalı';

  @override
  String get durationOneSecond => '1 saniye';

  @override
  String get durationOneMinute => '1 dakika';

  @override
  String get durationTenMinutes => '10 dakika';

  @override
  String get durationOneHour => '1 saat';

  @override
  String get durationSixHours => '6 saat';

  @override
  String get durationOneDay => '1 gün';

  @override
  String get durationTwoDays => '2 gün';

  @override
  String get durationOneWeek => '1 hafta';

  @override
  String get durationTwoWeeks => '2 hafta';

  @override
  String get durationOneSecondTimeoutPrompt => '1 saniyeliğine uzaklaştır';

  @override
  String get durationOneMinuteTimeoutPrompt => '1 dakikalığına uzaklaştır';

  @override
  String get durationTenMinutesTimeoutPrompt => '10 dakikalığına uzaklaştır';

  @override
  String get durationOneHourTimeoutPrompt => '1 saatliğine uzaklaştır';

  @override
  String get durationSixHoursTimeoutPrompt => '6 saatliğine uzaklaştır';

  @override
  String get durationOneDayTimeoutPrompt => '1 günlüğüne uzaklaştır';

  @override
  String get durationTwoDaysTimeoutPrompt => '2 günlüğüne uzaklaştır';

  @override
  String get durationOneWeekTimeoutPrompt => '1 haftalığına uzaklaştır';

  @override
  String get durationTwoWeeksTimeoutPrompt => '2 haftalığına uzaklaştır';

  @override
  String get errorFetchingViewerList =>
      'Bu kanal için izleyici listesi alınamadı';

  @override
  String get eventsTitle => 'Etkinlikler';

  @override
  String get followEventConfigTitle => 'Takip etkinliği';

  @override
  String get customizeYourFollowEvent => 'Takip etkinliğinizi özelleştirin';

  @override
  String get subscribeEventConfigTitle => 'Abonelik etkinliği';

  @override
  String get customizeYourSubscriptionEvent =>
      'Abonelik etkinliğinizi özelleştirin';

  @override
  String get cheerEventConfigTitle => 'Cheer etkinliği';

  @override
  String get customizeYourCheerEvent => 'Cheer etkinliğinizi özelleştirin';

  @override
  String get raidEventConfigTitle => 'Baskın etkinliği';

  @override
  String get customizeYourRaidEvent => 'Baskın etkinliğinizi özelleştirin';

  @override
  String get hostEventConfigTitle => 'Ev sahipliği etkinliği';

  @override
  String get customizeYourHostEvent =>
      'Ev sahipliği etkinliğinizi özelleştirin';

  @override
  String get hypetrainEventConfigTitle => 'Hype Treni etkinliği';

  @override
  String get customizeYourHypetrainEvent =>
      'Hype Treni etkinliğinizi özelleştirin';

  @override
  String get pollEventConfigTitle => 'Anket etkinliği';

  @override
  String get customizeYourPollEvent => 'Anket etkinliğinizi özelleştirin';

  @override
  String get predictionEventConfigTitle => 'Tahmin etkinliği';

  @override
  String get customizeYourPredictionEvent =>
      'Tahmin etkinliğinizi özelleştirin';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Kanal puanı ödülü etkinliği';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Kanal puanı ödülü etkinliğinizi özelleştirin';

  @override
  String get outgoingRaidEventConfigTitle => 'Giden baskın etkinliği';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Giden baskın etkinliğinizi özelleştirin';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b>, <b>$viewerCountString</b> izleyiciyle baskın yapıyor!';
  }

  @override
  String get shoutout => 'Öne çıkar';

  @override
  String raidingEventRaiding(String displayName) {
    return '<b>$displayName</b> kanalına baskın yapılıyor...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString sn';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> baskın yaptı!';
  }

  @override
  String get raidingEventJoin => 'Katıl';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b> baskını iptal edildi.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b>, Kademe $tier ile abone oldu!';
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

    return '<b>$gifterUserName</b>, $totalString adet Kademe $tier abonelik hediye etti ve toplamda $cumulativeTotalString hediyeye ulaştı!';
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

    return '<b>$subscriberUserName</b>, Kademe $tier ile $cumulativeMonthsString aydır abone!';
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

    return '<b>$subscriberUserName</b>, Kademe $tier ile peşin olarak $durationMonthsString ay, toplamda $cumulativeMonthsString ay abone oldu!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b>, <b>$value $currency</b> bahşiş gönderdi.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonim, <b>$value $currency</b> bahşiş gönderdi.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b>, StreamElements üzerinden <b>$formattedAmount</b> bahşiş gönderdi.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b>, Streamlabs üzerinden <b>$formattedAmount</b> bahşiş gönderdi.';
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

    return '<b>$redeemerUsername</b>, <b>$rewardCostString</b> puan karşılığında <b>$rewardName</b> ödülünü aldı. $userInput';
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

    return '<b>$redeemerUsername</b>, <b>$rewardCostString</b> puan karşılığında <b>$rewardName</b> ödülünü aldı.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b>, <b>$bitsString</b> bit ile Cheer yaptı. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonim';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b>, <b>$viewersString</b> kişilik bir grupla kanala ev sahipliği yapıyor.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Seviye <b>$level</b> Hype Treni devam ediyor! <b>%$progressPercent</b> tamamlandı!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Seviye <b>$levelString</b> Hype Treni başarıyla tamamlandı.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Seviye <b>$levelString</b> Hype Treni başarısız oldu.';
  }

  @override
  String get sampleMessage =>
      'Bu, metni konuşmaya dönüştürmek için örnek bir mesajdır.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author dedi: $text';
  }

  @override
  String get textToSpeechEnabled => 'Metin okuma etkinleştirildi';

  @override
  String get textToSpeechDisabled => 'Metin okuma devre dışı bırakıldı';

  @override
  String get alertsEnabled => 'Yalnızca uyarılar';

  @override
  String get pinDuration => 'Sabitleme süresi';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds saniye',
      one: '1 saniye',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes dakika',
      one: '1 dakika',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Etkinliği etkinleştir';

  @override
  String get showEventInChatHistory => 'Etkinliği sohbet geçmişinde göster';

  @override
  String get enableShoutouts => 'Öne çıkarmaları etkinleştir';

  @override
  String get enableShoutoutsSubtitle =>
      'Baskın yapan kanalın bağlantısını sohbete gönder';

  @override
  String get raidConfigurationTitle => 'Baskın yapılandırması';

  @override
  String get cheerConfigurationTitle => 'Cheer yapılandırması';

  @override
  String get followConfigurationTitle => 'Takip yapılandırması';

  @override
  String get outgoingRaidConfigurationTitle => 'Giden baskın yapılandırması';

  @override
  String get hostConfigurationTitle => 'Ev sahipliği yapılandırması';

  @override
  String get channelPointConfigurationTitle => 'Kanal puanı yapılandırması';

  @override
  String get pollConfigurationTitle => 'Anket yapılandırması';

  @override
  String get hypetrainConfigurationTitle => 'Hype Treni yapılandırması';

  @override
  String get subscriptionConfigurationTitle => 'Abonelik yapılandırması';

  @override
  String get predictionConfigurationTitle => 'Tahmin yapılandırması';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Tamamlanmamış ödüller için ek sabitleme süresi';

  @override
  String get pollPinDuration => 'Sonuç kesinleştikten sonraki sabitleme süresi';

  @override
  String get hypetrainPinDuration =>
      'Hype Treni bittikten sonraki sabitleme süresi';

  @override
  String get enableGiftedSubscriptions =>
      'Bireysel hediye abonelikleri etkinleştir';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Hediye edilen her aboneliği göster';

  @override
  String get settingsBackupTitle => 'Ayarları yedekleme ve geri yükleme';

  @override
  String get cloudBackup => 'Bulut yedeklemesi';

  @override
  String get lastBackupNever => 'Son yedekleme: hiçbir zaman';

  @override
  String get backUp => 'Yedekle';

  @override
  String get restore => 'Geri yükle';

  @override
  String get localBackup => 'Yerel yedekleme';

  @override
  String get exportSettings => 'Dışa aktar';

  @override
  String get importSettings => 'İçe aktar';

  @override
  String get showViewerAndFollowerCount =>
      'İzleyici ve takipçi sayısını göster';

  @override
  String get screenOrientation => 'Ekran yönü';

  @override
  String get appTheme => 'Uygulama teması';

  @override
  String get systemDefault => 'Sistem';

  @override
  String get portrait => 'Dikey';

  @override
  String get landscape => 'Yatay';

  @override
  String get lightTheme => 'Açık';

  @override
  String get darkTheme => 'Koyu';

  @override
  String get openSourceTitle => 'RealtimeChat açık kaynaklıdır';

  @override
  String get openSourceSubtitle => 'Bizi GitHub\'da bulun!';

  @override
  String get discordSubtitle => 'Muxable Discord sunucusuna katılın!';

  @override
  String get earlyTestersThanks =>
      'Hata raporu gönderen tüm erken test kullanıcılarına teşekkürler!';

  @override
  String get discoModeEnabled => '🕺 Disko modu etkinleştirildi! :D';

  @override
  String get discoModeDisabled => '🕺 Disko modu devre dışı bırakıldı D:';

  @override
  String get playSampleMessage => 'Örnek mesajı oynat';

  @override
  String get textToSpeechRate => 'Metin okuma hızı';

  @override
  String get textToSpeechPitch => 'Metin okuma ses perdesi';

  @override
  String get muteBots => 'Botlar için metin okumayı sustur';

  @override
  String get muteEmotes => 'Metin okumada tüm ifadeleri sustur';

  @override
  String get muteViewerNames => 'Metin okumada izleyici adlarını sustur';

  @override
  String get subscribersOnly => 'Yalnızca aboneler';

  @override
  String get fontSize => 'Yazı tipi boyutu';

  @override
  String get usernameContrastBoost => 'Kullanıcı adı kontrast artırma';

  @override
  String get twitchBadgeSettings => 'Twitch rozet ayarları';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Hangi rozetlerin görüneceğini kontrol edin';

  @override
  String get showDeletedMessages => 'Silinen mesajları göster';

  @override
  String get deletedMessagesGreyedOut =>
      'Silinen mesajlar gri renkte gösterilecek';

  @override
  String get deletedMessagesRemoved => 'Silinen mesajlar kaldırılacak';

  @override
  String get showLoginNames => 'Kullanıcı adlarını göster';

  @override
  String get loginNamesShown =>
      'Kullanıcı adları, görünen addan farklıysa gösterilecek';

  @override
  String get loginNamesHidden => 'Kullanıcı adları gizlenecek';

  @override
  String get compactMessages => 'Mesajları sıkıştır';

  @override
  String get dontCompactMessages => 'Mesajları sıkıştırma';

  @override
  String get dontCompactMessagesSubtitle =>
      'Mesajlar değiştirilmeden gösterilir';

  @override
  String get compactIndividualMessages => 'Tekil mesajları sıkıştır';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Mesajlardaki tekrarlayan metinler kısaltılır';

  @override
  String get announcementPinDuration => 'Duyuru sabitleme süresi';

  @override
  String get idleMessageAlertDuration => 'Boşta mesaj uyarısı süresi';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Bu süre boyunca hiç mesaj gelmezse ve ardından yeni bir mesaj gelirse bir uyarı sesi çalınır.';

  @override
  String get realtimeCashSubtitle => 'Bir ETH veya MATIC cüzdanı bağlayın';

  @override
  String get walletAddress => 'Cüzdan adresi';

  @override
  String get streamlabsSubtitle => 'Streamlabs bağışlarınızı görün';

  @override
  String get streamElementsSubtitle => 'StreamElements bağışlarınızı görün';

  @override
  String get thirdPartyAuthError =>
      'Hmm, bu işe yaramadı. Tekrar deneyin veya Discord\'da sorun.';

  @override
  String get companionAuthBrowserTooOld =>
      'Tarayıcınız doğrudan oturum açmayı destekleyemeyecek kadar eski. Başka bir cihazda oturum açmak için bu QR kodunu telefonunuzla tarayın.';

  @override
  String get companionAuthScanQrCode =>
      'Başka bir cihazda oturum açmak için bu QR kodunu telefonunuzla tarayın.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> abone oldu!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b>, $monthsString ay boyunca aboneliğini yeniledi!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b>, $countString abonelik hediye etti!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b>, $amountString Kicks gönderdi!';
  }

  @override
  String get signInWithKick => 'Kick ile oturum aç';

  @override
  String get textToSpeechTooManyMessages =>
      'Çok fazla mesaj var. Metin okuma devre dışı bırakıldı';

  @override
  String get turnOffTextToSpeech => 'Kapat';

  @override
  String get addToChat => 'Sohbete ekle';

  @override
  String get inChat => 'Sohbette';

  @override
  String get removeFromChat => 'Sohbetten kaldır';

  @override
  String cantChatWithAccount(String provider) {
    return '$provider hesabınız burada sohbet edemez';
  }

  @override
  String get cantChatWithAccounts => 'Hesaplarınız burada sohbet edemez';

  @override
  String sendAMessageTo(String channel) {
    return '$channel kanalına bir mesaj gönder...';
  }

  @override
  String replaceChannel(String channel) {
    return '$channel kanalını değiştir';
  }

  @override
  String get voicePacks => 'Ses paketleri';

  @override
  String get voicePacksDescription =>
      'Ses paketleri, indirildikten sonra çevrimdışı olarak cihazınızda çalışan doğal seslerle sohbeti okur. Sesler bir kişi tarafından kaydedilmemiştir, yapay zeka tarafından üretilmiştir.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices ses',
      one: '1 ses',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dil',
      one: '1 dil',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Bu modelin lisansı (OpenRAIL-M), kişilerin kimliğine bürünmek veya dezenformasyon yaymak gibi zararlı kullanımları yasaklar ve bu kısıtlamalar sizin için de geçerlidir.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return '$pack silinsin mi? Bu işlem $size alan açar.';
  }

  @override
  String get voicePackDownload => 'İndir';

  @override
  String get voicePackUpdate => 'Güncelle';

  @override
  String get voicePackWaitingForWifi => 'Wi-Fi bekleniyor';

  @override
  String get voicePackUseMobileData => 'Mobil veri kullan';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'İndiriliyor: $downloaded / $total';
  }

  @override
  String get voicePackInstalling => 'Yükleniyor';

  @override
  String voicePackInstallFailed(String pack) {
    return '$pack yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';
  }

  @override
  String get voices => 'Sesler';

  @override
  String get perViewerVoice => 'İzleyici başına ses';

  @override
  String get perViewerVoiceSubtitle =>
      'Her izleyiciye kendi sesi atanır. Seçtiğiniz ses uyarıları veya bu özellik kapalıyken her şeyi okur.';

  @override
  String get streamLanguage => 'Yayın dili';

  @override
  String get ttsEngineNeural => 'Nöral ses (cihaz içi)';

  @override
  String get ttsEngineSystem => 'Sistem sesi';

  @override
  String languageUnsupported(String language) {
    return '$language dili ses paketleriniz tarafından desteklenmiyor; sistem sesi kullanılacak';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Bu cihazda nöral sesler için yeterli bellek olmadığından sohbet sistem sesiyle okunur.';

  @override
  String get neuralFallbackLoadFailed =>
      'Nöral ses yüklenemediğinden sohbet sistem sesiyle okunur.';

  @override
  String get accounts => 'Hesaplar';

  @override
  String get accountsSubtitle => 'Yayın yaptığınız her platformda oturum açın';

  @override
  String addProviderAccount(String provider) {
    return '$provider hesabı ekle';
  }

  @override
  String signInWithProvider(String provider) {
    return '$provider ile oturum aç';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return '$provider üzerindeki $channel hesabından çıkılsın mı?';
  }

  @override
  String get signOutOfAll => 'Tüm hesaplardan çıkış yap';
}
