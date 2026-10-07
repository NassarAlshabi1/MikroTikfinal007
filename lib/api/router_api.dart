import 'package:mikronet/models/response.dart';
import 'package:mikronet/services/mikrotik_client.dart';

class RouterApi {
  static Future<AppResponse<void>> rebootSystem()async{
    try{
      await MikrotikClient.printData(commands: ["/system/reboot"]);
      return AppResponse(status: true, message: "سيتم اعادة التشغيل الان");
    }catch(e){
      return AppResponse(status: false, message: e.toString());
    }
  }
  static Future<AppResponse<String>> getRouterSerial()async{
    try{
      var res = await MikrotikClient.printData(commands: ["/system/routerboard/print"]);
      
      var serial = res.first["serial-number"] ?? "";
      return AppResponse(status: true, message: "",data: serial);
    }catch(e){
      return AppResponse(status: false, message: e.toString());
    }
  }

  
}