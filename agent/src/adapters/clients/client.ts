export interface ChatClient {
  readonly provider: string;
  readonly channel: string;

  disconnect(reconnect: boolean): void;
}
