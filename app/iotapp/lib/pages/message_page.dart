import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:iotapp/theme/message_provider.dart';
import 'package:provider/provider.dart';
import 'package:iotapp/pages/message_page_detail.dart';
import 'package:intl/intl.dart';

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<MessageProvider>().messages;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr("notification_title")),
      ),
      body: messages.isEmpty
          ? Center(
              child: Text(tr("no_notifications")),
            )
          : ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                // 👉 Tách và lấy giá trị mức khói
                String smokeLevel = "0";
                final khop = RegExp(r'Khói:\s*(\d+)');
                final match = khop.firstMatch(msg.content);
                if (match != null && match.groupCount >= 1) {
                  smokeLevel = match.group(1)!;
                }

                return ListTile(
                  leading: Icon(
                    msg.isRead
                        ? Icons.mark_email_read
                        : Icons.mark_email_unread,
                    color: msg.isRead ? Colors.grey : Color.fromARGB(255, 85, 6, 79),
                  ),
                  title: Text(
                    '${tr('smoke_level')}: $smokeLevel',
                    style: TextStyle(
                      fontWeight:
                          msg.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(msg.timestamp),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    context.read<MessageProvider>().markAsRead(msg.timestamp);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MessagePageDetail(message: msg.content),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
