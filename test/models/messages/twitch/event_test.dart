import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/messages/auxiliary/realtimecash.dart';
import 'package:rtchat/models/messages/auxiliary/streamelements.dart';
import 'package:rtchat/models/messages/auxiliary/streamlabs.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/messages/twitch/raiding_event.dart';
import 'package:rtchat/models/messages/twitch/shoutout_create_event.dart';
import 'package:rtchat/models/messages/twitch/shoutout_receive_event.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

// Timestamp.toDate() returns local time.
final timestamp = DateTime(2024, 1, 2, 3, 4, 5);

Map<String, dynamic> pollData({
  List<Map<String, dynamic>>? choices,
  Map<String, dynamic> extra = const {},
}) =>
    {
      "timestamp": Timestamp.fromDate(timestamp),
      "event": {
        "id": "p1",
        "title": "Best snack?",
        "started_at": "2024-01-02T03:00:00Z",
        "ends_at": "2024-01-02T03:05:00Z",
        "choices": choices ??
            [
              {"id": "a", "title": "Chips", "votes": 3, "bits_votes": 1},
              {"id": "b", "title": "Candy", "votes": 7},
            ],
        ...extra,
      },
    };

void main() {
  group("TwitchPollEventModel", () {
    test("parseChoices applies defaults for missing fields", () {
      final choices = TwitchPollEventModel.parseChoices(pollData(choices: [
        {"id": "x"},
      ]));
      expect(choices, hasLength(1));
      expect(choices.single.id, "x");
      expect(choices.single.title, "Untitled");
      expect(choices.single.votes, 0);
      expect(choices.single.bitVotes, 0);
      expect(choices.single.channelPointVotes, 0);
    });

    test("fromDocumentData parses an ongoing poll", () {
      final poll = TwitchPollEventModel.fromDocumentData(pollData());
      expect(poll.messageId, "pollp1");
      expect(poll.pollTitle, "Best snack?");
      expect(poll.isCompleted, isFalse);
      expect(poll.status, "ongoing");
      expect(poll.timestamp, timestamp);
      expect(poll.startTimestamp, DateTime.utc(2024, 1, 2, 3));
      expect(poll.endTimestamp, DateTime.utc(2024, 1, 2, 3, 5));
      expect(poll.totalVotes, 10);
      expect(poll.maxVotes, 7);
      expect(poll.totalBitVotes, 1);
      expect(poll.totalChannelPointsVotes, 0);
    });

    test("withEnd marks the poll completed with the final status", () {
      final poll = TwitchPollEventModel.fromDocumentData(pollData());
      final ended = poll.withEnd(pollData(extra: {
        "ended_at": "2024-01-02T03:04:00Z",
        "status": "completed",
      }));
      expect(ended.isCompleted, isTrue);
      expect(ended.status, "completed");
      expect(ended.messageId, poll.messageId);
      expect(ended.endTimestamp, DateTime.utc(2024, 1, 2, 3, 4));
    });
  });

  group("TwitchFollowEventModel", () {
    test("fromDocumentData", () {
      final model = TwitchFollowEventModel.fromDocumentData("f1", {
        "timestamp": Timestamp.fromDate(timestamp),
        "event": {"user_id": "1", "user_login": "foo", "user_name": "Foo"},
      });
      expect(model.messageId, "f1");
      expect(model.timestamp, timestamp);
      expect(model.followers, [
        const TwitchUserModel(userId: "1", login: "foo", displayName: "Foo")
      ]);
    });

    test("merged flattens followers, keeps first id and last timestamp", () {
      TwitchFollowEventModel follow(String id, String login, DateTime t) =>
          TwitchFollowEventModel(
              followers: [TwitchUserModel(userId: id, login: login)],
              messageId: "follow-$id",
              timestamp: t);
      final merged = TwitchFollowEventModel.merged([
        follow("1", "a", DateTime(2024, 1, 1)),
        follow("2", "b", DateTime(2024, 1, 2)),
        follow("3", "c", DateTime(2024, 1, 3)),
      ]);
      expect(merged.followers.map((f) => f.login), ["a", "b", "c"]);
      expect(merged.messageId, "follow-1");
      expect(merged.timestamp, DateTime(2024, 1, 3));
    });
  });

  group("TwitchRaidingEventModel", () {
    final data = {
      "timestamp": Timestamp.fromDate(timestamp),
      "raid": {
        "id": "r1",
        "force_raid_now_seconds": 90,
        "target_id": "42",
        "target_display_name": "Target",
        "target_login": "target",
      },
    };

    test("fromDocumentData", () {
      final model = TwitchRaidingEventModel.fromDocumentData(data);
      expect(model.messageId, "raiding.r1");
      expect(model.timestamp, timestamp);
      expect(model.duration, const Duration(seconds: 90));
      expect(
          model.targetUser,
          const TwitchUserModel(
              userId: "42", login: "target", displayName: "Target"));
      expect(model.isComplete, isFalse);
      expect(model.isSuccessful, isFalse);
    });

    test("withSuccessful and withCancel", () {
      final model = TwitchRaidingEventModel.fromDocumentData(data);
      final success = model.withSuccessful();
      expect(success.isComplete, isTrue);
      expect(success.isSuccessful, isTrue);
      expect(success.messageId, model.messageId);
      final cancel = model.withCancel();
      expect(cancel.isComplete, isTrue);
      expect(cancel.isSuccessful, isFalse);
      expect(success, isNot(cancel));
      expect(model.withCancel(), cancel);
    });
  });

  group("TwitchPredictionEventModel", () {
    Map<String, dynamic> predictionData(Map<String, dynamic> extra) => {
          "timestamp": Timestamp.fromDate(timestamp),
          "event": {
            "id": "pr1",
            "title": "Will we win?",
            "outcomes": [
              {
                "id": "o1",
                "title": "Yes",
                "color": "blue",
                "channel_points": 100
              },
              {
                "id": "o2",
                "title": "No",
                "color": "pink",
                "channel_points": 50
              },
            ],
            ...extra,
          },
        };

    test("fromDocumentData parses an in-progress prediction", () {
      final model = TwitchPredictionEventModel.fromDocumentData(
          predictionData({"locks_at": "2024-01-02T03:10:00Z"}));
      expect(model.messageId, "channel.prediction-pr1");
      expect(model.status, "in_progress");
      expect(model.endTime, DateTime.utc(2024, 1, 2, 3, 10));
      expect(model.outcomes.map((o) => o.title), ["Yes", "No"]);
      expect(model.totalPoints, 150);
      expect(model.winningOutcomeId, isNull);
    });

    test("fromDocumentData defaults missing channel points to zero", () {
      final data = predictionData({"locks_at": "2024-01-02T03:10:00Z"});
      (data["event"]["outcomes"] as List).first.remove("channel_points");
      final model = TwitchPredictionEventModel.fromDocumentData(data);
      expect(model.outcomes.first.points, 0);
      expect(model.totalPoints, 50);
    });

    test("fromEndEvent parses the result", () {
      final model = TwitchPredictionEventModel.fromEndEvent(predictionData({
        "ended_at": "2024-01-02T03:20:00Z",
        "status": "resolved",
        "winning_outcome_id": "o2",
      }));
      expect(model.status, "resolved");
      expect(model.winningOutcomeId, "o2");
      expect(model.endTime, DateTime.utc(2024, 1, 2, 3, 20));
    });

    test("outcome widget color", () {
      expect(TwitchPredictionOutcomeModel("o", 0, "pink", "t").widgetColor,
          isNot(TwitchPredictionOutcomeModel("o", 0, "blue", "t").widgetColor));
    });
  });

  group("TwitchChannelPointRedemptionEventModel", () {
    test("toEnum", () {
      expect(TwitchChannelPointRedemptionStatusParser.toEnum("fulfilled"),
          TwitchChannelPointRedemptionStatus.fulfilled);
      expect(TwitchChannelPointRedemptionStatusParser.toEnum("canceled"),
          TwitchChannelPointRedemptionStatus.canceled);
      expect(TwitchChannelPointRedemptionStatusParser.toEnum("unfulfilled"),
          TwitchChannelPointRedemptionStatus.unfulfilled);
      expect(TwitchChannelPointRedemptionStatusParser.toEnum("bogus"),
          TwitchChannelPointRedemptionStatus.unknown);
    });

    test("fromDocumentData", () {
      final model = TwitchChannelPointRedemptionEventModel.fromDocumentData({
        "timestamp": Timestamp.fromDate(timestamp),
        "event": {
          "id": "c1",
          "user_name": "Foo",
          "status": "unfulfilled",
          "reward": {"title": "Hydrate", "cost": 500},
          "user_input": "drink water",
        },
      });
      expect(model.messageId, "channel.point-redemption-c1");
      expect(model.redeemerUsername, "Foo");
      expect(model.status, TwitchChannelPointRedemptionStatus.unfulfilled);
      expect(model.rewardName, "Hydrate");
      expect(model.rewardCost, 500);
      expect(model.userInput, "drink water");
      expect(model.timestamp, timestamp);
    });
  });

  group("shoutouts", () {
    test("create fromDocumentData", () {
      final model = TwitchShoutoutCreateEventModel.fromDocumentData("s1", {
        "timestamp": Timestamp.fromDate(timestamp),
        "event": {
          "broadcaster_user_id": "1",
          "broadcaster_user_name": "Me",
          "to_broadcaster_user_id": "2",
          "to_broadcaster_user_name": "You",
          "viewer_count": 860,
        },
      });
      expect(model.messageId, "s1");
      expect(model.fromBroadcasterUserId, "1");
      expect(model.fromBroadcasterUserName, "Me");
      expect(model.toBroadcasterUserId, "2");
      expect(model.toBroadcasterUserName, "You");
      expect(model.viewerCount, 860);
      expect(model.timestamp, timestamp);
    });

    test("receive fromDocumentData", () {
      final model = TwitchShoutoutReceiveEventModel.fromDocumentData("s2", {
        "timestamp": Timestamp.fromDate(timestamp),
        "event": {
          "from_broadcaster_user_id": "3",
          "from_broadcaster_user_name": "Them",
          "viewer_count": 12,
        },
      });
      expect(model.messageId, "s2");
      expect(model.fromBroadcasterUserId, "3");
      expect(model.fromBroadcasterUserName, "Them");
      expect(model.viewerCount, 12);
    });
  });

  group("donations", () {
    final tip = {
      "timestamp": Timestamp.fromDate(timestamp),
      "name": "Donor",
      "formattedAmount": "\$5.00",
      "message": "gg",
      "currency": "USD",
    };

    test("streamlabs fromDocumentData", () {
      final model = StreamlabsDonationEventModel.fromDocumentData("d1", tip);
      expect(model.messageId, "d1");
      expect(model.name, "Donor");
      expect(model.formattedAmount, "\$5.00");
      expect(model.message, "gg");
      expect(model.currency, "USD");
      expect(model.timestamp, timestamp);
    });

    test("streamelements fromDocumentData", () {
      final model = StreamElementsTipEventModel.fromDocumentData("d2", tip);
      expect(model.messageId, "d2");
      expect(model.name, "Donor");
      expect(model.formattedAmount, "\$5.00");
      expect(model.currency, "USD");
    });

    test("realtimecash fromDocumentData", () {
      final model =
          SimpleRealtimeCashDonationEventModel.fromDocumentData("d3", {
        "timestamp": Timestamp.fromDate(timestamp),
        "activity": {"asset": "ETH", "value": 0.5, "hash": "0xabc"},
        "donor": "anon",
        "message": "hi",
      });
      expect(model.currency, "ETH");
      expect(model.value, 0.5);
      expect(model.hash, "0xabc");
      expect(model.donor, "anon");
      expect(model.message, "hi");
      expect(model.image.assetName, "assets/ETH.png");
    });

    test("realtimecash defaults unknown asset and parses string values", () {
      final model =
          SimpleRealtimeCashDonationEventModel.fromDocumentData("d4", {
        "timestamp": Timestamp.fromDate(timestamp),
        "activity": {"value": "1.25", "hash": "0xdef"},
      });
      expect(model.currency, "UNKNOWN");
      expect(model.value, 1.25);
      expect(model.image.assetName, "assets/UNKNOWN.png");
      expect(model.donor, isNull);
    });
  });
}
