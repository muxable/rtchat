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
  final List<TwitchPredictionOutcomeModel> outcomes;

  const TwitchPredictionEventModel(
      {required DateTime timestamp,
      required String messageId,
      required this.title,
      this.status,
      this.winningOutcomeId,
      required this.outcomes})
      : super(messageId: messageId, timestamp: timestamp);

  static TwitchPredictionEventModel fromDocumentData(
      Map<String, dynamic> data) {
    return TwitchPredictionEventModel(
        timestamp: data['timestamp'].toDate(),
        messageId: "channel.prediction-${data['event']['id']}",
        title: data['event']['title'],
        status: "in_progress",
        outcomes: List.from(data['event']['outcomes'].values.map((outcome) {
          return TwitchPredictionOutcomeModel(
              outcome['id'],
              outcome['channel_points'] ?? 0,
              outcome['color'],
              outcome['title']);
        })));
  }

  static TwitchPredictionEventModel fromEndEvent(Map<String, dynamic> data) {
    return TwitchPredictionEventModel(
        timestamp: data['timestamp'].toDate(),
        messageId: "channel.prediction-${data['event']['id']}",
        title: data['event']['title'],
        status: data['event']['status'],
        winningOutcomeId: data['event']['winning_outcome_id'],
        outcomes: List.from(data['event']['outcomes'].values.map((outcome) {
          return TwitchPredictionOutcomeModel(outcome['id'],
              outcome['channel_points'], outcome['color'], outcome['title']);
        })));
  }

  int get totalPoints {
    return outcomes.fold(0, (sum, outcome) => sum + outcome.points);
  }
}
