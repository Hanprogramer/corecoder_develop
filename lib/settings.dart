import 'package:corecoder_develop/util/theme_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppSettings {
  static String appTheme = "atom-one-dark";
}

class Settings {
  static AppSettings app = AppSettings();
}

enum SettingsPageItemType {
  TypeString,
  TypeStringList,
  TypeBoolean,
  TypeInteger,
  TypeFloat
}

class SettingsPageItem {
  Function(dynamic val) onSet;
  String name;
  String description;
  SettingsPageItemType type;
  dynamic provided; // the string list for list type
  dynamic defaultVal;
  dynamic currentVal;

  SettingsPageItem(this.name, this.description, this.onSet, this.type,
      this.provided, this.defaultVal);
}

class SettingsPage extends StatelessWidget {
  static var routeName = "/SettingsPage";
  var tabs = <Widget>[
    Tab(
      text: "General",
    ),
    Tab(text: "Plugins"),
    Tab(text: "About"),
  ];

  Widget getSettingsTabContent(BuildContext context) {
    return Column(
        children: List.generate(items.length, (index) {
      return generateListItem(index, context);
    }));
  }

  SettingsPage({Key? key}) : super(key: key);
  List<SettingsPageItem> items = [
    SettingsPageItem(
        "Theme",
        "The theme for entire app",
        (dynamic val) => {ThemeManager.setTheme(val)},
        SettingsPageItemType.TypeStringList,
        <String>["atom-one-dark", "atom-one-light"],
        "Atom One Dark")
  ];

  Widget generateListItem(int index, BuildContext context) {
    SettingsPageItem item = items[index];
    switch (item.type) {
      case SettingsPageItemType.TypeStringList:
        var list = (item.provided as List<String>);
        return ListTile(
          title: Text(item.name),
          subtitle: Text(item.description),
          trailing: Text((item.currentVal ?? item.defaultVal).toString()),
          onTap: () {
            showDialog<String>(
              context: context,
              barrierDismissible: false, // user must tap button!
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(item.name),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: List.generate(list.length, (index) {
                        return ListTile(
                          title: Text(list[index]),
                          onTap: () {
                            item.onSet(list[index]);
                            items[index].currentVal = list[index];
                          },
                        );
                      }),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
        break;
      case SettingsPageItemType.TypeString:
        // TODO: Handle this case.
        break;
      case SettingsPageItemType.TypeBoolean:
        // TODO: Handle this case.
        break;
      case SettingsPageItemType.TypeInteger:
        // TODO: Handle this case.
        break;
      case SettingsPageItemType.TypeFloat:
        // TODO: Handle this case.
        break;
    }
    return const SizedBox.shrink(); // Empty widget
  }

  @override
  Widget build(BuildContext context) {
    var tabsContent = <Widget>[
      /// General Page
      getSettingsTabContent(context),
      /// Plugins Page
      Column(),
      /// About page
      Column(children:const [
        Text("CoreCoder Develop"),
        Text("v0.0.1 dev beta"),
      ])
    ];
    return DefaultTabController(
        length: tabs.length,
        child: Scaffold(
            appBar: AppBar(
              title: const Text("Settings"),
              bottom: TabBar(
                tabs: tabs,
              ),
            ),
            body: TabBarView(
              children: tabsContent,
            )));
  }
}
