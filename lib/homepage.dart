import 'dart:io';

import 'package:corecoder_develop/settings.dart';
import 'package:corecoder_develop/util/cc_project_structure.dart';
import 'package:corecoder_develop/util/plugins_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'editor.dart';
import 'util/modules_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'util/cc_project_structure.dart';
import 'package:corecoder_develop/util/modules_manager.dart'
    show Module, ModulesManager, Template;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Updates the file last modified
void touchFile(File file, CCSolution solution) {
  var newTime = DateTime.now();
  solution.dateModified = newTime;
  file.setLastModifiedSync(newTime);
}

void loadSolution(CCSolution solution, BuildContext context) {
  Navigator.pushNamed(context, EditorPage.routeName, arguments: solution);
}

class RecentProjectsManager {
  static RecentProjectsManager? _instance;

  static RecentProjectsManager get instance {
    _instance ??= RecentProjectsManager();
    return _instance!;
  }

  List<CCSolution> projects = List.empty(growable: true);

  /// Commit the recent projects to the pref
  Future<void> commit(Future<SharedPreferences> _pref) async {
    List<String> list = List.empty(growable: true);
    for (CCSolution p in projects) {
      list.add(p.slnPath);
    }
    (await _pref).setStringList("recentProjectsSln", list).then((bool success) {
      debugPrint("Success: $success");
    });
  }

  static void staticCommit(){
    instance.commit(SharedPreferences.getInstance());
  }

  /// Add a solution file to the list
  Future<CCSolution?> addSolution(String slnPath) async {
    // Prevent project with same solution to be loaded
    for (var p in projects) {
      if (p.slnPath == slnPath) return null;
    }

    var sln = await CCSolution.loadFromFile(slnPath);
    if (sln != null) {
      projects.add(sln);
    }
    return sln;
  }

