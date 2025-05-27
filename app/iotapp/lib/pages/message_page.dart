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
        title: Text(tr("notification_title")), // Dùng tr() cho tiêu đề
      ),
      body:
          messages.isEmpty
              ? Center(
                child: Text(tr("no_notifications")),
              ) // Dùng tr() cho thông báo không có dữ liệu
              : ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  // Cắt nội dung để lấy giá trị số cho nhiệt độ và khói
                  final contentParts = msg.content.split(
                    ',',
                  ); // Tách nội dung theo dấu phẩy
                  //String temperature_number = "0";
                  String smokeLevel_number = "0";

                  // Kiểm tra nếu phần đầu tiên là Nhiệt độ và lấy số
                  // if (contentParts.isNotEmpty &&
                  //     contentParts[0].contains('Nhiệt độ')) {
                  //   final tempParts = contentParts[0].split(':');
                  //   temperature_number =
                  //       tempParts.length > 1 ? tempParts[1].trim() : "0";
                  // }

                  // Kiểm tra nếu phần thứ hai là Khói và lấy số
                  if (contentParts.length > 1 &&
                      contentParts[1].contains('Khói')) {
                    final smokeParts = contentParts[1].split(':');
                    smokeLevel_number =
                        smokeParts.length > 1 ? smokeParts[1].trim() : "0";
                  }
                  return ListTile(
                    leading: Icon(
                      msg.isRead
                          ? Icons.mark_email_read
                          : Icons.mark_email_unread,
                      color: msg.isRead ? Colors.grey : Colors.blue,
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text(
                        //   '${tr('temperature')}: $temperature_number',
                        //   maxLines: 1,
                        //   overflow: TextOverflow.ellipsis,
                        //   style: TextStyle(
                        //     fontWeight:
                        //         msg.isRead
                        //             ? FontWeight.normal
                        //             : FontWeight.bold,
                        //   ),
                        // ),
                        Text(
                          '${tr('smoke_level')}: $smokeLevel_number',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                msg.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                          ),
                        ),
                      ],
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
                          builder:
                              (_) => MessagePageDetail(message: msg.content),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
