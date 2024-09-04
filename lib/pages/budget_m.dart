import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget Management',
      theme: ThemeData(
        primaryColor: Colors.blue.shade800,
        hintColor: Colors.blue.shade600,
        scaffoldBackgroundColor: Colors.blue.shade900,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.grey),
            padding: MaterialStateProperty.all(
              EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
            ),
            textStyle: MaterialStateProperty.all(
              TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ),
      ),
      home: BudgetM(),
    );
  }
}

class BudgetM extends StatefulWidget {
  @override
  _BudgetMState createState() => _BudgetMState();
}

class _BudgetMState extends State<BudgetM> {
  double unitPrice = 65; // Default unit price for PKR
  TextEditingController amountController = TextEditingController();
  double calculatedUnits = 0;
  String selectedCurrency = 'PKR'; // Default currency
  List<String> calculationHistory = []; // List to store calculation history
  double monthlyLimit = 50; // Default monthly unit limit
  double currentUsage = 0; // Current usage fetched from Firestore
  double totalKwh = 0; // Total KWH fetched from Firestore
  bool fetchingData = false;
  bool errorFetchingData = false;

  // Map of currencies and their unit prices
  Map<String, double> currencyUnitPrices = {
    'PKR': 65, // Pakistani Rupee
    'USD': 0.23, // US Dollar
    'EUR': 0.22, // Euro
    'GBP': 0.19, // British Pound
  };

  @override
  void initState() {
    super.initState();
    _fetchCurrentUsage();
    _fetchTotalKwh();
  }

  Future<void> _fetchCurrentUsage() async {
    setState(() {
      fetchingData = true;
    });
    try {
      // Replace 'user_id' with the actual user ID
      var doc = await FirebaseFirestore.instance
          .collection('sensors')
          .doc('u0qFyj2eANOXyFNIal9AAbA5cKZ2')
          .get();
      setState(() {
        currentUsage = (doc.data()?['currentUsage'] ?? 0) as double;
        fetchingData = false;
      });
    } catch (e) {
      print("Error fetching current usage: $e");
      setState(() {
        fetchingData = false;
        errorFetchingData = true;
      });
    }
  }

  Future<void> _fetchTotalKwh() async {
    try {
      var querySnapshot =
          await FirebaseFirestore.instance.collection('sensors').get();
      double sum = 0;
      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          var kwh = data['KWH'];
          if (kwh is num) {
            sum += kwh.toDouble();
          }
        }
      }
      setState(() {
        totalKwh = sum;
      });
    } catch (e) {
      print("Error fetching total KWH: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Management'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade800,
                Colors.white,
                Colors.blue.shade900
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Calculate Units',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.0),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Enter Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  fillColor: Colors.lightBlue[50],
                  filled: true,
                ),
              ),
              SizedBox(height: 20.0),
              DropdownButtonFormField(
                value: selectedCurrency,
                items: currencyUnitPrices.keys.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCurrency = value.toString();
                    unitPrice = currencyUnitPrices[selectedCurrency]!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Select Currency',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    double amount = double.parse(amountController.text);
                    calculatedUnits = amount / unitPrice;
                    // Add calculation to history
                    calculationHistory.add(
                      '$amount ${selectedCurrency.toUpperCase()} = ${calculatedUnits.toStringAsFixed(2)} Units',
                    );
                    // Don't update currentUsage here
                    if (currentUsage + calculatedUnits >= monthlyLimit) {
                      _showMonthlyLimitExceededDialog();
                    }
                  });
                },
                child: Text('Calculate'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey,
                  onPrimary: Colors.white,
                  padding:
                      EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  textStyle:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              Text(
                'Calculated Units: ${calculatedUnits.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  _showCalculationHistory();
                },
                child: Text('Calculation History'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.grey,
                  padding:
                      EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  textStyle:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  _setMonthlyLimit();
                },
                child: Text('Set Monthly Limit'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.grey,
                  padding:
                      EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  textStyle:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  _viewUsageDetails();
                },
                child: Text('Remaining Units'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.grey,
                  padding:
                      EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  textStyle:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  _showFirestoreData();
                },
                child: Text('View Consumed Units'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.grey,
                  padding:
                      EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  textStyle:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              fetchingData
                  ? Center(child: CircularProgressIndicator())
                  : errorFetchingData
                      ? Text("")
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Limit: $monthlyLimit',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10.0),
                            Text(
                              'Current Usage: $currentUsage',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
              SizedBox(height: 20.0),
              // Custom text for SmartE app name
              Container(
                alignment: Alignment.center,
                child: Text(
                  'SmartE',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontFamily:
                        'BeautifulFont', // Replace 'BeautifulFont' with your desired font family
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to show dialog when monthly limit is exceeded
  void _showMonthlyLimitExceededDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Monthly Limit Exceeded'),
          content: Text('You have exceeded your monthly unit limit.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to show calculation history
  void _showCalculationHistory() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Calculation History'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: calculationHistory
                  .map((calculation) => Text(calculation))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to set monthly limit
  void _setMonthlyLimit() {
    TextEditingController limitController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Monthly Limit'),
          content: TextField(
            controller: limitController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Enter Monthly Limit',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                double newLimit = double.parse(limitController.text);
                if (newLimit < totalKwh) {
                  _showInvalidLimitDialog();
                } else {
                  setState(() {
                    monthlyLimit = newLimit;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Set Limit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Function to show invalid limit dialog
  void _showInvalidLimitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Invalid Limit'),
          content: Text('Monthly limit should be more than the total KWH.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to view usage details
  void _viewUsageDetails() {
    showDialog(
      context: context,
      builder: (context) {
        double remainingUnits = monthlyLimit - totalKwh;
        String usageDetails;
        if (remainingUnits >= 0) {
          usageDetails =
              'You have ${remainingUnits.toStringAsFixed(2)} units remaining for the month.';
        } else {
          usageDetails =
              'You have exceeded your monthly limit by ${remainingUnits.abs().toStringAsFixed(2)} units.';
        }

        return AlertDialog(
          title: Text('Usage Details'),
          content: Text(usageDetails),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to show Firestore data
  void _showFirestoreData() {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('sensors').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text('Firestore Data'),
                content: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return AlertDialog(
                title: Text('Firestore Data'),
                content: Text('Error fetching data.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            } else if (snapshot.hasData) {
              var documents = snapshot.data!.docs;
              List<String> kwhData = [];
              double sumKwh = 0;
              for (var doc in documents) {
                var data = doc.data() as Map<String, dynamic>?;
                if (data != null) {
                  var kwh = data['KWH'];
                  if (kwh is num) {
                    sumKwh += kwh.toDouble();
                    kwhData.add('KWH: $kwh');
                  } else {
                    // Handle the case where 'KWH' is not a number
                    kwhData.add('KWH: invalid data');
                  }
                }
              }
              totalKwh = sumKwh; // Update total KWH
              return AlertDialog(
                title: Text('Firestore Data'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: kwhData.map((kwh) => Text(kwh)).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            } else {
              return AlertDialog(
                title: Text('Firestore Data'),
                content: Text('No data available.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }
}
