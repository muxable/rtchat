/// The free space in bytes on the volume holding [path], or null when it
/// can't be told.
typedef FreeSpaceCheck = Future<int?> Function(String path);
