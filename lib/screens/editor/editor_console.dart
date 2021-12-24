import 'package:flutter/material.dart';

class EditorConsoleController extends TextEditingController {
  void setText(String val) {
    text = val;
  }

  void appendText(String val) {
    text += val + "\n";
  }

  EditorConsoleController();
}

class EditorConsole extends StatefulWidget {
  final EditorConsoleController controller;

  EditorConsole({Key? key, required this.controller}) : super(key: key) {
    controller.appendText("val\n\nval");
  }

  @override
  State<StatefulWidget> createState() => EditorConsoleState();

  void setText(String val) => controller.setText(val);

  void appendText(String val) => controller.appendText(val);
}

class EditorConsoleState extends State<EditorConsole> {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Theme.of(context).backgroundColor,
        child: Column(children: [
          const Text("Console Output"),
          Expanded(
              child: SingleChildScrollView(
                  child:TextField(
                enabled: false,
                readOnly: true,
                controller: widget.controller,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
              )))
        ]));
  }
}
