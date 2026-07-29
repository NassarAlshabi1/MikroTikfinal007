// lib/network_map_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'snackbar_helpers.dart';
import 'package:graphview/GraphView.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'mikrotik_connector.dart';

import 'theme/app_theme.dart';
enum DeviceStatus { unknown, online, offline }

class DeviceNode {
  String id;
  String name;
  String ip;
  DeviceStatus status;
  List<DeviceNode> children;
  double? dx;
  double? dy;

  DeviceNode({
    required this.id,
    required this.name,
    required this.ip,
    this.status = DeviceStatus.unknown,
    List<DeviceNode>? children,
    this.dx,
    this.dy,
  }) : children = children ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ip': ip,
        'children': [for (final c in children) c.toJson()],
        'dx': dx,
        'dy': dy,
      };

  factory DeviceNode.fromJson(Map<String, dynamic> json) => DeviceNode(
        id: json['id'],
        name: json['name'],
        ip: json['ip'],
        children: [
          for (final childJson in json['children'] as List<dynamic>)
            DeviceNode.fromJson(childJson as Map<String, dynamic>),
        ],
        dx: json['dx'],
        dy: json['dy'],
      );
}

class ManualPositioningSugiyamaAlgorithm extends SugiyamaAlgorithm {
  ManualPositioningSugiyamaAlgorithm(super.configuration);

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    final size = super.run(graph, shiftX, shiftY);

    if (graph == null) {
      return size;
    }

    for (var node in graph.nodes) {
      final deviceNode = node.key!.value as DeviceNode;
      if (deviceNode.dx != null && deviceNode.dy != null) {
        node.position = Offset(deviceNode.dx!, deviceNode.dy!);
      } else {
        deviceNode.dx = node.x;
        deviceNode.dy = node.y;
      }
    }
    
    return size;
  }
}


class NetworkMapScreen extends StatefulWidget {
  const NetworkMapScreen({super.key});

  @override
  State<NetworkMapScreen> createState() => _NetworkMapScreenState();
}

class _NetworkMapScreenState extends State<NetworkMapScreen> {
  final Graph _graph = Graph();
  final SugiyamaConfiguration _builder = SugiyamaConfiguration();
  late final ManualPositioningSugiyamaAlgorithm _algorithm;
  final TransformationController _transformationController = TransformationController();
  late final Paint _edgePaint;
  DeviceNode? _rootNode;
  bool _isLoading = true;
  bool _isCheckingStatus = false;
  bool _isEditMode = false;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _edgePaint = Paint()
      ..color = Theme.of(context).appColors.muted
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    _builder
      ..bendPointShape = CurvedBendPointShape(curveLength: 20)
      ..nodeSeparation = 80
      ..levelSeparation = 100
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

