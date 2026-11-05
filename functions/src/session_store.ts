import type * as admin from "firebase-admin";
import { Store, SessionData } from "express-session";

export interface StoreOptions {
  dataset: admin.firestore.Firestore;
  kind?: string;
}

export class FirestoreStore extends Store {
  db: admin.firestore.Firestore;
  kind: string;
  constructor(options: StoreOptions) {
    super();
    this.db = options.dataset;
    if (!this.db) {
      throw new Error("No dataset provided to Firestore Session.");
    }
    this.kind = options.kind || "Session";
  }

  get = (
    sid: string,
    callback: (err?: Error | null, session?: SessionData) => void,
  ) => {
    this.db
      .collection(this.kind)
      .doc(sid)
      .get()
      .then((doc) => {
        if (!doc.exists) {
          return callback();
        }

        try {
          const result = JSON.parse(doc.data()!.data);
          return callback(null, result);
        } catch (err) {
          return callback(err as Error);
        }
      }, callback);
  };

  set = (
    sid: string,
    session: SessionData,
    callback?: (err?: Error) => void,
  ) => {
    callback = callback || (() => {});
    let sessJson;

    try {
      sessJson = JSON.stringify(session);
    } catch (err) {
      return callback(err as Error);
    }

    this.db
      .collection(this.kind)
      .doc(sid)
      .set({ data: sessJson })
      .then(() => callback!(), callback);
  };

  destroy = (sid: string, callback?: (err?: Error) => void) => {
    callback = callback || (() => {});
    this.db
      .collection(this.kind)
      .doc(sid)
      .delete()
      .then(() => callback!(), callback);
  };
}
