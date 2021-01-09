import 'package:bottomnavigatorbar/Screens/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:page_transition/page_transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Constant/constants.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _emailController = new TextEditingController();
  final _passwordController = new TextEditingController();
  final _nameController = new TextEditingController();
  final _phoneNoController = new TextEditingController();
  final _confirmPasswordController = new TextEditingController();

  @override
  initState() {
    super.initState();
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

  String validateField() {
    String error;
    if (_nameController.text.isEmpty) {
      error = 'Please enter the Full Name';
    } else if (_phoneNoController.text.isEmpty) {
      error = 'Please enter the Phone Number';
    } else if (_phoneNoController.text.length != 10) {
      error = 'Please enter the valid Phone Number';
    } else if (_emailController.text.isEmpty) {
      error = 'Please enter the Email';
    } else if (_passwordController.text.isEmpty) {
      error = 'Please enter the Password';
    } else if (_passwordController.text.length < 8) {
      error = 'Please enter the Password';
    } else if (_confirmPasswordController.text.isEmpty) {
      error = 'Please enter the Confirm Password';
    } else if (_confirmPasswordController.text != _passwordController.text) {
      error = 'Confirm Password does not match';
    }
    return error;
  }

  Future<void> doRegisteration(context) async {
    String e = validateField();
    if (e == null) {
      showLoaderDialog(context, 'Please wait...');
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: _emailController.text,
                password: _passwordController.text);
        if (userCredential.user != null) {
          try {
            CollectionReference cr =
                FirebaseFirestore.instance.collection('Users');
            cr.doc(userCredential.user.uid).set({
              "userName": _nameController.text,
              "uId": userCredential.user.uid,
              "email": userCredential.user.email,
              "phoneNo": _phoneNoController.text,
              "qrCodeSize": 60,
              "tableRows": 8,
              "tablePadding": 10,
              "qrFontSize": 8,
            }, SetOptions(merge: true)).then((_) {
              final snackBar =
                  SnackBar(content: Text('Registration Successfully Done'));
              _scaffoldKey.currentState.showSnackBar(snackBar);
              _emailController.text = '';
              _passwordController.text = '';
              _nameController.text = '';
              _confirmPasswordController.text = '';
              _phoneNoController.text = '';
            });
          } catch (e) {
            final snackBar = SnackBar(content: Text(e.toString()));
            _scaffoldKey.currentState.showSnackBar(snackBar);
          }
        }
        userCredential.user.sendEmailVerification();
        Navigator.of(context).pop();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          final snackBar =
              SnackBar(content: Text('The account already exists!'));
          _scaffoldKey.currentState.showSnackBar(snackBar);
        } else {
          final snackBar = SnackBar(content: Text(e.message));
          _scaffoldKey.currentState.showSnackBar(snackBar);
        }
        Navigator.of(context).pop();
      } catch (e) {
        final snackBar = SnackBar(content: Text('Something went wrong'));
        _scaffoldKey.currentState.showSnackBar(snackBar);
        Navigator.of(context).pop();
      }
    } else {
      final snackBar = SnackBar(content: Text(e));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  Widget _buildFullNameTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Full Name',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            style: TextStyle(
              color: Colors.blue,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.person,
                color: Colors.blue,
              ),
              hintText: 'Enter your Full Name',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneNumberTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Phone Number',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            controller: _phoneNoController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: Colors.blue,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.phone_iphone_rounded,
                color: Colors.blue,
              ),
              hintText: 'Enter your Phone Number',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Email',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: Colors.blue,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.email,
                color: Colors.blue,
              ),
              hintText: 'Enter your Email',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Password',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            controller: _passwordController,
            obscureText: true,
            style: TextStyle(
              color: Colors.blue,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.lock,
                color: Colors.blue,
              ),
              hintText: 'Enter your Password',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Confirm Password',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            style: TextStyle(
              color: Colors.blue,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.lock,
                color: Colors.blue,
              ),
              hintText: 'Confirm Password',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpBtn(context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: RaisedButton(
        elevation: 5.0,
        onPressed: () => doRegisteration(context),
        padding: EdgeInsets.all(15.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        color: Colors.white,
        child: Text(
          'REGISTER',
          style: TextStyle(
            color: Colors.blue,
            letterSpacing: 1.5,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginBtn() {
    return GestureDetector(
      onTap: () => Navigator.pop(
        context,
        PageTransition(
            type: PageTransitionType.leftToRight,
            alignment: Alignment.topCenter,
            child: LoginPage()),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Already have an account? ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.w300,
              ),
            ),
            TextSpan(
              text: 'Sign In',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.blueAccent,
          ),
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
                        Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 30.0),
                        _buildFullNameTF(),
                        SizedBox(height: 10.0),
                        _buildPhoneNumberTF(),
                        SizedBox(height: 10.0),
                        _buildEmailTF(),
                        SizedBox(
                          height: 10.0,
                        ),
                        _buildPasswordTF(),
                        SizedBox(
                          height: 10.0,
                        ),
                        _buildConfirmPasswordTF(),
                        SizedBox(
                          height: 20.0,
                        ),
                        _buildSignUpBtn(context),
                        _buildLoginBtn(),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneNoController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
