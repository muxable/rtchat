import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TimeoutDialog extends StatefulWidget {
  final String title;
  final void Function(Duration) onPressed;

  const TimeoutDialog({Key? key, required this.title, required this.onPressed})
      : super(key: key);

  @override
  State<TimeoutDialog> createState() => _TimeoutDialogState();
}

class _TimeoutDialogState extends State<TimeoutDialog> {
  var _value = 5;

  String? getLabel(BuildContext context) {
    switch (_value) {
      case 1:
        return AppLocalizations.of(context)!.durationOneMinute;
      case 2:
        return AppLocalizations.of(context)!.durationFifteenMinutes;
      case 3:
        return AppLocalizations.of(context)!.durationOneHour;
      case 4:
        return AppLocalizations.of(context)!.durationSixHours;
      case 5:
        return AppLocalizations.of(context)!.durationOneDay;
      case 6:
        return AppLocalizations.of(context)!.durationTwoDays;
      case 7:
        return AppLocalizations.of(context)!.durationOneWeek;
      case 8:
        return AppLocalizations.of(context)!.durationOneMonth;
      case 9:
        return AppLocalizations.of(context)!.durationThreeMonths;
      case 10:
        return AppLocalizations.of(context)!.durationOneYear;
      case 11:
        return AppLocalizations.of(context)!.durationForever;
    }
    return null;
  }

  String getPrompt(BuildContext context) {
    switch (_value) {
      case 1:
        return AppLocalizations.of(context)!.durationOneMinuteTimeoutPrompt;
      case 2:
        return AppLocalizations.of(context)!
            .durationFifteenMinutesTimeoutPrompt;
      case 3:
        return AppLocalizations.of(context)!.durationOneHourTimeoutPrompt;
      case 4:
        return AppLocalizations.of(context)!.durationSixHoursTimeoutPrompt;
      case 5:
        return AppLocalizations.of(context)!.durationOneDayTimeoutPrompt;
      case 6:
        return AppLocalizations.of(context)!.durationTwoDaysTimeoutPrompt;
      case 7:
        return AppLocalizations.of(context)!.durationOneWeekTimeoutPrompt;
      case 8:
        return AppLocalizations.of(context)!.durationOneMonthTimeoutPrompt;
      case 9:
        return AppLocalizations.of(context)!.durationThreeMonthsTimeoutPrompt;
      case 10:
        return AppLocalizations.of(context)!.durationOneYearTimeoutPrompt;
      case 11:
        return AppLocalizations.of(context)!.durationForeverTimeoutPrompt;
    }
    return "";
  }

  Duration get _duration {
    switch (_value) {
      case 1:
        return const Duration(minutes: 1);
      case 2:
        return const Duration(minutes: 15);
      case 3:
        return const Duration(hours: 1);
      case 4:
        return const Duration(hours: 6);
      case 5:
        return const Duration(days: 1);
      case 6:
        return const Duration(days: 2);
      case 7:
        return const Duration(days: 7);
      case 8:
        return const Duration(days: 30);
      case 9:
        return const Duration(days: 90);
      case 10:
        return const Duration(days: 365);
      case 11:
        return const Duration(days: 100 * 365);
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
            max: 11,
            divisions: 11,
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
