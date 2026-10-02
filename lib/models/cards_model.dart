// String props="""
// username,password,
// actual-profile,
// uptime-used,download-used,
// upload-used,last-seen""";
enum CardStatus{
  normal,
  active,
  expired;

  static CardStatus parse(String value) {
    return switch (value.toLowerCase()) {
      'normal' => CardStatus.normal,
      'active' => CardStatus.active,
      _ => CardStatus.expired,
      
    };
  }
}
class CardModel {
  final String id;
  final String username;
  final String password;
  final String profile;
  final String status;
  final String customer;

  CardModel({
    required this.id,
    required this.username,
    required this.password,
    required this.profile,
    required this.status,
    required this.customer,
  });

  static CardModel fromMikrotik(Map card){
    String tempStatus="normal";
    String uptime="";

    uptime=card.keys.toList().contains("uptime-used")?card["uptime-used"]:"";

    if((!card.keys.toList().contains("actual-profile")) && uptime!=""){
      tempStatus="expired";
    }
    else if(card.keys.toList().contains("actual-profile") && uptime!=""){
      tempStatus="active";
    }
    else{
      tempStatus="normal";
    }
    return CardModel(
      id: card[".id"],
      username: card["username"], 
      password: card["password"], 
      profile: card["actual-profile"]??"unknown", 
      status: tempStatus, 
      customer: card["customer"],
    );
  }


  Map toMap(){
    return {
      "id":id,
      "username":username,
      "password":password,
      "profile":profile,
      "status":status,
      "customer":customer,
    };
  }
}


//  customer=admin user="issaka21802" 
//  nas-port-id="ether4"
// calling-station-id="D4:53:83:66:3C:BF"
// user-ip=9.9.9.16 
// from-time=jul/11/2025 07:27:24
// till-time=jul/11/2025 07:55:47 
// uptime=28m23s

class CustomerModel {
  final String id;
  final String name;

  CustomerModel({required this.id, required this.name});

  static CustomerModel fromMikrotik(Map data) {
    return CustomerModel(
      id: data[".id"] ?? "unknown",
      name: data["login"] ?? "unknown",
    );
  }

  Map toMap() {
    return {
      "id": id,
      "login": name,
    };
  }
}
class CardSessionModel {
  final String id;
  final String username;
  final String fromTime;
  final String toTime;
  final String macAddress;
  final String ip;
  final String uptime;
  final String port;
  // الخصائص الجديدة بنوع String
  final String download;
  final String upload;

  CardSessionModel({
    required this.id,
    required this.username,
    required this.fromTime,
    required this.toTime,
    required this.macAddress,
    required this.ip,
    required this.uptime,
    required this.port,
    required this.download,
    required this.upload,
  });

  static CardSessionModel fromMikrotik(Map session) {
    return CardSessionModel(
      id: session[".id"] ?? "",
      username: session["user"] ?? "",
      fromTime: session["from-time"] ?? "",
      toTime: session["till-time"] ?? "",
      macAddress: session["calling-station-id"] ?? "",
      ip: session["user-ip"] ?? "",
      uptime: session["uptime"] ?? "",
      port: session["nas-port-id"] ?? "",
      // تحويل القيم القادمة من ميكروتك إلى String بشكل آمن
      download: session["download"]?.toString() ?? "0",
      upload: session["upload"]?.toString() ?? "0",
    );
  }

  Map toMap() {
    return {
      "id": id,
      "username": username,
      "fromTime": fromTime,
      "toTime": toTime,
      "macAddress": macAddress,
      "ip": ip,
      "uptime": uptime,
      "port": port,
      "download": download,
      "upload": upload,
    };
  }
}