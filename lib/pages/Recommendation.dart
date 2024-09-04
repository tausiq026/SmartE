import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Recommendation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recommendation'),
        backgroundColor: Colors.blue.shade400,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade200, Colors.blue.shade400, Colors.white],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
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

            // Calculate hourly usage
            final hourlyUsage = Map<int, double>.fromIterable(
              List.generate(24, (index) => index),
              key: (item) => item,
              value: (item) => 0.0,
            );
            docs.forEach((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp?;
              final dateTime = timestamp?.toDate();
              if (dateTime != null) {
                final hour = dateTime.hour;
                final kwh = (data['KWH'] as num?)?.toDouble() ?? 0.0;
                if (hourlyUsage.containsKey(hour)) {
                  hourlyUsage[hour] = hourlyUsage[hour]! + kwh;
                }
              }
            });

            // Find peak hour
            final peakHour = hourlyUsage.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;
            final peakHourStr = DateFormat.jm()
                .format(DateTime(0).add(Duration(hours: peakHour)));

            // Generate chart data
            final chartData = hourlyUsage.entries
                .map((entry) => GraphData(entry.key.toString(), entry.value))
                .toList();

            String recommendation = '';
            if (hourlyUsage[peakHour]! > 40) {
              recommendation =
                  'We recommend you to lower your electricity usage during the peak hour ($peakHourStr) for the next day.';
            } else {
              recommendation =
                  'Your electricity usage is within normal limits. Keep up the good work!';
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Recommendation:',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Peak Hour of Usage:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Around $peakHourStr',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Recommendation:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              recommendation,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: SfCartesianChart(
                      primaryXAxis: CategoryAxis(
                        labelPlacement: LabelPlacement.betweenTicks,
                      ),
                      plotAreaBorderColor: Colors.black,
                      series: <CartesianSeries>[
                        ColumnSeries<GraphData, String>(
                          color: Colors.black,
                          dataSource: chartData,
                          xValueMapper: (GraphData x, _) => x.hour,
                          yValueMapper: (GraphData y, _) => y.kwh,
                          dataLabelSettings: DataLabelSettings(isVisible: true),
                        ),
                      ],
                      tooltipBehavior: TooltipBehavior(enable: true),
                      zoomPanBehavior: ZoomPanBehavior(enablePanning: true),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class GraphData {
  final String hour;
  final double kwh;

  GraphData(this.hour, this.kwh);
}
