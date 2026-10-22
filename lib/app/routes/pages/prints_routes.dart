import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_routes.dart';
import 'package:mikronet/features/prints/controllers/batches/batches_list_controller.dart';
import 'package:mikronet/features/prints/controllers/prints_unit_controller.dart';
import 'package:mikronet/features/prints/controllers/templates/add_template_controller.dart';
import 'package:mikronet/features/prints/controllers/templates/edit_template_controller.dart';
import 'package:mikronet/features/prints/controllers/templates/templates_list_controller.dart';
import 'package:mikronet/features/prints/views/batches/batches_list_page.dart';
import 'package:mikronet/features/prints/controllers/batches/add_batch_controller.dart';
import 'package:mikronet/features/prints/views/batches/add_batch_page.dart';
import 'package:mikronet/features/prints/views/prints_unit.dart';
import 'package:mikronet/features/prints/views/templates/add_template_page.dart';
import 'package:mikronet/features/prints/views/templates/edit_template_page.dart';
import 'package:mikronet/features/prints/views/templates/templates_list_page.dart';

class PrintsRoutes {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.print, 
      page: () => const PrintsUnitPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => PrintsUnitController())),
    ),
    GetPage(
      name: AppRoutes.batches, 
      page: () => const BatchesView(),
      binding: BindingsBuilder(() => Get.lazyPut(() => BatchesListController())),
    ),
    GetPage(
      name: AppRoutes.addBatch,
      page: () => AddBatchView(controller: Get.find<BatchesFormController>()),
      binding: BindingsBuilder(() => Get.lazyPut(() => BatchesFormController())),
    ),
    GetPage(
      name: AppRoutes.templates, 
      page: () => const TemplatesListPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => TemplatesListController())),
    ),
    GetPage(
      name: AppRoutes.addTemplate, 
      page: () => const AddTemplatePage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => AddTemplateController())),
    ),
    GetPage(
      name: AppRoutes.editTemplate, 
      page: () => const EditTemplatePage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => EditTemplateController(editedTemplate: Get.arguments))),
    ),
  ];
}
