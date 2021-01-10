import 'package:flutter/material.dart';
import './Screens/add_product_page.dart';
import './Screens/my_profile_page.dart';
import './Screens/home_page.dart';
import './Screens/generate_qr_page.dart';
import './Screens/sale_it_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './Screens/login_page.dart';
import 'package:page_transition/page_transition.dart';
import './widgets/mybottomnavbaritem.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      //|| !auth.currentUser.emailVerified
      Navigator.pushReplacement(
        context,
        PageTransition(
          duration: Duration(milliseconds: 500),
          type: PageTransitionType.scale,
          alignment: Alignment.topCenter,
          child: LoginPage(),
        ),
      );
    }
  }

  int _currentIndex = 2;

  Widget getPage(index) {
    if (index == 0) {
      return MyCardsPage();
    } else if (index == 1) {
      return AddProductPage();
    } else if (index == 2) {
      return SaleItPage();
    } else if (index == 3) {
      return GenerateQRPage();
    } else if (index == 4) {
      return MyProfilePage();
    } else {}
    return MyCardsPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Container(
              child: getPage(_currentIndex),
            ),
            Positioned(
              bottom: 0,
              height: 65,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25.0),
                    topRight: Radius.circular(25.0),
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 10.0,
                      offset: Offset(0, -2),
                    ),
                  ],
                  color: Colors.blue,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(11.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      MyBottomNavBarItem(
                        active: _currentIndex,
                        id: 0,
                        icon: Icons.home_filled,
                        text: "Home",
                        function: () {
                          setState(() {
                            _currentIndex = 0;
                          });
                        },
                      ),
                      MyBottomNavBarItem(
                        active: _currentIndex,
                        id: 1,
                        icon: Icons.add_business,
                        text: "Product",
                        function: () {
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                      ),
                      MyBottomNavBarItem(
                        active: _currentIndex,
                        id: 2,
                        icon: Icons.qr_code_rounded,
                        text: "Scan",
                        function: () {
                          setState(() {
                            _currentIndex = 2;
                          });
                        },
                      ),
                      MyBottomNavBarItem(
                        active: _currentIndex,
                        id: 3,
                        icon: Icons.download_rounded,
                        text: "Download",
                        function: () {
                          setState(() {
                            _currentIndex = 3;
                          });
                        },
                      ),
                      MyBottomNavBarItem(
                        active: _currentIndex,
                        id: 4,
                        icon: Icons.account_box_rounded,
                        text: "Profile",
                        function: () {
                          setState(() {
                            _currentIndex = 4;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
