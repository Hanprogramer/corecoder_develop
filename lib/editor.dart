import 'dart:async';
import 'dart:io';

import 'package:corecoder_develop/util/custom_code_box.dart' show InnerField, InnerFieldState;
import 'package:corecoder_develop/editor_drawer.dart';
import 'package:corecoder_develop/util/theme_manager.dart';
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
      ..color = const Color(0x3C3F4566);
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
    GlobalKey<InnerFieldState> _innerFieldState = GlobalKey<InnerFieldState>();
    var field = InnerField(key: _innerFieldState,
        language: language,
        theme: ThemeManager.getHighlighting(),
        source: source,
        filePath: filePath,
        onChange : (String filePath, String source){
          autoSaveTimer.reset();
        }
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
    });
  }

  @override
  Widget build(BuildContext context) {
    project = ModalRoute.of(context)!.settings.arguments as CCSolution;
    if (documentList.isEmpty) {
      // Populate the file browser tree once
      initializeTreeView();
    }
    final page = Column(//direction: Axis.vertical,
        children: [
      Expanded(
          child: tabs.isNotEmpty
              ? TabbedViewTheme(
                  data: getTabTheme(),
                  child: TabbedView(
                    onTabClose: (tabIndex, tabData) {
                      setState(() {
                        /// Just refresh the state
                      });
                    },
                    controller: TabbedViewController(tabs),
                  ))
              : const Center(child: Text("No file opened"))),
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
            icon: const Icon(FontAwesomeIcons.play),
            tooltip: "Run Project",
          ),
          IconButton(
            onPressed: () => {Navigator.pop(context)},
            icon: const Icon(FontAwesomeIcons.timesCircle),
            tooltip: "Close Project",
          ),
          IconButton(
              onPressed: () => {},
              icon: const Icon(FontAwesomeIcons.ellipsisV)),
          const SizedBox(width: 16.0),
        ],
      ),
      body: page,
    );
  }
}
