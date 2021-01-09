import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Constant/constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class HelpAndSupportPage extends StatefulWidget {
  @override
  _HelpAndSupportPageState createState() => _HelpAndSupportPageState();
}

class _HelpAndSupportPageState extends State<HelpAndSupportPage> {
  final _emailController = new TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String validateField() {
    String error;
    if (_emailController.text.isEmpty) {
      error = 'Please enter the Email';
    }
    return error;
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
        child: GestureDetector(
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
                            'Help And Support',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30.0),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'This app is under development. If any issue found then please contact us on harshspatel13799@gmail.com',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
