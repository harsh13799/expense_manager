import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../Constant/constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:edge_alert/edge_alert.dart';
import 'package:pie_chart/pie_chart.dart';
import '../widgets/report_expandable_view.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart'
    hide Row, Column, Alignment;
import 'package:open_file/open_file.dart' as open_file;

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;
  FirebaseAuth firebaseAuthInstance = FirebaseAuth.instance;
  DocumentReference dr;
  CollectionReference cr;
  List<Map<String, dynamic>> productList = [];
  bool isDialogBoxOpen = false;
  String textMsg = 'No Product Data!';
  StreamSubscription<QuerySnapshot> streamSub;
  double totalReturn = 0, totalInvest = 0, totalExpenses = 0, totalProfit = 0;
  List<Map<String, dynamic>> mainData = [];
  List<Map<String, dynamic>> qrCodeScannedList = [];
  Map<String, dynamic> data;
  var user;
  Map<String, double> dataMap = {
    "Invest : ": 0,
    "Return : ": 0,
    "Expenses : ": 0,
    "Profit : ": 0,
  };
  DateTime pickedFromDate;
  DateTime pickedToDate;
  var formatter = new DateFormat('dd-MM-yyyy');
  var formatter2 = new DateFormat.yMMMMd('en_US');

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
      totalExpenses =
          totalExpenses + pl[i]['expenses'] * pl[i]['QRData'].length;
      totalInvest =
          totalInvest + pl[i]['purchasePrice'] * pl[i]['QRData'].length;
      totalReturn =
          totalReturn + pl[i]['sellingPrice'] * pl[i]['QRData'].length;
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

  Future<void> _addBackProduct(String id, int index) async {
    return cr.doc(id).collection('QRData').get().then((querySnapshot) {
      for (QueryDocumentSnapshot query in querySnapshot.docs) {
        query.reference.delete();
      }
    }).then((_) {
      cr
          .doc(id)
          .update({
            'isQRCodeGenerated': false,
            'timestamp': Timestamp.now().seconds,
            'date': DateTime.now(),
            'totalQRCode': productList[index]['isBoxes']
                ? productList[index]['boxes']
                : productList[index]['quantity']
          })
          .then((_) => {
                Navigator.of(context).pop(),
                _scaffoldKey.currentState.showSnackBar(
                    SnackBar(content: Text('Product added back'))),
              })
          .catchError((error) => _scaffoldKey.currentState
              .showSnackBar(SnackBar(content: Text('Something went wrong'))));
    });
  }

  Future<void> _addBackPopup(BuildContext context, String id, int index) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Please Confirm!',
              style: TextStyle(color: Colors.white),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.blue,
            elevation: 10,
            content: Text(
              'Are you sure you want to add back this product?',
              style: TextStyle(color: Colors.white),
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 15, 0),
                child: Row(
                  children: [
                    RaisedButton(
                      elevation: 5.0,
                      onPressed: () => _addBackProduct(id, index),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      color: Colors.white,
                      child: Text(
                        'ADD BACK',
                        style: TextStyle(
                          color: Colors.blue,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    RaisedButton(
                      elevation: 5.0,
                      onPressed: () => Navigator.pop(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      color: Colors.white,
                      child: Text(
                        "CANCEL",
                        style: TextStyle(
                          color: Colors.blue,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }

  Widget header(context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            LineAwesomeIcons.arrow_left,
            size: ScreenUtil().setSp(kSpacingUnit.w * 3),
            color: Colors.white,
          ),
          SizedBox(
            width: 20,
          )
        ],
      ),
    );
  }

  Widget download(context) {
    return GestureDetector(
      onTap: () => generateExcel(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Icon(
            LineAwesomeIcons.download,
            size: ScreenUtil().setSp(kSpacingUnit.w * 3),
            color: Colors.white,
          )
        ],
      ),
    );
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

  Future<void> generateExcel(context) async {
    showLoaderDialog(context, "Please Wait...");
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.showGridlines = false;

    sheet.enableSheetCalculations();

    sheet.getRangeByName('A1').columnWidth = 4.82;
    sheet.getRangeByName('B1').columnWidth = 2.43; //id
    sheet.getRangeByName('C1').columnWidth = 12.00; //date
    sheet.getRangeByName('D1').columnWidth = 18.57; //qrcode
    sheet.getRangeByName('E1:F1').columnWidth = 10.00; // item
    sheet.getRangeByName('G1').columnWidth = 15.00; //cat
    sheet.getRangeByName('H1').columnWidth = 15.00; //sub cat
    sheet.getRangeByName('I1').columnWidth = 6.71; // boxes
    sheet.getRangeByName('J1').columnWidth = 9.43; //quantity
    sheet.getRangeByName('K1').columnWidth = 14.14; //price
    sheet.getRangeByName('L1').columnWidth = 11.86; //expenses
    sheet.getRangeByName('M1').columnWidth = 15.57; //purchase price
    sheet.getRangeByName('N1').columnWidth = 14.57; //selling price
    sheet.getRangeByName('O1').columnWidth = 16.57; // profit
    sheet.getRangeByName('P1').columnWidth = 4.82;

    sheet.getRangeByName('A1:P1').cellStyle.backColor = '#00B0F0';
    sheet.getRangeByName('A1:P1').merge();
    sheet.getRangeByName('B2:D4').merge();

    sheet.getRangeByName('B2').setText('Report');
    sheet.getRangeByName('B2').cellStyle.fontSize = 32;

    final Range range1 = sheet.getRangeByName('M2:O2');
    final Range range2 = sheet.getRangeByName('M3:O3');
    final Range range3 = sheet.getRangeByName('M4:O4');

    range1.merge();
    range2.merge();
    range3.merge();

    sheet.getRangeByName('O2').setText('DATE');
    range1.cellStyle.fontSize = 9;
    range1.cellStyle.bold = true;
    range1.cellStyle.hAlign = HAlignType.right;

    sheet.getRangeByName('O3').dateTime = DateTime.now();
    sheet.getRangeByName('O3').numberFormat =
        '[\$-x-sysdate]dddd, mmmm dd, yyyy';
    range2.cellStyle.fontSize = 9;
    range2.cellStyle.hAlign = HAlignType.right;

    sheet.getRangeByName('O4').setText('S K BROTHERS');
    range3.cellStyle.fontSize = 12;
    range3.cellStyle.bold = true;
    range3.cellStyle.hAlign = HAlignType.right;

    final Range range4 = sheet.getRangeByName('A6:P6');
    range4.cellStyle.fontSize = 12;
    range4.cellStyle.bold = true;
    range4.cellStyle.hAlign = HAlignType.center;
    range4.cellStyle.backColor = '#00B0F0';
    range4.cellStyle.fontColor = '#FFFFFF';
    range4.merge();
    sheet.getRangeByName('P6').text =
        '${formatter2.format(pickedFromDate)} - ${formatter2.format(pickedToDate)} ';

    sheet.getRangeByIndex(8, 2).setText('#');
    sheet.getRangeByIndex(8, 2).cellStyle.bold = true;
    sheet.getRangeByIndex(8, 3).setText('Date');
    sheet.getRangeByIndex(8, 3).cellStyle.bold = true;
    sheet.getRangeByIndex(8, 4).setText('QR Code');
    sheet.getRangeByIndex(8, 4).cellStyle.bold = true;
    sheet.getRangeByIndex(8, 5).setText('Item Name');
    sheet.getRangeByIndex(8, 5, 8, 6).merge();
    sheet.getRangeByIndex(8, 5, 8, 6).cellStyle.bold = true;
    sheet.getRangeByIndex(8, 7).setText('Category');
    sheet.getRangeByIndex(8, 7).cellStyle.bold = true;
    sheet.getRangeByIndex(8, 8).setText('Sub Category');
    sheet.getRangeByIndex(8, 8).cellStyle.bold = true;
    sheet.getRangeByIndex(8, 9).setText('Boxes');
    sheet.getRangeByIndex(8, 9).cellStyle.bold = true;
    sheet.getRangeByIndex(8, 10).setText('Quantity');
    sheet.getRangeByIndex(8, 10).cellStyle.bold = true;
    sheet.getRangeByIndex(8, 11).setText('Price');
    sheet.getRangeByIndex(8, 11).cellStyle.hAlign = HAlignType.right;
    sheet.getRangeByIndex(8, 11).cellStyle.bold = true;
    sheet.getRangeByIndex(8, 12).setText('Expenses');
    sheet.getRangeByIndex(8, 12).cellStyle.hAlign = HAlignType.right;
    sheet.getRangeByIndex(8, 12).cellStyle.bold = true;
    sheet.getRangeByIndex(8, 13).setText('Purchase Price');
    sheet.getRangeByIndex(8, 13).cellStyle.hAlign = HAlignType.right;
    sheet.getRangeByIndex(8, 13).cellStyle.bold = true;
    sheet.getRangeByIndex(8, 14).setText('Selling Price');
    sheet.getRangeByIndex(8, 14).cellStyle.hAlign = HAlignType.right;
    sheet.getRangeByIndex(8, 14).cellStyle.bold = true;
    sheet.getRangeByIndex(8, 15).setText('Profit');
    sheet.getRangeByIndex(8, 15).cellStyle.hAlign = HAlignType.right;
    sheet.getRangeByIndex(8, 15).cellStyle.bold = true;
    // sheet.autoFitRow(8);
    int i = 0;
    for (i = 0; i < mainData.length; i++) {
      sheet.getRangeByIndex(9 + i, 2).setNumber(i.toDouble() + 1);
      sheet.getRangeByIndex(9 + i, 3).setText(DateFormat('dd-MM-yyyy')
          .format(DateTime.fromMillisecondsSinceEpoch(
              int.parse(mainData[i]['scannedTime'].toString()) * 1000))
          .toString());
      sheet.getRangeByIndex(9 + i, 4).setText(
          mainData[i]['QRData'][0]['data'].toString().substring(0, 10));
      sheet.getRangeByIndex(9 + i, 5).setText(mainData[i]['itemName']);
      sheet.getRangeByIndex(9 + i, 5, 9 + i, 6).merge();
      sheet.getRangeByIndex(9 + i, 7).setText(mainData[i]['category']);
      sheet.getRangeByIndex(9 + i, 8).setText(mainData[i]['subCategory']);

      if (mainData[i]['isBoxes']) {
        sheet
            .getRangeByIndex(9 + i, 9)
            .setText((mainData[i]['QRData'].length).toString());
        sheet
            .getRangeByIndex(9 + i, 10)
            .setText((mainData[i]['quantity']).toString());
        sheet.getRangeByIndex(9 + i, 11).setNumber(
            (mainData[i]['QRData'].length * mainData[i]['purchasePrice'])
                .toDouble());
        sheet.getRangeByIndex(9 + i, 12).setNumber(
            (mainData[i]['QRData'].length * mainData[i]['expenses'])
                .toDouble());
        sheet.getRangeByIndex(9 + i, 13).setNumber(
            (mainData[i]['QRData'].length * mainData[i]['totalPrice'])
                .toDouble());
        sheet.getRangeByIndex(9 + i, 14).setNumber(
            (mainData[i]['QRData'].length * mainData[i]['sellingPrice'])
                .toDouble());
      } else {
        sheet.getRangeByIndex(9 + i, 9).setText('0');
        sheet
            .getRangeByIndex(9 + i, 10)
            .setText((mainData[i]['QRData'].length).toString());
        sheet.getRangeByIndex(9 + i, 11).setNumber(
            (mainData[i]['QRData'].length * mainData[i]['purchasePrice'])
                .toDouble());
        sheet.getRangeByIndex(9 + i, 12).setNumber(
            (mainData[i]['QRData'].length * mainData[i]['expenses'])
                .toDouble());
        sheet.getRangeByIndex(9 + i, 13).setNumber(
            (mainData[i]['QRData'].length * mainData[i]['totalPrice'])
                .toDouble());
        sheet.getRangeByIndex(9 + i, 14).setNumber(
            (mainData[i]['QRData'].length * mainData[i]['sellingPrice'])
                .toDouble());
      }
      sheet.getRangeByIndex(9 + i, 15).setFormula('=N${9 + i}-M${9 + i}');
      sheet.getRangeByIndex(9 + i, 11, 9 + i, 15).numberFormat = '\₹#,##0.00';
    }

    // sheet.getRangeByName('E15:G15').cellStyle.hAlign = HAlignType.right;
    // sheet.getRangeByName('B15:G15').cellStyle.fontSize = 10;
    // sheet.getRangeByName('B15:G15').cellStyle.bold = true;
    // sheet.getRangeByName('B16:G20').cellStyle.fontSize = 9;

    sheet.getRangeByName('D${10 + i}:F${10 + i}').merge();
    sheet.getRangeByName('D${10 + i}:F${10 + i}').cellStyle.hAlign =
        HAlignType.right;
    sheet.getRangeByName('D${11 + i}:F${11 + i}').merge();

    sheet.getRangeByName('G${10 + i}:H${10 + i}').merge();
    sheet.getRangeByName('G${10 + i}:H${10 + i}').cellStyle.hAlign =
        HAlignType.right;
    sheet.getRangeByName('G${11 + i}:H${11 + i}').merge();

    sheet.getRangeByName('I${10 + i}:K${10 + i}').merge();
    sheet.getRangeByName('I${10 + i}:K${10 + i}').cellStyle.hAlign =
        HAlignType.right;
    sheet.getRangeByName('I${11 + i}:K${11 + i}').merge();

    sheet.getRangeByName('L${10 + i}:M${10 + i}').merge();
    sheet.getRangeByName('L${10 + i}:M${10 + i}').cellStyle.hAlign =
        HAlignType.right;
    sheet.getRangeByName('L${11 + i}:M${11 + i}').merge();

    sheet.getRangeByName('N${10 + i}:O${10 + i}').merge();
    sheet.getRangeByName('N${10 + i}:O${10 + i}').cellStyle.hAlign =
        HAlignType.right;
    sheet.getRangeByName('N${11 + i}:O${11 + i}').merge();

    final Range range5 = sheet.getRangeByName('F${10 + i}');
    final Range range6 = sheet.getRangeByName('F${11 + i}');

    range5.setText('TOTAL PRICE');
    range5.cellStyle.fontSize = 8;
    range6.setFormula('=SUM(K9:K${9 + i})');
    range6.numberFormat = '\₹#,##0.00';
    range6.cellStyle.fontSize = 18;
    range6.cellStyle.hAlign = HAlignType.right;
    range6.cellStyle.bold = true;

    final Range range7 = sheet.getRangeByName('H${10 + i}');
    final Range range8 = sheet.getRangeByName('H${11 + i}');

    range7.setText('TOTAL EXPENSES');
    range7.cellStyle.fontSize = 8;
    range8.setFormula('=SUM(L9:L${9 + i})');
    range8.numberFormat = '\₹#,##0.00';
    range8.cellStyle.fontSize = 18;
    range8.cellStyle.hAlign = HAlignType.right;
    range8.cellStyle.bold = true;

    final Range range11 = sheet.getRangeByName('K${10 + i}');
    final Range range12 = sheet.getRangeByName('K${11 + i}');

    range11.setText('TOTAL PURCHASE');
    range11.cellStyle.fontSize = 8;
    range12.setFormula('=SUM(M9:M${9 + i})');
    range12.numberFormat = '\₹#,##0.00';
    range12.cellStyle.fontSize = 20;
    range12.cellStyle.hAlign = HAlignType.right;
    range12.cellStyle.bold = true;

    final Range range13 = sheet.getRangeByName('M${10 + i}');
    final Range range14 = sheet.getRangeByName('M${11 + i}');

    range13.setText('TOTAL SELLING');
    range13.cellStyle.fontSize = 8;
    range14.setFormula('=SUM(N9:N${9 + i})');
    range14.numberFormat = '\₹#,##0.00';
    range14.cellStyle.fontSize = 20;
    range14.cellStyle.hAlign = HAlignType.right;
    range14.cellStyle.bold = true;

    final Range range15 = sheet.getRangeByName('O${10 + i}');
    final Range range16 = sheet.getRangeByName('O${11 + i}');

    range15.setText('TOTAL PROFIT');
    range15.cellStyle.fontSize = 8;
    range16.setFormula('=SUM(O9:O${9 + i})');
    range16.numberFormat = '\₹#,##0.00';
    range16.cellStyle.fontSize = 24;
    range16.cellStyle.hAlign = HAlignType.right;
    range16.cellStyle.bold = true;

    final Range range17 = sheet.getRangeByName('A${13 + i}:P${13 + i}');
    range17.cellStyle.backColor = '#00B0F0';
    range17.merge();

    //Save and launch the excel.
    final List<int> bytes = workbook.saveAsStream();
    //Dispose the document.
    workbook.dispose();

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(now);
    final Directory _appDocDirFolder =
        Directory('/storage/emulated/0/ExpenseManager/Report');
    if (!await _appDocDirFolder.exists()) {
      await _appDocDirFolder.create(recursive: true);
    }
    final File file = File('${_appDocDirFolder.path}/$formattedDate.xlsx');
    await file.writeAsBytes(bytes);

    if (isDialogBoxOpen) {
      Navigator.of(context).pop();
      setState(() {
        isDialogBoxOpen = false;
      });
    }

    //Launch the file (used open_file package)
    await open_file.OpenFile.open(
        '${_appDocDirFolder.path}/$formattedDate.xlsx');
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
      key: _scaffoldKey,
      backgroundColor: Colors.blue,
      body: NestedScrollView(
        physics: ScrollPhysics(parent: PageScrollPhysics()),
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  SizedBox(height: 35),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 40.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        header(context),
                        Text(
                          'Report',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        download(context),
                      ],
                    ),
                  ),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
            child: Column(
              children: <Widget>[
                Expanded(
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    streamSub.cancel();
    super.dispose();
  }
}
