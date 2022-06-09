import 'package:flutter/material.dart';
import 'package:rtchat/models/messages/message.dart';

class TwitchPredictionOutcomeModel {
  final String id;
  final int points;
  final String color;
  final String title;

  TwitchPredictionOutcomeModel(this.id, this.points, this.color, this.title);

  MaterialColor get widgetColor => color == "pink" ? Colors.pink : Colors.blue;
}

class TwitchPredictionEventModel extends MessageModel {
  final String title;
  final String? status;
  final String? winningOutcomeId;
  final DateTime endTime;
  final List<TwitchPredictionOutcomeModel> outcomes;

  const TwitchPredictionEventModel(
      {required DateTime timestamp,
      required String messageId,
      required this.title,
      this.status,
      this.winningOutcomeId,
      required this.endTime,
      required this.outcomes})
      : super(messageId: messageId, timestamp: timestamp);

  static TwitchPredictionEventModel fromDocumentData(
      Map<String, dynamic> data) {
    return TwitchPredictionEventModel(
        timestamp: data['timestamp'].toDate(),
        messageId: "channel.prediction-${data['event']['id']}",
        title: data['event']['title'],
        status: "in_progress",
        endTime: DateTime.parse(data['event']['locks_at']),
        outcomes: data['event']['outcomes']
            .map<TwitchPredictionOutcomeModel>((outcome) {
          return TwitchPredictionOutcomeModel(
              outcome['id'],
              outcome['channel_points'] ?? 0,
              outcome['color'],
              outcome['title']);
        }).toList());
  }

  static TwitchPredictionEventModel fromEndEvent(Map<String, dynamic> data) {
    return TwitchPredictionEventModel(
        timestamp: data['timestamp'].toDate(),
        messageId: "channel.prediction-${data['event']['id']}",
        title: data['event']['title'],
        status: data['event']['status'],
        winningOutcomeId: data['event']['winning_outcome_id'],
        endTime: DateTime.parse(data['event']['ended_at']),
        outcomes: data['event']['outcomes']
            .map<TwitchPredictionOutcomeModel>((outcome) {
          return TwitchPredictionOutcomeModel(outcome['id'],
              outcome['channel_points'], outcome['color'], outcome['title']);
        }).toList());
  }

  int get totalPoints {
    return outcomes.fold(0, (sum, outcome) => sum + outcome.points);
  }
}
