import 'dart:async';
import 'dart:io';

import 'package:corecoder_develop/screens/editor/editor_console.dart';
import 'package:corecoder_develop/util/custom_code_box.dart' show InnerField;
import 'package:corecoder_develop/screens/editor/editor_drawer.dart';
import 'package:corecoder_develop/util/modules_manager.dart';
import 'package:corecoder_develop/util/theme_manager.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import '../../util/cc_project_structure.dart';
import '../../filebrowser/models/document.dart';
import 'package:async/async.dart' show RestartableTimer;

class EditorPage extends StatefulWidget {
  static const String routeName = "/EditorPage";

  const EditorPage({Key? key}) : super(key: key);

  @override
  _EditorPageState createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late CCSolution project;
  List<Document> documentList = [];
  List<TabData> tabs = [];
  Map<String, TabData> fileEditors = {};
  bool autoCompleteShown = false;
  List<String> autoComplete = <String>[
    "var|hello",
    "var|world",
    "func|helloWorld",
    "func|helloCoreCoder",
  ];
  double autoCompleteX = 0;
  double autoCompleteY = 0;
  int? selectedTab;
  EditorConsoleController consoleController = EditorConsoleController();
  bool showConsole = false;

  @override
  void initState() {
    super.initState();
    autoSaveTimer = RestartableTimer(const Duration(seconds: 1), onAutoSave);
  }

  @override
  void dispose() {
    super.dispose();
  }

  TabbedViewThemeData getTabTheme() {
    TabbedViewThemeData themeData = TabbedViewThemeData();
    themeData.tabsArea
      //..border = Border(bottom: BorderSide(color: Colors.green[700]!, width: 3))
      ..middleGap = 0
      ..color = ThemeManager.getThemeSchemeColor("background");
    themeData.menu.textStyle = const TextStyle(color: Colors.white);
    Radius radius = Radius.zero;
    BorderRadiusGeometry? borderRadius =
        BorderRadius.only(topLeft: radius, topRight: radius);
    themeData.tab
      ..padding = const EdgeInsets.fromLTRB(28, 8, 14, 8)
      ..buttonsOffset = 8
      ..textStyle = const TextStyle(color: Colors.white)
      ..closeIcon = IconProvider.data(Icons.close)
      ..normalButtonColor = Colors.white
      ..hoverButtonColor = Colors.red
      ..decoration = BoxDecoration(
          shape: BoxShape.rectangle,
          color: Colors.black38,
          borderRadius: borderRadius)
      ..selectedStatus.decoration = const BoxDecoration(
          color: Colors.black26,
          border: Border(top: BorderSide(color: Colors.greenAccent, width: 3)))
      ..highlightedStatus.decoration =
          const BoxDecoration(color: Colors.black12);
    return themeData;
  }

  List<Document> readFolder(Directory dir) {
    /// Walk the dir and add it to the parent node
    List<Document> children = List.empty(growable: true);
    dir.list(recursive: false).listen((file) {
      var stat = file.statSync();
      if (stat.type == FileSystemEntityType.directory) {
        // Recursively call this method
        List<Document> _children = readFolder(Directory(file.path));
        Document newNode = Document(
            name: path.basename(file.path),
            dateModified: DateTime.now(),
            isFile: false,
            path: file.path,
            childData: _children);
        children.add(newNode);
      } else {
        // Is File
        children.add(Document(
          name: path.basename(file.path),
          dateModified: DateTime.now(),
          isFile: true,
          path: file.path,
        ));
      }
    });
    return children;
  }

  //TODO: Add file under directory
  //TODO: Add dir under dir
  //TODO: Rename file
  //TODO: Move file

  void deleteFile(String filepath) async {
    final file = File(filepath);
    await file.delete();
    refreshFileBrowser();
  }

  void deleteDir(String dirpath) async {
    final dir = Directory(dirpath);
    await dir.delete(recursive: true);
    refreshFileBrowser();
  }

  void createFile(String filepath) {
    final file = File(filepath);
  }

