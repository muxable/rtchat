class ChatMode {
  final String title;
  final String subtitle;

  ChatMode(this.title, this.subtitle);

  static List<ChatMode> get chatModes => [
        ChatMode("/subscribers", "Restrict Chat to subscribers"),
        ChatMode("/subscribersoff", "Turn off subscribers-only mode"),
        ChatMode("/uniquechat",
            "Prevent users from sending duplicate messages in Chat"),
        ChatMode("/uniquechatoff", "Turn off unique-chat mode"),
        ChatMode("/emoteonly", "Users can only send emotes in their messages"),
        ChatMode("/emoteonlyoff", "Disable emotes only mode"),
        ChatMode("/followers",
            "Restrict the chat to followers-only mode; optionally, specify a time duration (e.g., 30 minutes, 1 week)"),
        ChatMode("/followersoff", "Disable followers-only mode"),
      ];
}
