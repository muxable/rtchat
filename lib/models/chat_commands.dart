class ChatCommand {
  final String name;
  final String description;
  final List<String> arguments;

  const ChatCommand({
    required this.name,
    this.description = '',
    this.arguments = const [],
  });
}

const List<ChatCommand> chatCommands = [
  ChatCommand(
    name: '/me',
    description: 'Send an action message',
    arguments: ['message'],
  ),
  ChatCommand(
    name: '/color',
    description:
        'Change your username color, i.e. blue, green, or any Hex value for Turbo users.',
    arguments: ['color'],
  ),
  ChatCommand(
    name: '/block',
    description: 'Block a user from interacting with you on Twitch',
    arguments: ['username'],
  ),
  ChatCommand(
    name: '/unblock',
    description: 'Remove user from your block list',
    arguments: ['username'],
  ),
  ChatCommand(
    name: '/w',
    description:
        'This command sends a private message to another user on Twitch.',
    arguments: ['username', 'message'],
  ),
  ChatCommand(
    name: '/user',
    description: 'Display profile information about a user on this channel',
    arguments: ['username'],
  ),
  ChatCommand(
    name: '/pin',
    description: 'Pin a message you send into chat for the channel.',
    arguments: ['message'],
  ),
  ChatCommand(
    name: '/shoutout',
    description: 'Highlight a channel for viewers to follow',
    arguments: ['message'],
  ),
  ChatCommand(
    name: '/announce',
    description: 'Call attention to your message with a highlight.',
    arguments: ['message'],
  ),
  ChatCommand(
    name: '/timeout',
    description: 'Temporarily ban a user from Chat (default 600)',
    arguments: ['username', 'seconds', 'reason'],
  ),
  ChatCommand(
    name: '/ban',
    description: 'Permanently ban a user from Chat',
    arguments: ['username'],
  ),
  ChatCommand(
    name: '/unban',
    description: 'Remove a timeout or permanent ban on a user',
    arguments: ['username'],
  ),
  ChatCommand(
    name: '/endpoll',
    description: 'End the active poll in the given channel',
  ),
  ChatCommand(
    name: '/deletepoll',
    description: 'Delete the active poll on the given channel',
  ),
  ChatCommand(
    name: '/commercial',
    description:
        'Command that runs a commercial, for the seconds specified (default 30), for all of your viewers.',
    arguments: ['duration'],
  ),
  ChatCommand(
    name: '/prediction',
    description: 'This command will enable you to manage predictions.',
  ),
  ChatCommand(
    name: '/raid',
    description: 'Send viewers to another channel when your stream ends',
    arguments: ['channel'],
  ),
  ChatCommand(name: '/unraid', description: 'Cancel an outgoing Raid'),
  ChatCommand(
    name: '/marker',
    description: 'Add a stream marker at the current timestamp',
    arguments: ['description'],
  ),
  ChatCommand(
    name: '/mod',
    description: 'Grant moderator status to a user',
    arguments: ['username'],
  ),
  ChatCommand(
    name: '/unmod',
    description: 'Revoke moderator status from a user',
    arguments: ['username'],
  ),
  ChatCommand(
    name: '/vip',
    description: 'Grant VIP status to a user',
    arguments: ['username'],
  ),
  ChatCommand(
    name: '/unvip',
    description: 'Revoke VIP status from a user',
    arguments: ['username'],
  ),
];
