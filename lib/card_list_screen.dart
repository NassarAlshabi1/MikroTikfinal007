// lib/card_list_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'mqtt_service.dart';
import 'snackbar_helpers.dart';
import 'providers/mqtt_service_provider.dart';

class CardListScreen extends ConsumerWidget {
  final List<Map<String, String>> cardList;
  final bool isNetworkLinked;
  final Map<String, dynamic> linkedData;

  const CardListScreen({
    super.key,
    required this.cardList,
    this.isNetworkLinked = false,
    this.linkedData = const {},
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mqttService = ref.watch(mqttServiceProvider);
    final cardListData = widget.cardList;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('الكروت المضافة حديثاً'),
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: cardListData.length,
        itemBuilder: (context, index) {
          final card = cardListData[index];
          final displayText = 'username: ${card['username']}, password: ${card['password']}';
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              dense: true,
              title: Text(displayText),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: displayText));
                  showSuccessSnackBar(context, 'تم نسخ الكرت!');
                },
                tooltip: 'نسخ',
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).cardColor,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final fileContent = cardListData.map((card) => 'username: ${card['username']}, password: ${card['password']}').join('\n');
                  final directory = await getApplicationDocumentsDirectory();
                  final filePath = '${directory.path}/shared_cards.txt';
                  final file = File(filePath);
                  await file.writeAsString(fileContent);
                  Share.shareXFiles([XFile(filePath)], text: 'الكروت المضافة حديثاً');
                },
                icon: const Icon(Icons.copy_all),
                label: const Text('نسخ الكل'),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final fileContent = cardListData.map((card) => 'username: ${card['username']}, password: ${card['password']}').join('\n');
                  final directory = await getApplicationDocumentsDirectory();
                  final filePath = '${directory.path}/shared_cards.txt';
                  final file = File(filePath);
                  await file.writeAsString(fileContent);
                  Share.shareXFiles([XFile(filePath)], text: 'الكروت المضافة حديثاً');
                },
                icon: const Icon(Icons.share),
                label: const Text('مشاركة الكل'),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              ),
            ),
            if (isNetworkLinked) ...[
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    String? selectedUnitId;
                    final units = (linkedData['network_details']?['units'] as List?) ?? [];
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('اختر فئة م/نصار الشعبي'),
                          content: DropdownButtonFormField<String>(
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            dropdownColor: Colors.white,
                            hint: const Text('اختر الفئة', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                            items: units.map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit['id'],
                                child: Text(unit['name'], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            onChanged: (value) => selectedUnitId = value,
                            validator: (value) => value == null ? 'الرجاء اختيار فئة' : null,
                          ),
                          actions: [
                            TextButton(child: const Text('إلغاء'), onPressed: () => Navigator.of(context).pop()),
                            ElevatedButton(
                              child: const Text('تأكيد وإضافة'),
                              onPressed: () {
                                if (selectedUnitId != null) {
                                  Navigator.of(context).pop();
                                  _sendCardsToQahtani(selectedUnitId);
                                }
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.add_to_queue),
                  label: const Text('إضافة للقحطاني'),
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
