import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/expandable_list_view.dart';

class GenerateQRPage extends StatefulWidget {
  @override
  _GenerateQRPageState createState() => _GenerateQRPageState();
}

class _GenerateQRPageState extends State<GenerateQRPage> {
  FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;
  FirebaseAuth firebaseAuthInstance = FirebaseAuth.instance;
  DocumentReference dr;
  CollectionReference cr;
  double qrSize, pdfRow, pdfPadding, qrFontSize;
  List<Map<String, dynamic>> productList = [];
  bool isDialogBoxOpen = false;
  String textMsg = 'No Product Data!';
  String belowTextMsg = 'Please Add Products!';
  StreamSubscription<QuerySnapshot> streamSub;

  @override
  initState() {
    super.initState();
    new Future.delayed(Duration.zero, () {
      showLoaderDialog(context, 'Fetching Data...');
    });
    var user = firebaseAuthInstance.currentUser;
    dr = firestoreInstance.collection("Users").doc(user.uid);
    cr = dr.collection('products');
    dr.snapshots().listen((snapshot) {
      setState(() {
        qrSize = double.parse(snapshot['qrCodeSize'].toString());
        pdfRow = double.parse(snapshot['tableRows'].toString());
        pdfPadding = double.parse(snapshot['tablePadding'].toString());
        qrFontSize = double.parse(snapshot['qrFontSize'].toString());
      });
    });
    streamSub = cr.snapshots().listen((snapshot) {
      productList = [];
      cr
          .where('isQRCodeGenerated', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .get()
          .then((qerySnapshot) => {
                qerySnapshot.docs.forEach((result) {
                  productList.add(result.data());
                }),
                setState(() {
                  productList = productList;
                  if (isDialogBoxOpen) {
                    Navigator.of(context).pop();
                    isDialogBoxOpen = false;
                  }
                }),
              });
    });
  }

  @override
  void dispose() {
    streamSub.cancel();
    super.dispose();
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
          child:AlertDialog(
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

  pw.Column _column(image, data, mrp) {
    return pw.Column(
      children: <pw.Widget>[
        pw.Container(
          height: 7,
        ),
        pw.ClipRect(
          child: pw.Container(
            width: qrSize,
            height: qrSize,
            child: pw.Image.provider(image),
          ),
        ),
        pw.Container(
          height: 2,
        ),
        pw.Text(
          data,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: qrFontSize),
        ),
        pw.Container(
          height: 2,
        ),
        pw.Text(
          mrp,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: qrFontSize + 2),
        ),
        pw.Container(
          height: 4,
        ),
      ],
    );
  }

  Future<void> generateQRCode(context) async {
    Navigator.of(context).pop();
    showLoaderDialog(context, 'Creating PDF...');
    var qrFinalData = [];
    var mrpFinalData = [];
    var qrFinalDisplayNameData = [];
    for (int i = 0; i < productList.length; i++) {
      var data = productList[i]['QRCodeData'];
      for (var d in data) {
        mrpFinalData.add(productList[i]['sellingPrice'].toString());
        qrFinalData.add(d);
        qrFinalDisplayNameData.add(productList[i]['itemName'].toString());
      }
    }

    List<dynamic> qrImages = [];

    for (int i = 0; i < qrFinalData.length; i++) {
      var qr = await QrPainter(
        data: qrFinalData[i],
        gapless: true,
        version: QrVersions.auto,
        emptyColor: Colors.white,
      ).toImage(150);

      var a = await qr.toByteData(format: ImageByteFormat.png);
      var image = pw.MemoryImage(a.buffer.asUint8List());
      qrImages.add(image);
    }

    List<pw.TableRow> _tableRow() {
      List<pw.TableRow> tableRow = List<pw.TableRow>();

      List<pw.Widget> col = new List<pw.Widget>();
      for (int i = 0; i < qrFinalData.length; i++) {
        if (i == qrFinalData.length - 1) {
          tableRow.add(pw.TableRow(children: col));
        } else if (i >= pdfRow && i % pdfRow == 0) {
          // changes the row here
          tableRow.add(pw.TableRow(children: col));
          col = new List<pw.Widget>();
        }
        col.add(
            _column(qrImages[i], qrFinalDisplayNameData[i], mrpFinalData[i]));
      }
      return tableRow;
    }

    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(pdfPadding), // chaange the margin
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Table(
              border: pw.TableBorder.all(),
              children: _tableRow(),
            )
          ];
        }));
    WriteBatch writeBatch = firestoreInstance.batch();
    DocumentReference postRef;
    for (int i = 0; i < productList.length; i++) {
      for (int j = 0; j < productList[i]['QRCodeData'].length; j++) {
        postRef = cr.doc(productList[i]['id']).collection('QRData').doc();
        writeBatch.set(
            postRef,
            {
              'id': postRef.id,
              'isScanned': false,
              'data': productList[i]['QRCodeData'][j],
              'createdTime': Timestamp.now().seconds,
              'scannedTime': Timestamp.now().seconds
            },
            SetOptions(merge: false));
      }
      writeBatch
          .update(cr.doc(productList[i]['id']), {'isQRCodeGenerated': true});
    }
    Directory path = await getExternalStorageDirectory();
    final file = File("${path.path}/${DateTime.now()}.pdf");
    await file.writeAsBytes(pdf.save());
    writeBatch.commit().then((_) {
      setState(() {
        textMsg = 'PDF is created.';
        belowTextMsg = '${path.path}/${DateTime.now()}.pdf';
      });
    });
  }

  Future<void> _deleteProduct(String id) async {
    return dr
        .collection('products')
        .doc(id)
        .delete()
        .then((value) => {
              print("Product Deleted"),
              Navigator.pop(context),
            })
        .catchError((error) => print("Failed to delete user: $error"));
  }

  Future<void> _deleteProductShowDialog(BuildContext context, String id) async {
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
              'Are you sure you want to delete?',
              style: TextStyle(color: Colors.white),
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 15, 0),
                child: Row(
                  children: [
                    RaisedButton(
                      elevation: 5.0,
                      onPressed: () => _deleteProduct(id),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      color: Colors.white,
                      child: Text(
                        'DELETE',
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

  Future<void> _qrCodeDownloadDialog(BuildContext context) async {
    int totalQRcodeCount = 0;
    for (int i = 0; i < productList.length; i++) {
      var data = productList[i]['QRCodeData'];
      totalQRcodeCount = totalQRcodeCount + data.length;
    }

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Please confirm',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.blue,
            elevation: 10,
            content: Container(
              height: 140,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total QR Code : ' + totalQRcodeCount.toString(),
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    'QR code size : ' + qrSize.toString(),
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: 14),
                  ),
                  Text(
                    'Font size : ' + qrFontSize.toString(),
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: 14),
                  ),
                  Text(
                    'Row in single column : ' + pdfRow.toString(),
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: 14),
                  ),
                  Text(
                    'PDF padding : ' + pdfPadding.toString(),
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: 14),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    'You can change this settings in Profile Section.',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        fontSize: 10),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 15, 0),
                child: Row(
                  children: [
                    RaisedButton(
                      elevation: 5.0,
                      onPressed: () => generateQRCode(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      color: Colors.white,
                      child: Text(
                        'DOWNLOAD',
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
                      onPressed: () => Navigator.of(context).pop(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60.0),
        child: productList.length > 0
            ? FloatingActionButton(
                onPressed: () => _qrCodeDownloadDialog(context),
                child: Icon(
                  LineAwesomeIcons.download,
                  color: Colors.white,
                  size: 29,
                ),
                backgroundColor: Colors.blue[300],
                tooltip: 'Download PDF',
                elevation: 5,
              )
            : SizedBox(
                width: 0,
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(0, 0, 0, 64),
          child: productList.length > 0
              ? ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    return ExpandableListView(
                        products: productList,
                        index: index,
                        context: context,
                        tailIcon: Icons.delete,
                        toolTipMessage: 'Delete product',
                        isHistoryPage: false,
                        onTap: () => _deleteProductShowDialog(
                            context, productList[index]['id'].toString()));
                  },
                  itemCount: productList.length,
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        textMsg,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        belowTextMsg,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w300),
                      )
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
