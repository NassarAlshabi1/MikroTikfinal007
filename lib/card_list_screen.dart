import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'mqtt_service.dart';
import 'providers/mqtt_service_provider.dart';
import 'snackbar_helpers.dart';

class CardListScreen extends ConsumerWidget {
  const CardListScreen({
    super.key,
    required this.cardList,
    this.isNetworkLinked = false,
    this.linkedData = const {},
  });

  final List<Map<String, String>> cardList;
  final bool isNetworkLinked;
  final Map<String, dynamic> linkedData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mqttService = ref.read(mqttClientProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الكروت المضافة حديثاً')),
      body: cardList.isEmpty
          ? const _EmptyCardsState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              itemCount: cardList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _CardCredentialTile(
                number: index + 1,
                card: cardList[index],
              ),
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: cardList.isEmpty ? null : () => _copyAll(context),
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('نسخ الكل'),
              ),
              FilledButton.icon(
                onPressed: cardList.isEmpty ? null : () => _shareAll(context),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('مشاركة'),
              ),
              if (isNetworkLinked)
                FilledButton.tonalIcon(
                  onPressed: cardList.isEmpty ? null : () => _chooseQahtaniUnit(context, mqttService),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('إرسال للشبكة'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String get _cardsAsText => cardList
      .map((card) => 'اسم المستخدم: ${card['username'] ?? ''}\nكلمة المرور: ${card['password'] ?? ''}')
      .join('\n\n');

  Future<void> _copyAll(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _cardsAsText));
    if (context.mounted) showSuccessSnackBar(context, 'تم نسخ جميع الكروت.');
  }

  Future<void> _shareAll(BuildContext context) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/mikrotik_cards.txt');
    await file.writeAsString(_cardsAsText);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'كروت MikroTik المضافة حديثاً'),
    );
  }

  Future<void> _chooseQahtaniUnit(BuildContext context, MqttService mqttService) async {
    final units = (linkedData['network_details']?['units'] as List?)
            ?.whereType<Map>()
            .cast<Map<dynamic, dynamic>>()
            .toList() ??
        const <Map<dynamic, dynamic>>[];
    if (units.isEmpty) {
      showErrorSnackBar(context, 'لا توجد وحدات متاحة للإرسال.');
      return;
    }

    final selectedUnitId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('اختيار جهة الإرسال'),
        content: DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'الوحدة'),
          items: units
              .map(
                (unit) => DropdownMenuItem<String>(
                  value: unit['id']?.toString(),
                  child: Text(unit['name']?.toString() ?? 'وحدة غير مسماة'),
                ),
              )
              .toList(),
          onChanged: (value) => Navigator.of(dialogContext).pop(value),
        ),
      ),
    );
    if (selectedUnitId == null || !context.mounted) return;

    mqttService.publish({
      'command': 'add_cards',
      'unit_id': selectedUnitId,
      'cards': cardList,
    });
    showSuccessSnackBar(context, 'تمت جدولة إرسال الكروت إلى الوحدة المحددة.');
  }
}

class _CardCredentialTile extends StatelessWidget {
  const _CardCredentialTile({required this.number, required this.card});

  final int number;
  final Map<String, String> card;

  @override
  Widget build(BuildContext context) {
    final username = card['username'] ?? '—';
    final password = card['password'] ?? '—';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
              foregroundColor: Theme.of(context).colorScheme.primary,
              child: Text('$number'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('كلمة المرور: $password', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              tooltip: 'نسخ الكرت',
              icon: const Icon(Icons.copy_outlined),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: 'username: $username\npassword: $password'));
                if (context.mounted) showSuccessSnackBar(context, 'تم نسخ الكرت.');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCardsState extends StatelessWidget {
  const _EmptyCardsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('لا توجد كروت لعرضها', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('أضف كروتاً جديدة لتظهر هنا وتصبح جاهزة للنسخ أو المشاركة.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
