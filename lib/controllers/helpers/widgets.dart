import 'package:flutter/material.dart';
import 'package:mikronet/controllers/helpers/functions.dart';

class MySelectedMenu extends StatefulWidget {
  final List items;
  final String hintText;
  final String emptyText;
  final String selectedKeyName;
  final String selectedValueName;
   dynamic value;
  final Function onSave;
  final Color? bgColor;
  final TextStyle textStyle;
  final Border? border;
  final double width;
  final String? mainValue;
  final double borderRadiusCircular;
  final Widget icon;
   MySelectedMenu(
      {super.key,
      required this.items,
      this.value,
      this.bgColor,
      this.textStyle=const TextStyle(fontWeight: FontWeight.bold,color: Colors.black),
      this.width=80,
      this.border,
      this.borderRadiusCircular= 15,
      required this.onSave(String val),
      this.mainValue,
      this.selectedKeyName = "id",
      this.selectedValueName = "name",
      this.hintText = "Select One",
      this.emptyText="لاتوجد بيانات",
      this.icon=const Icon(Icons.keyboard_arrow_down,size: 20,color: Color(0xFF1E3A8A),),
    });
  @override
  State<StatefulWidget> createState() => _MySelectedMenu();
}

class _MySelectedMenu extends State<MySelectedMenu> {
  String? dropdownvalue;
  @override
  void initState() {
    // setState(() {
      if (widget.items.isNotEmpty) {
        dropdownvalue =
            widget.mainValue ?? widget.items[0][widget.selectedValueName];
      }
      // else{
      //   dropdownvalue="0";
      // }
    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.items.isEmpty
        ? Container(
            width: widget.width ,
            decoration: BoxDecoration(
              border: widget.border ,
              color: widget.bgColor ?? Theme.of(context).primaryColor.withOpacity(.1),
              borderRadius: BorderRadius.circular(widget.borderRadiusCircular),
            ),
            child: MaterialButton(
              onPressed: () {},
              child: Text(widget.emptyText),
            ))
        : Container(
            width: widget.width,
            decoration: BoxDecoration(
              border: widget.border ?? Border.all(),
              color: widget.bgColor ?? Theme.of(context).primaryColor.withOpacity(.1),
              borderRadius: BorderRadius.circular(widget.borderRadiusCircular),
            ),
            alignment: Alignment.center, // ????? ??????? ???? ??? Container
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                // underline: SizedBox(),
                // iconSize: 50
                padding: EdgeInsets.symmetric(horizontal: widget.width/4),
                icon: widget.icon,
                isExpanded: true, 
                value: dropdownvalue,
                hint: Text(widget.hintText/* ,textAlign: TextAlign.center */,style: widget.textStyle,), // ????? ???? ?????????
                items: widget.items.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item[widget.selectedValueName],
                    child: Center(
                      child: Text(item[widget.selectedValueName],
                          textAlign: TextAlign.center),
                    ),
                  );
                }).toList(),
                onChanged: (String? val) {
                  setState(() {
                    dropdownvalue = val!;
                    widget.value = getAttrFromQuery(widget.items,widget.selectedKeyName, widget.selectedValueName, val);
                    widget.onSave(widget.value.toString());
                  });
                },
              ),
            ),
          );
  }
}







