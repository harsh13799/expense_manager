import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:edge_alert/edge_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SaleItPage extends StatefulWidget {
  @override
  _SaleItPageState createState() => _SaleItPageState();
}

class _SaleItPageState extends State<SaleItPage> {
  Barcode result;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;
  FirebaseAuth firebaseAuthInstance = FirebaseAuth.instance;
  DocumentReference dr;
  CollectionReference cr;
  List<Map<String, dynamic>> productList = [];
  bool isDialogBoxOpen = false;
  bool isDisable = false;
  StreamSubscription<QuerySnapshot> streamSub;

  @override
  initState() {
    super.initState();
    var user = firebaseAuthInstance.currentUser;
    dr = firestoreInstance.collection("Users").doc(user.uid);
    cr = dr.collection('products');
    streamSub = cr.snapshots().listen(
      (snapshot) {
        productList = [];
        cr
            .where('isQRCodeGenerated', isEqualTo: true)
            .orderBy('timestamp', descending: true)
            .get()
            .then(
          (qerySnapshot) {
            qerySnapshot.docs.forEach((result) {
              productList.add(result.data());
            });
            setState(() {
              productList = productList;
              if (isDialogBoxOpen) {
                Navigator.of(context).pop();
                isDialogBoxOpen = false;
              }
            });
          },
        );
      },
    );
  }

  Future<void> _sellProduct(
      String id, String qrData, BuildContext context) async {
    setState(() {
      isDisable = true;
    });
    CollectionReference c = cr.doc(id).collection('QRData');
    return await c.where('data', isEqualTo: qrData).get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        if (result.data()['isScanned']) {
          Navigator.of(context).pop();
          controller.resumeCamera();
          setState(() {
            isDialogBoxOpen = false;
            isDisable = false;
          });
          EdgeAlert.show(context,
              title: 'Product already sold out!',
              gravity: EdgeAlert.TOP,
              backgroundColor: Colors.blue,
              icon: Icons.error_outline_rounded);
        } else if (!result.data()['isScanned']) {
          c
              .doc(result.id)
              .update(
                  {'isScanned': true, 'scannedTime': Timestamp.now().seconds})
              .then((_) => {
                    cr.doc(id).update({
                      'totalQRCode': FieldValue.increment(-1),
                      'scannedTime': Timestamp.now().seconds
                    }),
                    Navigator.of(context).pop(),
                    controller.resumeCamera(),
                    setState(() {
                      isDialogBoxOpen = false;
                      isDisable = false;
                    }),
                    EdgeAlert.show(context,
                        title: 'Product sold!',
                        gravity: EdgeAlert.TOP,
                        backgroundColor: Colors.blue,
                        icon: Icons.done)
                  })
              .catchError((error) => EdgeAlert.show(context,
                  title: error.toString(),
                  gravity: EdgeAlert.TOP,
                  backgroundColor: Colors.blue,
                  icon: Icons.remove));
        }
      });
    });
  }

  Future<void> _saleItPopup(BuildContext context, String id) async {
    String itemName = 'No such item found';
    String sellingPrice = 'NA';
    String quantity = 'NA';
    String boxes = 'NA';
    String itemid = 'NA';
    bool isBoxes = false, isValid = false;
    if (isDialogBoxOpen) return;
    setState(() {
      isDialogBoxOpen = true;
    });

    for (int i = 0; i < productList.length; i++) {
      if (productList[i]['QRCodeData'][0].toString().substring(0, 10) ==
          id.substring(0, 10)) {
        for (int j = 0; j < productList[i]['QRCodeData'].length; j++) {
          var data = productList[i]['QRCodeData'][j];
          if (data.toString() == id) {
            setState(() {
              itemName = productList[i]['itemName'];
              isBoxes = productList[i]['isBoxes'];
              sellingPrice = productList[i]['sellingPrice'].toString();
              quantity = productList[i]['totalQRCode'].toString();
              boxes = productList[i]['totalQRCode'].toString();
              itemid = productList[i]['id'].toString();
              isValid = true;
            });
            break;
          }
        }
      }
    }
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: Text(
                itemName,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.blue,
              elevation: 10,
              content: Container(
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      'MRP : ' + sellingPrice,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    isBoxes
                        ? Text(
                            'Remaining boxes : ' + boxes,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          )
                        : Text(
                            'Remaing quantity : ' + quantity,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          )
                  ],
                ),
              ),
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 15, 0),
                  child: Row(
                    children: [
                      isValid
                          ? RaisedButton(
                              elevation: 5.0,
                              onPressed: () => isDisable
                                  ? ''
                                  : _sellProduct(itemid, id, context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              color: Colors.white,
                              child: Text(
                                'SALE IT',
                                style: TextStyle(
                                  color: Colors.blue,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : SizedBox(
                              width: 0,
                            ),
                      SizedBox(
                        width: 10,
                      ),
                      RaisedButton(
                        elevation: 5.0,
                        onPressed: () => {
                          controller.resumeCamera(),
                          Navigator.pop(context),
                          setState(() {
                            isDialogBoxOpen = false;
                          })
                        },
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
            ),
          );
        });
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (notification) {
          Future.microtask(
              () => controller?.updateDimensions(qrKey, scanArea: scanArea));
          return false;
        },
        child: SizeChangedLayoutNotifier(
            key: const Key('qr-size-notifier'),
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: scanArea,
              ),
            )));
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        if (!isDialogBoxOpen) _saleItPopup(context, result.code);
        controller.pauseCamera();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 1,
            child: _buildQrView(context),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    streamSub.cancel();
    super.dispose();
  }
}
