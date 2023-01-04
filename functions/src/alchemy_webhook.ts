import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { ethers } from "ethers";

type Log = {
  removed: boolean;
  address: string;
  data: string;
  topics: string[];
};

type RawContract = {
  rawvalue?: string;
  address?: string;
  decimal?: number;
};

type Activity = {
  category: string;
  fromAddress: string;
  toAddress: string;
  blockNum: string;
  value?: number;
  erc721TokenId?: string;
  asset?: string;
  hash: string;
  typeTraceAddress: string;
  rawContract?: RawContract;
  log?: Log;
};

type AddressEvent = {
  network: string;
  activity: Activity[];
};

type AddressNotification = {
  webhookId: string;
  id: string;
  createdAt: string;
  type: string;
  event: AddressEvent;
};

function isValidSignatureForStringBody(
  body: string, // must be raw string body, not json transformed version of the body
  signature: string, // your "X-Alchemy-Signature" from header
  signingKey: string // taken from dashboard for specific webhook
): boolean {
  const hmac = crypto.createHmac("sha256", signingKey); // Create a HMAC SHA256 hash using the signing key
  hmac.update(body, "utf8"); // Update the token hash with the request body using utf8
  const digest = hmac.digest("hex");
  return signature === digest;
}

const ABI = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256",
        name: "donationAmount",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address payable",
        name: "receiverAddress",
        type: "address",
      },
      {
        indexed: false,
        internalType: "string",
        name: "donor",
        type: "string",
      },
      {
        indexed: false,
        internalType: "string",
        name: "message",
        type: "string",
      },
    ],
    name: "donation",
    type: "event",
  },
  {
    stateMutability: "payable",
    type: "fallback",
  },
  {
    inputs: [
      {
        internalType: "address payable",
        name: "_to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
      {
        internalType: "string",
        name: "donor",
        type: "string",
      },
      {
        internalType: "string",
        name: "message",
        type: "string",
      },
    ],
    name: "donate",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [],
    name: "getBalance",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "myAddress",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    stateMutability: "payable",
    type: "receive",
  },
];

const contractInterface = new ethers.utils.Interface(ABI);

async function storeDonation(
  notification: AddressNotification,
  activity: Activity,
  toAddr: string,
  donor: string,
  message: string
) {
  // look for userId that associated with this address
  const addressDoc = await admin
    .firestore()
    .collection("realtimecash")
    .where("address", "==", toAddr)
    .limit(1)
    .get();

  if (addressDoc.empty) {
    functions.logger.error(`No userId found for address ${toAddr}`);
  }
  const userId = addressDoc.docs[0].id;
  functions.logger.info("UserId obtained", { userId: userId });

  // get channelId for this user
  const profileDoc = await admin
    .firestore()
    .collection("profiles")
    .doc(userId)
    .get();

  const channelId = `twitch:${profileDoc.get("twitch").id}`;
  functions.logger.info("ChannelId obtained", { channelId: channelId });

  // storing donation respoonses in realtimecash collection
  await admin
    .firestore()
    .collection("channels")
    .doc(channelId)
    .collection("messages")
    .add({
      channelId: channelId,
      webhookId: notification.webhookId,
      id: notification.id,
      createdAt: notification.createdAt,
      type: "realtimecash.donation",
      notificationType: notification.type,
      activity: activity,
      donor: donor,
      message: message,
      timestamp: new Date(),
      expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 1000 * 86400 * 7 * 2),
    });
  functions.logger.info("Payload is stored in messages collection");
}

const infuraEthURL =
  "https://mainnet.infura.io/v3/44f12a91c4c146ae83472b2656b4fff6";
const ethProdProvider = new ethers.providers.JsonRpcProvider(infuraEthURL);

