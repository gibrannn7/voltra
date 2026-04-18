import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Colors.black, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: provider.isLoading && provider.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : provider.notifications.isEmpty
              ? const Center(
                  child: Text('Belum ada notifikasi.', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B))),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.notifications.length,
                  itemBuilder: (context, index) {
                    final notif = provider.notifications[index];
                    return GestureDetector(
                      onTap: () {
                        if (notif.isRead == false) { // atau notif.isRead == 0 tergantung model Anda
                          context.read<NotificationProvider>().markAsRead(notif.id);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: notif.isRead == false ? const Color(0xFFEFF6FF) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif.title,
                              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notif.message,
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}