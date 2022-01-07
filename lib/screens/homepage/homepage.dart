import 'dart:ffi';
import 'dart:io';

import 'package:corecoder_develop/filebrowser/utils/utils.dart';
import 'package:corecoder_develop/screens/homepage/homepage_project_create.dart';
import 'package:corecoder_develop/screens/settings/plugins_browser.dart';
import 'package:corecoder_develop/screens/settings/settings.dart';
import 'package:corecoder_develop/util/cc_project_structure.dart';
import 'package:corecoder_develop/util/desktop_tabbar.dart';
import 'package:corecoder_develop/util/theme_manager.dart';
import 'package:flutter/material.dart';

import '../editor/editor.dart';
import '../../main.dart';
import '../../util/modules_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../util/cc_project_structure.dart';
import 'package:corecoder_develop/util/modules_manager.dart'
    show Module, ModulesManager, Template;

import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:corecoder_develop/util/string_extensions.dart';
import 'homepage_projectlist.dart';

/// Updates the file last modified
void touchFile(File file, CCSolution solution) {
  var newTime = DateTime.now();
  solution.dateModified = newTime;
  file.setLastModifiedSync(newTime);
}

void loadSolution(CCSolution solution, BuildContext context) {
  Navigator.pushNamed(context, EditorPage.routeName, arguments: solution);
  // Save the last solution opened to preferences
  SharedPreferences.getInstance()
      .then((value) => value.setString("lastOpenedPath", solution.slnPath));
}

enum HistoryItemType { solution, singleFile }

class HistoryItem {
  HistoryItemType type;
  CCSolution? solution;
  String? filePath;
  DateTime dateModified;
  String name;

  HistoryItem(this.type,
      {this.solution,
      this.filePath,
      required this.dateModified,
      required this.name});
}

class RecentProjectsManager {
  static RecentProjectsManager? _instance;

  static RecentProjectsManager get instance {
    _instance ??= RecentProjectsManager();
    return _instance!;
  }

  List<HistoryItem> projects = List.empty(growable: true);

  /// Commit the recent projects to the pref
  Future<void> commit(Future<SharedPreferences> _pref) async {
    List<String> list = List.empty(growable: true);
    for (HistoryItem p in projects) {
      if (p.type == HistoryItemType.solution) {
        list.add(p.solution!.slnPath);
      }
      //TODO: support single file
    }
    (await _pref).setStringList("recentProjectsSln", list).then((bool success) {
      debugPrint("Success: $success");
    });
  }

  static void staticCommit() {
    instance.commit(SharedPreferences.getInstance());
  }

