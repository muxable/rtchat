"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cleanup = exports.subscribe = void 0;
const functions = require("firebase-functions");
const pubsub_1 = require("@google-cloud/pubsub");
const admin = require("firebase-admin");
exports.subscribe = functions.https.onRequest(async (req, res) => {
    var _a, _b;
    const provider = (_a = req.body) === null || _a === void 0 ? void 0 : _a.provider;
    const channel = (_b = req.body) === null || _b === void 0 ? void 0 : _b.channel;
    if (!provider || !channel) {
        res.status(400).send("missing provider, channel");
        return;
    }
    const pubsub = new pubsub_1.PubSub({ projectId: "rtchat-47692" });
    const response = await pubsub
        .topic("projects/rtchat-47692/topics/subscribe")
        .publish(Buffer.from(JSON.stringify({ provider, channel })));
    res.status(200).send(response);
});
exports.cleanup = functions.pubsub
    .schedule("* * * * *")
    .onRun(async () => {
    // remove any messages older than 24 hours.
    const timestamp = admin.firestore.Timestamp.fromMillis(new Date().getTime() - 86400 * 1000);
    while (true) {
        const snapshot = await admin
            .firestore()
            .collection("messages")
            .where("timestamp", "<=", timestamp)
            .limit(500)
            .get();
        if (snapshot.empty) {
            return;
        }
        const batch = admin.firestore().batch();
        for (const doc of snapshot.docs) {
            batch.delete(doc.ref);
        }
        await batch.commit();
    }
});
//# sourceMappingURL=index.js.map