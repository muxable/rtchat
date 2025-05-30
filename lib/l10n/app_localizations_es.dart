// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get sendAMessage => 'Enviar un mensaje...';

  @override
  String get writeSomething => 'Escribe algo...';

  @override
  String get speakToTheCrowds => 'Habla a las masas...';

  @override
  String get shareYourThoughts => 'Comparte lo que piensas...';

  @override
  String get saySomethingYouLittleBitch => 'Di algo, perrita...';

  @override
  String get search => 'Buscar';

  @override
  String get notSignedIn => 'Sin iniciar sesión';

  @override
  String get searchChannels => 'Buscar';

  @override
  String get raidAChannel => 'Raid';

  @override
  String get noMessagesEmptyState => 'Demasiado silencioso...';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes nuevos',
      one: '1 mensaje nuevo',
      zero: 'Sin mensajes nuevos',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Inicia sesión con Twitch';

  @override
  String get signInError =>
      'Ocurrió un error iniciando sesión. Intenta de nuevo.';

  @override
  String get continueAsGuest => 'Continuar como invitado';

  @override
  String get signInToSendMessages => 'Inicia sesión para enviar mensajes';

  @override
  String get currentViewers => 'Espectadores';

  @override
  String get textToSpeech => 'Texto a voz';

  @override
  String get streamPreview => 'Vista previa del stream';

  @override
  String get activityFeed => 'Feed de actividades';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'En línea $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Fuera de línea $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Chat limpiado $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Configuración enlaces rápidos';

  @override
  String get disableRainMode => 'Desactivar modo lluvia';

  @override
  String get enableRainMode => 'Activar modo lluvia';

  @override
  String get disableRainModeSubtitle => 'Desactiva la interacción';

  @override
  String get enableRainModeSubtitle => 'Activa la interacción';

  @override
  String get refreshAudioSources => 'Refrescar fuentes de audio';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fuentes de audio refrescadas',
      one: '1 fuente de audio refrescada',
      zero: 'No se refrescaron fuentes de audio',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Configuración';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get cancel => 'Cancelar';

  @override
  String get signOutConfirmation => 'Estás seguro que deseas cerrar sesión?';

  @override
  String get broadcaster => 'Streamer';

  @override
  String get moderators => 'Moderadores';

  @override
  String get viewers => 'Espectadores';

  @override
  String get communityVips => 'VIPs de la comunidad';

  @override
  String get searchViewers => 'Buscar espectadores';

  @override
  String get reconnecting => 'Reconectando...';

  @override
  String get twitchBadges => 'Emblemas de Twitch';

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get quickLinks => 'Enlaces rápidos';

  @override
  String get swipeToDeleteQuickLinks => 'Desliza a los lados para eliminar';

  @override
  String get quickLinksLabelHint => 'Nombre';

  @override
  String get invalidUrlErrorText => 'Este no parece ser un enlace válido';

  @override
  String get duplicateUrlErrorText => 'Este enlace ya existe';

  @override
  String get or => 'o';

  @override
  String get clearCookies => 'Limpiar cookies';

  @override
  String get disabled => 'Desactivado';

  @override
  String get twitchActivityFeed => 'Feed de actividades de Twitch';

  @override
  String get signInToEnable => 'Debes iniciar sesión ara activar está opción';

  @override
  String get customUrl => 'URL Personalizada';

  @override
  String get preview => 'Vista previa';

  @override
  String get audioSources => 'Fuentes de audio';

  @override
  String get enableOffStreamSwitchTitle =>
      'Activar fuera de línea (utiliza más batería)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'También se reproducirá audio cuando esté fuera de línea';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Sólo se reproducirá audio cuando esté en línea';

  @override
  String get iosOggWarningTitle => 'Hey! Atención!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS no soporta el formato *.ogg, el cual es utilizado por defecto en Streamlabs. Asegúrese de utilizar otro formato para que las alertas sean reproducidas.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Personaliza tu feed de actividades';

  @override
  String get audioSourcesSubtitle =>
      'Agrega sitios web para reproducir alertas sonoras';

  @override
  String get quickLinksSubtitle => 'Agrega atajos a herramientas frecuentes';

  @override
  String get chatHistory => 'Historial de Chat';

  @override
  String get chatHistorySubtitle => 'Cambia la apariencia del chat';

  @override
  String get textToSpeechSubtitle => 'Cambia la configuración de Texto a Voz';

  @override
  String get events => 'Eventos';

  @override
  String get eventsSubtitle => 'Configura eventos de Twitch';

  @override
  String get thirdPartyServices => 'Servicios de terceros';

  @override
  String get thirdPartyServicesSubtitle => 'Conecta un servicio de terceros';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> te está siguiendo';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> y <b>$displayNameTwo</b> te están siguiendo';
  }

  @override
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>, <b>$displayNameTwo</b>, y $numOthersString otros te están siguiendo';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Quitar silencio a $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Silenciar a $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Suspender a $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Bannear a $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Quitar ban a $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Ver perfil de $displayName';
  }

  @override
  String get copyMessage => 'Copiar mensaje';

  @override
  String get deleteMessage => 'Eliminar mensaje';

  @override
  String get longScrollNotification => 'Estás bajando mucho, no?';

  @override
  String get stfu => 'ok';

  @override
  String get globalEmotes => 'Emoticonos globales';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString seguidores',
      one: '1 seguidor',
      zero: '0 seguidores',
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
      other: '$countString espectadores',
      one: '1 espectador',
      zero: '0 espectadores',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'La vista previa del stream utiliza batería considerable. Leer el chat sin la vista previa extenderá la batería.';

  @override
  String get okay => 'Ok';

  @override
  String get streamPreviewLoading => 'Cargando (o el stream no está en línea)';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get audioSourcesRequirePermissions =>
      'Las fuentes de audio requireren permisos';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Autorice a RealtimeChat para utilizar fuentes de audio';

  @override
  String get audioSourcesRemoveButton => 'Eliminar fuentes de audio';

  @override
  String get audioSourcesOpenSettingsButton => 'Abrir configuración';

  @override
  String get flashOn => 'Flash activado';

  @override
  String get flashOff => 'Flash desactivado';

  @override
  String get durationOneSecond => '1 segundo';

  @override
  String get durationOneMinute => '1 minuto';

  @override
  String get durationTenMinutes => '10 minutos';

  @override
  String get durationOneHour => '1 hora';

  @override
  String get durationSixHours => '6 horas';

  @override
  String get durationOneDay => '1 día';

  @override
  String get durationTwoDays => '2 días';

  @override
  String get durationOneWeek => '1 semana';

  @override
  String get durationTwoWeeks => '2 semanas';

  @override
  String get durationOneSecondTimeoutPrompt => 'Suspender por 1 segundo';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Suspender por 1 minuto';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Suspender por 10 minutos';

  @override
  String get durationOneHourTimeoutPrompt => 'Suspender por 1 hora';

  @override
  String get durationSixHoursTimeoutPrompt => 'Suspender por 6 horas';

  @override
  String get durationOneDayTimeoutPrompt => 'Suspender por 1 día';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Suspender por 2 días';

  @override
  String get durationOneWeekTimeoutPrompt => 'Suspender por 1 semana';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Suspender por 2 semanas';

  @override
  String get errorFetchingViewerList =>
      'No se pudo obtener la lista de espectadores para este canal';

  @override
  String get eventsTitle => 'Eventos';

  @override
  String get followEventConfigTitle => 'Evento de seguimiento';

  @override
  String get customizeYourFollowEvent => 'Personaliza tu evento de seguimiento';

  @override
  String get subscribeEventConfigTitle => 'Evento de suscripción';

  @override
  String get customizeYourSubscriptionEvent =>
      'Personaliza tu evento de suscripción';

  @override
  String get cheerEventConfigTitle => 'Evento de animación';

  @override
  String get customizeYourCheerEvent => 'Personaliza tu evento de animación';

  @override
  String get raidEventConfigTitle => 'Evento de incursión';

  @override
  String get customizeYourRaidEvent => 'Personaliza tu evento de incursión';

  @override
  String get hostEventConfigTitle => 'Evento de anfitrión';

  @override
  String get customizeYourHostEvent => 'Personaliza tu evento de anfitrión';

  @override
  String get hypetrainEventConfigTitle => 'Evento de tren de hype';

  @override
  String get customizeYourHypetrainEvent =>
      'Personaliza tu evento de tren de hype';

  @override
  String get pollEventConfigTitle => 'Evento de encuesta';

  @override
  String get customizeYourPollEvent => 'Personaliza tu evento de encuesta';

  @override
  String get predictionEventConfigTitle => 'Evento de predicción';

  @override
  String get customizeYourPredictionEvent =>
      'Personaliza tu evento de predicción';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Evento de canje de puntos del canal';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Personaliza tu evento de canje de puntos del canal';

  @override
  String get outgoingRaidEventConfigTitle => 'Evento de incursión saliente';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Personaliza tu evento de incursión saliente';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

    return '<b>$displayName</b> está haciendo una incursión con <b>$viewerCountString</b> espectadores!';
  }

  @override
  String get shoutout => 'Shoutout';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Incursión en <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Quedan $secondsString segundos';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> ha hecho una incursión!';
  }

  @override
  String get raidingEventJoin => 'Unirse';

  @override
  String raidingEventCanceled(String displayName) {
    return 'La incursión de <b>$displayName</b> fue cancelada.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> se ha suscrito en el nivel $tier!';
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

    return '<b>$gifterUserName</b> ha regalado $totalString suscripciones de nivel $tier, sumando un total de $cumulativeTotalString!';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b> se ha suscrito por $cumulativeMonthsString meses en el nivel $tier!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> ha dado una propina de <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anónimo ha dado una propina de <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ha dado una propina de <b>$formattedAmount</b> en StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ha dado una propina de <b>$formattedAmount</b> en Streamlabs.';
  }

  @override
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> canjeó <b>$rewardName</b> por <b>$rewardCostString</b> puntos. $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> canjeó <b>$rewardName</b> por <b>$rewardCostString</b> puntos.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> animó con <b>$bitsString</b> bits. $cheerMessage';
  }

  @override
  String get anonymous => 'Anónimo';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> está alojando con un grupo de <b>$viewersString</b>.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return '¡El tren del hype nivel <b>$level</b> está en progreso! ¡<b>$progressPercent%</b> completado!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'El tren del hype nivel <b>$levelString</b> ha tenido éxito.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'El tren del hype nivel <b>$levelString</b> ha fallado.';
  }

  @override
  String get sampleMessage => 'Este es un mensaje de muestra para texto a voz.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author dijo: $text';
  }

  @override
  String get textToSpeechEnabled => 'Texto a voz activado';

  @override
  String get textToSpeechDisabled => 'Texto a voz desactivado';

  @override
  String get alertsEnabled => 'Alerts only';

  @override
  String get sidebarActions => 'Sidebar Actions';
}
