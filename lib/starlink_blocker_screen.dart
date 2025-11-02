import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';
import 'mikrotik_connector.dart';

class StarlinkBlockerScreen extends StatefulWidget {
  const StarlinkBlockerScreen({super.key});

  @override
  State<StarlinkBlockerScreen> createState() => _StarlinkBlockerScreenState();
}

class _StarlinkBlockerScreenState extends State<StarlinkBlockerScreen> {
  bool _isLoading = true;
  bool _scriptExists = false;
  bool _firewallRuleActive = false;
  String _errorMessage = '';
  String? _scriptId;
  String? _firewallRuleId;
  bool _isProcessing = false;

  final String _blockScriptName = 'block-starlink';
  final String _unblockScriptName = 'unblock-starlink';
  final String _firewallComment = 'Block starlink';

  final String _blockScriptSource = '''
/ip firewall filter
add action=drop chain=forward comment="Block starlink" dst-address=192.168.100.1 dst-port=9201,80,9200,9005 protocol=tcp
''';

  final String _unblockScriptSource = '''
/ip firewall filter
:foreach rule in=[find where comment="Block starlink"] do={
  remove \$rule
}
''';

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      final scriptResponse = await client.talk(['/system/script/print']);
      _scriptExists = false;
      _scriptId = null;

      for (var script in scriptResponse) {
        final name = script['name']?.toString() ?? '';
        if (name == _blockScriptName || name == _unblockScriptName) {
          _scriptExists = true;
          break;
        }
      }

      final firewallResponse = await client.talk(['/ip/firewall/filter/print']);
      _firewallRuleActive = false;
      _firewallRuleId = null;

