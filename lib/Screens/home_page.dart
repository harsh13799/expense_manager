import 'dart:async';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:edge_alert/edge_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pie_chart/pie_chart.dart';
import '../widgets/report_expandable_view.dart';

class MyCardsPage extends StatefulWidget {
  @override
  _MyCardsPageState createState() => _MyCardsPageState();
}

class _MyCardsPageState extends State<MyCardsPage> {
  FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;
  FirebaseAuth firebaseAuthInstance = FirebaseAuth.instance;
  DocumentReference dr;
  CollectionReference cr;
  double totalReturn = 0, totalInvest = 0, totalExpenses = 0, totalProfit = 0;
  List<Map<String, dynamic>> productList = [];
  List<Map<String, dynamic>> mainData = [];
  List<Map<String, dynamic>> qrCodeScannedList = [];
  Map<String, dynamic> data;
  bool isDialogBoxOpen = false;
  var user;
  String textMsg = 'No Product Data!';
  Map<String, double> dataMap = {
    "Invest : ": 0,
    "Return : ": 0,
    "Expenses : ": 0,
    "Profit : ": 0,
  };
  DateTime pickedFromDate;
  DateTime pickedToDate;
  var formatter = new DateFormat('dd-MM-yyyy');

  @override
  initState() {
    super.initState();
    user = firebaseAuthInstance.currentUser;
    pickedFromDate = DateTime.now().subtract(new Duration(days: 6));
    pickedToDate = DateTime.now();
    dr = firestoreInstance.collection("Users").doc(user.uid);
    cr = dr.collection('products');
    _getData(context);
  }

  Future<void> _setTopBar(List pl) async {
    totalProfit = 0;
    totalExpenses = 0;
    totalInvest = 0;
    totalReturn = 0;
    for (int i = 0; i < pl.length; i++) {
      if (pl[i]['isBoxes']) {
        totalExpenses = totalExpenses +
            pl[i]['expenses'] * (pl[i]['boxes'] - pl[i]['totalQRCode']);
        totalInvest = totalInvest +
            pl[i]['purchasePrice'] * (pl[i]['boxes'] - pl[i]['totalQRCode']);
        totalReturn = totalReturn +
            pl[i]['sellingPrice'] * (pl[i]['boxes'] - pl[i]['totalQRCode']);
      } else {
        totalExpenses = totalExpenses +
            pl[i]['expenses'] * (pl[i]['quantity'] - pl[i]['totalQRCode']);
        totalInvest = totalInvest +
            pl[i]['purchasePrice'] * (pl[i]['quantity'] - pl[i]['totalQRCode']);
        totalReturn = totalReturn +
            pl[i]['sellingPrice'] * (pl[i]['quantity'] - pl[i]['totalQRCode']);
      }
    }
    totalProfit = totalReturn - totalInvest - totalExpenses;
  }

