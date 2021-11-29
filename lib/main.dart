import 'dart:convert';
import 'dart:math';

import 'package:corecoder_develop/editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show File, Platform;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:corecoder_develop/modules_manager.dart'
    show Module, ModulesManager, Template;
import 'package:image/image.dart' as IMG;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class CCProject {
  final String name, desc, author, identifier, slnPath;

  CCProject(this.name, this.desc, this.author, this.identifier, this.slnPath);

  void load(BuildContext context) {
    /// Load the project

    Navigator.pushNamed(context, EditorPage.routeName, arguments: this);
  }
}

class RecentProjectsManager {
  List<CCProject> projects = List.empty(growable: true);
  var decoder = JsonDecoder();

  /// Commit the recent projects to the pref
  Future<void> commit(Future<SharedPreferences> _pref) async {
    List<String> list = List.empty(growable: true);
    for (CCProject p in projects) {
      list.add(p.slnPath);
    }
    (await _pref).setStringList("recentProjectsSln", list).then((bool success) {
      debugPrint("Success: $success");
    });
  }

  /// Add a solution file to the list
  Future<CCProject?> addProject(String slnPath) async {
    var file = File(slnPath);
    if (await file.exists()) {
      String input = await file.readAsString();
      var obj = decoder.convert(input);
      try {
        var result = CCProject(obj["name"], obj["description"] ?? "",
            obj["author"], obj["identifier"], slnPath);
        projects.add(result);
        return result;
      } on Exception catch (e) {
        debugPrint("Error: project is corrupted: $slnPath");
        return null;
      }
    } else {
      debugPrint("Error: project can't be found: $slnPath");
      return null;
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CoreCoder Develop',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      //home: HomePage(),
      initialRoute: "/",
      routes: {
        "/": (context) => HomePage(),
        EditorPage.routeName: (context) => EditorPage()
      },
    );
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
          for (Module m in mm.modules) {
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
                                var slnPath = await t.onCreated(values); //TODO: This is prone to error (not checking if the file existed first)

                                /// Add it to recent projects
                                CCProject? project =
                                    await rpm.addProject(slnPath);
                                if (project != null) {
                                  await rpm.commit(_pref);
                                  Navigator.pop(context, 3);
                                  refreshRecentProjects();
                                  project.load(context);
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
      await rpm.addProject(sln);
      debugPrint(sln);
    }
    debugPrint("DONE");
    refreshRecentProjects();
  }

  @override
  void initState() {
    super.initState();
    loadPrefs();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
      for (CCProject p in rpm.projects) {
        debugPrint(p.name);
        projectsWidgets.add(Container(
            constraints:
                const BoxConstraints(minWidth: 128.0, minHeight: 128.0),
            padding: const EdgeInsets.all(4.0),
            child: ElevatedButton(
                onPressed: () {
                  p.load(context);
                },
                child: Text(p.name))));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // final button = ElevatedButton(
    //   onPressed: () async {
    //     //var result = Platform.environment["LOCALAPPDATA"];
    //     // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //     //   content: Text("$result"),
    //     // ));
    //     showCreateProjectDialog();
    //   },
    //   child: Text("Invoke"),
    // );

    final page = Center(
        child: Container(
      padding: EdgeInsets.all(16.0),
      constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
          minWidth: double.infinity),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          "Recent Projects",
          style: TextStyle(color: Colors.white),
        ),
        Wrap(
          children: projectsWidgets,
          direction: Axis.horizontal,
          alignment: WrapAlignment.start,
        )
      ]),
    ));
    return Scaffold(
      backgroundColor: Color(0xFF363636),
      appBar: AppBar(
        backgroundColor: Color(0xff23241f),
        title: Text("CoreCoder Develop"),
        // title: Text("Recursive Fibonacci"),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () => {showCreateProjectDialog()},
              icon: Icon(FontAwesomeIcons.plus),
              tooltip: "Create Project"),
          IconButton(
              onPressed: () => {refreshRecentProjects()},
              icon: Icon(FontAwesomeIcons.sync),
              tooltip: "Refresh Projects"),
          SizedBox(width: 16.0),
        ],
      ),
      body: SingleChildScrollView(child: page),
    );
  }
}
