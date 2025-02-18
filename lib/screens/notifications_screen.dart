import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting
import 'package:intl/date_symbol_data_local.dart'; // Import date symbol data

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting(
        'id_ID', null); // Initialize date formatting for Indonesian locale
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifikasi'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .orderBy('read')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Terjadi error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Tidak ada notifikasi."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot notificationDoc = snapshot.data!.docs[index];
              Map<String, dynamic> notificationData =
                  notificationDoc.data() as Map<String, dynamic>;

              String formattedDate = DateFormat('EEEE, d MMMM y', 'id_ID')
                  .format(notificationData['createdAt'].toDate());

              return ListTile(
                title: Text(notificationData['message']),
                subtitle: Text("Tanggal: $formattedDate"),
                trailing: IconButton(
                  icon: Icon(notificationData['read']
                      ? Icons.check_circle
                      : Icons.notifications),
                  color: notificationData['read'] ? Colors.green : Colors.red,
                  onPressed: null, // Disable the button
                ),
              );
            },
          );
        },
      ),
    );
  }
}