  showLoaderDialog(BuildContext context, String text) {
    setState(() {
      isDialogBoxOpen = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.blue,
            elevation: 10,
            content: new Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Container(
                  margin: EdgeInsets.only(left: 15),
                  child: Text(
                    text,
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _pickFromDate() async {
    DateTime date = await showDatePicker(
        context: context,
        firstDate: user.metadata.creationTime,
        lastDate: DateTime.now(),
        initialDate: pickedFromDate,
        helpText: 'Select from date');
    if (date != null)
      setState(() {
        pickedFromDate = date;
      });
  }

  _pickToDate() async {
    DateTime date = await showDatePicker(
        context: context,
        firstDate: user.metadata.creationTime,
        lastDate: DateTime.now(),
        initialDate: pickedToDate,
        helpText: 'Select to date');
    if (date != null)
      setState(() {
        pickedToDate =
            date.add(new Duration(hours: 23, minutes: 59, seconds: 59));
      });
  }

  Future<void> _getData(BuildContext context) async {
    productList = [];
    mainData = [];
    if (pickedToDate.difference(pickedFromDate).inDays < 0) {
      EdgeAlert.show(context,
          title: 'Please select valid dates',
          gravity: EdgeAlert.TOP,
          backgroundColor: Colors.blue,
          icon: Icons.error);
    } else {
      new Future.delayed(Duration.zero, () {
        showLoaderDialog(context, 'Please wait...');
      });
      await cr
          .where('isQRCodeGenerated', isEqualTo: true)
          .orderBy('scannedTime', descending: true)
          .get()
          .then((qerySnapshot) {
        qerySnapshot.docs.forEach((result) {
          productList.add(result.data());
        });
      });
      for (int i = 0; i < productList.length; i++) {
        await cr
            .doc(productList[i]['id'])
            .collection('QRData')
            .where('isScanned', isEqualTo: true)
            .where('scannedTime',
                isGreaterThanOrEqualTo:
                    Timestamp.fromDate(pickedFromDate).seconds)
            .where('scannedTime',
                isLessThanOrEqualTo: Timestamp.fromDate(pickedToDate).seconds)
            .orderBy('scannedTime', descending: true)
            .get()
            .then((qr) {
          for (int j = 0; j < qr.docs.length; j++) {
            qrCodeScannedList.add(qr.docs[j].data());
            if (j == qr.docs.length - 1) {
              data = {};
              data = productList[i];
              data['QRData'] = qrCodeScannedList;
              mainData.add(data);
              qrCodeScannedList = [];
            }
          }
        });
      }
      setState(() {
        mainData = mainData;
      });
      _setTopBar(mainData).then((_) {
        dataMap = {
          "Return : " + totalReturn.toString(): totalReturn.toDouble(),
          "Invest : " + totalInvest.toString(): totalInvest.toDouble(),
          "Expenses : " + totalExpenses.toString(): totalExpenses.toDouble(),
          "Profit : " + totalProfit.toString(): totalProfit.toDouble()
        };
      });
      if (isDialogBoxOpen) {
        Navigator.of(context).pop();
        setState(() {
          isDialogBoxOpen = false;
        });
      }
    }
    return mainData;
  }

  @override
  Widget build(BuildContext context) {
    final chart = PieChart(
      key: ValueKey(0),
      dataMap: dataMap,
      animationDuration: Duration(milliseconds: 800),
      chartLegendSpacing: 40,
      chartRadius: MediaQuery.of(context).size.width / 3.2 > 300
          ? 300
          : MediaQuery.of(context).size.width / 3.2,
      colorList: [
        Colors.white,
        Colors.orange,
        Colors.red,
        Colors.green,
      ],
      initialAngleInDegree: 0,
      chartType: ChartType.ring,
      centerText: null,
      legendOptions: LegendOptions(
        showLegendsInRow: false,
        legendPosition: LegendPosition.right,
        showLegends: true,
        legendShape: BoxShape.circle,
        legendTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      chartValuesOptions: ChartValuesOptions(
        showChartValueBackground: false,
        chartValueBackgroundColor: Colors.white,
        showChartValues: false,
        showChartValuesInPercentage: false,
        showChartValuesOutside: false,
        chartValueStyle: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.w500,
        ),
      ),
      ringStrokeWidth: 12,
    );

    return Scaffold(
      backgroundColor: Colors.blue,
      body: NestedScrollView(
        physics: ScrollPhysics(parent: PageScrollPhysics()),
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  SizedBox(height: 7),
                  Container(
                    height: 120,
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    child: chart,
                  ),
                  SizedBox(height: 7),
                  Divider(
                    height: 2,
                    indent: 30,
                    endIndent: 30,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ];
        },
        body: Container(
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 15.0),
                  child: Row(
                    children: [
                      RaisedButton(
                        elevation: 5.0,
                        onPressed: () => _pickFromDate(),
                        padding: EdgeInsets.all(10.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        color: Colors.white,
                        child: Text(
                          formatter.format(pickedFromDate),
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        'To',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      RaisedButton(
                        elevation: 5.0,
                        onPressed: () => _pickToDate(),
                        padding: EdgeInsets.all(10.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        color: Colors.white,
                        child: Text(
                          formatter.format(pickedToDate),
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Spacer(),
                      RaisedButton(
                        elevation: 5.0,
                        onPressed: () => _getData(context),
                        padding: EdgeInsets.all(5.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        color: Colors.white,
                        child: Icon(
                          LineAwesomeIcons.search,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 2,
                indent: 30,
                endIndent: 30,
                color: Colors.white,
              ),
              Expanded(
                flex: 8,
                child: mainData.length > 0
                    ? ListView.builder(
                        itemBuilder: (BuildContext context, int index) {
                          return ReportExapandablePage(
                              products: mainData,
                              index: index,
                              context: context,
                              tailIcon: Icons.delete,
                              toolTipMessage: '',
                              isHistoryPage: false,
                              onTap: () => null);
                        },
                        itemCount: mainData.length,
                      )
                    : Center(
                        child: Text(
                          textMsg,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
              SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
