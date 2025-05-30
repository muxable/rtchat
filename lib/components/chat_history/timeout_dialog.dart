import 'package:flutter/material.dart';
import 'package:rtchat/l10n/app_localizations.dart';

class TimeoutDialog extends StatefulWidget {
  final String title;
  final void Function(Duration) onPressed;

  const TimeoutDialog(
      {super.key, required this.title, required this.onPressed});

  @override
  State<TimeoutDialog> createState() => _TimeoutDialogState();
}

class _TimeoutDialogState extends State<TimeoutDialog> {
  var _value = 5;

  String? getLabel(BuildContext context) {
    switch (_value) {
      case 1:
        return AppLocalizations.of(context)!.durationOneSecond;
      case 2:
        return AppLocalizations.of(context)!.durationOneMinute;
      case 3:
        return AppLocalizations.of(context)!.durationTenMinutes;
      case 4:
        return AppLocalizations.of(context)!.durationOneHour;
      case 5:
        return AppLocalizations.of(context)!.durationSixHours;
      case 6:
        return AppLocalizations.of(context)!.durationOneDay;
      case 7:
        return AppLocalizations.of(context)!.durationTwoDays;
      case 8:
        return AppLocalizations.of(context)!.durationOneWeek;
      case 9:
        return AppLocalizations.of(context)!.durationTwoWeeks;
    }
    return null;
  }

  String getPrompt(BuildContext context) {
    switch (_value) {
      case 1:
        return AppLocalizations.of(context)!.durationOneSecondTimeoutPrompt;
      case 2:
        return AppLocalizations.of(context)!.durationOneMinuteTimeoutPrompt;
      case 3:
        return AppLocalizations.of(context)!.durationTenMinutesTimeoutPrompt;
      case 4:
        return AppLocalizations.of(context)!.durationOneHourTimeoutPrompt;
      case 5:
        return AppLocalizations.of(context)!.durationSixHoursTimeoutPrompt;
      case 6:
        return AppLocalizations.of(context)!.durationOneDayTimeoutPrompt;
      case 7:
        return AppLocalizations.of(context)!.durationTwoDaysTimeoutPrompt;
      case 8:
        return AppLocalizations.of(context)!.durationOneWeekTimeoutPrompt;
      case 9:
        return AppLocalizations.of(context)!.durationTwoWeeksTimeoutPrompt;
    }
    return "";
  }

  Duration get _duration {
    switch (_value) {
      case 1:
        return const Duration(seconds: 1);
      case 2:
        return const Duration(minutes: 1);
      case 3:
        return const Duration(minutes: 10);
      case 4:
        return const Duration(hours: 1);
      case 5:
        return const Duration(hours: 6);
      case 6:
        return const Duration(days: 1);
      case 7:
        return const Duration(days: 2);
      case 8:
        return const Duration(days: 7);
      case 9:
        return const Duration(days: 14);
    }
    return const Duration(days: 100 * 365);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          height: 56,
          child: Slider(
            value: _value.toDouble(),
            min: 1,
            max: 9,
            divisions: 9,
            label: getLabel(context),
            onChanged: (double value) {
              setState(() {
                _value = value.toInt();
              });
            },
          ),
        ),
        actions: [
          TextButton(
              child: Text(getPrompt(context)),
              onPressed: () {
                widget.onPressed(_duration);
              })
        ]);
  }
}
