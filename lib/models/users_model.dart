enum UserType{
  blocked,
  regular,
  authorized,
  bypassed;
  static UserType parse(String value) {
    return switch (value.toLowerCase()) {
      'blocked' => UserType.blocked,
      'bypassed' => UserType.bypassed,
      'authorized' => UserType.authorized,
      _ => UserType.regular
      
    };
  }
  UserType get toMikrotik => 
      (this == UserType.blocked || this == UserType.bypassed) ? this : UserType.regular;
    
  
}


class SavedUserModel {
  final String id;
  final String srcAddress;
  final String dstAddress;
  final String macAddress;
  final String server;
  final UserType type;
  final String label;

  SavedUserModel({
    required this.id,
    this.srcAddress="0.0.0.0",
    this.dstAddress="0.0.0.0",
    required this.macAddress,
    this.server="all",
    required this.type,
    required this.label,
  });

  static SavedUserModel fromMikrotik(Map data){
    return SavedUserModel(
      id: data[".id"]??"Unknown", 
      srcAddress: data["address"]??"0.0.0.0", 
      dstAddress: data["to-address"]??"0.0.0.0", 
      macAddress: data["mac-address"]??"", 
      server: data["server"]??"all",
      type: UserType.parse(data["type"].toString()), 
      label: data["comment"]??"Unknown",
    );
  }

  Map toMap(){
    return {
      "id":id,
      "srcAddress":srcAddress,
      "dstAddress":dstAddress,
      "macAddress":macAddress,
      "server":server,
      "type": type.toMikrotik,
      "label":label,
    };
  }


}





class HostUserModel {
  final String id;
  final String srcAddress;
  final String dstAddress;
  final String macAddress;
  final String uptime;
  final String server;
  final String download;
  final String upload;
  final UserType type;
  final String label;
  
  HostUserModel({
    required this.id,
    required this.srcAddress,
    required this.dstAddress,
    required this.macAddress,
    required this.uptime,
    required this.server,
    required this.download,
    required this.upload,
    required this.type,
    required this.label,
  });

  static HostUserModel fromMikrotik(Map user){
    bool isAuth=user.keys.contains("authorized");
    bool isBypass=user.keys.contains("bypassed");
    if( isAuth && user["authorized"]=="true" ){
      user["type"]="authorized";
    }
    else if( isBypass && user["bypassed"]=="true" ){
      user["type"]="bypassed";
    }
    else{
      user["type"]="regular";
    }
    return HostUserModel(
      id: user[".id"]??"Unknown",
      srcAddress: user["address"]??"Unknown", 
      dstAddress: user["to-address"]??"Unknown", 
      macAddress: user["mac-address"]??"Unknown", 
      uptime: user["uptime"]??"Unknown", 
      server: user["server"]??"Unknown", 
      download: user["bytes-out"]??"Unknown",
      upload: user["bytes-in"]??"Unknown",
      type: UserType.parse(user["type"]),
      label: user["comment"]??"Unknown",
    );
  }

  Map toMap(){
    return {
      "id":id,
      "srcAddress":srcAddress,
      "dstAddress":dstAddress,
      "macAddress":macAddress,
      "uptime":uptime,
      "server":server,
      "download":download,
      "upload":upload,
      "type":type.name,
      "label":label,
    };
  }
}







class ActiveUserModel {
  final String id;
  final String address;
  final String macAddress;
  final String uptime;
  final String server;
  final String download;
  final String upload;
  final String label;
  final String username;
  final String timeLeft;
  final String totalPalance;
  
  ActiveUserModel({
    required this.id,
    required this.address,
    required this.macAddress,
    required this.uptime,
    required this.server,
    required this.download,
    required this.upload,
    required this.label,
    required this.username,
    required this.totalPalance ,
    required this.timeLeft
  });

  static ActiveUserModel fromMikrotik(Map user){
    return ActiveUserModel(
      id: user[".id"]??"Unknown",
      address: user["address"]??"Unknown", 
      macAddress: user["mac-address"]??"Unknown", 
      uptime: user["uptime"]??"Unknown", 
      server: user["server"]??"Unknown", 
      download: user["bytes-out"]??"Unknown",
      upload: user["bytes-in"]??"Unknown",
      label: user["comment"]??"Unknown",
      username: user["user"]??"Unknown",
      totalPalance: user["limit-bytes-total"]??"Unknown", 
      timeLeft: user["session-time-left"]??"Unknown", 
      
    );
  }

  Map toMap(){
    return {
      "id":id,
      "address":address,
      "macAddress":macAddress,
      "uptime":uptime,
      "server":server,
      "download":download,
      "upload":upload,
      "label":label,
      "username":username,
      "totalPalance":totalPalance,
      "timeLeft":timeLeft,
    };
  }
}
class DeviceType{
  bool isBlocked;
  bool isFree;
  bool isNormal;
  DeviceType({
    this.isBlocked=false,
    this.isFree=false,
    this.isNormal=true,
  });

  static DeviceType fromMikrotik(String type){
    // bool blo
    return DeviceType(
      isBlocked: type=="blocked",
      isFree: type=="bypassed",
      isNormal: (type!="blocked" && type!="bypassed")
    );
  }

  String toMikrotik(){
    return (isBlocked?"blocked":isFree?"bypassed":"regular");
  }
}
class DevicesModel {
  String id;
  String clientIp;
  String address;
  String macAddress;
  String server;
  DeviceType type;
  String label;

  DevicesModel({
    required this.id,
    this.clientIp="0.0.0.0",
    this.address="0.0.0.0",
    required this.macAddress,
    this.server="all",
    required this.type,
    required this.label,
  });

  static DevicesModel fromMikrotik(Map data){
    return DevicesModel(
      id: data[".id"]??"Unknown", 
      clientIp: data["address"]??"any ip", 
      address: data["to-address"]??"any ip", 
      macAddress: data["mac-address"]??"any mac", 
      server: data["server"]??"all",
      type: DeviceType.fromMikrotik(data["type"]??"normal"), 
      label: data["comment"]??"Unknown",
    );
  }

  Map toMikrotik(){
    return {
      // ".id":id,
      "address":clientIp,
      "to-address":address,
      "mac-address":macAddress,
      "server":server,
      "type":type.toMikrotik(),
      "comment":label,
    };
  }


}
