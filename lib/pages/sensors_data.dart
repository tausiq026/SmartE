import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: FetchData(),
  ));
}

class FetchData extends StatefulWidget {
  @override
  _FetchDataState createState() => _FetchDataState();
}

class _FetchDataState extends State<FetchData> {
  double vrms = 0.0;
  double irms = 0.0;
  double power = 0.0;
  double kwh = 0.0;

  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.reference().child('sensors');
  final CollectionReference _firestoreRef =
      FirebaseFirestore.instance.collection('sensors');

  @override
  void initState() {
    super.initState();
    _dbRef.onValue.listen((event) {
      if (mounted) {
        print('Firebase Realtime Database event received');
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          vrms = (data['VRMS'] ?? 0).toDouble();
          irms = (data['IRMS'] ?? 0).toDouble();
          power = (data['POWER'] ?? 0).toDouble();
          kwh = (data['KWH'] ?? 0).toDouble();
        });
        print(
            'Updated state with new values: VRMS: $vrms, IRMS: $irms, POWER: $power, KWH: $kwh');
        _updateFirestore(data);
      } else {
        print('Widget is disposed, skipping setState()');
      }
    });
  }

  Future<void> _updateFirestore(Map<String, dynamic> data) async {
    try {
      print('Attempting to add data to Firestore...');
      await _firestoreRef.add({
        'timestamp': FieldValue.serverTimestamp(),
        'VRMS': data['VRMS'],
        'IRMS': data['IRMS'],
        'POWER': data['POWER'],
        'KWH': data['KWH'],
      });
      print('Data added to Firestore');
    } catch (e) {
      print('Failed to add data to Firestore: $e');
      if (e is FirebaseException) {
        print('FirebaseException code: ${e.code}');
        print('FirebaseException message: ${e.message}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Electricity Monitoring'),
        backgroundColor: Colors.blue.shade400,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade200, Colors.blue.shade400, Colors.white],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Column(
            children: [
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 5.0,
                  mainAxisSpacing: 5.0,
                  children: [
                    MeterWidget(
                        title: 'VRMS', value: vrms, color: Colors.yellow),
                    MeterWidget(
                      title: 'IRMS',
                      value: irms,
                      color: Colors.green,
                    ),
                    MeterWidget(
                      title: 'POWER',
                      value: power,
                      color: Colors.blue,
                    ),
                    MeterWidget(
                      title: 'KWH',
                      value: kwh,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              SummaryGraph(
                vrms: vrms,
                irms: irms,
                power: power,
                kwh: kwh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MeterWidget extends StatefulWidget {
  final String title;
  final double value;
  final Color color;

  const MeterWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  _MeterWidgetState createState() => _MeterWidgetState();
}

class _MeterWidgetState extends State<MeterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(MeterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: 0, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
              SizedBox(
                width: 120,
                height: 120,
                child: SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 0,
                      maximum: 1023,
                      showLabels: false,
                      showTicks: false,
                      startAngle: 145,
                      endAngle: 35,
                      axisLineStyle: AxisLineStyle(
                        thickness: 20,
                        color: widget.color.withOpacity(0.3),
                      ),
                      pointers: <GaugePointer>[
                        NeedlePointer(
                          value: _animation.value,
                          needleColor: widget.color,
                          needleStartWidth: 1,
                          needleEndWidth: 5,
                          lengthUnit: GaugeSizeUnit.factor,
                          needleLength: 0.8,
                        ),
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                          widget: Text(
                            _animation.value.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: widget.color,
                            ),
                          ),
                          angle: 90,
                          positionFactor: 0.5,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class SummaryGraph extends StatelessWidget {
  final double vrms;
  final double irms;
  final double power;
  final double kwh;

  const SummaryGraph({
    Key? key,
    required this.vrms,
    required this.irms,
    required this.power,
    required this.kwh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: EdgeInsets.all(20.0),
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        series: <CartesianSeries>[
          ColumnSeries<SummaryData, String>(
            dataSource: [
              SummaryData('VRMS', vrms),
              SummaryData('IRMS', irms),
              SummaryData('POWER', power),
              SummaryData('KWH', kwh),
            ],
            xValueMapper: (SummaryData data, _) => data.title,
            yValueMapper: (SummaryData data, _) => data.value,
            color: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}

class SummaryData {
  final String title;
  final double value;

  SummaryData(this.title, this.value);
}
