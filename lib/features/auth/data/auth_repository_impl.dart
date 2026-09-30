import 'package:shared_preferences/shared_preferences.dart';

import '../../../mikrotik_connector.dart';
import '../../../services/secure_credentials_storage.dart';
import '../domain/auth_credentials.dart';
import '../domain/auth_repository.dart';

/// Persists non-sensitive connection metadata and delegates secrets to the
/// platform secure store. The connector still reads the active connection
/// keys during the compatibility migration.
class AuthRepositoryImpl implements AuthRepository {
  final SecureCredentialsStorage _secureStorage;

  AuthRepositoryImpl({SecureCredentialsStorage? secureStorage})
      : _secureStorage = secureStorage ??
            SecureCredentialsStorageContainer.instance;

  @override
  Future<SavedAuthCredentials> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    RouterCredentials? local;
    RouterCredentials? remote;

    if (prefs.getBool('remember_me') ?? false) {
      local = RouterCredentials(
        host: prefs.getString('ip') ?? '',
        username: prefs.getString('user') ?? '',
        password: await _secureStorage.getMikrotikPassword() ?? '',
        port: prefs.getString('port') ?? '8728',
        rememberMe: true,
      );
    }

    if (prefs.getBool('remember_me_remote') ?? false) {
      remote = RouterCredentials(
        host: prefs.getString('remote_server') ?? '',
        username: prefs.getString('remote_user') ?? '',
        password: await _secureStorage.getRemotePassword() ?? '',
        port: prefs.getString('remote_port') ?? '8728',
        rememberMe: true,
      );
    }

    return SavedAuthCredentials(local: local, remote: remote);
  }

  @override
  Future<void> connectLocal(RouterCredentials credentials) async {
    await _persistActiveConnection(credentials);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', credentials.rememberMe);
    await prefs.setBool('clear_on_logout', !credentials.rememberMe);
    await MikrotikConnector.connect();
  }

  @override
  Future<void> connectRemote(RouterCredentials credentials) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me_remote', credentials.rememberMe);
    await prefs.setBool('clear_on_logout', !credentials.rememberMe);
    await prefs.setString('remote_server', credentials.host.trim());
    await prefs.setString('remote_port', credentials.port.trim());
    await prefs.setString('remote_user', credentials.username.trim());
    await _secureStorage.setRemotePassword(credentials.password);

    // The current connector consumes the active local keys. Mirror the remote
    // endpoint into those keys before connecting until it accepts config
    // injection directly.
    await _persistActiveConnection(credentials);
    await MikrotikConnector.connect();
  }

  @override
  Future<void> signOut() async {
    MikrotikConnector.forceDisconnect();
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('clear_on_logout') ?? false) {
      await prefs.remove('ip');
      await prefs.remove('user');
      await prefs.remove('port');
      await _secureStorage.setMikrotikPassword(null);
      await prefs.remove('clear_on_logout');
    }

    if (!(prefs.getBool('remember_me_remote') ?? false)) {
      await prefs.remove('remote_server');
      await prefs.remove('remote_port');
      await prefs.remove('remote_user');
      await _secureStorage.setRemotePassword(null);
    }
  }

  Future<void> _persistActiveConnection(RouterCredentials credentials) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip', credentials.host.trim());
    await prefs.setString('user', credentials.username.trim());
    await prefs.setString('port', credentials.port.trim());
    await _secureStorage.setMikrotikPassword(credentials.password);
  }
}
