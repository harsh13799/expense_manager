import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_share_me/flutter_share_me.dart';
import '../Screens/login_page.dart';
import '../Screens/help_and_support_page.dart';
import '../Screens/settings_page.dart';
import '../Constant/constants.dart';
import '../Screens/history_page.dart';

class ProfileListItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool hasNavigation;
  final int index;

  const ProfileListItem({
    Key key,
    this.icon,
    this.text,
    this.index,
    this.hasNavigation = true,
  }) : super(key: key);

  _logOut(context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      PageTransition(
        duration: Duration(milliseconds: 500),
        type: PageTransitionType.rightToLeft,
        alignment: Alignment.topCenter,
        child: LoginPage(),
      ),
    );
  }

  _onTap(context, int index) {
    switch (index) {
      case 0:
        {
          Navigator.push(
            context,
            PageTransition(
              duration: Duration(milliseconds: 500),
              type: PageTransitionType.rightToLeft,
              alignment: Alignment.topCenter,
              child: HistoryPage(),
            ),
          );
          break;
        }
      case 1:
        {
          Navigator.push(
            context,
            PageTransition(
              duration: Duration(milliseconds: 500),
              type: PageTransitionType.rightToLeft,
              alignment: Alignment.topCenter,
              child: HelpAndSupportPage(),
            ),
          );
          break;
        }
      case 2:
        {
          Navigator.push(
            context,
            PageTransition(
              duration: Duration(milliseconds: 500),
              type: PageTransitionType.rightToLeft,
              alignment: Alignment.topCenter,
              child: SettingsPage(),
            ),
          );
          break;
        }
      case 3:
        {
          FlutterShareMe().shareToWhatsApp(
              msg:
                  'Hi, I am using *Expense Manager* application for my shop. I can track my all items history with the help of *QR Code*. If you are excited and want to join then download it from below link. https://google.com');
          break;
        }
      case 4:
        {
          _logOut(context);
          break;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kSpacingUnit.w * 5.5,
      margin: EdgeInsets.symmetric(
        horizontal: kSpacingUnit.w * 4,
        vertical: kSpacingUnit.h * 2,
      ).copyWith(
        bottom: kSpacingUnit.w * 0.5,
      ),
      child: RaisedButton(
        elevation: 5.0,
        onPressed: () => _onTap(context, this.index),
        padding: EdgeInsets.all(15.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        color: Colors.white,
        child: Row(
          children: <Widget>[
            Icon(
              this.icon,
              size: kSpacingUnit.w * 2.5,
              color: Colors.blue,
            ),
            SizedBox(width: kSpacingUnit.w * 1.5),
            Text(
              this.text,
              style: kTitleTextStyle.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            if (this.hasNavigation)
              Icon(
                LineAwesomeIcons.angle_right,
                size: kSpacingUnit.w * 2.5,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }
}