  void refreshFileBrowser() async {
    List<Document> docs = List.empty(growable: true);

    // Add folders from the solution file
    for (var key in project.folders.keys) {
      var dir = project.slnFolderPath +
          Platform.pathSeparator +
          (project.folders[key])!;
      List<Document> children = readFolder(Directory(dir));

      Document node = Document(
        name: key,
        dateModified: DateTime.now(),
        isFile: false,
        childData: children,
        path: project.folders[key]!,
      );

      docs.add(node);
    }

    // Add the solution file itself
    Document node = Document(
      name: project.name,
      dateModified: DateTime.now(),
      isFile: true,
      childData: [],
      path: project.slnPath,
    );

    docs.add(node);

    setState(() {
      documentList = docs;
    });
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

  // List<Node> fileBrowserNodes = <Node>[];
  List<Tab> editorTabs = <Tab>[];
  List<Tab> tempTabs = <Tab>[];
  List<InnerField> codeFields = <InnerField>[];
  late RestartableTimer autoSaveTimer;

  void onAutoSave() async {
    for (var tab in tabs) {
      var field = (((tab.content as SingleChildScrollView).child as Container)
          .child as InnerField);

      //TODO: better saving function
      await File(field.filePath).writeAsString(field.codeController.rawText);
    }
  }

  TabData createFileTab(
      String title, String source, String language, String filePath) {
    var field = InnerField(
      language: language,
      theme: ThemeManager.getHighlighting(),
      source: source,
      filePath: filePath,
      onChange: (String filePath, String source) {
        autoSaveTimer.reset();
      },
      onAutoComplete: (String lastToken) {
        autoComplete = [];
        for (var module in ModulesManager.modules) {
          autoComplete.addAll(module.onAutoComplete(language, lastToken));
        }
        setState(() {
          autoCompleteShown = true;
        });
      },
      setCursorOffset: (Offset offset) {
        setState(() {
          autoCompleteX = offset.dx;
          autoCompleteY = offset.dy + 64;
        });
      },
      onUnAutoComplete: () {
        setState(() {
          autoCompleteShown = false;
        });
      },
    );
    codeFields.add(field);
    return TabData(
        text: title,
        closable: true,
        keepAlive: true,
        value: filePath,
        content: SingleChildScrollView(
            controller: ScrollController(),
            child: Container(
              constraints: BoxConstraints(
                  minHeight: MediaQuery
                      .of(context)
                      .size
                      .height * 2),
              child: field,
            )));
  }

  void openFile(String filepath) async {
    if (!fileEditors.containsKey(filepath)) {
      var filename = path.basename(filepath);
      var content = await File(filepath).readAsString();
      //debugPrint(content);
      content = content.replaceAll("\t", "    ");
      setState(() {
        var language = 'javascript';
        if (filename.endsWith(".json")) {
          language = 'json';
        }
        if (filename.endsWith(".lua")) {
          language = 'lua';
        }
        var tab = createFileTab(filename, content, language, filepath);
        fileEditors[filepath] = tab;
        tabs.add(tab);
        selectedTab = tabs.length - 1;
      });
    } else {
      // Tab already exists
      var tab = fileEditors[filepath];
      if (tab != null) {
        setState(() {
          selectedTab = tabs.indexOf(tab);
        });
      }
    }
  }

  List<Widget> getAutoCompleteControls(String? a) {
    List<Widget> result = List.generate(autoComplete.length, (index) {
      var item = autoComplete[index].split("|");
      var type = "undefined", name = "name", desc = "undefined";
      if (item.isNotEmpty) {
        type = item.length > 1 ? item[0] : "undefined";
        name = item.length > 1 ? item[1] : item[0];
        desc = item.length > 2 ? item[2] : "";
      }
      var color = Colors.black12;
      switch (type) {
        case "var":
          color = Colors.blueAccent;
          break;
        case "function":
          color = Colors.purpleAccent;
          break;
        case "type":
          color = Colors.orangeAccent;
          break;
        case "module":
          color = Colors.redAccent;
          break;
      }
      return Tooltip(
          verticalOffset: 64,
          message: desc,
          child: InkWell(
            //style: TextStyle(padding: MaterialStateProperty.all(EdgeInsets.zero)),
            child: Row(
              children: [
                Container(
                  color: color,
                  child: Text(
                    type.characters.first,
                    textAlign: TextAlign.center,
                  ),
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.only(right: 8.0),
                  width: 32,
                ),
                Text(
                  name,
                ),
                const Spacer(
                  flex: 1,
                ),
                Flexible(
                  child: Text(
                    desc,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                  fit: FlexFit.tight,
                ),
                const SizedBox.square(
                  dimension: 12,
                )
              ],
            ),
            onTap: () {
              setState(() {
                autoCompleteShown = false;
                if (selectedTab == null || selectedTab! < 0) return;
                var currentTab = tabs[selectedTab!];
                var currentField =
                    ((currentTab.content as SingleChildScrollView).child
                            as Container)
                        .child as InnerField;
                var controller = currentField.codeController;
                controller.insertStr(name);
              });
            },
          ));
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    var _tapPosition;

    void _storePosition(TapDownDetails details) {
      _tapPosition = details.globalPosition;
    }

    project = ModalRoute.of(context)!.settings.arguments as CCSolution;
    var query = MediaQuery.of(context);
    if (documentList.isEmpty) {
      // Populate the file browser tree once
      refreshFileBrowser();
    }
    var tabController = TabbedViewController(
      tabs,
    );
    tabController.selectedIndex = tabs.isNotEmpty ? selectedTab : null;
    final page = Stack(children: [
      Column(//direction: Axis.vertical,
          children: [
        Expanded(
          child: tabs.isNotEmpty
              ? TabbedViewTheme(
                  data: getTabTheme(),
                  child: TabbedView(
                    onTabSelection: (int? selection) {
                      selectedTab = selection ?? -1;
                    },
                    onTabClose: (tabIndex, tabData) {
                      setState(() {
                        fileEditors.remove(tabData.value);
                      });
                    },
                    controller: tabController,
                  ))
              : const Center(child: Text("No file opened")),
        ),
      ]),
      if (autoCompleteShown)
        Positioned(
            top: autoCompleteY,
            left: autoCompleteX,
            width: 512,
            child: ClipRRect(
                child: Container(
                    constraints: const BoxConstraints(
                        minWidth: 256,
                        maxWidth: 600,
                        minHeight: 16,
                        maxHeight: 300),
                    clipBehavior: Clip.none,
                    color: ThemeManager.getThemeSchemeColor("foreground"),
                    child: Material(
                        child: ListView(
                            children: getAutoCompleteControls(null)))))),
      if(showConsole)
        Positioned(
          left: 0,
          top: query.size.height / 2,
          height: query.size.height / 2,
          width: query.size.width,
          child:EditorConsole(controller: consoleController),
        )
    ]);

    return Scaffold(
      drawer: MyDrawer(documentList, project, (String filepath) {
        openFile(filepath);
        Navigator.pop(context);
      }, (String filepath) async {
        var selection = await showMenu(context: context, position: const RelativeRect.fromLTRB(1, 1, 1, 1), items: <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: "delete",
            child: Text('Delete file'),
          ),
        ]);
        //TODO: Menu should show up at tap location
        //TODO: Refactor menu into separate file
        switch(selection) {
          case 'delete':
            deleteFile(filepath);
        }
      }, (String dirpath) async {
        var selection = await showMenu(context: context, position: const RelativeRect.fromLTRB(1, 1, 1, 1), items: <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: "delete",
            child: Text('Delete folder'),
          ),
        ]);
        //TODO: Menu should show up at tap location
        //TODO: Refactor menu into separate file
        switch(selection) {
          case 'delete':
            deleteDir(dirpath);
        }
      }
      ),
      appBar: AppBar(
        title: null,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              project.run(consoleController);
            },
            icon: const Icon(Icons.play_arrow),
            tooltip: "Run Project",
          ),
          IconButton(
            onPressed: () {
              setState(() {
                /// Toggle the console
                showConsole = !showConsole;
              });
            },
            icon: const Icon(Icons.assessment_rounded),
            tooltip: "Toggle Console",
          ),
          PopupMenuButton(
            child: const Icon(Icons.more_horiz),
            tooltip: "Menu",
            padding: const EdgeInsets.all(32.0),
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry>[
                PopupMenuItem(
                  child: const Text("Close Project"),
                  onTap: () => Navigator.pop(context),
                )
              ];
            },
          ),
          const SizedBox(width: 16.0),
        ],
      ),
      body:
          page
    );
  }
}
