import 'package:intl/intl.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class ReportExapandablePage extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final BuildContext context;
  final int index;
  final IconData tailIcon;
  final Function onTap;
  final String toolTipMessage;
  final bool isHistoryPage;
  const ReportExapandablePage(
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
  _ReportExapandablePageState createState() => _ReportExapandablePageState();
}

class _ReportExapandablePageState extends State<ReportExapandablePage> {
  List<Widget> _buildList(int index) {
    List<Widget> listTile = [];
    for (int i = 0; i < widget.products[index]['QRData'].length; i++) {
      if (widget.products[index]['QRData'][i]['isScanned'])
        listTile.add(ListTile(
          dense: true,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('dd-MM-yyyy hh:mm a')
                    .format(DateTime.fromMillisecondsSinceEpoch(int.parse(widget
                            .products[index]['QRData'][i]['scannedTime']
                            .toString()) *
                        1000))
                    .toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blue, fontSize: 14),
              ),
            ],
          ),
        ));
    }
    return listTile;
  }

  Widget _buildTiles() {
    bool isBoxes = widget.products[widget.index]['isBoxes'];
    return Container(
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
        children: _buildList(widget.index),
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
