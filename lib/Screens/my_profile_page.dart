import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../Constant/constants.dart';
import '../widgets/profile_list_item.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class MyProfilePage extends StatefulWidget {
  @override
  _MyProfilePageState createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  String userName = 'Guest User';
  String email = 'temp@gmail.com';

  @override
  initState() {
    super.initState();
    new Future.delayed(Duration.zero, () {
      showLoaderDialog(context, 'Please wait...');
    });
    FirebaseAuth auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      DocumentReference dr = FirebaseFirestore.instance
          .collection('Users')
          .doc(auth.currentUser.uid);
      dr.snapshots().listen((snapshot) {
        setState(() {
          userName = snapshot['userName'].toString();
          email = snapshot['email'].toString();
          Navigator.pop(context);
        });
      });
    } else {
      Navigator.pop(context);
    }
  }

  showLoaderDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, height: 896, width: 414, allowFontScaling: true);
    var profileInfo = Expanded(
      child: Column(
        children: <Widget>[
          Container(
            height: kSpacingUnit.w * 10,
            width: kSpacingUnit.w * 10,
            margin: EdgeInsets.only(top: kSpacingUnit.w * 1),
            child: Stack(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kSpacingUnit.w * 5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10.0,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: kSpacingUnit.w * 5,
                    backgroundImage: AssetImage('Assets/Images/avatar.png'),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: GestureDetector(
                    child: Container(
                      height: kSpacingUnit.w * 2.5,
                      width: kSpacingUnit.w * 2.5,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        heightFactor: kSpacingUnit.w * 1.5,
                        widthFactor: kSpacingUnit.w * 1.5,
                        child: Icon(
                          LineAwesomeIcons.pen,
                          color: Colors.blue,
                          size: ScreenUtil().setSp(kSpacingUnit.w * 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: kSpacingUnit.w * 2),
          Text(
            userName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              fontFamily: 'OpenSans',
            ),
          ),
          SizedBox(height: kSpacingUnit.w * 0.5),
          Text(
            email,
            style: kCaptionTextStyle,
          ),
          SizedBox(height: kSpacingUnit.w * 2),
        ],
      ),
    );

    var header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: kSpacingUnit.w * 3),
        profileInfo,
        SizedBox(width: kSpacingUnit.w * 3),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.blue,
      body: Column(
        children: <Widget>[
          SizedBox(height: kSpacingUnit.w * 2),
          header,
          Divider(
            height: 0.5,
            indent: 30,
            endIndent: 30,
            color: Colors.white24,
          ),
          Expanded(
            child: ListView(
              children: <Widget>[
                ProfileListItem(
                  icon: LineAwesomeIcons.history,
                  text: 'History',
                  index: 0,
                ),
                ProfileListItem(
                  icon: LineAwesomeIcons.question_circle,
                  text: 'Help & Support',
                  index: 1,
                ),
                ProfileListItem(
                  icon: LineAwesomeIcons.cog,
                  text: 'Settings',
                  index: 2,
                ),
                ProfileListItem(
                  icon: LineAwesomeIcons.share,
                  text: 'Share',
                  index: 3,
                ),
                ProfileListItem(
                  icon: LineAwesomeIcons.alternate_sign_out,
                  text: 'Logout',
                  index: 4,
                  hasNavigation: false,
                ),
              ],
            ),
          ),
          SizedBox(height: 64),
        ],
      ),
    );
  }
}
