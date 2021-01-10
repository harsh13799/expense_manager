import 'package:flutter/material.dart';

class MyBottomNavBarItem extends StatelessWidget {
  final int id;
  final int active;
  final Function function;
  final String text;
  final IconData icon;
  const MyBottomNavBarItem(
      {Key key, this.active, this.function, this.id, this.text, this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: function,
        borderRadius: BorderRadius.circular(25.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 9.0),
          decoration: BoxDecoration(
            color: active == id ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25.0),
            boxShadow: [
              active == id
                  ? BoxShadow(
                      color: Colors.black45,
                      blurRadius: 6.0,
                      offset: Offset(0, 2),
                    )
                  : BoxShadow(
                      color: Colors.transparent,
                    )
            ],
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                color: active == id ? Colors.blue : Colors.white,
              ),
              active == id ? SizedBox(width: 5) : SizedBox(width: 0),
              active == id
                  ? Text(
                      "$text",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Container()
            ],
          ),
        ),
      ),
    );
  }
}
