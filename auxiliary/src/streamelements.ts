import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import fetch from "cross-fetch";
import * as admin from "firebase-admin";
import {
  catchError,
  distinctUntilChanged,
  from,
  merge,
  mergeMap,
  Observable,
  retry,
  switchMap,
  tap,
} from "rxjs";
// @ts-ignore streamelements requires exactly socket.io-client@2.3.1
import io from "socket.io-client";
import { log } from "./log";

type Tip = {
  id: number;
  channelId: string;
  name: string;
  amount: string;
  formattedAmount: string;
  message: string | null;
  currency: string;
  timestamp: Date;
};

async function refreshToken(refreshToken: string) {
  const client = new SecretManagerServiceClient();
  const [clientIdVersion] = await client.accessSecretVersion({
    name: "projects/rtchat-47692/secrets/streamelements-client-id/versions/latest",
  });
  const clientIdSecret = clientIdVersion.payload?.data?.toString();
  if (!clientIdSecret) {
    throw new Error("unable to retrieve credentials from secret manager");
  }
  const [clientSecretVersion] = await client.accessSecretVersion({
    name: "projects/rtchat-47692/secrets/streamelements-client-secret/versions/latest",
  });
  const clientSecretSecret = clientSecretVersion.payload?.data?.toString();
  if (!clientSecretSecret) {
    throw new Error("unable to retrieve credentials from secret manager");
  }
  const response = await fetch(`https://api.streamelements.com/oauth2/token`, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: refreshToken,
      client_id: clientIdSecret,
      client_secret: clientSecretSecret,
    }),
  });
  const json = await response.json();
  const expiresAt = new Date(+new Date() + json["expires_in"] * 1000);
  return { ...json, expires_at: expiresAt.toISOString() };
}

