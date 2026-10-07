import 'package:get/get.dart';
import '../../dialog_helper.dart';
import '../../../api/cards_api.dart';
import '../../../models/cards_model.dart';
import '../../../models/response.dart';

class CardSessionsController extends GetxController {
  final String cardCode;

  CardSessionsController({required this.cardCode});

  RxBool isLoading = true.obs;
  RxList<CardSessionModel> sessionsList = <CardSessionModel>[].obs;
  int _requestCounter = 0;

  @override
  void onInit() {
    super.onInit();
    _fetchSessions(); 
  }

  void goBack() {
    Get.back();
  }

  Future<void> _fetchSessions() async {
    final currentId = ++_requestCounter;
    isLoading.value = true;
    
    try {
      AppResponse<List<CardSessionModel>> response = await CardsApi.getCardSessions(cardCode);

      if (currentId != _requestCounter) return;

      if (response.status && response.data != null) {
        sessionsList.assignAll(response.data!);
      } else {
        showMsgDialog(message: response.message);
      }
    } catch (e) {
      if (currentId == _requestCounter) {
        showMsgDialog(message: "Error fetching sessions: $e");
      }
    } finally {
      if (currentId == _requestCounter) {
        isLoading.value = false;
      }
    }
  }
}