// listen for eth mainnet
export const ethAlchemyWebhook = functions.https.onRequest(async (req, res) => {
  const body = req.body;
  const rawBody = req.rawBody.toString();
  const headerKey = req.headers["x-alchemy-signature"] as string;
  const signingKey = functions.config().alchemy.ethsigningkey;

  if (!isValidSignatureForStringBody(rawBody, headerKey, signingKey)) {
    res.status(403).send("Fail to validate signature");
    return;
  }

  const notification: AddressNotification = body as AddressNotification;

  for (const activity of notification.event.activity) {
    const transaction = contractInterface.parseTransaction(
      await ethProdProvider.getTransaction(activity.hash)
    );
    if (transaction.name === "donate") {
      functions.logger.info("transaction args", {
        transaction_args: transaction.args,
      });
      const [to, amount, donor, message] = transaction.args;
      functions.logger.info("donation", {
        to,
        amount,
        donor,
        message,
        activity,
        msg: transaction.args[3],
      });
      const toAddr = to.toLowerCase();
      await storeDonation(notification, activity, toAddr, donor, message);
    }
  }
  res.status(200).send("OK");
});

const infuraPolyURL =
  "https://polygon-mainnet.infura.io/v3/44f12a91c4c146ae83472b2656b4fff6";
const polyProvider = new ethers.providers.JsonRpcProvider(infuraPolyURL);

// MATIC, listen for matic mainnet
export const alchemyWebhook = functions.https.onRequest(async (req, res) => {
  const body = req.body;
  const rawBody = req.rawBody.toString();
  const headerKey = req.headers["x-alchemy-signature"] as string;
  const signingKey = functions.config().alchemy.signingkey;

  functions.logger.info("body", {
    req: req,
    rawBody: rawBody,
    headerKey: headerKey,
    signingKey: signingKey,
    body: body,
  });

  if (!isValidSignatureForStringBody(rawBody, headerKey, signingKey)) {
    res.status(403).send("Fail to validate signature");
    return;
  }

  functions.logger.info("Signature validated");
  const notification: AddressNotification = body as AddressNotification;

  for (const activity of notification.event.activity) {
    const transaction = contractInterface.parseTransaction(
      await polyProvider.getTransaction(activity.hash)
    );
    if (transaction.name === "donate") {
      functions.logger.info("transaction args", {
        transaction_args: transaction.args,
      });
      const [to, amount, donor, message] = transaction.args;
      functions.logger.info("donation", {
        to,
        amount,
        donor,
        message, // not showing the actual message in log
        activity,
        msg: transaction.args[3],
      });
      const toAddr = to.toLowerCase();
      await storeDonation(notification, activity, toAddr, donor, message);
    }
  }
  res.status(200).send("OK");
});

export const setRealTimeCashAddress = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      functions.logger.error("User is not authenticated");
      throw new functions.https.HttpsError("permission-denied", "missing auth");
    }

    const userId = context.auth.uid;
    const address = data?.address;
    functions.logger.info("caller payload", {
      userId: userId,
      address: address,
    });
    if (!address) {
      functions.logger.error("missing address");
      throw new functions.https.HttpsError(
        "invalid-argument",
        "missing userId, address params"
      );
    }

    functions.logger.info("address valid, calling alchemy api");

    const MATICWEBHOOKID = functions.config().alchemy.maticwebhookid;
    const ETHWEBHOOKID = functions.config().alchemy.ethwebhookid;

    functions.logger.info("payload", {
      userId: userId,
      addresses_to_add: address,
      ethwebhook_id: ETHWEBHOOKID,
      maticwebhook_id: MATICWEBHOOKID,
    });

    await admin
      .firestore()
      .collection("realtimecash")
      .doc(userId)
      .set(
        {
          address,
          maticWebhookId: MATICWEBHOOKID,
        },
        { merge: true }
      )
      .catch((error) => {
        functions.logger.error("Error writing document: ", error);
        // fail to write to firestore
        throw new functions.https.HttpsError(error, error.message);
      });

    await admin
      .firestore()
      .collection("realtimecash")
      .doc(userId)
      .set(
        {
          address,
          ethWebhookId: ETHWEBHOOKID,
        },
        { merge: true }
      )
      .catch((error) => {
        functions.logger.error("Error writing document: ", error);
        // fail to write to firestore
        throw new functions.https.HttpsError(error, error.message);
      });

    return;
  }
);
