import 'package:corecoder_develop/main.dart';
import 'package:corecoder_develop/plugins_browser.dart';
import 'package:corecoder_develop/util/modules_manager.dart';
import 'package:corecoder_develop/util/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'util/plugins_manager.dart';

class AppSettings {
  static String appTheme = "core-coder-dark";
}

class Settings {
  static AppSettings app = AppSettings();
}

enum SettingsPageItemType {
  typeString,
  typeStringList,
  typeBoolean,
  typeInteger,
  typeFloat
}

class SettingsPageItem {
  Function(SettingsPageItem item, dynamic val) onSet;
  Function(SettingsPageItem item) onInitialized;
  String name;
  String description;
  SettingsPageItemType type;
  dynamic provided; // the string list for list type
  dynamic defaultVal;
  dynamic currentVal;

  SettingsPageItem(
      {required this.name,
      required this.description,
      required this.onSet,
      required this.onInitialized,
      required this.type,
      this.provided,
      this.defaultVal});
}

class SettingsPage extends StatefulWidget {
  final ModulesManager modulesManager;

  const SettingsPage(this.modulesManager, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  static final Future<SharedPreferences> _pref =
      SharedPreferences.getInstance();
  static var routeName = "/SettingsPage";
  var tabs = <Widget>[
    const Tab(
      text: "General",
    ),
    const Tab(text: "Plugins"),
    const Tab(text: "About"),
  ];

  Widget getSettingsTabContent(BuildContext context) {
    return Column(
        children: List.generate(items.length, (index) {

      return generateListItem(index, context);
    }));
  }

  List<SettingsPageItem> items = [
    SettingsPageItem(
        name: "Theme",
        description: "The theme for entire app",
        onSet: (SettingsPageItem item, dynamic val) async {
          ThemeManager.setTheme(val);

          // Set the value to be stored
          (await _pref).setString("theme", val);
        },
        onInitialized: (SettingsPageItem item)async{
          // Get the item value from prefs
          var val = (await _pref).getString("theme");
          item.currentVal ??= val;
        },
        type: SettingsPageItemType.typeStringList,
        provided: <String>["core-coder-dark", "core-coder-light"],
        defaultVal: ThemeManager.currentTheme.value),
    SettingsPageItem(
        name: "Open last project on startup",
        description: "Open last project when the app started",
        onSet: (SettingsPageItem item, dynamic val) async {
          item.currentVal = val;
          // Set the value to be stored
          (await _pref).setBool("openLastProjectOnStartup", val);
        },
        onInitialized: (SettingsPageItem item)async{
          // Get the item value from prefs
          var val = (await _pref).getBool("openLastProjectOnStartup");
          item.currentVal ??= val;
        },
        type: SettingsPageItemType.typeBoolean,
        provided: <bool>[true, false],
        defaultVal: true)
  ];

  Widget generateListItem(int index, BuildContext context) {
    SettingsPageItem item = items[index];
    item.onInitialized(item);
    switch (item.type) {
      case SettingsPageItemType.typeStringList:
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
                            item.onSet(item, list[index]);
                            item.currentVal = list[index];
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
      case SettingsPageItemType.typeString:
        // TODO: Handle this case.
        break;
      case SettingsPageItemType.typeBoolean:
        return CheckboxListTile(
            title: Text(item.name),
            subtitle: Text(item.description),
            value: item.currentVal ?? item.defaultVal,
            onChanged: (bool? val) {
              item.onSet(item, val);
              setState(() {
                item.currentVal = val;
              });
            });
      case SettingsPageItemType.typeInteger:
        // TODO: Handle this case.
        break;
      case SettingsPageItemType.typeFloat:
        // TODO: Handle this case.
        break;
    }
    return const SizedBox.shrink(); // Empty widget
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: tabs.length,
        child: Scaffold(
            appBar: AppBar(
              title: const Text("Settings"),
              bottom: TabBar(
                tabs: tabs,
              ),
            ),
            body: FutureBuilder(
              builder: (
                BuildContext context,
                AsyncSnapshot<String> snapshot,
              ) {
                return TabBarView(
                  children: [
                    /// General Page
                    getSettingsTabContent(context),

                    /// Plugins Page
                    Column(children: [
                      if (snapshot.hasData)
                        Visibility(
                          visible: snapshot.hasData,
                          child: Text(
                            snapshot.data!,
                          ),
                        ),
                      ListTile(
                        leading: const Icon(
                          Icons.download,
                          size: 48,
                        ),
                        title: const Text("Download Plugins"),
                        subtitle: const Text("Get plugins from the internet"),
                        onTap: () {
                          Navigator.pushNamed(
                              context, PluginsBrowser.routeName);
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.refresh,
                          size: 48,
                        ),
                        title: const Text("Reload Plugins"),
                        subtitle: const Text("Reload plugins from the disk"),
                        onTap: () {
                          widget.modulesManager.initialize(context);
                          setState(() {});
                        },
                      ),
                      const Text("Installed Plugins"),
                      Column(
                          children: List.generate(ModulesManager.modules.length,
                              (index) {
                        var mod = ModulesManager.modules[index];
                        return ListTile(
                          onTap: () {},
                          leading: mod.icon,
                          title: Text(mod.name),
                          subtitle: Text(mod.desc + " version:" + mod.version),
                          // trailing: PopupMenuButton<String>(
                          //   onSelected: (String result) {
                          //     switch (result) {
                          //       case "delete":
                          //         showDialog(
                          //             context: context,
                          //             builder: (BuildContext context) {
                          //               return AlertDialog(
                          //                 title: Text("Delete ${p.name}?"),
                          //                 content: Text(
                          //                     "This action cannot be undone!\n folders will be deleted: ${() {
                          //                       String result = "";
                          //                       for (var folder in p.folders.keys) {
                          //                         result +=
                          //                             (p.folders[folder] as String) + ", \n";
                          //                       }
                          //                       return result;
                          //                     }()}"),
                          //                 actions: [
                          //                   TextButton(
                          //                       onPressed: () {
                          //                         Navigator.pop(context);
                          //                       },
                          //                       child: const Text("No")),
                          //                   TextButton(
                          //                       onPressed: () {
                          //                         var folders = <String>[];
                          //                         for (var folder in p.folders.keys) {
                          //                           folders.add(p.slnFolderPath +
                          //                               Platform.pathSeparator +
                          //                               p.folders[folder]!);
                          //                         }
                          //                         deleteFolderWithIndicator(
                          //                             context, folders);
                          //                         // Delete the solution file too
                          //                         File(p.slnPath).deleteSync();
                          //
                          //                         // Quit and refresh
                          //                         Navigator.pop(context);
                          //                         refreshRecentProjects();
                          //                       },
                          //                       child: const Text(
                          //                         "Delete",
                          //                         style:
                          //                         TextStyle(color: Colors.redAccent),
                          //                       )),
                          //                 ],
                          //               );
                          //             });
                          //         break;
                          //     }
                          //   },
                          //   itemBuilder: (BuildContext context) =>
                          //   <PopupMenuEntry<String>>[
                          //     const PopupMenuItem<String>(
                          //       value: "delete",
                          //       child: Text('Delete Project'),
                          //     ),
                          //     const PopupMenuItem<String>(
                          //       //TODO: Implement this menu
                          //       value: "rename",
                          //       child: Text('Rename Project'),
                          //     ),
                          //     const PopupMenuItem<String>(
                          //       //TODO: Implement this menu
                          //       value: "export",
                          //       child: Text('Export Project'),
                          //     ),
                          //   ],
                          // ))
                        );
                      }))
                    ]),

                    /// About page
                    ListTile(
                      leading: Image.asset("assets/logo.png"),
                      title: const Text("CoreCoder Develop"),
                      subtitle: const Text(CoreCoderApp.version),
                    )
                  ],
                );
              },
              future: PluginsManager.pluginsPath,
            )));
  }
}