function listenForSingleUserId(userId: string) {
  log.info({ userId }, "checking if streamelements linked");
  return new Observable<
    admin.firestore.DocumentSnapshot<admin.firestore.DocumentData>
  >((subscriber) =>
    admin
      .firestore()
      .collection("streamelements")
      .doc(userId)
      .onSnapshot((doc) => subscriber.next(doc))
  ).pipe(
    // distinct on token
    distinctUntilChanged((a, b) => a.get("token") === b.get("token")),
    switchMap((doc) => {
      // if there's no token, return an empty observable.
      const channelId = doc.get("channelId");
      const token = doc.get("token");
      if (!token || !channelId) {
        return new Observable<never>((subscriber) => subscriber.complete());
      }
      const parsed = JSON.parse(token);
      if (!parsed) {
        return new Observable<never>((subscriber) => subscriber.complete());
      }
      const accessToken = parsed["access_token"];
      if (!accessToken) {
        return new Observable<never>((subscriber) => subscriber.complete());
      }
      // check the expiration date.
      const expiresAt = Date.parse(parsed["expires_at"]);
      if (expiresAt < +new Date() + 1000 * 60 * 60 * 24) {
        // refresh the token.
        log.info({ userId }, "refreshing streamelements token");
        refreshToken(parsed["refresh_token"]).then((newToken) => {
          return doc.ref.update({ token: JSON.stringify(newToken) });
        });
        return new Observable<never>((subscriber) => subscriber.complete());
      }

      // log a message to indicate that we're listening for donations.
      log.info({ userId, channelId }, "listening for donations");
      const after = doc.get("after");
      async function* poll() {
        console.log(accessToken);
        const channel = await fetch(
          `https://api.streamelements.com/kappa/v2/channels/me`,
          {
            headers: {
              Accept: "application/json",
              "Content-Type": "application/json",
              Authorization: `OAuth ${accessToken}`,
            },
          }
        )
          .then((response) => response.json())
          .then((json) => json["_id"]);
        let url = `https://api.streamelements.com/kappa/v2/tips/${channel}`;
        if (after) {
          url += `&after=${after}`;
        }
        const response = await fetch(url, {
          headers: {
            "Content-Type": "application/json",
            Authorization: `OAuth ${accessToken}`,
          },
        });
        const json = await response.json();
        if (!json["docs"]) {
          return;
        }
        for (const doc of json["docs"]) {
          const formatter = new Intl.NumberFormat("en-US", {
            style: "currency",
            currency: doc["donation"]["currency"],
          });
          yield <Tip>{
            id: doc["_id"],
            channelId,
            name: doc["donation"]["user"]["username"],
            amount: doc["donation"]["amount"],
            formattedAmount: formatter.format(doc["donation"]["amount"]),
            message: doc["donation"]["message"],
            currency: doc["donation"]["currency"],
            timestamp: new Date(doc["createdAt"]),
          };
        }
      }
      function push() {
        // if there's no token, return an empty observable.
        return new Observable<Tip>((subscriber) => {
          const streamelements = io(`https://realtime.streamelements.com/`, {
            transports: ["websocket"],
          });
          streamelements.on("connect", () => {
            log.info({ userId }, "connected to streamelements");
            streamelements.emit("authenticate", {
              method: "oauth2",
              token: accessToken,
            });
          });
          streamelements.on("event", (eventData: any) => {
            if (eventData["type"] === "tip") {
              const tip = eventData["data"];
              const formatter = new Intl.NumberFormat("en-US", {
                style: "currency",
                currency: tip["currency"],
              });
              subscriber.next(<Tip>{
                id: eventData["_id"],
                channelId,
                name: tip["username"],
                amount: tip["amount"],
                formattedAmount: formatter.format(tip["amount"]),
                message: tip["message"],
                currency: tip["currency"],
                timestamp: new Date(Date.parse(eventData["createdAt"])),
              });
            }
          });
          streamelements.on("authenticated", () => {
            log.info({ userId }, "authenticated with streamelements");
          });
          streamelements.on("disconnect", () => {
            log.error({ userId }, "unexpected disconnect from streamelements");
            subscriber.error(
              new Error("unexpected disconnect from streamelements")
            );
          });
          streamelements.on("unauthorized", (reason: any) => {
            log.error({ userId, reason }, "unauthorized from streamelements");
            subscriber.error(
              new Error("unauthorized from streamelements: " + reason)
            );
          });
          return () => streamelements.disconnect();
        });
      }
      return merge(
        // return an observable that starts by polling for any missed donations.
        from(poll()),
        // and merge with a socket that listens for new donations.
        from(push().pipe(retry(5)))
      ).pipe(
        tap((donation) => {
          // write the after value to the database.
          admin.firestore().runTransaction(async (tx) => {
            const streamelementsDoc = await tx.get(doc.ref);
            const after = streamelementsDoc.get("after");
            if (!after || after < donation.id) {
              tx.update(doc.ref, { after: donation.timestamp.getTime() });
            }
          });
        })
      );
    }),
    // log the donation to bunyan.
    tap((donation) => {
      log.info({ userId, donation }, "received donation from streamelements");
    }),
    // and then commit the donation to the database.
    mergeMap((donation) => {
      return admin
        .firestore()
        .collection("channels")
        .doc(donation.channelId)
        .collection("messages")
        .doc(`streamelements-${donation.channelId}-${donation.id}`)
        .set({
          ...donation,
          type: "streamelements.tip",
          timestamp: admin.firestore.Timestamp.fromDate(donation.timestamp),
          expiresAt: admin.firestore.Timestamp.fromMillis(
            Date.now() + 1000 * 86400 * 7 * 2
          ),
        });
    })
  );
}

export const streamelements$ = new Observable<
  admin.firestore.QueryDocumentSnapshot<admin.firestore.DocumentData>
>((subscriber) => {
  const threshold = admin.firestore.Timestamp.fromMillis(
    new Date().getTime() - 3 * 86400 * 1000
  );
  return admin
    .firestore()
    .collection("profiles")
    .where("lastActiveAt", ">", threshold)
    .onSnapshot(async (snapshot) => {
      for (const change of snapshot.docChanges()) {
        if (change.type === "added") {
          subscriber.next(change.doc);
        }
      }
    });
}).pipe(
  mergeMap((doc) =>
    listenForSingleUserId(doc.id).pipe(
      catchError((error) => {
        log.error({ userId: doc.id, error: error.message }, "got error");
        return new Observable<never>((subscriber) => subscriber.complete());
      })
    )
  )
);
