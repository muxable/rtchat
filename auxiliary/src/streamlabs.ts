import fetch from "cross-fetch";
import * as admin from "firebase-admin";
import {
  catchError,
  distinctUntilChanged,
  from,
  merge,
  mergeMap,
  Observable,
  switchMap,
  tap,
} from "rxjs";
// @ts-ignore streamlabs requires exactly socket.io-client@2.3.1
import io from "socket.io-client";
import { log } from "./log";

type Donation = {
  id: number;
  channelId: string;
  name: string;
  amount: string;
  formattedAmount: string;
  message: string | null;
  currency: string;
  timestamp: Date;
};

function listenForSingleUserId(userId: string) {
  log.info({ userId }, "checking if streamlabs linked");
  return new Observable<
    admin.firestore.DocumentSnapshot<admin.firestore.DocumentData>
  >((subscriber) =>
    admin
      .firestore()
      .collection("streamlabs")
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
      const accessToken = JSON.parse(token)?.["access_token"];
      if (!accessToken) {
        return new Observable<never>((subscriber) => subscriber.complete());
      }
      // log a message to indicate that we're listening for donations.
      log.info({ userId, channelId }, "listening for donations");
      const after = doc.get("after");
      const currency = doc.get("currency");
      async function* poll() {
        let url = `https://streamlabs.com/api/v1.0/donations?access_token=${accessToken}`;
        if (after) {
          url += `&after=${after}`;
        }
        if (currency) {
          url += `&currency=${currency}`;
        }
        const response = await fetch(url);
        const json = await response.json();
        if (!json["data"]) {
          return;
        }
        for (const donation of json["data"]) {
          const formatter = new Intl.NumberFormat("en-US", {
            style: "currency",
            currency: donation["currency"],
          });
          yield <Donation>{
            id: donation["donation_id"],
            channelId,
            name: donation["name"],
            amount: donation["amount"],
            formattedAmount: formatter.format(donation["amount"]),
            message: donation["message"],
            currency: donation["currency"],
            timestamp: new Date(donation["created_at"] * 1000),
          };
        }
      }
      async function socketToken() {
        const response = await fetch(
          `https://streamlabs.com/api/v1.0/socket/token?access_token=${accessToken}`
        );
        const json = await response.json();
        return json["socket_token"] as string;
      }
      return merge(
        // return an observable that starts by polling for any missed donations.
        from(poll()),
        // and merge with a socket that listens for new donations.
        from(socketToken()).pipe(
          mergeMap((token) => {
            return new Observable<Donation>((subscriber) => {
              if (!token) {
                subscriber.error("no token");
                return;
              }
              const streamlabs = io(
                `https://sockets.streamlabs.com/?token=${token}`,
                {
                  transports: ["websocket"],
                }
              );
              streamlabs.on("event", (eventData: any) => {
                if (!eventData.for && eventData.type === "donation") {
                  for (const donation of eventData.message) {
                    subscriber.next({
                      id: donation.id,
                      channelId,
                      name: donation.name,
                      amount: donation.amount,
                      formattedAmount: donation.formatted_amount,
                      message: donation.message,
                      currency: donation.currency,
                      timestamp: new Date(),
                    });
                  }
                }
              });
              return () => streamlabs.disconnect();
            });
          })
        )
      ).pipe(
        tap((donation) => {
          // write the after value to the database.
          admin.firestore().runTransaction(async (tx) => {
            const streamlabsDoc = await tx.get(doc.ref);
            const after = streamlabsDoc.get("after");
            if (!after || after < donation.id) {
              tx.update(doc.ref, { after: donation.id });
            }
          });
        })
      );
    }),
    // log the donation to bunyan.
    tap((donation) => {
      log.info({ userId, donation }, "received donation from streamlabs");
    }),
    // and then commit the donation to the database.
    mergeMap((donation) => {
      return admin
        .firestore()
        .collection("channels")
        .doc(donation.channelId)
        .collection("messages")
        .doc(`streamlabs-${donation.channelId}-${donation.id}`)
        .set({
          ...donation,
          type: "streamlabs.donation",
          timestamp: admin.firestore.Timestamp.fromDate(donation.timestamp),
          expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 1000 * 86400 * 7 * 2),
        });
    })
  );
}

export const streamlabs$ = new Observable<
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
