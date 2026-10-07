import 'package:permission_handler/permission_handler.dart';

Future<bool> requestStoragePermission() async {
  var status = await Permission.storage.request();
  if(!status.isGranted){
    status=await Permission.manageExternalStorage.request();
  }
  // try {
  //   status=await Permission.manageExternalStorage.request();
  // } catch (e) {
  //   status = await Permission.storage.request();
  // }
  return status.isGranted;
}