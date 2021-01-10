import 'dart:async';
import 'package:flutter/material.dart';
import '../Constant/constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/expandable_list_view.dart';

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

  @override
  initState() {
    super.initState();
    new Future.delayed(Duration.zero, () {
      showLoaderDialog(context, 'Fetching Data...');
    });
    var user = firebaseAuthInstance.currentUser;
    dr = firestoreInstance.collection("Users").doc(user.uid);
    cr = dr.collection('products');
    streamSub = cr.snapshots().listen((snapshot) {
      productList = [];
      cr
          .where('isQRCodeGenerated', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get()
          .then((qerySnapshot) {
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
      });
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.blue,
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 40,
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 40.0,
            ),
            child: Row(
              children: <Widget>[
                header(context),
                Text(
                  'History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Divider(
            height: 1,
            indent: 30,
            endIndent: 30,
            color: Colors.white24,
          ),
          Expanded(
            child: productList.length > 0
                ? ListView.builder(
                    itemBuilder: (BuildContext context, int index) {
                      return ExpandableListView(
                          products: productList,
                          index: index,
                          context: context,
                          tailIcon: Icons.refresh_rounded,
                          toolTipMessage: 'Add Back to product list',
                          isHistoryPage: true,
                          onTap: () => _addBackPopup(context,
                              productList[index]['id'].toString(), index));
                    },
                    itemCount: productList.length,
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
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    streamSub.cancel();
    super.dispose();
  }
}
