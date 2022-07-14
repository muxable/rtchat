enum ChatMode {
  followers(
      title: "/followers",
      subtitle:
          "Restrict the chat to followers-only mode; optionally, specify a time duration (e.g., 30 minutes, 1 week)"),
  followersoff(title: "/followersoff", subtitle: "Disable followers-only mode"),
  subscribers(title: "/subscribers", subtitle: "Restrict Chat to subscribers"),
  subscribersoff(
      title: "/subscribersoff", subtitle: "Turn off subscribers-only mode"),
  uniquechat(
      title: "/uniquechat",
      subtitle: "Prevent users from sending duplicate messages in Chat"),
  uniquechatoff(title: "/uniquechatoff", subtitle: "Turn off unique-chat mode"),
  emoteonly(
      title: "/emoteonly",
      subtitle: "Users can only send emotes in their messages"),
  emoteonlyoff(title: "/emoteonlyoff", subtitle: "Disable emotes only mode"),
  slow(
      title: "/slow",
      subtitle: "Limit the rate at which users can send messages"),
  slowoff(title: "/slowoff", subtitle: "Disable slow mode");

  const ChatMode({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}
