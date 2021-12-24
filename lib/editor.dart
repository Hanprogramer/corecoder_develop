import 'dart:async';
import 'dart:io';

import 'package:corecoder_develop/util/custom_code_box.dart'
    show InnerField, InnerFieldState;
import 'package:corecoder_develop/editor_drawer.dart';
import 'package:corecoder_develop/util/modules_manager.dart';
import 'package:corecoder_develop/util/theme_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'util/cc_project_structure.dart';
import 'filebrowser/models/document.dart';
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
  bool autoCompleteShown = false;
  List<String> autoComplete = <String>[
    "var|hello",
    "var|world",
    "func|helloWorld",
    "func|helloCoreCoder",
  ];
  double autoCompleteX = 0;
  double autoCompleteY = 0;
  int? selectedTab = null;

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
    themeData.menu..textStyle = const TextStyle(color: Colors.white);
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
      ..selectedStatus.decoration = BoxDecoration(
          color: Colors.black26,
          border: Border(top: BorderSide(color: Colors.greenAccent, width: 3)))
      ..highlightedStatus.decoration = BoxDecoration(color: Colors.black12);
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

  void initializeTreeView() async {
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
    debugPrint("autosave");
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
        content: SingleChildScrollView(
            controller: ScrollController(),
            child: Container(
              constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 2),
              child: field,
            )));
  }

  void openFile(String filepath) async {
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
      tabs.add(createFileTab(filename, content, language, filepath));
      selectedTab = tabs.length - 1;
    });
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
    project = ModalRoute.of(context)!.settings.arguments as CCSolution;
    if (documentList.isEmpty) {
      // Populate the file browser tree once
      initializeTreeView();
    }
    var tabController = TabbedViewController(
      tabs,
    );
    tabController.selectedIndex = tabs.isNotEmpty? selectedTab : null;
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
                        /// Just refresh the state
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
                            children: getAutoCompleteControls(null))))))
    ]);

    return Scaffold(
      drawer: MyDrawer(documentList, project, (String filepath) {
        openFile(filepath);
        Navigator.pop(context);
      }),
      appBar: AppBar(
        title: null,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => {project.run()},
            icon: const Icon(Icons.play_arrow),
            tooltip: "Run Project",
          ),
          IconButton(
            onPressed: () => {},
            icon: const Icon(Icons.assessment_rounded),
            tooltip: "Toggle Console",
          ),
          IconButton(
            onPressed: () => {Navigator.pop(context)},
            icon: const Icon(Icons.close),
            tooltip: "Close Project",
          ),
          IconButton(onPressed: () => {}, icon: const Icon(Icons.more_horiz)),
          const SizedBox(width: 16.0),
        ],
      ),
      body: page,
    );
  }
}
