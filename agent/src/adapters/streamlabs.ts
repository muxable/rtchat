import { io } from "socket.io-client";

export type Donation = {
  id: string;
  name: string;
  amount: string;
  formattedAmount: string;
  message: string;
  currency: string;
};

export function onStreamlabsDonation(
  token: string,
  onDonation: (arg0: Donation) => void
): () => void {
  const streamlabs = io(`https://sockets.streamlabs.com?token=${token}`, {
    transports: ["websocket"],
  });

  streamlabs.on("event", (eventData) => {
    if (!eventData.for && eventData.type === "donation") {
      for (const donation of eventData.message) {
        onDonation({
          id: donation._id,
          name: donation.name,
          amount: donation.amount,
          formattedAmount: donation.formatted_amount,
          message: donation.message,
          currency: donation.currency,
        });
      }
    }
  });

  return () => streamlabs.close();
}