  void clear() {
    projects.clear();
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ModulesManager mm;
  final Future<SharedPreferences> _pref = SharedPreferences.getInstance();
  var projectsWidgets = <Widget>[];

  void showSettings() {
    Navigator.pushNamed(context, SettingsPage.routeName);
  }

  Future<void> showCreateProjectDialog() async {
    /// -------------------------------------------------
    /// Template Selection
    /// -------------------------------------------------
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
      status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        await Permission.manageExternalStorage.request();
      }
    }
    switch (await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          List<Widget> options = List.empty(growable: true);
          for (Module m in ModulesManager.modules) {
            options.add(Text(
              m.name,
              style: const TextStyle(fontSize: 21),
            ));
            for (Template t in m.templates) {
              /// -------------------------------------------------
              /// Project Options
              ///  -------------------------------------------------
              options.add(ListTile(
                leading: t.icon,
                trailing: Text(t.version),
                title: Text(t.title),
                subtitle: Text(t.desc),
                onTap: () async {
                  /// The options changed later after the window closed
                  Map<String, dynamic> values = {};
                  await showDialog<int>(
                      context: context,
                      builder: (BuildContext context) {
                        List<Widget> controls = List.empty(growable: true);

                        /// Add Options
                        for (var argName in t.options.keys) {
                          controls.add(Text(
                            argName,
                            textAlign: TextAlign.end,
                          ));
                          if (t.options[argName] == "String") {
                            controls.add(TextField(
                                maxLines: 1,
                                autofocus: true,
                                onChanged: (change) {
                                  values[argName] = change;
                                }));
                            values[argName] = "";
                          }
                        }

                        /// Add Buttons
                        var row = Row(
                          children: [
                            TextButton(
                              child: const Text("Cancel"),
                              onPressed: () {
                                Navigator.pop(context, 1);
                              },
                            ),
                            TextButton(
                              child: const Text("Create"),
                              onPressed: () async {
                                /// Go Ahead and create project asynchronously
                                var slnPath = await t.onCreated(
                                    values); //TODO: This is prone to error (not checking if the file existed first)
                                if (slnPath == null) return;

                                /// Add it to recent projects
                                CCSolution? project =
                                    await RecentProjectsManager.instance.addSolution(slnPath);
                                if (project != null) {
                                  await RecentProjectsManager.instance.commit(_pref);
                                  Navigator.pop(context, 3);
                                  refreshRecentProjects();
                                  loadSolution(project, context);
                                }
                              },
                            )
                          ],
                        );
                        controls.add(row);
                        // Return the dialog to be opened
                        return SimpleDialog(
                          title: Text('Create ${t.title}'),
                          children: <Widget>[
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(children: controls))
                          ],
                        );
                      },
                      barrierDismissible: true);
                },
              ));
            }
          }
          return SimpleDialog(
            title: const Text('Create new project'),
            children: options,
          );
        })) {
      case 0:
        // Let's go.
        // ...
        break;
      case 1:
        // ...
        break;
      case null:
        // dialog dismissed
        break;
    }
  }

  Future loadPrefs() async {
    debugPrint("LOADING PREFS");
    var pref = await _pref;
    // Read recent projects list
    RecentProjectsManager.instance.clear();
    for (var sln in pref.getStringList("recentProjectsSln") ?? []) {
      await RecentProjectsManager.instance.addSolution(sln);
      //debugPrint(sln);
    }
    debugPrint("DONE");
  }

  //#region init/dispose
  @override
  void initState() {
    super.initState();
    mm = ModulesManager(context);
    refreshRecentProjects();
  }

  @override
  void dispose() {
    super.dispose();
  }

  //#endregion

  Future _launchInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
        headers: <String, String>{'my_header_key': 'my_header_value'},
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  /// Delete a folder recursively with the added indicator
  Future<void> deleteFolderWithIndicator(
      BuildContext context, List<String> paths) async {
    var text = "";
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text("Deleting folder"),
            children: [
              const CircularProgressIndicator(value: null),
              Text(text)
            ],
          );
        });
    for (var path in paths) {
      Directory target = Directory(path);
      text = path;
      await target.delete(recursive: true);
    }
    Navigator.pop(context);
  }

  void refreshRecentProjects() async {
    await loadPrefs();
    setState(() {
      projectsWidgets.clear();
      RecentProjectsManager.instance.projects.sort((CCSolution a, CCSolution b) {
        return b.dateModified.compareTo(a.dateModified);
      });
      for (CCSolution p in RecentProjectsManager.instance.projects) {
        if (p.name == "") {
          continue;
        } // TODO: add better way to check if project is corrupt
        //debugPrint(p.name);
        projectsWidgets.add(Card(
            child: ListTile(
                onTap: () {
                  touchFile(File(p.slnPath), p);
                  refreshRecentProjects();
                  loadSolution(p, context);
                },
                leading: p.image ??
                    const Icon(
                      Icons.insert_drive_file,
                      size: 48,
                    ),
                title: Text(p.name),
                subtitle: Text(
                    p.desc + " Last Modified: " + p.dateModified.toString()),
                trailing: PopupMenuButton<String>(
                  onSelected: (String result) {
                    switch (result) {
                      case "delete":
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Delete ${p.name}?"),
                                content: Text(
                                    "This action cannot be undone!\n folders will be deleted: ${() {
                                  String result = "";
                                  for (var folder in p.folders.keys) {
                                    result +=
                                        (p.folders[folder] as String) + ", \n";
                                  }
                                  return result;
                                }()}"),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text("No")),
                                  TextButton(
                                      onPressed: () {
                                        var folders = <String>[];
                                        for (var folder in p.folders.keys) {
                                          folders.add(p.slnFolderPath +
                                              Platform.pathSeparator +
                                              p.folders[folder]!);
                                        }
                                        deleteFolderWithIndicator(
                                            context, folders);
                                        // Delete the solution file too
                                        File(p.slnPath).deleteSync();

                                        // Quit and refresh
                                        Navigator.pop(context);
                                        refreshRecentProjects();
                                      },
                                      child: const Text(
                                        "Delete",
                                        style:
                                            TextStyle(color: Colors.redAccent),
                                      )),
                                ],
                              );
                            });
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: "delete",
                      child: Text('Delete Project'),
                    ),
                    const PopupMenuItem<String>(
                      //TODO: Implement this menu
                      value: "rename",
                      child: Text('Rename Project'),
                    ),
                    const PopupMenuItem<String>(
                      //TODO: Implement this menu
                      value: "export",
                      child: Text('Export Project'),
                    ),
                  ],
                ))));
        // IconButton(
        //   onPressed: () {
        //     showMenu(context: context, position: RelativeRect.fromLTRB(
        //       details.globalPosition.dx,
        //       details.globalPosition.dy,
        //       details.globalPosition.dx,
        //       details.globalPosition.dy,
        //     ), items: <PopupMenuEntry<dynamic>>[]);
        //   },
        //   icon: const Icon(FontAwesomeIcons.ellipsisV),
        // )));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final page = Center(
        child: Container(
      padding: const EdgeInsets.all(16.0),
      constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
          minWidth: double.infinity),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Text(
            "Recent Projects",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24.0,
            ),
          ),
          const Spacer(flex: 1),
          OutlinedButton(
            onPressed: () {
              refreshRecentProjects();
            },
            child: const Text("Refresh"),
          ),
          OutlinedButton(
            onPressed: () {},
            child: const Text("Add"),
          ),
          ElevatedButton(
              onPressed: () => showCreateProjectDialog(),
              child: const Text("New")),
        ]),
        Column(
          children: projectsWidgets,
        )
      ]),
    ));
    return Scaffold(
      appBar: AppBar(
        title: const Text("CoreCoder Develop"),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () => {showSettings()},
              icon: const Icon(Icons.settings),
              tooltip: "Settings"),
          const SizedBox(width: 16.0),
        ],
      ),
      body: SingleChildScrollView(child: page),
    );
  }
}
