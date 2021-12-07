import 'package:corecoder_develop/util/theme_manager.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: SingleChildScrollView(
        controller: ScrollController(),
        child: Column(
            children: List.generate(items.length, (index) {
          return generateListItem(index, context);
        })),
      ),
    );
  }
}
