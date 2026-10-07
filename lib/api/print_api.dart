
import 'package:mikronet/models/response.dart';

import '/api/cards_api.dart';
import '/api/database_api.dart';

class PrintTemplatesApi {
 static Future<List> getAllTemplates()async{
  return await DBApi.select("templates");
 }

 static Future<Map> getTemplateData(int id)async{
  List result=await DBApi.select("templates","id=$id");
  return result.isEmpty?{}:result[0];
 }

 static Future<int> addOneTemplate(Map data)async{
  return await DBApi.insert("templates", data as Map<String, dynamic>);
 }

 static Future<int> templateEdit(int id, Map data)async{
  return await DBApi.update("templates", data as Map<String, dynamic> ,"id=$id");
 }

 static Future<int> deleteTemplate(int id)async{
  return await DBApi.delete("templates","id=$id");
 }
 


}





class PrintBatchesApi {
 static Future<List> getAllBatches()async{
  return await DBApi.select("batches");
 }

 static Future<List> getAllCards()async{
  return await DBApi.select("cards");
 }

 static Future<List> getBatchCards(int batchId)async{
  return await DBApi.select("cards","batch_id=$batchId");
 }

 static Future<List> getAllBatches2()async{
  List batches=await DBApi.select("batches");
  List cards=await DBApi.select("cards");
  List result= batches.map((b){
    var c=cards.where((i)=>i["batch_id"]==b["id"]).toList();
    var temp=Map.from(b);
    temp["cards"]=c;
    return temp;
  }).toList();
  return result;
 }
 static Future<List> getAllBatchesByRouter(String routerSerial)async{
  // return await DBApi.select("batches","router_serial='$routerSerial'");
  List batches=await DBApi.select("batches","router_serial like '$routerSerial'");
  List cards=await DBApi.select("cards");
  List result= batches.map((b){
    var c=cards.where((i)=>i["batch_id"]==b["id"]).toList();
    var temp=Map.from(b);
    temp["cards"]=c;
    return temp;
  }).toList();
  return result;
  
 }

 static Future<Map> getBatchData(int id)async{
  List result=await DBApi.select("batches","id=$id");
  return result.isEmpty?{}:result[0];
 }

 static Future<List> getBatchWith(String where)async{
  return await DBApi.select("batches",where);
 }

 static Future<int> addOneBatch(Map<String, dynamic>  data)async{
  return await DBApi.insert("batches", data);
 }

 static Future<int> deleteBatchCards(int batchId)async{
  return await DBApi.delete("cards", "batch_id=$batchId");
 }

 static Future<int> addBatchCards(List<Map<String, dynamic>> cards,int batchId)async{
  cards=cards.map((i){
    i["batch_id"]=batchId;
    return i;
  }).toList();
  return await DBApi.insertBatch("cards", cards);
 }

 static Future<int> changeCardType(bool isAdd)async{
  return await DBApi.update("cards", {'is_add':isAdd?1:0});
 }

//  static Future<int> addOneBatch2(Map<String, dynamic>  data,List<Map<String, dynamic>> ids)async{
//   int batch=await DBApi.insert("batches", data);
//   ids.map((i){
//     i["batch_id"]=batch;
//     return i;
//   }).toList();
//   // for (var i in ids) {
//   //   i["batch_id"]=batch;
//   //   await DBApi.insert("cards", i);
//   // }
//   int cards=await DBApi.insertBatch("cards", ids);
//   return cards;
//  }

 static Future<int> batchEdit(int id, Map<String, dynamic> data)async{
  return await DBApi.update("batches", data ,"id=$id");
 }

 static Future<int> deleteFromLocal(int id)async{
  await deleteBatchCards(id);
  return await DBApi.delete("batches","id=$id");
 }

 static Future<String> deleteFromServer(int id)async{
  try {
    Map batch=await getBatchData(id);
    String cards=batch["generated_cards"];
    AppResponse<List<String>> ids= await CardsApi.getIdsByUsernames( cards.split(",") );
    await CardsApi.deleteCardsBatch(ids.data??[]);
    return "done";
  } catch (e) {
    throw Exception(e.toString());
  }
 }

 static Future<String> deleteBatch(int id)async{
  try {
    await deleteFromServer(id);
    await deleteFromLocal(id);
    return "done";
  } catch (e) {
    throw Exception(e.toString());
  }
 }
 


}



