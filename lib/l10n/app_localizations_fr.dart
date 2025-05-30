// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get sendAMessage => 'Envoyer un message...';

  @override
  String get writeSomething => 'Écrivez quelque chose...';

  @override
  String get speakToTheCrowds => 'Parlez aux masses...';

  @override
  String get shareYourThoughts => 'Partagez votre avis...';

  @override
  String get saySomethingYouLittleBitch => 'Dit quelque chose, petite pute...';

  @override
  String get search => 'Rechercher';

  @override
  String get notSignedIn => 'Non signé';

  @override
  String get searchChannels => 'chercher chaînes';

  @override
  String get raidAChannel => 'lancer un raid';

  @override
  String get noMessagesEmptyState => 'aucuns messages';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux messages',
      one: '1 nouveau message',
      zero: 'aucun nouveau message',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'se connecter avec twitch';

  @override
  String get signInError =>
      'La connection avec twitch a raté. Veuillez réessayer.';

  @override
  String get continueAsGuest => 'Continuer en tant qu\'invité';

  @override
  String get signInToSendMessages => 'Inscrivez-vous pour envoyer des messages';

  @override
  String get currentViewers => 'spéctateurs actuels';

  @override
  String get textToSpeech => 'texte vers voix';

  @override
  String get streamPreview => 'aperçu de stream';

  @override
  String get activityFeed => 'Fil d\'actualité';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'stream en ligne à $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'stream hors ligne à $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'discussion effacée à $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'créer liens rapides';

  @override
  String get disableRainMode => 'désactiver mode pluie';

  @override
  String get enableRainMode => 'activer mode pluie';

  @override
  String get disableRainModeSubtitle => 'désactiver sous-titres du mode pluie';

  @override
  String get enableRainModeSubtitle => 'activer sous-titres du mode pluie';

  @override
  String get refreshAudioSources => 'actualiser les sources audio';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count source audio actualisées',
      one: '1 source audio actualisée ',
      zero: 'aucune source audio actualisée',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Paramètres';

  @override
  String get signOut => 'déconnecter';

  @override
  String get cancel => 'annuler';

  @override
  String get signOutConfirmation =>
      'Êtes-vous certain de vouloir vous déconnecter?';

  @override
  String get broadcaster => 'diffuseur';

  @override
  String get moderators => 'modérateurs';

  @override
  String get viewers => 'spectateurs';

  @override
  String get communityVips => 'VIP de communauté';

  @override
  String get searchViewers => 'chercher spectateurs';

  @override
  String get reconnecting => 'entrain de se reconnecter';

  @override
  String get twitchBadges => 'badges twitch';

  @override
  String get selectAll => 'tout sélectionner';

  @override
  String get quickLinks => 'liens rapides';

  @override
  String get swipeToDeleteQuickLinks =>
      'glisser pour suprimer les liens rapides';

  @override
  String get quickLinksLabelHint => 'nom';

  @override
  String get invalidUrlErrorText => 'Ce lien semble indisponible.';

  @override
  String get duplicateUrlErrorText => 'Ce lien existe déjà.';

  @override
  String get or => 'ou';

  @override
  String get clearCookies => 'supprimer les cookies';

  @override
  String get disabled => 'déactivé';

  @override
  String get twitchActivityFeed => 'Fil d\'actualité twitch';

  @override
  String get signInToEnable => 'Connectez-vous pour activé.';

  @override
  String get customUrl => 'URL personnalisée';

  @override
  String get preview => 'aperçu';

  @override
  String get audioSources => 'source audio';

  @override
  String get enableOffStreamSwitchTitle =>
      'activer hors ligne (utilise plus de batterie)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'lecture audio prend aussi place hors ligne';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'lecture audio prend place qu\'en ligne';

  @override
  String get iosOggWarningTitle => 'Hé! Écoutez!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS ne soutien pas le format *.ogg qui est automatiquement utilisé par Streamlabs. Utilisez s\'il vous plaît un format soutenu, pour que les alertes puissent jouer.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'personnaliser le fil d\'actualité';

  @override
  String get audioSourcesSubtitle =>
      'Ajoutez des sites Internet pour jouer les alertes sonores';

  @override
  String get quickLinksSubtitle => 'Ajouter raccourcis aux outils communs';

  @override
  String get chatHistory => 'historique du chat';

  @override
  String get chatHistorySubtitle => 'changer l\'apparence du chat';

  @override
  String get textToSpeechSubtitle => 'changer paramètres du text vers voix';

  @override
  String get events => 'événements';

  @override
  String get eventsSubtitle => 'configurer événements-twitch';

  @override
  String get thirdPartyServices => 'service tiers';

  @override
  String get thirdPartyServicesSubtitle => 'connecter service tiers';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> t\'a suivi';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> et <b>$displayNameTwo</b> t\'ont suivi';
  }

  @override
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>, <b>$displayNameTwo</b>, et $numOthersString t\'ont suivi';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Ne plus mettre $displayName en sourdine';
  }

  @override
  String muteUser(String displayName) {
    return 'Mettre $displayName en sourdine';
  }

  @override
  String timeoutUser(String displayName) {
    return 'bannir $displayName temporairement';
  }

  @override
  String banUser(String displayName) {
    return 'bannir $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'débannir $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'voir le profil de $displayName';
  }

  @override
  String get copyMessage => 'copier le message';

  @override
  String get deleteMessage => 'supprimer le message';

  @override
  String get longScrollNotification =>
      'Vous défilez un peu loin, vous ne trouvez pas?';

  @override
  String get stfu => 'stfu';

  @override
  String get globalEmotes => 'Emoticônes globales';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString suiveurs',
      one: '1 suiveur',
      zero: '0 suiveurs',
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
      other: '$countString téléspectateurs',
      one: '1 téléspectateur',
      zero: '0 téléspectateurs',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Bonjour à tous ! Je suis ravi que tu aimes utiliser la prévisualisation du flux, mais je te préviens qu\'elle consomme beaucoup de batterie. Lire le chat sans l\'utiliser prolongera la durée de vie de ta batterie.';

  @override
  String get okay => 'd\'accord';

  @override
  String get streamPreviewLoading =>
      'Chargement (ou le flux est hors ligne)...';

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get audioSourcesRequirePermissions =>
      'Les sources audio nécessitent des autorisations';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Approuver RealtimeChat pour qu\'il ait la priorité sur les autres applications pour l\'utilisation des sources audio.';

  @override
  String get audioSourcesRemoveButton => 'Supprimer les sources audio';

  @override
  String get audioSourcesOpenSettingsButton => 'Ouvrir les paramètres';

  @override
  String get flashOn => 'Flash allumé';

  @override
  String get flashOff => 'Flash désactivé';

  @override
  String get durationOneSecond => '1 seconde';

  @override
  String get durationOneMinute => '1 minute';

  @override
  String get durationTenMinutes => '10 minutes';

  @override
  String get durationOneHour => '1 heure';

  @override
  String get durationSixHours => '6 heures';

  @override
  String get durationOneDay => '1 jour';

  @override
  String get durationTwoDays => '2 jours';

  @override
  String get durationOneWeek => '1 semaine';

  @override
  String get durationTwoWeeks => '2 semaines';

  @override
  String get durationOneSecondTimeoutPrompt =>
      'Délai d\'attente pour 1 seconde';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Délai d\'attente pour 1 minute';

  @override
  String get durationTenMinutesTimeoutPrompt =>
      'Délai d\'attente pour 10 minutes';

  @override
  String get durationOneHourTimeoutPrompt => 'Délai d\'attente pour 1 heure';

  @override
  String get durationSixHoursTimeoutPrompt => 'Délai d\'attente pour 6 heures';

  @override
  String get durationOneDayTimeoutPrompt => 'Délai d\'attente pour 1 jour';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Délai d\'attente pour 2 jours';

  @override
  String get durationOneWeekTimeoutPrompt => 'Délai d\'attente pour 1 semaine';

  @override
  String get durationTwoWeeksTimeoutPrompt =>
      'Délai d\'attente pour 2 semaines';

  @override
  String get errorFetchingViewerList =>
      'Nous n\'avons pas pu récupérer la liste des téléspectateurs pour cette chaîne';

  @override
  String get eventsTitle => 'Événements';

  @override
  String get followEventConfigTitle => 'Événement de suivi';

  @override
  String get customizeYourFollowEvent =>
      'Personnalisez votre événement de suivi';

  @override
  String get subscribeEventConfigTitle => 'Événement d\'abonnement';

  @override
  String get customizeYourSubscriptionEvent =>
      'Personnalisez votre événement d\'abonnement';

  @override
  String get cheerEventConfigTitle => 'Événement de cheer';

  @override
  String get customizeYourCheerEvent =>
      'Personnalisez votre événement de cheer';

  @override
  String get raidEventConfigTitle => 'Événement de raid';

  @override
  String get customizeYourRaidEvent => 'Personnalisez votre événement de raid';

  @override
  String get hostEventConfigTitle => 'Événement d\'hôte';

  @override
  String get customizeYourHostEvent => 'Personnalisez votre événement d\'hôte';

  @override
  String get hypetrainEventConfigTitle => 'Événement de train de la hype';

  @override
  String get customizeYourHypetrainEvent =>
      'Personnalisez votre événement de train de la hype';

  @override
  String get pollEventConfigTitle => 'Événement de sondage';

  @override
  String get customizeYourPollEvent =>
      'Personnalisez votre événement de sondage';

  @override
  String get predictionEventConfigTitle => 'Événement de prédiction';

  @override
  String get customizeYourPredictionEvent =>
      'Personnalisez votre événement de prédiction';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Événement de rachat de points de chaîne';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Personnalisez votre événement de rachat de points de chaîne';

  @override
  String get outgoingRaidEventConfigTitle => 'Événement de raid sortant';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Personnalisez votre événement de raid sortant';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

    return '<b>$displayName</b> fait un raid avec <b>$viewerCountString</b> spectateurs !';
  }

  @override
  String get shoutout => 'Shoutout';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Raid sur <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Temps restant : $secondsString secondes';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> a fait un raid !';
  }

  @override
  String get raidingEventJoin => 'Rejoindre';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Le raid de <b>$displayName</b> a été annulé.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> s\'est abonné au niveau $tier !';
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

    return '<b>$gifterUserName</b> a offert $totalString abonnements de niveau $tier, totalisant $cumulativeTotalString !';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b> est abonné depuis $cumulativeMonthsString mois au niveau $tier !';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> a donné un pourboire de <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonyme a donné un pourboire de <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> a donné un pourboire de <b>$formattedAmount</b> sur StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> a donné un pourboire de <b>$formattedAmount</b> sur Streamlabs.';
  }

  @override
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> a échangé <b>$rewardName</b> contre <b>$rewardCostString</b> points. $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> a échangé <b>$rewardName</b> contre <b>$rewardCostString</b> points.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> a acclamé <b>$bitsString</b> bits. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonyme';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> héberge avec un groupe de <b>$viewersString</b>.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Le train de la hype de niveau <b>$level</b> est en cours ! <b>$progressPercent%</b> terminé !';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Le train de la hype de niveau <b>$levelString</b> a réussi.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Le train de la hype de niveau <b>$levelString</b> a échoué.';
  }

  @override
  String get sampleMessage =>
      'Il s\'agit d\'un exemple de message pour la synthèse vocale.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author a dit: $text';
  }

  @override
  String get textToSpeechEnabled => 'Synthèse vocale activée';

  @override
  String get textToSpeechDisabled => 'Synthèse vocale désactivée';

  @override
  String get alertsEnabled => 'Alerts only';
}
