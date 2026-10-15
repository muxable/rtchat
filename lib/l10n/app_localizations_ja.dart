// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get sendAMessage => 'メッセージを送信...';

  @override
  String get writeSomething => '何か書いて...';

  @override
  String get speakToTheCrowds => '群衆に話しかける...';

  @override
  String get shareYourThoughts => 'あなたの考えを共有する...';

  @override
  String get saySomethingYouLittleBitch => '何か言って、この小娘...';

  @override
  String get search => '検索';

  @override
  String get notSignedIn => 'サインインしていません';

  @override
  String get searchChannels => 'チャンネルを検索';

  @override
  String get raidAChannel => 'チャンネルをレイド';

  @override
  String get noMessagesEmptyState => 'メッセージがありません';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countの新しいメッセージ',
      one: '1つの新しいメッセージ',
      zero: '新しいメッセージはありません',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Twitchでサインイン';

  @override
  String get signInError => 'サインイン中にエラーが発生しました。もう一度お試しください。';

  @override
  String get continueAsGuest => 'ゲストとして続行';

  @override
  String get signInToSendMessages => 'メッセージを送信するにはサインインしてください';

  @override
  String get currentViewers => '現在の視聴者';

  @override
  String get textToSpeech => 'テキストを音声に';

  @override
  String get streamPreview => 'ストリームプレビュー';

  @override
  String get activityFeed => 'アクティビティフィード';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString、$timeStringにオンライン';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString、$timeStringにオフライン';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString、$timeStringにチャットをクリア';
  }

  @override
  String get configureQuickLinks => 'クイックリンクを設定';

  @override
  String get disableRainMode => 'レインモードを無効にする';

  @override
  String get enableRainMode => 'レインモードを有効にする';

  @override
  String get disableRainModeSubtitle => 'インタラクションが有効になります';

  @override
  String get enableRainModeSubtitle => 'インタラクションが無効になります';

  @override
  String get refreshAudioSources => 'オーディオソースを更新';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countのオーディオソースが更新されました',
      one: '1つのオーディオソースが更新されました',
      zero: 'オーディオソースが更新されませんでした',
    );
    return '$_temp0';
  }

  @override
  String get settings => '設定';

  @override
  String get signOut => 'サインアウト';

  @override
  String get cancel => 'キャンセル';

  @override
  String get signOutConfirmation => 'サインアウトしてもよろしいですか？';

  @override
  String get broadcaster => 'ブロードキャスター';

  @override
  String get moderators => 'モデレーター';

  @override
  String get viewers => '視聴者';

  @override
  String get communityVips => 'コミュニティVIP';

  @override
  String get searchViewers => '視聴者を検索';

  @override
  String get reconnecting => '再接続中...';

  @override
  String get twitchBadges => 'Twitchバッジ';

  @override
  String get selectAll => 'すべて選択';

  @override
  String get quickLinks => 'クイックリンク';

  @override
  String get swipeToDeleteQuickLinks => 'クイックリンクを削除するには左右にスワイプ';

  @override
  String get quickLinksLabelHint => 'ラベル';

  @override
  String get invalidUrlErrorText => '無効なURLのようです';

  @override
  String get duplicateUrlErrorText => 'このリンクは既に存在します';

  @override
  String get or => 'または';

  @override
  String get clearCookies => 'クッキーをクリア';

  @override
  String get disabled => '無効';

  @override
  String get twitchActivityFeed => 'Twitchアクティビティフィード';

  @override
  String get signInToEnable => 'この機能を有効にするにはサインインしてください';

  @override
  String get customUrl => 'カスタムURL';

  @override
  String get preview => 'プレビュー';

  @override
  String get audioSources => 'オーディオソース';

  @override
  String get enableOffStreamSwitchTitle => 'オフストリームを有効にする（バッテリーをより多く使用します）';

  @override
  String get enableOffStreamSwitchEnabledSubtitle => 'オフラインの場合でもオーディオが再生されます';

  @override
  String get enableOffStreamSwitchDisabledSubtitle => 'オーディオはライブ中のみ再生されます';

  @override
  String get iosOggWarningTitle => '聞いて！';

  @override
  String get iosOggWarningSubtitle =>
      'iOSは*.oggメディアファイルをサポートしていません。これはStreamlabsのデフォルトファイルです。アラートが再生されるように、別のフォーマットを使用してください。';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'アクティビティフィードをカスタマイズする';

  @override
  String get audioSourcesSubtitle => 'アラート音のためのウェブソースを追加する';

  @override
  String get quickLinksSubtitle => 'よく使うツールへのショートカットを追加する';

  @override
  String get chatHistory => 'チャット履歴';

  @override
  String get chatHistorySubtitle => 'チャットの外観を変更する';

  @override
  String get textToSpeechSubtitle => 'テキストから音声への設定を変更する';

  @override
  String get events => 'イベント';

  @override
  String get eventsSubtitle => 'Twitchイベントを設定する';

  @override
  String get thirdPartyServices => 'サードパーティサービス';

  @override
  String get thirdPartyServicesSubtitle => 'サードパーティサービスに接続する';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> がフォローしました';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> と <b>$displayNameTwo</b> がフォローしました';
  }

  @override
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>、<b>$displayNameTwo</b>、他 $numOthersString 人がフォローしました';
  }

  @override
  String unmuteUser(String displayName) {
    return '$displayName のミュートを解除';
  }

  @override
  String muteUser(String displayName) {
    return '$displayName をミュート';
  }

  @override
  String timeoutUser(String displayName) {
    return '$displayName をタイムアウト';
  }

  @override
  String banUser(String displayName) {
    return '$displayName を禁止';
  }

  @override
  String unbanUser(String displayName) {
    return '$displayName の禁止を解除';
  }

  @override
  String viewProfile(String displayName) {
    return '$displayName のプロフィールを見る';
  }

  @override
  String get copyMessage => 'メッセージをコピー';

  @override
  String get deleteMessage => 'メッセージを削除';

  @override
  String get longScrollNotification => 'かなり遠くまでスクロールしていますね';

  @override
  String get stfu => '黙れ';

  @override
  String get globalEmotes => 'グローバルエモート';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString人のフォロワー',
      one: '1人のフォロワー',
      zero: 'フォロワーがいません',
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
      other: '$countString人の視聴者',
      one: '1人の視聴者',
      zero: '視聴者がいません',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'ストリームプレビューを使用していただきありがとうございますが、バッテリーを大量に消費することに注意してください。プレビューなしでチャットを読むと、バッテリーの寿命が延びます。';

  @override
  String get okay => 'OK';

  @override
  String get streamPreviewLoading => '読み込み中（またはストリームがオフラインです）...';

  @override
  String get copiedToClipboard => 'クリップボードにコピーされました';

  @override
  String get audioSourcesRequirePermissions => 'オーディオソースには権限が必要です';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'オーディオソースを使用するために、RealtimeChatに他のアプリの上に表示する権限を与えてください。';

  @override
  String get audioSourcesRemoveButton => 'オーディオソースを削除';

  @override
  String get audioSourcesOpenSettingsButton => '設定を開く';

  @override
  String get flashOn => 'フラッシュオン';

  @override
  String get flashOff => 'フラッシュオフ';

  @override
  String get durationOneSecond => '1秒';

  @override
  String get durationOneMinute => '1分';

  @override
  String get durationTenMinutes => '10分';

  @override
  String get durationOneHour => '1時間';

  @override
  String get durationSixHours => '6時間';

  @override
  String get durationOneDay => '1日';

  @override
  String get durationTwoDays => '2日';

  @override
  String get durationOneWeek => '1週間';

  @override
  String get durationTwoWeeks => '2週間';

  @override
  String get durationOneSecondTimeoutPrompt => '1秒間タイムアウト';

  @override
  String get durationOneMinuteTimeoutPrompt => '1分間タイムアウト';

  @override
  String get durationTenMinutesTimeoutPrompt => '10分間タイムアウト';

  @override
  String get durationOneHourTimeoutPrompt => '1時間タイムアウト';

  @override
  String get durationSixHoursTimeoutPrompt => '6時間タイムアウト';

  @override
  String get durationOneDayTimeoutPrompt => '1日間タイムアウト';

  @override
  String get durationTwoDaysTimeoutPrompt => '2日間タイムアウト';

  @override
  String get durationOneWeekTimeoutPrompt => '1週間タイムアウト';

  @override
  String get durationTwoWeeksTimeoutPrompt => '2週間タイムアウト';

  @override
  String get errorFetchingViewerList => 'このチャンネルの視聴者リストを取得できませんでした';

  @override
  String get eventsTitle => 'イベント';

  @override
  String get followEventConfigTitle => 'フォローイベント';

  @override
  String get customizeYourFollowEvent => 'フォローイベントをカスタマイズする';

  @override
  String get subscribeEventConfigTitle => 'サブスクライブイベント';

  @override
  String get customizeYourSubscriptionEvent => 'サブスクリプションイベントをカスタマイズする';

  @override
  String get cheerEventConfigTitle => 'チアイベント';

  @override
  String get customizeYourCheerEvent => 'チアイベントをカスタマイズする';

  @override
  String get raidEventConfigTitle => 'レイドイベント';

  @override
  String get customizeYourRaidEvent => 'レイドイベントをカスタマイズする';

  @override
  String get hostEventConfigTitle => 'ホストイベント';

  @override
  String get customizeYourHostEvent => 'ホストイベントをカスタマイズする';

  @override
  String get hypetrainEventConfigTitle => 'ハイプトレインイベント';

  @override
  String get customizeYourHypetrainEvent => 'ハイプトレインイベントをカスタマイズする';

  @override
  String get pollEventConfigTitle => '投票イベント';

  @override
  String get customizeYourPollEvent => '投票イベントをカスタマイズする';

  @override
  String get predictionEventConfigTitle => '予測イベント';

  @override
  String get customizeYourPredictionEvent => '予測イベントをカスタマイズする';

  @override
  String get channelPointRedemptionEventConfigTitle => 'チャンネルポイント交換イベント';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'チャンネルポイント交換イベントをカスタマイズする';

  @override
  String get outgoingRaidEventConfigTitle => '送信レイドイベント';

  @override
  String get customizeYourOutgoingRaidEvent => '送信レイドイベントをカスタマイズする';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

    return '<b>$displayName</b> が <b>$viewerCountString</b> 人の視聴者とレイドしています！';
  }

  @override
  String get shoutout => 'シャウトアウト';

  @override
  String raidingEventRaiding(String displayName) {
    return '<b>$displayName</b> をレイド中...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '残り$secondsString秒';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b>がレイドしました！';
  }

  @override
  String get raidingEventJoin => '参加する';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b>のレイドがキャンセルされました。';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b>がティア$tierにサブスクライブしました！';
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

    return '<b>$gifterUserName</b>がティア$tierのサブスクリプションを$totalString個ギフトし、合計$cumulativeTotalString個になりました！';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b>がティア$tierに$cumulativeMonthsStringヶ月間サブスクライブしました！';
  }

  @override
  String subscriptionMessageMultiMonthEvent(String subscriberUserName,
      String tier, int durationMonths, int cumulativeMonths) {
    final intl.NumberFormat durationMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String durationMonthsString =
        durationMonthsNumberFormat.format(durationMonths);
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b>さんがTier $tierで$durationMonthsStringか月分を先払いでサブスクしました（累計$cumulativeMonthsStringか月）！';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> さんが <b>$value $currency</b> のチップを送りました。';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return '匿名のユーザーが <b>$value $currency</b> にチップを送りました。';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b>がStreamElementsで<b>$formattedAmount</b>をチップしました。';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b>がStreamlabsで<b>$formattedAmount</b>をチップしました。';
  }

  @override
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> が <b>$rewardName</b> を <b>$rewardCostString</b> ポイントで交換しました。 $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> が <b>$rewardName</b> を <b>$rewardCostString</b> ポイントで交換しました。';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> が <b>$bitsString</b> ビッツをチアーしました。 $cheerMessage';
  }

  @override
  String get anonymous => '匿名';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> が <b>$viewersString</b> 人のパーティーでホストしています。';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'ハイプトレインレベル <b>$level</b> が進行中です！ <b>$progressPercent%</b> 完了しました！';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'ハイプトレインレベル <b>$levelString</b> が成功しました。';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'ハイプトレインレベル <b>$levelString</b> が失敗しました。';
  }

  @override
  String get sampleMessage => 'これは音声合成のサンプルメッセージです。';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author は次のように言った: $text';
  }

  @override
  String get textToSpeechEnabled => 'テキスト読み上げ機能が有効';

  @override
  String get textToSpeechDisabled => 'テキスト読み上げが無効になっています';

  @override
  String get alertsEnabled => 'アラートのみ';

  @override
  String get pinDuration => 'ピン留め時間';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds秒',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes分',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'イベントを有効にする';

  @override
  String get showEventInChatHistory => 'チャット履歴にイベントを表示';

  @override
  String get enableShoutouts => 'シャウトアウトを有効にする';

  @override
  String get enableShoutoutsSubtitle => 'レイドしてきたチャンネルへのリンクをチャットに送信';

  @override
  String get raidConfigurationTitle => 'レイドの設定';

  @override
  String get cheerConfigurationTitle => 'Cheerの設定';

  @override
  String get followConfigurationTitle => 'フォローの設定';

  @override
  String get outgoingRaidConfigurationTitle => '送信レイドの設定';

  @override
  String get hostConfigurationTitle => 'ホストの設定';

  @override
  String get channelPointConfigurationTitle => 'チャンネルポイントの設定';

  @override
  String get pollConfigurationTitle => '投票の設定';

  @override
  String get hypetrainConfigurationTitle => 'ハイプトレインの設定';

  @override
  String get subscriptionConfigurationTitle => 'サブスクリプションの設定';

  @override
  String get predictionConfigurationTitle => '予想の設定';

  @override
  String get unfulfilledRewardsPinDuration => '未対応の特典の追加ピン留め時間';

  @override
  String get pollPinDuration => '結果確定後のピン留め時間';

  @override
  String get hypetrainPinDuration => 'ハイプトレイン終了後のピン留め時間';

  @override
  String get enableGiftedSubscriptions => 'ギフトサブを個別に表示する';

  @override
  String get enableGiftedSubscriptionsSubtitle => 'ギフトされたサブスクをすべて表示';

  @override
  String get settingsBackupTitle => '設定のバックアップと復元';

  @override
  String get cloudBackup => 'クラウドバックアップ';

  @override
  String get lastBackupNever => '前回のバックアップ: なし';

  @override
  String get backUp => 'バックアップ';

  @override
  String get restore => '復元';

  @override
  String get localBackup => 'ローカルバックアップ';

  @override
  String get exportSettings => 'エクスポート';

  @override
  String get importSettings => 'インポート';

  @override
  String get showViewerAndFollowerCount => '視聴者数とフォロワー数を表示';

  @override
  String get screenOrientation => '画面の向き';

  @override
  String get appTheme => 'アプリのテーマ';

  @override
  String get systemDefault => 'システム';

  @override
  String get portrait => '縦向き';

  @override
  String get landscape => '横向き';

  @override
  String get lightTheme => 'ライト';

  @override
  String get darkTheme => 'ダーク';

  @override
  String get openSourceTitle => 'RealtimeChatはオープンソースです';

  @override
  String get openSourceSubtitle => 'GitHubで見つけてください！';

  @override
  String get discordSubtitle => 'MuxableのDiscordに参加しよう！';

  @override
  String get earlyTestersThanks => 'バグを報告してくれた初期テスターの皆さんに感謝します！';

  @override
  String get discoModeEnabled => '🕺 ディスコモード オン！ :D';

  @override
  String get discoModeDisabled => '🕺 ディスコモード オフ D:';

  @override
  String get playSampleMessage => 'サンプルメッセージを再生';

  @override
  String get textToSpeechRate => '読み上げ速度';

  @override
  String get textToSpeechPitch => '読み上げの高さ';

  @override
  String get muteBots => 'ボットの読み上げをミュート';

  @override
  String get muteEmotes => 'すべてのエモートの読み上げをミュート';

  @override
  String get muteViewerNames => '視聴者名の読み上げをミュート';

  @override
  String get subscribersOnly => 'サブスク登録者のみ';

  @override
  String get fontSize => 'フォントサイズ';

  @override
  String get usernameContrastBoost => 'ユーザー名のコントラスト強調';

  @override
  String get twitchBadgeSettings => 'Twitchバッジの設定';

  @override
  String get twitchBadgeSettingsSubtitle => '表示するバッジを選択';

  @override
  String get showDeletedMessages => '削除されたメッセージを表示';

  @override
  String get deletedMessagesGreyedOut => '削除されたメッセージはグレー表示されます';

  @override
  String get deletedMessagesRemoved => '削除されたメッセージは非表示になります';

  @override
  String get showLoginNames => 'ログイン名を表示';

  @override
  String get loginNamesShown => '表示名と異なる場合はログイン名を表示します';

  @override
  String get loginNamesHidden => 'ログイン名は非表示になります';

  @override
  String get compactMessages => 'メッセージの短縮';

  @override
  String get dontCompactMessages => 'メッセージを短縮しない';

  @override
  String get dontCompactMessagesSubtitle => 'メッセージはそのまま表示されます';

  @override
  String get compactIndividualMessages => '個々のメッセージを短縮';

  @override
  String get compactIndividualMessagesSubtitle => 'メッセージ内の繰り返しを短縮します';

  @override
  String get announcementPinDuration => 'アナウンスのピン留め時間';

  @override
  String get idleMessageAlertDuration => 'チャット無音アラートの時間';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'この時間メッセージがなく、新しいメッセージが届くとアラート音が鳴ります。';

  @override
  String get realtimeCashSubtitle => 'ETHまたはMATICウォレットを接続';

  @override
  String get walletAddress => 'ウォレットアドレス';

  @override
  String get streamlabsSubtitle => 'Streamlabsの寄付を表示';

  @override
  String get streamElementsSubtitle => 'StreamElementsの寄付を表示';

  @override
  String get thirdPartyAuthError => 'うまくいきませんでした。もう一度試すか、Discordで質問してください。';

  @override
  String get companionAuthBrowserTooOld =>
      'お使いのブラウザは古いため直接ログインできません。スマートフォンでこのQRコードをスキャンして、別のデバイスでログインしてください。';

  @override
  String get companionAuthScanQrCode =>
      'スマートフォンでこのQRコードをスキャンして、別のデバイスでログインしてください。';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b>さんがサブスクライブしました！';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b>さんが$monthsStringか月目のサブスクを更新しました！';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b>さんが$countString件のサブスクをギフトしました！';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b>さんが$amountString Kicksを送りました！';
  }

  @override
  String get signInWithKick => 'Kickでサインイン';

  @override
  String get textToSpeechTooManyMessages => 'メッセージが多すぎます。読み上げをオフにしました';

  @override
  String get turnOffTextToSpeech => 'オフにする';

  @override
  String get addChannel => 'チャンネルを追加';

  @override
  String get addToChat => 'チャットに追加';

  @override
  String get defaultChannels => 'デフォルトのチャンネル';

  @override
  String get defaultChannelsSubtitle => 'アプリを開いたときに表示されるチャンネル';

  @override
  String get save => '保存';

  @override
  String get resetToMyChannel => '自分のチャンネルに戻す';

  @override
  String get inChat => 'チャットに表示中';

  @override
  String get removeFromChat => 'チャットから削除';

  @override
  String cantChatWithAccount(String provider) {
    return '$providerアカウントではここでチャットできません';
  }

  @override
  String replaceChannel(String channel) {
    return '$channelと入れ替える';
  }

  @override
  String get removeChannel => '削除';

  @override
  String get ttsVoiceSection => 'Voice';

  @override
  String get ttsEngine => 'Reads chat with';

  @override
  String get ttsEngineNeural => 'Neural voice (on-device)';

  @override
  String get ttsEngineSystem => 'System voice';

  @override
  String get voicePacks => 'Voice packs';

  @override
  String get voicePacksSubtitleNone =>
      'Download natural-sounding voices that run on your device';

  @override
  String voicePacksSubtitleInstalled(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count installed',
      one: '1 installed',
    );
    return '$_temp0 · $size';
  }

  @override
  String get voicePacksDescription =>
      'Voice packs read chat with natural-sounding neural voices. They run on your device and work offline once downloaded.';

  @override
  String voicePacksStorageUsed(String size) {
    return 'Storage used: $size';
  }

  @override
  String get voicePacksAllowMobileData => 'Download over mobile data';

  @override
  String get voicePacksAllowMobileDataSubtitle =>
      'Voice packs are large, so they download over Wi-Fi only unless you allow this';

  @override
  String get voicePacksLoadError => 'Couldn\'t load the voice packs';

  @override
  String voicePackLanguageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count languages',
      one: '1 language',
    );
    return '$_temp0';
  }

  @override
  String voicePackVoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voices',
      one: '1 voice',
    );
    return '$_temp0';
  }

  @override
  String voicePackDownloadSize(String size) {
    return '$size download';
  }

  @override
  String voicePackSizeOnDisk(String size) {
    return '$size on device';
  }

  @override
  String get voicePackInstalled => 'Installed';

  @override
  String get voicePackUpgradeAvailable => 'Update available';

  @override
  String get voicePackDownload => 'Download';

  @override
  String voicePackDownloadLabel(String pack) {
    return 'Download $pack';
  }

  @override
  String get voicePackUpdate => 'Update';

  @override
  String get voicePackDelete => 'Delete';

  @override
  String voicePackDeleteLabel(String pack) {
    return 'Delete $pack';
  }

  @override
  String voicePackCancelLabel(String pack) {
    return 'Cancel downloading $pack';
  }

  @override
  String voicePackDeleteTitle(String pack) {
    return 'Delete $pack?';
  }

  @override
  String voicePackDeleteBody(String size) {
    return 'This frees $size. Languages no other voice pack speaks will be read with the system voice.';
  }

  @override
  String get voicePackWaitingForWifi => 'Waiting for Wi-Fi';

  @override
  String get voicePackWaiting => 'Waiting to download';

  @override
  String get voicePackUseMobileData => 'Use mobile data';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Downloading: $downloaded of $total';
  }

  @override
  String voicePackProgressLabel(String pack) {
    return '$pack download progress';
  }

  @override
  String get voicePackVerifying => 'Checking the download';

  @override
  String get voicePackExtracting => 'Installing';

  @override
  String voicePackInstallFailed(String pack, String reason) {
    return 'Couldn\'t install $pack: $reason';
  }

  @override
  String voicePackErrorSpace(String size) {
    return 'there isn\'t enough free storage ($size needed)';
  }

  @override
  String get voicePackErrorDownload =>
      'the download failed; check your connection and try again';

  @override
  String get voicePackErrorDamaged => 'the download was damaged; try again';

  @override
  String get voicePackErrorUnsupported => 'it needs a newer version of the app';

  @override
  String get voicePackErrorUnknown => 'something went wrong';

  @override
  String voicePackLicense(String license) {
    return 'License: $license';
  }

  @override
  String get voicePackViewLicense => 'View license';

  @override
  String get voicePackOpenRailNotice =>
      'This model\'s license (OpenRAIL-M) forbids harmful uses, such as impersonating people or spreading disinformation, and these restrictions apply to you too.';

  @override
  String get voicePackMachineGenerated =>
      'Voices from voice packs are machine-generated: they are made by AI, not recorded by a person.';

  @override
  String get voices => 'Voices';

  @override
  String get voicesSubtitle => 'Pick a voice for each language';

  @override
  String get voicesEmpty => 'Download a voice pack to pick voices';

  @override
  String get streamLanguage => 'Stream language';

  @override
  String voicePreviewLabel(String voice) {
    return 'Play a sample of $voice';
  }

  @override
  String get voicePreviewFailed => 'Couldn\'t play the sample';

  @override
  String get voiceFemale => 'Female';

  @override
  String get voiceMale => 'Male';

  @override
  String get perViewerVoice => 'Per-viewer voice';

  @override
  String get perViewerVoiceOnSubtitle =>
      'Each viewer gets their own voice. The voices you pick read alerts and system messages.';

  @override
  String get perViewerVoiceOffSubtitle => 'The voices you pick read everything';

  @override
  String languageUnsupported(String language) {
    return '$language isn\'t supported by your voice packs; the system voice will be used';
  }

  @override
  String get voicePackSuggestionTitle => 'Try a more natural voice';

  @override
  String voicePackSuggestionBody(String pack, String size, String language) {
    return '$pack reads $language chat with a neural voice that runs on your device. It\'s a $size download.';
  }

  @override
  String get voicePackRetry => 'Try again';

  @override
  String get notNow => 'Not now';

  @override
  String get neuralFallbackLowMemoryTitle => 'Using the system voice';

  @override
  String get neuralFallbackLowMemoryBody =>
      'This device doesn\'t have enough memory for neural voices, so chat is read with your phone\'s system voice.';

  @override
  String get neuralFallbackLoadFailedTitle => 'Neural voice couldn\'t start';

  @override
  String get neuralFallbackLoadFailedBody =>
      'The neural voice couldn\'t be loaded, so chat is read with your phone\'s system voice until the app restarts.';

  @override
  String get neuralFallbackLowMemorySnackBar =>
      'Not enough memory for neural voices: chat is read with the system voice';

  @override
  String get neuralFallbackLoadFailedSnackBar =>
      'The neural voice couldn\'t start: chat is read with the system voice';

  @override
  String get gotIt => 'Got it';

  @override
  String get voicePackLowMemory =>
      'This device doesn\'t have enough memory for neural voices';

  @override
  String get voicePackLoadFailed =>
      'Neural voices couldn\'t be loaded on this device this time; the system voice is reading chat';
}
