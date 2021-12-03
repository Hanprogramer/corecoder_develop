import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'custom_code_box.dart';

class EditorTabBar extends StatefulWidget {
  List<EditorTab> tabs = <EditorTab>[];

  EditorTabBar({Key? key, required this.tabs}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return EditorTabBarState();
  }

}

class EditorTab extends StatefulWidget {
  //ValueListenable<int> selectedTab;
  int tabId;
  String title;
  bool selected = false;

  EditorTab({Key? key, required this.title, required this.tabId})
      : super(key: key);

  void deselect() {
    selected = true;
    //ValueNotifier()
  }

  @override
  State<StatefulWidget> createState() {
    return EditorTabState();
  }
}

class EditorTabState extends State<EditorTab>{
  bool selected = false;
  EditorTabState();
  @override
  Widget build(BuildContext context) {return Container(
      decoration: BoxDecoration(
        border: selected
            ? const Border(
          bottom: BorderSide(width: 2.0, color: Colors.greenAccent),
        )
            : null,
      ),
      child: TextButton(
          onPressed: () {
            setState((){
                //widget.deselectAll();
                selected = true;
            });
          },
          style: ButtonStyle(),
          child: Row(children: [
            Text(widget.title),
            IconButton(icon: Icon(Icons.close), onPressed: () {})
          ])));
  }

}

class EditorTabBarState extends State<EditorTabBar> {
  ValueNotifier<int> selectedTab = ValueNotifier(0);
  void deselectAll() {
    for (var tab in widget.tabs) {
      tab.deselect();
    }
  }
  EditorTab getSelectedTab(){
    return widget.tabs[selectedTab.value];
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
      // crossAxisAlignment: CrossAxisAlignment.stretch, // add this
      //direction: Axis.vertical,
      children: [
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              //children: List.generate(
              //    40, (index) => EditorTab(title: "Helloasdasd$index", getSelectedTab: getSelectedTab,)),
            )),
        Expanded(
          child: Column(children: []),
          // constraints: BoxConstraints(
          //     minHeight: MediaQuery.of(context).size.height,
          //     minWidth: double.infinity),
          // child: InnerField(
          //     language: 'json',
          //     theme: 'atom-one-dark',
          //     source: "HELLLOOO")),
        ),
        Text(
          'Second widget',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        // Expanded(
        //   child: codeBox,
        //   // constraints: BoxConstraints(
        //   //     minHeight: MediaQuery.of(context).size.height,
        //   //     minWidth: double.infinity),
        // )
      ],
    );
  }
}
