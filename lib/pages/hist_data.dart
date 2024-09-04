import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistData extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historical Data'),
      ),
      backgroundColor: Colors.blue.shade100,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sensors').snapshots(),
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
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final serialNumber = index + 1;
              final timestamp = data['timestamp'] as Timestamp?;
              final dateTime = timestamp?.toDate();
              final formattedTime = dateTime != null
                  ? DateFormat.jm().format(dateTime)
                  : 'Unknown time';
              final dayName = dateTime != null
                  ? DateFormat.E().format(dateTime)
                  : 'Unknown day';
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.blue.shade200, // Blue shade color
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.black,
                    child: Text(
                      serialNumber.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    'Timestamp: $dayName, $formattedTime',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VRMS: ${data['VRMS']}'),
                      Text('IRMS: ${data['IRMS']}'),
                      Text('POWER: ${data['POWER']}'),
                      Text('KWH: ${data['KWH']}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
