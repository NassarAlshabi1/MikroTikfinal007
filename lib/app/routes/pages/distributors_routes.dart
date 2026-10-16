import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_routes.dart';
import 'package:mikronet/features/distributors/controllers/distributor_form_controller.dart';
import 'package:mikronet/features/distributors/controllers/distributor_statement_controller.dart';
import 'package:mikronet/features/distributors/controllers/distributors_list_controller.dart';
import 'package:mikronet/features/distributors/models/distributor_model.dart';
import 'package:mikronet/features/distributors/views/distributor_form_page.dart';
import 'package:mikronet/features/distributors/views/distributor_statement_page.dart';
import 'package:mikronet/features/distributors/views/distributors_list_page.dart';

class DistributorsRoutes {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.distributors,
      page: () => const DistributorsListPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => DistributorsListController())),
    ),
    GetPage(
      name: AppRoutes.distributorForm,
      page: () => const DistributorFormPage(),
      binding: BindingsBuilder(() => Get.lazyPut(
        () => DistributorFormController(
          Get.arguments is DistributorModel ? Get.arguments as DistributorModel : null,
        ),
      )),
    ),
    GetPage(
      name: AppRoutes.distributorStatement,
      page: () => const DistributorStatementPage(),
      binding: BindingsBuilder(() => Get.lazyPut(
        () => DistributorStatementController(Get.arguments as DistributorModel),
      )),
    ),
  ];
}
