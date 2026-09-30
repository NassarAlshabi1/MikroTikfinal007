import 'auth_credentials.dart';

abstract interface class AuthRepository {
  Future<SavedAuthCredentials> loadSavedCredentials();

  Future<void> connectLocal(RouterCredentials credentials);

  Future<void> connectRemote(RouterCredentials credentials);

  Future<void> signOut();
}
