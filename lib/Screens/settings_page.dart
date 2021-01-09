import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:ui';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Constant/constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _qrSizeController = new TextEditingController();
  final _qrFontSizeController = new TextEditingController();
  final _pdfRowController = new TextEditingController();
  final _pdfPaddingController = new TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;
  FirebaseAuth firebaseAuthInstance = FirebaseAuth.instance;
  DocumentReference dr;

  @override
  initState() {
    super.initState();
    var user = firebaseAuthInstance.currentUser;
    dr = firestoreInstance.collection("Users").doc(user.uid);
    dr.snapshots().listen((snapshot) {
      setState(() {
        _qrSizeController.text = snapshot['qrCodeSize'].toString();
        _pdfRowController.text = snapshot['tableRows'].toString();
        _pdfPaddingController.text = snapshot['tablePadding'].toString();
        _qrFontSizeController.text = snapshot['qrFontSize'].toString();
      });
    });
  }

  pw.Column _column(image, data, mrp) {
    return pw.Column(
      children: <pw.Widget>[
        pw.Container(
          height: 7,
        ),
        pw.ClipRect(
          child: pw.Container(
            width: double.parse(_qrSizeController.text),
            height: double.parse(_qrSizeController.text),
            child: pw.Image.provider(image),
          ),
        ),
        pw.Container(
          height: 2,
        ),
        pw.Text(
          data,
          textAlign: pw.TextAlign.center,
          style:
              pw.TextStyle(fontSize: double.parse(_qrFontSizeController.text)),
        ),
        pw.Container(
          height: 2,
        ),
        pw.Text(
          mrp,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
              fontSize: double.parse(_qrFontSizeController.text) + 2),
        ),
        pw.Container(
          height: 4,
        ),
      ],
    );
  }

  void generateQRCode() async {
    print(_pdfRowController.text);
    String e = validateField();
    if (e == null) {
      //TODO change this
      var data = [
        'It is a long established fact that a',
        'TEMPORARY',
        'TEMPORARY',
        'TEMPORARY',
        'TEMPORARY',
        'TEMPORARY',
        'TEMPORARY',
        'TEMPORARY',
        'TEMPORARY',
        'TEMPORARY',
        'TEMPORARY',
        'TEMPORARY'
      ];
      var data1 = [
        '1000',
        '1000',
        '1000',
        '1000',
        '1000',
        '1000',
        '1000',
        '1000',
        '1000',
        '1000',
        '1000',
        '1000'
      ];
      List<dynamic> qrImages = [];

      for (int i = 0; i < data.length; i++) {
        var qr = await QrPainter(
          data: data[i],
          gapless: true,
          version: QrVersions.auto,
          emptyColor: Colors.white,
        ).toImage(150);

        var a = await qr.toByteData(format: ImageByteFormat.png);
        var image = pw.MemoryImage(a.buffer.asUint8List());
        qrImages.add(image);
      }

      List<pw.TableRow> _temp() {
        List<pw.TableRow> gameCells = List<pw.TableRow>();

        List<pw.Widget> col = new List<pw.Widget>();
        for (int i = 0; i < data.length; i++) {
          if (i == data.length - 1) {
            gameCells.add(pw.TableRow(children: col));
          } else if (i >= double.parse(_pdfRowController.text) &&
              i % double.parse(_pdfRowController.text) == 0) {
            // changes the row here
            gameCells.add(pw.TableRow(children: col));
            col = new List<pw.Widget>();
          }
          col.add(_column(qrImages[i], data[i], data1[i]));
        }
        return gameCells;
      }

      final pdf = pw.Document();

      pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(
              double.parse(_pdfPaddingController.text)), // chaange the margin
          build: (pw.Context context) {
            return <pw.Widget>[
              pw.Table(
                defaultColumnWidth: pw.FixedColumnWidth(50.0),
                border: pw.TableBorder.all(),
                children: _temp(),
              )
            ];
          }));

      Directory path = await getExternalStorageDirectory();
      final file = File("${path.path}/Preview.pdf");
      print(path.path);
      await file.writeAsBytes(pdf.save());
      final snackBar = SnackBar(
        content: Text(
            'Preview.pdf created. Please preview it \/data\/com.example.expese_manager\/files'),
        duration: Duration(seconds: 4),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
    } else {
      final snackBar = SnackBar(content: Text(e));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  Future<void> _saveSettings() async {
    String e = validateField();
    if (e == null) {
      dr.set({
        "qrCodeSize": int.parse(_qrSizeController.text),
        "tableRows": int.parse(_pdfRowController.text),
        "tablePadding": int.parse(_pdfPaddingController.text),
        "qrFontSize": int.parse(_qrFontSizeController.text),
      }, SetOptions(merge: true)).then((_) {
        final snackBar = SnackBar(content: Text('Settings saved successfully'));
        _scaffoldKey.currentState.showSnackBar(snackBar);
      });
    } else {
      final snackBar = SnackBar(content: Text(e));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  String validateField() {
    String error;
    if (_qrSizeController.text.isEmpty) {
      error = 'Please enter QR code size';
    } else if (int.parse(_qrSizeController.text) < 0) {
      error = 'Please enter the valid QR code size';
    } else if (_qrFontSizeController.text.isEmpty) {
      error = 'Please enter Font size';
    } else if (int.parse(_qrFontSizeController.text) < 0) {
      error = 'Please enter the valid Font size';
    } else if (_pdfRowController.text.isEmpty) {
      error = 'Please enter the Row number';
    } else if (int.parse(_pdfRowController.text) < 0) {
      error = 'Please enter the valid the Row number';
    } else if (_pdfPaddingController.text.isEmpty) {
      error = 'Please enter the Padding size';
    } else if (int.parse(_pdfPaddingController.text) < 0) {
      error = 'Please enter the valid Padding size';
    }
    return error;
  }

  Widget _buildSizeTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Size',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            keyboardType: TextInputType.number,
            controller: _qrSizeController,
            style: TextStyle(
              color: Colors.blue,
            ),
            decoration: InputDecoration(
              errorStyle: TextStyle(
                fontSize: 16.0,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.format_size,
                color: Colors.blue,
              ),
              hintText: 'Enter the QR code size',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Font Size',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            keyboardType: TextInputType.number,
            controller: _qrFontSizeController,
            style: TextStyle(
              color: Colors.blue,
            ),
            decoration: InputDecoration(
              errorStyle: TextStyle(
                fontSize: 16.0,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.format_size,
                color: Colors.blue,
              ),
              hintText: 'Enter the Font size',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRowTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Rows',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            keyboardType: TextInputType.number,
            controller: _pdfRowController,
            style: TextStyle(
              color: Colors.blue,
            ),
            decoration: InputDecoration(
              errorStyle: TextStyle(
                fontSize: 16.0,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.table_view,
                color: Colors.blue,
              ),
              hintText: 'Enter the Rows in single column',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaddingTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Padding',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            keyboardType: TextInputType.number,
            controller: _pdfPaddingController,
            style: TextStyle(
              color: Colors.blue,
            ),
            decoration: InputDecoration(
              errorStyle: TextStyle(
                fontSize: 16.0,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.padding,
                color: Colors.blue,
              ),
              hintText: 'Enter the Padding size',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveBtn() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RaisedButton(
            elevation: 5.0,
            onPressed: () => generateQRCode(),
            padding: EdgeInsets.all(15.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            color: Colors.white,
            child: Text(
              'PREVIEW PDF',
              style: TextStyle(
                color: Colors.blue,
                letterSpacing: 1.5,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          RaisedButton(
            elevation: 5.0,
            onPressed: () => _saveSettings(),
            padding: EdgeInsets.all(15.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            color: Colors.white,
            child: Text(
              'SAVE',
              style: TextStyle(
                color: Colors.blue,
                letterSpacing: 1.5,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: <Widget>[
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: <Widget>[
                  // Container(
                  //   height: double.infinity,
                  //   width: double.infinity,
                  //   decoration: BoxDecoration(
                  //     gradient: LinearGradient(
                  //       begin: Alignment.topCenter,
                  //       end: Alignment.bottomCenter,
                  //       colors: [
                  //         Color(0xFF80aeff),
                  //         Color(0xFF669eff),
                  //         Color(0xFF4d8eff),
                  //         Color(0xFF448aff),
                  //       ],
                  //       stops: [0.1, 0.4, 0.7, 0.9],
                  //     ),
                  //   ),
                  // ),
                  Container(
                    color: Colors.blue,
                    height: double.infinity,
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 40.0,
                        vertical: 40.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              header(context),
                              Text(
                                'Settings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.0),
                          Text(
                            'QR Code Settings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                            ),
                          ),
                          Divider(
                            color: Colors.white,
                          ),
                          _buildSizeTF(),
                          SizedBox(
                            height: 10.0,
                          ),
                          _buildFontSizeTF(),
                          SizedBox(
                            height: 30.0,
                          ),
                          Text(
                            'PDF Settings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                            ),
                          ),
                          Divider(
                            color: Colors.white,
                          ),
                          _buildRowTF(),
                          SizedBox(
                            height: 10.0,
                          ),
                          _buildPaddingTF(),
                          SizedBox(
                            height: 10.0,
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'Note: Please enter the valid Size and Rows. This can destroy the view of PDF.\nThe ideal QR Code Size is 60 and Font Size is 8 with PDF Rows 8 and Padding 10.',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 30.0,
                          ),
                          _buildSaveBtn(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _qrSizeController.dispose();
    _pdfRowController.dispose();
    _pdfPaddingController.dispose();
    _qrFontSizeController.dispose();
    super.dispose();
  }
}
