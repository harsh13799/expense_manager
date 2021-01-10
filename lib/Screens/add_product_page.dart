import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Constant/constants.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:edge_alert/edge_alert.dart';
import 'package:uuid/uuid.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _ddCategoryKey = GlobalKey<DropdownSearchState<String>>();
  final _ddSubCategoryKey = GlobalKey<DropdownSearchState<String>>();
  final _categoryTextController = new TextEditingController();
  final _subCategoryTextController = new TextEditingController();
  final _itemTextController = new TextEditingController();
  final _boxesTextController = new TextEditingController();
  final _quantityTextController = new TextEditingController();
  final _purchaseTextController = new TextEditingController();
  final _expenseTextController = new TextEditingController();
  final _sellingTextController = new TextEditingController();
  FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;
  FirebaseAuth firebaseAuthInstance = FirebaseAuth.instance;
  DocumentReference dr;
  List<String> categoryItems;
  List<String> subCategoryItems;
  bool isCategorySelected = false;
  bool isSubCategorySelected = false;
  bool _isBoxes = false;
  StreamSubscription<DocumentSnapshot> streamSub;

  var userMap = {};

  @override
  initState() {
    super.initState();
    var user = firebaseAuthInstance.currentUser;
    dr = firestoreInstance.collection("Users").doc(user.uid);
    streamSub = dr.snapshots().listen((snapshot) {
      setState(() {
        categoryItems = List<String>.from(snapshot['category']);
        subCategoryItems = List<String>.from(snapshot['subCategory']);
      });
    });
  }

  showLoaderDialog(BuildContext context, String text) {
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

  List<String> _getQRCodedata() {
    List<String> data = [];
    int totalQRCodeCount = 0;
    String itemName;
    if (_itemTextController.text.substring(0, 3).contains(' ')) {
      itemName = _itemTextController.text.replaceAll(' ', '');
    } else {
      itemName = _itemTextController.text;
    }
    String _s0 = _isBoxes ? 'B' : 'Q';
    String _s1 = _categoryTextController.text.substring(0, 3).toUpperCase() +
        _subCategoryTextController.text.substring(0, 3).toUpperCase() +
        itemName.substring(0, 3).toUpperCase();
    if (_isBoxes) {
      totalQRCodeCount = int.parse(_boxesTextController.text);
    } else {
      totalQRCodeCount = int.parse(_quantityTextController.text);
    }
    for (int i = 0; i < totalQRCodeCount; i++) {
      data.add(_s0 + _s1 + Uuid().v4().substring(28));
    }
    return data;
  }

  Future<void> _addProduct(context) async {
    String e = validateField();
    if (e == null) {
      showLoaderDialog(context, 'Please Wait...');
      DocumentReference postRef = dr.collection('products').doc();
      postRef.set({
        'id': postRef.id,
        'category': _categoryTextController.text,
        'subCategory': _subCategoryTextController.text,
        'itemName': _itemTextController.text,
        'isBoxes': _isBoxes,
        'boxes': _isBoxes ? int.parse(_boxesTextController.text) : 0,
        'quantity': int.parse(_quantityTextController.text),
        'purchasePrice': int.parse(_purchaseTextController.text),
        'expenses': int.parse(_expenseTextController.text),
        'sellingPrice': int.parse(_sellingTextController.text),
        'timestamp': Timestamp.now().seconds,
        'date': DateTime.now(),
        'totalPrice': (int.parse(_purchaseTextController.text) +
            int.parse(_expenseTextController.text)),
        'totalQuantity': _isBoxes
            ? (int.parse(_boxesTextController.text) *
                int.parse(_quantityTextController.text))
            : int.parse(_quantityTextController.text),
        'totalQRCode': _isBoxes
            ? int.parse(_boxesTextController.text)
            : int.parse(_quantityTextController.text),
        'isQRCodeGenerated': false,
        'QRCodeData': _getQRCodedata(),
      }, SetOptions(merge: true)).then((_) {
        Navigator.of(context).pop();
        EdgeAlert.show(context,
            title: 'Product added successfully',
            gravity: EdgeAlert.TOP,
            backgroundColor: Colors.blue,
            icon: Icons.done);
        setState(() {
          _categoryTextController.text = '';
          _subCategoryTextController.text = '';
          _itemTextController.text = '';
          _boxesTextController.text = '';
          _quantityTextController.text = '';
          _purchaseTextController.text = '';
          _expenseTextController.text = '';
          _sellingTextController.text = '';
          _isBoxes = false;
          _ddCategoryKey.currentState.changeSelectedItem(null);
          _ddSubCategoryKey.currentState.changeSelectedItem(null);
        });
      });
    } else {
      EdgeAlert.show(context,
          title: e,
          gravity: EdgeAlert.TOP,
          backgroundColor: Colors.blue,
          icon: Icons.error_outline_rounded);
    }
  }

  String validateField() {
    String error;
    if (_categoryTextController.text.isEmpty) {
      error = 'Please select Category';
    } else if (_subCategoryTextController.text.isEmpty) {
      error = 'Please select Sub Category';
    } else if (_itemTextController.text.isEmpty) {
      error = 'Please enter the Item name';
    } else if (_itemTextController.text.toString().length < 3) {
      error = 'Item name should be more then 3 characters';
    } else if (_isBoxes && _boxesTextController.text.isEmpty) {
      error = 'Please enter the Boxes number';
    } else if (_isBoxes && int.parse(_boxesTextController.text) < 0) {
      error = 'Please enter the valid Boxes number';
    } else if (_quantityTextController.text.isEmpty) {
      error = 'Please enter the Quantity';
    } else if (int.parse(_quantityTextController.text) < 0) {
      error = 'Please enter the valid Quantity';
    } else if (_purchaseTextController.text.isEmpty) {
      error = 'Please enter the Purchase Price';
    } else if (int.parse(_purchaseTextController.text) < 0) {
      error = 'Please enter the valid Purchase Price';
    } else if (_expenseTextController.text.isEmpty) {
      error = 'Please enter the Expenses';
    } else if (int.parse(_expenseTextController.text) < 0) {
      error = 'Please enter the valid Expenses';
    } else if (_sellingTextController.text.isEmpty) {
      error = 'Please enter the Selling Price';
    } else if (int.parse(_sellingTextController.text) < 0) {
      error = 'Please enter the valid Selling Price';
    }
    return error;
  }

  _catDropDownChange(String value) {
    setState(() {
      if (value != null) {
        isCategorySelected = true;
        _categoryTextController.text = value;
      } else {
        isCategorySelected = false;
        _categoryTextController.text = '';
      }
    });
  }

  _subDropDownChange(String value) {
    setState(() {
      if (value != null) {
        isSubCategorySelected = true;
        _subCategoryTextController.text = value;
      } else {
        isSubCategorySelected = false;
        _subCategoryTextController.text = '';
      }
    });
  }

  _deleteCategory(context) {
    if (_categoryTextController.text.toString() != '') {
      dr.set({
        "category": FieldValue.arrayRemove([_categoryTextController.text]),
      }, SetOptions(merge: true)).then((_) {
        _ddCategoryKey.currentState.changeSelectedItem(null);
        _categoryTextController.text = '';
        isCategorySelected = false;
      });
      Navigator.pop(context);
    } else {
      EdgeAlert.show(context,
          title: 'Please enter Category',
          gravity: EdgeAlert.TOP,
          backgroundColor: Colors.blue,
          icon: Icons.error_outline_rounded);
    }
  }

  _addCategory(context) {
    if (_categoryTextController.text.toString() != '') {
      if (_categoryTextController.text.toString().length > 3) {
        dr.set({
          'category': FieldValue.arrayUnion([_categoryTextController.text]),
        }, SetOptions(merge: true)).then((_) {
          _categoryTextController.text = '';
        });
        Navigator.pop(context);
      } else {
        EdgeAlert.show(context,
            title: 'Category name should be more then 3 characters',
            gravity: EdgeAlert.TOP,
            backgroundColor: Colors.blue,
            icon: Icons.error_outline_rounded);
      }
    } else {
      EdgeAlert.show(context,
          title: 'Please enter Category',
          gravity: EdgeAlert.TOP,
          backgroundColor: Colors.blue,
          icon: Icons.error_outline_rounded);
    }
  }

  _deleteSubCategory(context) {
    if (_subCategoryTextController.text.toString() != '') {
      dr.set({
        "subCategory":
            FieldValue.arrayRemove([_subCategoryTextController.text]),
      }, SetOptions(merge: true)).then((_) {
        _ddSubCategoryKey.currentState.changeSelectedItem(null);
        _subCategoryTextController.text = '';
        isSubCategorySelected = false;
      });
      Navigator.pop(context);
    } else {
      EdgeAlert.show(context,
          title: 'Please enter Sub Category',
          gravity: EdgeAlert.TOP,
          backgroundColor: Colors.blue,
          icon: Icons.error_outline_rounded);
    }
  }

  _addSubCategory(context) {
    if (_subCategoryTextController.text.toString() != '') {
      if (_subCategoryTextController.text.toString().length > 3) {
        dr.set({
          'subCategory':
              FieldValue.arrayUnion([_subCategoryTextController.text]),
        }, SetOptions(merge: true)).then((_) {
          _subCategoryTextController.text = '';
        });
        Navigator.pop(context);
      } else {
        EdgeAlert.show(context,
            title: 'Sub Category name should be more then 3 characters',
            gravity: EdgeAlert.TOP,
            backgroundColor: Colors.blue,
            icon: Icons.error_outline_rounded);
      }
    } else {
      EdgeAlert.show(context,
          title: 'Please enter Sub Category',
          gravity: EdgeAlert.TOP,
          backgroundColor: Colors.blue,
          icon: Icons.error_outline_rounded);
    }
  }

  Future<void> _displayCatTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              isCategorySelected ? 'Delete Category' : 'Add Category',
              style: TextStyle(color: Colors.white),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.blue,
            elevation: 10,
            content: Container(
              alignment: Alignment.centerLeft,
              decoration: kBoxDecorationStyle,
              height: 60.0,
              child: TextField(
                controller: _categoryTextController,
                enabled: !isCategorySelected,
                keyboardType: TextInputType.name,
                style: TextStyle(
                  color: Colors.blue,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 14.0),
                  prefixIcon: Icon(
                    Icons.category,
                    color: Colors.blue,
                  ),
                  hintText: 'Enter the Category',
                  hintStyle: kHintTextStyle,
                ),
              ),
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 15, 0),
                child: RaisedButton(
                  elevation: 5.0,
                  onPressed: () => {
                    isCategorySelected
                        ? _deleteCategory(context)
                        : _addCategory(context)
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  color: Colors.white,
                  child: Text(
                    isCategorySelected ? 'DELETE' : 'ADD',
                    style: TextStyle(
                      color: Colors.blue,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        });
  }

  Future<void> _displaySubTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              isSubCategorySelected
                  ? 'Delete Sub Category'
                  : 'Add Sub Category',
              style: TextStyle(color: Colors.white),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.blue,
            elevation: 10,
            content: Container(
              alignment: Alignment.centerLeft,
              decoration: kBoxDecorationStyle,
              height: 60.0,
              child: TextField(
                controller: _subCategoryTextController,
                enabled: !isSubCategorySelected,
                keyboardType: TextInputType.name,
                style: TextStyle(
                  color: Colors.blue,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 14.0),
                  prefixIcon: Icon(
                    Icons.category,
                    color: Colors.blue,
                  ),
                  hintText: 'Enter the Sub Category',
                  hintStyle: kHintTextStyle,
                ),
              ),
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 15, 0),
                child: RaisedButton(
                  elevation: 5.0,
                  onPressed: () => {
                    isSubCategorySelected
                        ? _deleteSubCategory(context)
                        : _addSubCategory(context)
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  color: Colors.white,
                  child: Text(
                    isSubCategorySelected ? 'DELETE' : 'ADD',
                    style: TextStyle(
                      color: Colors.blue,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        });
  }

  Widget _buildCategory() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SizedBox(
            height: 60,
            child: DropdownSearch<String>(
              key: _ddCategoryKey,
              dropdownSearchDecoration: InputDecoration(
                contentPadding: EdgeInsets.only(left: 15.0, top: 10.0),
                filled: true,
                fillColor: Colors.white,
                focusColor: Colors.white,
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 16,
                    color: Colors.blue),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black45),
                  borderRadius: new BorderRadius.circular(10.0),
                ),
                border: new OutlineInputBorder(
                  borderRadius: new BorderRadius.circular(10.0),
                ),
              ),
              mode: Mode.BOTTOM_SHEET,
              showSelectedItem: true,
              showSearchBox: true,
              showClearButton: true,
              items: categoryItems,
              label: "Category",
              onChanged: (v) => {_catDropDownChange(v)},
              searchBoxDecoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.fromLTRB(12, 12, 8, 0),
                labelText: "Search a category",
              ),
            ),
          ),
        ),
        SizedBox(
          width: 10,
        ),
        Container(
          alignment: Alignment.center,
          height: 60,
          width: 60,
          child: RaisedButton(
            elevation: 5.0,
            onPressed: () => _displayCatTextInputDialog(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            color: Colors.white,
            child: Icon(
              isCategorySelected ? Icons.delete : Icons.add,
              color: Colors.blue,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubCategory() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SizedBox(
            height: 60,
            child: DropdownSearch<String>(
              key: _ddSubCategoryKey,
              mode: Mode.BOTTOM_SHEET,
              dropdownSearchDecoration: InputDecoration(
                contentPadding: EdgeInsets.only(left: 15.0, top: 10.0),
                filled: true,
                fillColor: Colors.white,
                focusColor: Colors.white,
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 16,
                    color: Colors.blue),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black45),
                  borderRadius: new BorderRadius.circular(10.0),
                ),
                border: new OutlineInputBorder(
                  borderRadius: new BorderRadius.circular(10.0),
                ),
              ),
              showSelectedItem: true,
              showSearchBox: true,
              showClearButton: true,
              items: subCategoryItems,
              label: "Sub Category",
              onChanged: (v) => {_subDropDownChange(v)},
              searchBoxDecoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.fromLTRB(12, 12, 8, 0),
                labelText: "Search a sub category",
              ),
            ),
          ),
        ),
        SizedBox(
          width: 10,
        ),
        Container(
          alignment: Alignment.center,
          height: 60,
          width: 60,
          child: RaisedButton(
            elevation: 5.0,
            onPressed: () => _displaySubTextInputDialog(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            color: Colors.white,
            child: Icon(
              isSubCategorySelected ? Icons.delete : Icons.add,
              color: Colors.blue,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Item',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            controller: _itemTextController,
            keyboardType: TextInputType.name,
            style: TextStyle(
              color: Colors.blue,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.book,
                color: Colors.blue,
              ),
              hintText: 'Enter Item Name',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildisBoxesCheckbox() {
    return Container(
      height: 20.0,
      child: Row(
        children: <Widget>[
          Theme(
            data: ThemeData(unselectedWidgetColor: Colors.white),
            child: Checkbox(
              value: _isBoxes,
              checkColor: Colors.blue,
              activeColor: Colors.white,
              onChanged: (value) {
                setState(() {
                  _isBoxes = value;
                });
              },
            ),
          ),
          Text(
            'Is Boxes?',
            style: kLabelStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityCategory() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Boxes',
                style: kLabelStyle,
              ),
              SizedBox(height: 10.0),
              Container(
                alignment: Alignment.centerLeft,
                decoration: kBoxDecorationStyle,
                height: 60.0,
                child: TextField(
                  controller: _boxesTextController,
                  enabled: _isBoxes,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: _isBoxes ? Colors.blue : Colors.grey,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 14.0),
                    prefixIcon: Icon(
                      LineAwesomeIcons.boxes,
                      color: _isBoxes ? Colors.blue : Colors.grey,
                    ),
                    hintText: 'Enter Boxes',
                    hintStyle: _isBoxes
                        ? kHintTextStyle
                        : TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w300,
                            fontFamily: 'OpenSans',
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 10,
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Quantity',
                style: kLabelStyle,
              ),
              SizedBox(height: 10.0),
              Container(
                alignment: Alignment.centerLeft,
                decoration: kBoxDecorationStyle,
                height: 60.0,
                child: TextField(
                  controller: _quantityTextController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: Colors.blue,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 14.0),
                    prefixIcon: Icon(
                      LineAwesomeIcons.box,
                      color: Colors.blue,
                    ),
                    hintText: 'Enter Quantity',
                    hintStyle: kHintTextStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Purchase Price',
                style: kLabelStyle,
              ),
              SizedBox(height: 10.0),
              Container(
                alignment: Alignment.centerLeft,
                decoration: kBoxDecorationStyle,
                height: 60.0,
                child: TextField(
                  controller: _purchaseTextController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: Colors.blue,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 14.0),
                    prefixIcon: Icon(
                      Icons.money_rounded,
                      color: Colors.blue,
                    ),
                    hintText: 'Enter Purchase Price',
                    hintStyle: kHintTextStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 10,
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Expenses',
                style: kLabelStyle,
              ),
              SizedBox(height: 10.0),
              Container(
                alignment: Alignment.centerLeft,
                decoration: kBoxDecorationStyle,
                height: 60.0,
                child: TextField(
                  controller: _expenseTextController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: Colors.blue,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 14.0),
                    prefixIcon: Icon(
                      Icons.money_off_rounded,
                      color: Colors.blue,
                    ),
                    hintText: 'Enter Extra Expenses',
                    hintStyle: kHintTextStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSellingPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Selling Price',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            controller: _sellingTextController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: Colors.blue,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.equalizer,
                color: Colors.blue,
              ),
              hintText: 'Enter Selling Price',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddProductBtn(context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: RaisedButton(
        elevation: 5.0,
        onPressed: () => _addProduct(context),
        padding: EdgeInsets.all(15.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        color: Colors.white,
        child: Text(
          'ADD PRODUCT',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.blue,
          ),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: <Widget>[
                Container(
                  color: Colors.blue,
                  height: double.infinity,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 40.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: 30.0),
                        _buildCategory(),
                        SizedBox(height: 10.0),
                        _buildSubCategory(),
                        SizedBox(height: 10.0),
                        _buildItemCategory(),
                        SizedBox(
                          height: 20.0,
                        ),
                        Divider(
                          height: 1,
                          indent: 30,
                          endIndent: 30,
                          color: Colors.white24,
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        _buildisBoxesCheckbox(),
                        SizedBox(
                          height: 5.0,
                        ),
                        _buildQuantityCategory(),
                        SizedBox(
                          height: 20.0,
                        ),
                        Divider(
                          height: 1,
                          indent: 30,
                          endIndent: 30,
                          color: Colors.white24,
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        _buildPrice(),
                        SizedBox(
                          height: 10.0,
                        ),
                        _buildSellingPrice(),
                        SizedBox(
                          height: 20.0,
                        ),
                        _buildAddProductBtn(context),
                        SizedBox(
                          height: 50.0,
                        ),
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
    _categoryTextController.dispose();
    _subCategoryTextController.dispose();
    _itemTextController.dispose();
    _boxesTextController.dispose();
    _quantityTextController.dispose();
    _purchaseTextController.dispose();
    _expenseTextController.dispose();
    _sellingTextController.dispose();
    streamSub.cancel();
    super.dispose();
  }
}