  /// Add a solution file to the list
  Future<CCSolution?> addSolution(String slnPath) async {
    // Prevent project with same solution to be loaded
    for (var p in projects) {
      if (p.solution?.slnPath == slnPath) return null;
    }

    var sln = await CCSolution.loadFromFile(slnPath);

    if (sln != null) {
      var item = HistoryItem(HistoryItemType.solution,
          solution: sln, dateModified: sln.dateModified, name: sln.name);
      projects.add(item);
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
  bool isListView = true;
  final Future<SharedPreferences> _pref = SharedPreferences.getInstance();

  /// Called from the project list control
  /// Switches between list and grid view
  void onToggleView() async {
    (await _pref).setBool("isListView", isListView);
    setState(() {
      isListView = !isListView;
    });
  }

  List<PopupMenuEntry<String>> getPopupMenu(HistoryItem item) {
    return <PopupMenuEntry<String>>[
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
      const PopupMenuItem<String>(
          //TODO: Implement this menu
          value: "remove",
          child: Text('Remove from list')),
    ];
  }

  void onMenuItemSelected(String itemTitle, HistoryItem item) {
    switch (itemTitle) {
      case "delete":
        if (item.type == HistoryItemType.solution) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Delete ${item.name}?"),
                  content: Text(
                      "This action cannot be undone!\n folders will be deleted: ${() {
                    String result = "";
                    for (var folder in item.solution!.folders.keys) {
                      result +=
                          (item.solution!.folders[folder] as String) + ", \n";
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
                          for (var folder in item.solution!.folders.keys) {
                            folders.add(item.solution!.slnFolderPath +
                                Platform.pathSeparator +
                                item.solution!.folders[folder]!);
                          }
                          deleteFolderWithIndicator(context, folders);
                          // Delete the solution file too
                          File(item.solution!.slnPath).deleteSync();

                          // Quit and refresh
                          Navigator.pop(context);
                          refreshRecentProjects();
                        },
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.redAccent),
                        )),
                  ],
                );
              });
        } else {
          //TODO: Handle single file delete
        }
        break;
      case "remove":
        setState(() {
          /// Remove item from the list without deleting the actual file
          RecentProjectsManager.instance.projects.remove(item);
          RecentProjectsManager.staticCommit();
        });
        break;
    }
  }

  void onHistoryItemTap(HistoryItem p){
    if (p.type == HistoryItemType.solution) {
      touchFile(File(p.solution!.slnPath), p.solution!);
      refreshRecentProjects();
      loadSolution(p.solution!, context);
    }
    //TODO: Handle single file
  }

  List<Widget> get projectsWidgetList {
    var result = <Widget>[];

    /// The create button
    result.add(ProjectItem(
        isListView: isListView, menuButton: null,
        icon: const Icon(Icons.add, size: 48,),
        title: "Create project", subtitle: "",
        onPressed: ()=>showCreateProjectDialog()));

    for (HistoryItem p in RecentProjectsManager.instance.projects) {
      // if (p.name == "") {
      //   continue;
      // } // TODO: add better way to check if project is corrupt
      //debugPrint(p.name);
      result.add(ProjectItem(
          isListView: isListView,
          menuButton: PopupMenuButton<String>(
              onSelected: (String result) =>
                  onMenuItemSelected(result, p),
              itemBuilder: (BuildContext context) => getPopupMenu(p)),
          icon: p.type == HistoryItemType.solution
              ? p.solution!.image ??
              const Icon(
                Icons.insert_drive_file,
                size: 48,
              )
              : const Icon(
            Icons.insert_drive_file,
            size: 48,
          ),
          title: p.name,
          subtitle: "Last Modified: " +
              Utils.getFormattedDateTime(dateTime: p.dateModified),
          onPressed:()=> onHistoryItemTap(p)));
    }
    return result;
  }

  void showSettings() {
    Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (BuildContext context) => SettingsPage(mm)));
  }

  Future<void> showCreateProjectDialog() async {
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
    Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                HomePageProjectCreate(refreshProjects: refreshRecentProjects)));
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

    mm.initialize(context);
    mm.onFinishedLoading = () {
      refreshRecentProjects();
    };

    /// Check the last opened projects
    SharedPreferences.getInstance().then((inst) async {
      var isAutoOpen = inst.getBool("openLastProjectOnStartup");
      isListView = inst.getBool("isListView") ?? true;
      if (isAutoOpen != null && isAutoOpen) {
        var val = inst.getString("lastOpenedPath");
        debugPrint("Loading last opened $val");
        if (val != null) {
          if (val.endsWith(".ccsln.json")) {
            var sln = await CCSolution.loadFromFile(val);
            if (sln != null) {
              loadSolution(sln, context);
            }
          } else {
            //TODO: handle loading single file
          }
        }
      }
    });
    checkForUpdate();
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

  Future<void> checkForUpdate() async {
    var url = "https://github.com/Hanprogramer/corecoder_develop";
    var git = "Hanprogramer/corecoder_develop";
    var github = GitHub();
    try {
      Repository repo =
          await github.repositories.getRepository(RepositorySlug.full(git));

      List<Release> releases =
          await github.repositories.listReleases(repo.slug()).toList();

      if (repo.hasDownloads) {
        var r = releases.first;
        String onGithubVersion = r.name ?? "v0.0.0";
        var requireUpdate =
            CoreCoderApp.version.compareVersion(onGithubVersion);
        if (requireUpdate) {
          final snackBar = SnackBar(
            content: Text('An update is available! $onGithubVersion'),
            action: SnackBarAction(
              label: 'View on Github',
              onPressed: () {
                _launchInBrowser(r.htmlUrl ?? url);
              },
            ),
          );

          // Find the ScaffoldMessenger in the widget tree
          // and use it to show a SnackBar.
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }
    } on GitHubError catch (err) {
      debugPrint("[Update Checker] Can't fetch update from url $url");
      final snackBar = SnackBar(
        content: Text("Can't fetch update from url $url"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } on SocketException catch (err) {
      debugPrint("[Update Checker] Can't connect to github");
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
      if (path.endsWith(".")) path = path.substring(0, path.length - 2);
      debugPrint(path);
      Directory target = Directory(path);
      text = path;
      await target.delete(recursive: true);
    }
    Navigator.pop(context);
  }

  /// Reload the recent projects from saved preferences
  void refreshRecentProjects() async {
    await loadPrefs();
    setState(() {
      //projectWidgetsMobile.clear();
      RecentProjectsManager.instance.projects
          .sort((HistoryItem a, HistoryItem b) {
        return b.dateModified.compareTo(a.dateModified);
      });
      if (RecentProjectsManager.instance.projects.isEmpty) {
        /*projectWidgetsMobile.add(
            const Text(
                'No recent projects found. Create one using the button below!',
            )
        );*/
      } else {}
    });
  }

  /// Add project from a specific folder path
  /// Called from ProjectList
  void onAddProject(String path) async {
    CCSolution? sln = await CCSolution.loadFromFile(path);
    if (sln != null) {
      await RecentProjectsManager.instance.addSolution(path);
      setState(() {
        RecentProjectsManager.staticCommit();
      });
      loadSolution(sln, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final isLandscape = (query.orientation == Orientation.landscape &&
        query.size.width > query.size.height);
    final page = Center(
        child: Container(
      constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 34,
          minWidth: double.infinity),
      child: isLandscape
          ?

          /// ==================
          /// The windows layout
          /// ==================
          DesktopTabBar(tabs: <DesktopTabData>[
              DesktopTabData(
                  icon: const Icon(Icons.featured_play_list),
                  title: const Text("Projects")),
              DesktopTabData(
                  icon: const Icon(Icons.input), title: const Text("Plugins")),
              DesktopTabData(
                  icon: const Icon(Icons.settings),
                  title: const Text("Settings")),
            ], content: <Widget>[
              ProjectList(
                onAddProject: onAddProject,
                onRefresh: refreshRecentProjects,
                children: projectsWidgetList,
                isListView: isListView,
                onToggleView: onToggleView,
              ),
              PluginsBrowser(modulesManager: mm),
              SettingsPage(mm),
            ])
          :

          /// ==================
          /// The android layout
          /// ==================
          ProjectList(
              onAddProject: onAddProject,
              onRefresh: refreshRecentProjects,
              children: projectsWidgetList,
              isListView: isListView,
              onToggleView: onToggleView,
            ),
    ));
    return Scaffold(
        appBar: CoreCoderApp.isLandscape(context)
            ? null
            : AppBar(
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
        body: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: ThemeManager.getImage("mainBG")!.image,
                    fit: BoxFit.cover)),
            child: SingleChildScrollView(
              child: page,
            )),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showCreateProjectDialog(),
          child: const Icon(Icons.create_new_folder),
        ));
  }
}
