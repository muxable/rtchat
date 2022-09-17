import * as admin from "firebase-admin";
import {
  combineLatestWith,
  filter,
  groupBy,
  merge,
  mergeMap,
  Observable,
} from "rxjs";
// @ts-ignore
import { guessLanguage } from "guesslanguage";
import fetch from "cross-fetch";
import { log } from "./log";

type DeepLSupportedLanguage =
  | "BG"
  | "CS"
  | "DA"
  | "DE"
  | "EL"
  | "EN"
  | "EN-GB"
  | "EN-US"
  | "ES"
  | "ET"
  | "FI"
  | "FR"
  | "HU"
  | "ID"
  | "IT"
  | "JA"
  | "LT"
  | "LV"
  | "NL"
  | "PL"
  | "PT"
  | "PT-BR"
  | "PT-PT"
  | "RO"
  | "RU"
  | "SK"
  | "SL"
  | "SV"
  | "TR"
  | "UK"
  | "ZH";

export function translations$(deeplApiKey: string) {
  async function deepLTranslate(text: string, target: DeepLSupportedLanguage) {
    const response = await fetch("https://api.deepl.com/v2/translate", {
      method: "POST",
      headers: {
        Authorization: `DeepL-Auth-Key ${deeplApiKey}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: `text=${encodeURIComponent(text)}&target_lang=${target}`,
    });
    const json = await response.json();
    if (json.translations[0].detected_source_language === target) {
      return null; // we didn't translate anything.
    }
    return json.translations[0].text as string;
  }

  async function translate(text: string, language: string) {
    const detected = (
      await new Promise<string>((resolve) =>
        guessLanguage.detect(text, resolve)
      )
    ).toUpperCase();
    if (detected === language) {
      return null;
    }
    log.info({ detected, text, language }, "translating");
    return deepLTranslate(text, language as DeepLSupportedLanguage);
  }

  return new Observable<
    admin.firestore.QueryDocumentSnapshot<admin.firestore.DocumentData>
  >((subscriber) => {
    // tfw firestore is just a message bus.
    // TODO: can we optimize this maybe put it in agent safely?
    return admin
      .firestore()
      .collection("messages")
      .orderBy("timestamp", "desc")
      .limit(1)
      .onSnapshot((snapshot) => {
        snapshot.docChanges().forEach((change) => {
          if (change.type === "added") {
            subscriber.next(change.doc);
          }
        });
      });
  }).pipe(
    filter((doc) => doc.get("type") === "message"),
    groupBy((doc) => doc.get("channelId")),
    mergeMap((group) => {
      // watch for the requested translation languages.
      const [provider, channelId] = group.key.split(":");
      return group.pipe(
        combineLatestWith(
          new Observable<string[]>((subscriber) => {
            const ref = admin
              .database()
              .ref("translations")
              .child(provider)
              .child(channelId);
            const listener = (snapshot: admin.database.DataSnapshot) => {
              subscriber.next(Object.keys(snapshot.val() || {}));
            };
            ref.on("value", listener);
            return () => ref.off("value", listener);
          })
        ),
        mergeMap(([doc, languages]) => {
          if (!languages.length) {
            return new Observable<never>((subscriber) => subscriber.complete());
          }
          return merge(
            languages.map(async (language) => {
              const translation = await translate(doc.get("message"), language);
              if (!translation) {
                return;
              }
              // write the translation to the child collection.
              await admin
                .firestore()
                .collection("messages")
                .doc(doc.id)
                .collection("translations")
                .doc(language)
                .set({
                  translation,
                  timestamp: admin.firestore.FieldValue.serverTimestamp(),
                });
            })
          );
        })
      );
    })
  );
}
