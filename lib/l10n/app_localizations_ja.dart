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
  String get alertsEnabled => 'Alerts only';
}
