class DNSCacheModel {
  final String id;
  final String name;
  final String type;
  final String data;
  final String ttl;
  
  
  DNSCacheModel({
    required this.id,
    required this.name,
    required this.type,
    required this.data,
    required this.ttl,

  });

  static DNSCacheModel fromMikrotik(Map dns){
    
    return DNSCacheModel(
      id: dns[".id"]??"",
      name: dns["name"]??"", 
      type: dns["type"]??"", 
      data: dns["data"]??"", 
      ttl: dns["ttl"]??"", 
      
    );
  }

  Map toMap(){
    return {
      "id":id,
      "name":name,
      "type":type,
      "data":data,
      "ttl":ttl,    
    };
  }
}

class BlockedSiteModel {
  final String id;
  final String name;
  final String blockType;  // نوع الحظر: 'IP', 'Domain', 'Content'
  final String blockValue; // القيمة: (مثلاً 192.168.1.5 أو google.com أو كلمة معينة)
  final String interface;
  final String filterId;
  final String linkId;
  final String layer7Id;


  BlockedSiteModel({
    required this.id,
    required this.name,
    required this.blockType,
    required this.blockValue,
    required this.interface,
    required this.filterId,
    required this.linkId,
    required this.layer7Id,

  });

  // دالة لتحويل بيانات المايكروتك إلى المودل
  // نمرر لها Map القادم من المايكروتك، بالإضافة لنوع الحظر لنعرف من أي حقل نسحب البيانات
  static BlockedSiteModel fromMikrotik(Map data) {
    
    return BlockedSiteModel(
      id: data["id"] ?? "",
      name: data["name"] ?? "Unknown",
      blockType: data["type"] == "ssl" ? "Domain" : "Content",
      blockValue: data["value"],
      interface: data["interface"],
      filterId: data["filter-id"] ?? "",
      linkId: data["link-id"] ??"",
      layer7Id: data["layer7-id"]?? ""
    );
  }

}