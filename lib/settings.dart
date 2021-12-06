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

  SettingsPageItem(this.name, this.description, this.onSet, this.type);
}

class SettingsPage extends StatelessWidget {
  static var routeName = "/SettingsPage";

  SettingsPage({Key? key}) : super(key: key);
  List<SettingsPageItem> items = [
    SettingsPageItem("Theme", "The theme for entire app", (dynamic val) => {},
        SettingsPageItemType.TypeStringList)
  ];

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
          return ListTile(
            title: Text(items[index].name),
            subtitle: Text(items[index].description),
              onTap: () => print("ListTile")
          );
        })),
      ),
    );
  }
}
