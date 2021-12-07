import 'dart:io';

import 'package:corecoder_develop/settings.dart';
import 'package:corecoder_develop/util/cc_project_structure.dart';
import 'package:flutter/material.dart';

import 'editor.dart';
import 'util/modules_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'util/cc_project_structure.dart';
import 'package:corecoder_develop/util/modules_manager.dart'
    show Module, ModulesManager, Template;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
void loadSolution(
    CCSolution solution, BuildContext context, ModulesManager modulesManager) {
  /// Load the project
  // var template = modulesManager.getTemplateByIdentifier(solution.identifier);
  Navigator.pushNamed(context, EditorPage.routeName, arguments: solution);
}

class RecentProjectsManager {
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

  /// Add a solution file to the list
  Future<CCSolution?> addSolution(String slnPath) async {
    var sln = await CCSolution.loadFromFile(slnPath);
    if (sln != null) {
      projects.add(sln);
    }
    return sln;
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ModulesManager mm = ModulesManager();
  RecentProjectsManager rpm = RecentProjectsManager();
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
              style: TextStyle(fontSize: 21),
            ));
            for (Template t in m.templates) {
              /// -------------------------------------------------
              /// Project Options
              ///  -------------------------------------------------
              options.add(SimpleDialogOption(
                onPressed: () async {
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
                              child: Text("Cancel"),
                              onPressed: () {
                                Navigator.pop(context, 1);
                              },
                            ),
                            TextButton(
                              child: Text("Create"),
                              onPressed: () async {
                                /// Go Ahead and create project asynchronously
                                var slnPath = await t.onCreated(
                                    values); //TODO: This is prone to error (not checking if the file existed first)

                                /// Add it to recent projects
                                CCSolution? project =
                                    await rpm.addSolution(slnPath);
                                if (project != null) {
                                  await rpm.commit(_pref);
                                  Navigator.pop(context, 3);
                                  refreshRecentProjects();
                                  loadSolution(project, context, mm);
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
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(children: controls))
                          ],
                        );
                      },
                      barrierDismissible: true);
                },
                child: Row(
                  children: [
                    Image(
                        image:
                            ResizeImage.resizeIfNeeded(48, 48, t.icon.image)),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(t.desc)
                        ]),
                    const Expanded(child: Center()),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [Text(t.version)],
                      mainAxisAlignment: MainAxisAlignment.end,
                    ),
                  ],
                ),
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

  void loadPrefs() async {
    debugPrint("LOADING PREFS");
    var pref = await _pref;
    // Read recent projects list
    for (var sln in pref.getStringList("recentProjectsSln") ?? []) {
      await rpm.addSolution(sln);
      debugPrint(sln);
    }
    debugPrint("DONE");
    refreshRecentProjects();
  }

  //#region init/dispose
  @override
  void initState() {
    super.initState();
    loadPrefs();
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

  void refreshRecentProjects() {
    setState(() {
      projectsWidgets.clear();
      for (CCSolution p in rpm.projects) {
        if (p.name == "")
          continue; // TODO: add better way to check if project is corrupt
        debugPrint(p.name);
        projectsWidgets.add(ListTile(
          onTap: () {
            loadSolution(p, context, mm);
          },
          leading: p.image != null
              ? Image(image: ResizeImage.resizeIfNeeded(48, 48, p.image!.image))
              : const Icon(
                  Icons.insert_drive_file,
                  size: 48,
                ),
          title: Text(p.name),
          subtitle:
              Text(p.desc + " Last Modified: " + p.dateModified.toString()),
          trailing: IconButton(onPressed: () {  }, icon: const Icon(FontAwesomeIcons.ellipsisV),)
        ));
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
        const Text(
          "Recent Projects",
        ),
        Column(
          children: projectsWidgets,
        )
      ]),
    ));
    return Scaffold(
      appBar: AppBar(
        title: const Text("CoreCoder Develop"),
        // title: Text("Recursive Fibonacci"),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () => {showCreateProjectDialog()},
              icon: const Icon(Icons.add),
              tooltip: "Create Project"),
          IconButton(
              onPressed: () => {refreshRecentProjects()},
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh Projects"),
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
