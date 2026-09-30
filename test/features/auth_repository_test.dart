import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/features/auth/data/auth_repository_impl.dart';
import 'package:mikrotik_manager/services/secure_credentials_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySecureCredentialsStorage secureStorage;
  late AuthRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureStorage = InMemorySecureCredentialsStorage();
    repository = AuthRepositoryImpl(secureStorage: secureStorage);
  });

  test('does not expose credentials when remember-me is disabled', () async {
    SharedPreferences.setMockInitialValues({
      'ip': '192.168.88.1',
      'user': 'admin',
      'remember_me': false,
    });
    await secureStorage.setMikrotikPassword('secret');

    final saved = await repository.loadSavedCredentials();

    expect(saved.local, isNull);
  });

  test('loads remembered local metadata and password from secure storage',
      () async {
    SharedPreferences.setMockInitialValues({
      'remember_me': true,
      'ip': '192.168.88.1',
      'user': 'admin',
      'port': '8729',
    });
    await secureStorage.setMikrotikPassword('secret');

    final saved = await repository.loadSavedCredentials();

    expect(saved.local, isNotNull);
    expect(saved.local!.host, '192.168.88.1');
    expect(saved.local!.username, 'admin');
    expect(saved.local!.password, 'secret');
    expect(saved.local!.port, '8729');
    expect(saved.local!.rememberMe, isTrue);
  });

  test('loads remote credentials only from remote keys', () async {
    SharedPreferences.setMockInitialValues({
      'remember_me_remote': true,
      'remote_server': 'router.example.com',
      'remote_user': 'operator',
      'remote_port': '8729',
    });
    await secureStorage.setRemotePassword('remote-secret');

    final saved = await repository.loadSavedCredentials();

    expect(saved.local, isNull);
    expect(saved.remote, isNotNull);
    expect(saved.remote!.host, 'router.example.com');
    expect(saved.remote!.username, 'operator');
    expect(saved.remote!.password, 'remote-secret');
  });

  test('sign-out removes ephemeral local and remote credentials', () async {
    SharedPreferences.setMockInitialValues({
      'ip': '192.168.88.1',
      'user': 'admin',
      'port': '8728',
      'clear_on_logout': true,
      'remember_me_remote': false,
      'remote_server': 'router.example.com',
      'remote_user': 'operator',
      'remote_port': '8729',
    });
    await secureStorage.setMikrotikPassword('local-secret');
    await secureStorage.setRemotePassword('remote-secret');

    await repository.signOut();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ip'), isNull);
    expect(prefs.getString('user'), isNull);
    expect(prefs.getString('remote_server'), isNull);
    expect(await secureStorage.getMikrotikPassword(), isNull);
    expect(await secureStorage.getRemotePassword(), isNull);
  });

  test('sign-out preserves explicitly remembered credentials', () async {
    SharedPreferences.setMockInitialValues({
      'ip': '192.168.88.1',
      'user': 'admin',
      'clear_on_logout': false,
      'remember_me_remote': true,
      'remote_server': 'router.example.com',
      'remote_user': 'operator',
    });
    await secureStorage.setMikrotikPassword('local-secret');
    await secureStorage.setRemotePassword('remote-secret');

    await repository.signOut();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ip'), '192.168.88.1');
    expect(prefs.getString('remote_server'), 'router.example.com');
    expect(await secureStorage.getMikrotikPassword(), 'local-secret');
    expect(await secureStorage.getRemotePassword(), 'remote-secret');
  });
}
