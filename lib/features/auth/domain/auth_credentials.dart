class RouterCredentials {
  final String host;
  final String username;
  final String password;
  final String port;
  final bool rememberMe;

  const RouterCredentials({
    required this.host,
    required this.username,
    required this.password,
    required this.port,
    required this.rememberMe,
  });
}

class SavedAuthCredentials {
  final RouterCredentials? local;
  final RouterCredentials? remote;

  const SavedAuthCredentials({this.local, this.remote});
}
