import 'package:flutter/material.dart';

import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class ExpandableListView extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final BuildContext context;
  final int index;
  final IconData tailIcon;
  final Function onTap;
  final String toolTipMessage;
  final bool isHistoryPage;
  const ExpandableListView(
      {Key key,
      this.products,
      this.context,
      this.index,
      this.onTap,
      this.toolTipMessage,
      this.tailIcon,
      this.isHistoryPage})
      : super(key: key);
  @override
  _ExpandableListViewState createState() => _ExpandableListViewState();
}

class _ExpandableListViewState extends State<ExpandableListView> {
  Widget _buildTiles() {
    bool isBoxes = widget.products[widget.index]['isBoxes'];
    int totalScanned = 0;
    if (isBoxes) {
      totalScanned = widget.products[widget.index]['boxes'] -
          widget.products[widget.index]['totalQRCode'];
    } else {
      totalScanned = widget.products[widget.index]['quantity'] -
          widget.products[widget.index]['totalQRCode'];
    }

    return Container(
      // padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 9.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 6.0,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: ExpansionTile(
        key: PageStorageKey(widget.products[widget.index]['id']),
        initiallyExpanded: false,
        leading: isBoxes
            ? Icon(
                LineAwesomeIcons.boxes,
                size: 32,
                color: Colors.blue,
              )
            : Icon(
                LineAwesomeIcons.box,
                size: 32,
                color: Colors.blue,
              ),
        title: Text(
          widget.products[widget.index]['itemName'],
          style: TextStyle(
              color: Colors.blue, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        children: <Widget>[
          ListTile(
            dense: true,
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isBoxes
                      ? widget.products[widget.index]['boxes'].toString()
                      : widget.products[widget.index]['quantity'].toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                isBoxes
                    ? Text(
                        '(' +
                            widget.products[widget.index]['quantity']
                                .toString() +
                            ')',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w300),
                      )
                    : SizedBox(
                        width: 0,
                      ),
              ],
            ),
            title: Row(
              children: [
                Text(
                  widget.products[widget.index]['category'],
                  textAlign: TextAlign.left,
                  style: TextStyle(color: Colors.blue, fontSize: 18),
                ),
                Text(
                  ' (' + widget.products[widget.index]['subCategory'] + ')',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w300),
                ),
              ],
            ),
            trailing: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(25.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5.0, vertical: 5.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  child: Tooltip(
                    message: widget.toolTipMessage,
                    child: Icon(
                      widget.tailIcon,
                      size: 26,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
            subtitle: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹' +
                            widget.products[widget.index]['purchasePrice']
                                .toString(),
                        style: TextStyle(
                            color: Colors.blue,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        ' + ₹' +
                            widget.products[widget.index]['expenses']
                                .toString(),
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 18,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '₹' +
                            widget.products[widget.index]['sellingPrice']
                                .toString(),
                        style: TextStyle(
                            color: Colors.blue,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  widget.isHistoryPage
                      ? Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              totalScanned.toString() + ' Scanned',
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300),
                            ),
                          ],
                        )
                      : SizedBox(
                          height: 0,
                        )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
      child: _buildTiles(),
    );
  }
}