    _algorithm = ManualPositioningSugiyamaAlgorithm(_builder);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }
  
  @override
  void dispose() {
    _transformationController.dispose();
    _graph.nodes.clear();
    _graph.edges.clear();
    // Paint لا يملك dispose() في Flutter — لا مورد يحتاج تحرير
    super.dispose();
  }

  Future<void> _loadInitialData() async {
     if (!mounted) return;
     setState(() { _isLoading = true; });
     final prefs = await SharedPreferences.getInstance();
     
    final mapJson = prefs.getString('network_map_json');
    if (mapJson != null) {
      _rootNode = DeviceNode.fromJson(jsonDecode(mapJson));
    } else {
      _isEditMode = true;
    }
    _rebuildGraph();
    if (!mounted) return;
    setState(() { _isLoading = false; });
  }

  Future<void> _saveMap() async {
    if (_rootNode == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('network_map_json');
      if(mounted) {
        showSuccessSnackBar(context, 'تم حذف الخريطة.');
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final mapJson = jsonEncode(_rootNode!.toJson());
    await prefs.setString('network_map_json', mapJson);
    if(mounted) {
      showSuccessSnackBar(context, 'تم حفظ الخريطة بنجاح.');
    }
  }
  
  void _rebuildGraph() {
    _graph.nodes.clear();
    _graph.edges.clear();
    if (_rootNode != null) {
      _addNodeAndChildrenToGraph(_rootNode!);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkAllStatuses() async {
    if (_rootNode == null) {
      showErrorSnackBar(context, 'الخريطة فارغة، قم بإضافة جهاز رئيسي أولاً.');
      return;
    }
    await _performCheck(_rootNode!);
  }

  Future<void> _checkSingleBranch(DeviceNode branchRoot) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('جاري فحص "${branchRoot.name}" وفروعه...')),
    );
    await _performCheck(branchRoot);
  }

  Future<void> _checkSpecificDeviceStatus(DeviceNode deviceNode) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('جاري فحص "${deviceNode.name}"...')),
    );
    await _performCheck(deviceNode);
  }
  
  Future<void> _performCheck(DeviceNode nodeToCheck) async {
    if (!mounted) return;
    setState(() { _isCheckingStatus = true; });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      Set<String> onlineIps = {};
      
      final neighborResponse = await client.talk(['/ip/neighbor/print']);
      
      for (var neighbor in neighborResponse) {
        if (neighbor['address'] != null) {
          onlineIps.add(neighbor['address']!);
        }
      }
      
      _updateNodeStatusFromNeighbors(nodeToCheck, onlineIps);

    } on MikrotikCredentialsMissingException catch (e) {
      if(mounted) {
        showErrorSnackBar(context, 'خطأ في بيانات الدخول: ${e.message}');
      }
    } on MikrotikConnectionException catch (e) {
      if(mounted) {
        showErrorSnackBar(context, 'خطأ في الاتصال: ${e.message}');
      }
    } on TimeoutException {
       if(mounted) {
        showErrorSnackBar(context, 'انتهت مهلة الفحص. قد تكون الشبكة بطيئة أو بعض الأجهزة لا تستجيب.');
      }
    } catch (e) {
      if(mounted) {
        showErrorSnackBar(context, 'حدث خطأ أثناء الفحص.');
      }
    } finally {
      // لا نغلق الاتصال - تجمع الاتصالات يديره تلقائياً
      if(mounted) {
        _rebuildGraph();
        setState(() { _isCheckingStatus = false; });
      }
    }
  }

  void _updateNodeStatusFromNeighbors(DeviceNode node, Set<String> onlineIps) {
    if (onlineIps.contains(node.ip)) {
      node.status = DeviceStatus.online;
    } else {
      node.status = DeviceStatus.offline;
    }
    
    for (var child in node.children) {
      _updateNodeStatusFromNeighbors(child, onlineIps);
    }
  }

  void _addNodeAndChildrenToGraph(DeviceNode node) {
    final graphNode = Node.Id(node);
    _graph.addNode(graphNode);
    for (var child in node.children) {
      final childGraphNode = Node.Id(child);
      _graph.addEdge(graphNode, childGraphNode);
      _addNodeAndChildrenToGraph(child);
    }
  }

  Future<void> _showAddEditDialog({DeviceNode? existingNode, DeviceNode? parentNode}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingNode?.name);
    final ipController = TextEditingController(text: existingNode?.ip);
    final isEditing = existingNode != null;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'تعديل جهاز' : 'إضافة جهاز جديد'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'اسم الجهاز (مثال: صحن رئيسي)'),
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Theme.of(context).colorScheme.onSurface),
                validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
              ),
              TextFormField(
                controller: ipController,
                decoration: InputDecoration(labelText: 'عنوان IP'),
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Theme.of(context).colorScheme.onSurface),
                validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                if (isEditing) {
                  existingNode.name = nameController.text;
                  existingNode.ip = ipController.text;
                } else {
                  final newNode = DeviceNode(
                    id: _uuid.v4(),
                    name: nameController.text,
                    ip: ipController.text,
                  );
                  if (parentNode != null) {
                    parentNode.children.add(newNode);
                  } else {
                    _rootNode = newNode;
                  }
                }
                _rebuildGraph();
                Navigator.of(context).pop();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _handleDelete(DeviceNode nodeToDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${nodeToDelete.name}" وكل الأجهزة المتفرعة منه؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              if (_rootNode?.id == nodeToDelete.id) {
                _rootNode = null;
              } else {
                _findAndRemoveNode(_rootNode, nodeToDelete.id);
              }
              _rebuildGraph();
              Navigator.of(context).pop();
            },
            child: Text('حذف', style: TextStyle(color: Theme.of(context).appColors.error)),
          ),
        ],
      ),
    );
  }
  
  bool _findAndRemoveNode(DeviceNode? currentNode, String targetId) {
    if (currentNode == null) return false;
    for (int i = 0; i < currentNode.children.length; i++) {
        if (currentNode.children[i].id == targetId) {
            currentNode.children.removeAt(i);
            return true;
        }
        if (_findAndRemoveNode(currentNode.children[i], targetId)) {
            return true;
        }
    }
    return false;
  }

  Future<void> _exportMap() async {
    if (_rootNode == null) {
      showErrorSnackBar(context, 'لا توجد خريطة لتصديرها.');
      return;
    }
    
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'network_map_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      
      final mapJson = jsonEncode(_rootNode!.toJson());
      await file.writeAsString(mapJson);

      final xFile = XFile(file.path);
      await SharePlus.instance.share(ShareParams(
        files: [xFile],
        text: 'ملف النسخ الاحتياطي لخريطة الشبكة',
      ));

    } catch (e) {
      // ignore: use_build_context_synchronously
      showErrorSnackBar(context, 'فشلت عملية التصدير.');
    }
  }

  Future<void> _importMap() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        
        // ignore: use_build_context_synchronously
        final confirm = await showDialog<bool>(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الاستيراد'),
            content: const Text('سيتم استبدال الخريطة الحالية بالخريطة الجديدة. هل أنت متأكد؟'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('تأكيد', style: TextStyle(color: Theme.of(context).appColors.warning))),
            ],
          ),
        );
        
        if (confirm == true) {
          if (!mounted) return;
          setState(() {
            _rootNode = DeviceNode.fromJson(jsonDecode(content));
          });
          _rebuildGraph();
          await _saveMap();
        }
      // ignore: use_build_context_synchronously
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      showErrorSnackBar(context, 'فشل الاستيراد: ملف غير صالح أو خطأ في القراءة.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'تعديل خريطة الشبكة' : 'خريطة الشبكة'),
        backgroundColor: _isEditMode ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).cardColor,
        actions: [
           PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                _exportMap();
              } else if (value == 'import') {
                _importMap();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'export',
                child: ListTile(leading: Icon(Icons.file_upload), title: Text('تصدير / مشاركة', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold))),
              ),
              PopupMenuItem<String>(
                value: 'import',
                child: ListTile(leading: Icon(Icons.file_download), title: Text('استيراد خريطة', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold))),
              ),
            ],
          ),
          if (!_isEditMode)
            IconButton(
              icon: Icon(Icons.sync),
              tooltip: 'فحص حالة الأجهزة',
              onPressed: _isCheckingStatus ? null : _checkAllStatuses,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          TextButton.icon(
            icon: Icon(_isEditMode ? Icons.check_circle : Icons.edit),
            label: Text(_isEditMode ? 'حفظ' : 'تعديل'),
            onPressed: () {
              if (_isEditMode) {
                _saveMap();
              }
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _rootNode == null ? _buildEmptyView() : _buildGraphView(),
                if (_isCheckingStatus) _buildLoadingOverlay(),
              ],
            ),
    );
  }

  Widget _buildGraphView() {
    return RepaintBoundary(
      child: InteractiveViewer(
        transformationController: _transformationController,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.01, 
        maxScale: 5.0,
        child: GraphView(
          graph: _graph,
          algorithm: _algorithm,
          paint: _edgePaint,
          builder: (Node node) {
            final deviceNode = node.key!.value as DeviceNode;
            return _buildNodeWidget(deviceNode);
          },
        ),
      ),
    );
  }
  
  Widget _buildNodeWidget(DeviceNode deviceNode) {
    Color nodeColor;
    switch (deviceNode.status) {
      case DeviceStatus.online:
        nodeColor = Theme.of(context).appColors.success;
        break;
      case DeviceStatus.offline:
        nodeColor = Theme.of(context).appColors.muted;
        break;
      default:
        nodeColor = Theme.of(context).appColors.info;
    }

    final nodeContent = Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: nodeColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).hintColor, width: 1),
        boxShadow: [
          BoxShadow(color: nodeColor.withValues(alpha: 0.5), blurRadius: 8)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(deviceNode.name, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  Text(deviceNode.ip, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
                  if (!_isEditMode && deviceNode.status == DeviceStatus.offline)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.refresh, size: 18),
                        label: Text('فحص', style: TextStyle(fontSize: 12)),
                        onPressed: () => _checkSpecificDeviceStatus(deviceNode),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).appColors.warning,
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          minimumSize: Size.zero, // Set this
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // and this
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap, // and this
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        if (!_isEditMode && !_isCheckingStatus) {
          _checkSingleBranch(deviceNode);
        }
      },
      onLongPress: () {
        if (_isEditMode) {
          _showEditMenu(context, deviceNode);
        }
      },
      onPanUpdate: _isEditMode ? (details) {
        final currentScale = _transformationController.value.getMaxScaleOnAxis();
        setState(() {
          deviceNode.dx = (deviceNode.dx ?? 0) + (details.delta.dx / currentScale);
          deviceNode.dy = (deviceNode.dy ?? 0) + (details.delta.dy / currentScale);
        });
      } : null,
      child: nodeContent,
    );
  }

  void _showEditMenu(BuildContext context, DeviceNode deviceNode) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox widgetBox = context.findRenderObject() as RenderBox;
    final offset = widgetBox.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu(
      context: context, 
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + widgetBox.size.height,
        offset.dx + widgetBox.size.width,
        offset.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'add',
          child: ListTile(
            leading: Icon(Icons.add_circle_outline),
            title: Text('إضافة جهاز فرعي', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('تعديل الجهاز', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Theme.of(context).appColors.error),
            title: Text('حذف الجهاز', style: TextStyle(color: Theme.of(context).appColors.error, fontWeight: FontWeight.bold)),
          ),
        ),
      ]
    ).then((value) {
        if (value == 'add') {
           _showAddEditDialog(parentNode: deviceNode);
        } else if (value == 'edit') {
           _showAddEditDialog(existingNode: deviceNode);
        } else if (value == 'delete') {
           _handleDelete(deviceNode);
        }
    });
  }


  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_outlined, size: 80, color: Theme.of(context).appColors.muted),
          SizedBox(height: 16),
          Text('الخريطة فارغة', style: TextStyle(fontSize: 22)),
          SizedBox(height: 8),
          Text('ابدأ ببناء خريطة شبكتك الآن', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add),
            label: const Text('أضف أول جهاز (الجذر)'),
          )
        ],
      ),
    );
  }
  
  Widget _buildLoadingOverlay() {
    return Container(
      color: const Color(0xB3000000),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('جاري فحص حالة الأجهزة...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}