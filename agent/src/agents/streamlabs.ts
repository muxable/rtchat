import { firestore } from "firebase-admin";
import { FirebaseAdapter } from "../adapters/firebase";
import { onStreamlabsDonation } from "../adapters/streamlabs";

export function writeStreamlabsDonationsToMessages(
  adapter: FirebaseAdapter,
  userId: string
) {
  let socket: (() => void) | null = null;
  const unsubscribe = adapter.firestore
    .collection("streamlabs")
    .doc(userId)
    .onSnapshot((doc) => {
      const token = JSON.parse(doc.get("token"));
      const access_token = token["access_token"];
      if (access_token) {
        socket?.();
        socket = onStreamlabsDonation(access_token, async (donation) => {
          const doc = await adapter.firestore
            .collection("profiles")
            .doc(userId)
            .get();
          const channel = doc.get(adapter.provider)["login"];
          const channelId = `${adapter.provider}:${
            doc.get(adapter.provider)["id"]
          }`;
          adapter.firestore
            .collection("messages")
            .add({
              channel,
              channelId,
              type: "streamlabs.donation",
              donation,
              timestamp: firestore.FieldValue.serverTimestamp(),
            })
            .catch((error) => console.log(error));
        });
      }
    });
  return () => {
    socket?.();
    unsubscribe();
  };
}