      for (var rule in firewallResponse) {
        final comment = rule['comment']?.toString() ?? '';
        if (comment == _firewallComment) {
          _firewallRuleId = rule['.id']?.toString();
          final disabled = rule['disabled']?.toString() ?? 'false';
          _firewallRuleActive = disabled != 'true';
          break;
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } on MikrotikCredentialsMissingException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ في بيانات الدخول: ${e.message}';
          _isLoading = false;
        });
      }
    } on MikrotikConnectionException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ في الاتصال: ${e.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ: ${e.toString()}';
          _isLoading = false;
        });
      }
    } finally {
      client?.close();
    }
  }

  Future<void> _createScripts() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      final existingScripts = await client.talk(['/system/script/print']);
      
      bool blockExists = false;
      bool unblockExists = false;
      
      for (var script in existingScripts) {
        final name = script['name']?.toString() ?? '';
        if (name == _blockScriptName) blockExists = true;
        if (name == _unblockScriptName) unblockExists = true;
      }

      if (!blockExists) {
        await client.talk([
          '/system/script/add',
          '=name=$_blockScriptName',
          '=source=$_blockScriptSource',
        ]);
      }

      if (!unblockExists) {
        await client.talk([
          '/system/script/add',
          '=name=$_unblockScriptName',
          '=source=$_unblockScriptSource',
        ]);
      }

      if (mounted) {
        setState(() {
          _scriptExists = true;
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء Scripts بنجاح في MikroTik'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء إنشاء Scripts: ${e.toString()}';
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إنشاء Scripts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      client?.close();
    }
  }

  Future<void> _toggleBlock(bool shouldBlock) async {
    if (!_scriptExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب إنشاء Scripts أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      if (shouldBlock) {
        await client.talk([
          '/system/script/run',
          '=$_blockScriptName',
        ]);
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        final firewallResponse = await client.talk(['/ip/firewall/filter/print']);
        for (var rule in firewallResponse) {
          final comment = rule['comment']?.toString() ?? '';
          if (comment == _firewallComment) {
            _firewallRuleId = rule['.id']?.toString();
            _firewallRuleActive = true;
            break;
          }
        }
      } else {
        await client.talk([
          '/system/script/run',
          '=$_unblockScriptName',
        ]);
        
        _firewallRuleActive = false;
        _firewallRuleId = null;
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shouldBlock 
              ? 'تم تفعيل حظر Starlink بنجاح' 
              : 'تم إلغاء حظر Starlink بنجاح'),
            backgroundColor: shouldBlock ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ: ${e.toString()}';
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تنفيذ Script: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      client?.close();
      _checkStatus();
    }
  }

  Future<void> _deleteScripts() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف Scripts حظر Starlink نهائياً من MikroTik؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      final scripts = await client.talk(['/system/script/print']);
      
      for (var script in scripts) {
        final name = script['name']?.toString() ?? '';
        if (name == _blockScriptName || name == _unblockScriptName) {
          final id = script['.id']?.toString();
          if (id != null) {
            await client.talk([
              '/system/script/remove',
              '=.id=$id',
            ]);
          }
        }
      }

      if (_firewallRuleActive && _firewallRuleId != null) {
        await client.talk([
          '/ip/firewall/filter/remove',
          '=.id=$_firewallRuleId',
        ]);
      }

      if (mounted) {
        setState(() {
          _scriptExists = false;
          _firewallRuleActive = false;
          _firewallRuleId = null;
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف Scripts والقواعد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء الحذف: ${e.toString()}';
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حذف Scripts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      client?.close();
    }
  }

  Future<void> _viewScripts() async {
    setState(() => _isProcessing = true);
    
    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      final scripts = await client.talk(['/system/script/print']);
      
      String blockSource = 'غير موجود';
      String unblockSource = 'غير موجود';
      
      for (var script in scripts) {
        final name = script['name']?.toString() ?? '';
        final source = script['source']?.toString() ?? '';
        if (name == _blockScriptName) blockSource = source;
        if (name == _unblockScriptName) unblockSource = source;
      }
      
      if (mounted) {
        setState(() => _isProcessing = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('محتوى Scripts'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Script الحظر ($_blockScriptName):',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      blockSource,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Script إلغاء الحظر ($_unblockScriptName):',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      unblockSource,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل قراءة Scripts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      client?.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حظر تطبيق Starlink'),
        backgroundColor: Theme.of(context).cardColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading || _isProcessing ? null : _checkStatus,
            tooltip: 'تحديث',
          ),
          if (_scriptExists)
            IconButton(
              icon: const Icon(Icons.code),
              onPressed: _isProcessing ? null : _viewScripts,
              tooltip: 'عرض Scripts',
            ),
          if (_scriptExists)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isProcessing ? null : _deleteScripts,
              tooltip: 'حذف Scripts',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'جاري فحص الحالة...',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),
          if (!_scriptExists) ...[
            _buildCreateScriptsCard(),
            const SizedBox(height: 20),
          ],
          if (_scriptExists) ...[
            _buildToggleCard(),
            const SizedBox(height: 20),
            _buildStatusCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[400]!.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: Colors.blue[400], size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'معلومات الحظر',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'هذه الميزة تقوم بإنشاء Scripts في MikroTik للتحكم في حظر تطبيق Starlink:',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.code, color: Colors.green[400], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Script الحظر: يضيف قاعدة Firewall',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.code, color: Colors.orange[400], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Script الإلغاء: يحذف قاعدة Firewall',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.block, color: Colors.red[400], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'المنافذ المحظورة: 9201, 80, 9200, 9005',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateScriptsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.orange[900]!.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 64,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Scripts غير موجودة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يجب إنشاء Scripts في MikroTik أولاً قبل استخدام الميزة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _createScripts,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add),
              label: Text(_isProcessing ? 'جاري الإنشاء...' : 'إنشاء Scripts'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[400],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _firewallRuleActive
          ? Colors.red[900]!.withOpacity(0.3)
          : Colors.green[900]!.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              _firewallRuleActive ? Icons.block : Icons.check_circle_outline,
              size: 64,
              color: _firewallRuleActive ? Colors.red[400] : Colors.green[400],
            ),
            const SizedBox(height: 16),
            Text(
              _firewallRuleActive ? 'تطبيق Starlink محظور' : 'تطبيق Starlink مفعّل',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _firewallRuleActive
                  ? 'المستخدمون لا يمكنهم الوصول لتطبيق Starlink'
                  : 'المستخدمون يمكنهم الوصول لتطبيق Starlink',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isProcessing || _firewallRuleActive) ? null : () => _toggleBlock(true),
                    icon: const Icon(Icons.block),
                    label: const Text('تفعيل الحظر'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isProcessing || !_firewallRuleActive) ? null : () => _toggleBlock(false),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('إلغاء الحظر'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[400],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              const Text('جاري التنفيذ...'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[400]!.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.settings, color: Colors.purple[400], size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'الحالة الحالية',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildStatusRow(
              'Scripts موجودة:',
              _scriptExists ? 'نعم' : 'لا',
              statusColor: _scriptExists ? Colors.green[400] : Colors.red[400],
            ),
            _buildStatusRow(
              'قاعدة Firewall نشطة:',
              _firewallRuleActive ? 'نعم' : 'لا',
              statusColor: _firewallRuleActive ? Colors.red[400] : Colors.green[400],
            ),
            if (_firewallRuleId != null)
              _buildStatusRow('Firewall Rule ID:', _firewallRuleId!),
            _buildStatusRow(
              'حالة الحظر:',
              _firewallRuleActive ? 'محظور' : 'مفعّل',
              statusColor: _firewallRuleActive ? Colors.red[400] : Colors.green[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: statusColor ?? Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
