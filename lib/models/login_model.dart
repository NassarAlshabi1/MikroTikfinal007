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
    return LoginModel(
      id: data["id"], 
      hostAddress: data["host"], 
      username: data["username"], 
      password: data["password"], 
      port: int.parse(data["port"]), 
      networkName: data["name"]
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