class LoginModel {
  final int id;
  final String hostAddress;
  final String username;
  final String password;
  final int port;
  final String networkName;

  LoginModel({
    required this.id,
    required this.hostAddress,
    required this.username,
    required this.password,
    required this.port,
    required this.networkName,
  });

  static LoginModel fromDatabase(Map data){
    // متين ضد القيم الفارغة/التالفة في قاعدة البيانات (لا يُسقط التطبيق)
    return LoginModel(
      id: (data["id"] is int) ? data["id"] : int.tryParse('${data["id"]}') ?? 0,
      hostAddress: '${data["host"] ?? ''}',
      username: '${data["username"] ?? ''}',
      password: '${data["password"] ?? ''}',
      port: int.tryParse('${data["port"]}') ?? 8728,
      networkName: '${data["name"] ?? ''}',
    );
  }

  Map<String, dynamic> toDatabase(){
    return <String, dynamic>{
      "host":hostAddress,
      "username":username,
      "password":password,
      "port":port,
      "name":networkName,
    };
  }
}