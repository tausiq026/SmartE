import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CheckUsage extends StatefulWidget {
  @override
  _CheckUsageState createState() => _CheckUsageState();
}

class _CheckUsageState extends State<CheckUsage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool isNotificationSent = false;

  @override
  void initState() {
    super.initState();
    final initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    checkUsageAndSendNotification();
  }

  Future<void> checkUsageAndSendNotification() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final QuerySnapshot snapshot = await firestore.collection('sensors').get();

    double totalUsage = 0;
    snapshot.docs.forEach((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final kwh = data['KWH'] != null
          ? double.tryParse(data['KWH'].toString()) ?? 0.0
          : 0.0;
      totalUsage += kwh;
    });

    if (totalUsage < 40 && !isNotificationSent) {
      sendNotification('High Electricity Usage',
          'Your today\'s consumption is high. Please reduce your electricity usage.');
      setState(() {
        isNotificationSent = true;
      });
    }
  }

  Future<void> sendNotification(String title, String body) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('usage_notification', 'Usage Notification',
            importance: Importance.high, priority: Priority.high);
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'Check your electricity usage.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check Usage'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[100]!, Colors.blue[900]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: EdgeInsets.all(16),
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('sensors').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Text('No data available.'),
                );
              }

              // Calculate total usage
              double totalUsage = 0;

              List<Widget> usageWidgets =
                  []; // List to store widgets for displaying usage details

              // Create data boxes
              for (int i = 0; i < docs.length; i += 2) {
                // For every two documents, create a row
                List<Widget> rowWidgets = [];

                for (int j = i; j < i + 2 && j < docs.length; j++) {
                  final data = docs[j].data() as Map<String, dynamic>;
                  final kwh = data['KWH'] != null
                      ? double.tryParse(data['KWH'].toString()) ?? 0.0
                      : 0.0;
                  totalUsage += kwh;

                  // Add the data box to the row
                  rowWidgets.add(
                    Expanded(
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[200],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reading ${j + 1}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'kWh: ${kwh.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Add the row to the list of widgets
                usageWidgets.add(
                  Row(
                    children: rowWidgets,
                  ),
                );
              }

              // Check if totalUsage is greater than 40
              if (totalUsage > 40 && !isNotificationSent) {
                sendNotification('High Electricity Usage',
                    'Your today\'s consumption is high. Please reduce your electricity usage.');
                setState(() {
                  isNotificationSent = true;
                });
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Usage Today:',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${totalUsage.toStringAsFixed(6)} kWh',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.green.shade900,
                    ),
                  ),
                  SizedBox(height: 20),
                  if (isNotificationSent)
                    Text(
                      'Your daily 40 units limit has exceeded',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  SizedBox(height: 20),
                  Column(
                    children: usageWidgets,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
