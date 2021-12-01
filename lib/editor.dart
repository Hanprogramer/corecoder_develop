import 'dart:io';

import 'package:corecoder_develop/custom_code_box.dart';
import 'package:corecoder_develop/editor_drawer.dart';

// import 'package:filebrowser/readme/readme_examples.dart';
import 'package:flutter/material.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import 'filebrowser/models/document.dart';
import 'main.dart';

class EditorPage extends StatefulWidget {
  static const String routeName = "/EditorPage";

  const EditorPage({Key? key}) : super(key: key);

  @override
  _EditorPageState createState() => _EditorPageState();
}
class _EditorPageState extends State<EditorPage> {
  late CCProject project;
  List<Document> documentList = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
    for (var key in project.folders.keys) {
      var dir = project.slnFolderPath +
          Platform.pathSeparator +
          (project.folders[key])!;
      List<Document> children = readFolder(Directory(dir));
      //await
      Document node = Document(
        name: key,
        dateModified: DateTime.now(),
        isFile: false,
        childData: children,
        path: project.folders[key]!,
      );

      docs.add(node);
    }
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

  Tab createFileTab(String title) {
    return Tab(
      child: Row(//direction: Axis.horizontal,
          children: [
        Text(title),
        IconButton(
          icon: const Icon(FontAwesomeIcons.times),
          onPressed: () {},
        )
      ]),
    );
  }

  void openFile(String filepath) {
    var filename = path.basename(filepath);
    tempTabs.add(createFileTab(filename));
    setState(() {
      editorTabs = tempTabs;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TreeViewController _treeViewController =
    //     TreeViewController(children: fileBrowserNodes);
    project = ModalRoute.of(context)!.settings.arguments as CCProject;
    initializeTreeView();
    final codeBox = InnerField(
        language: 'json', theme: 'atom-one-dark', source: project.name);
    final page = Container(
      child: Flex(direction: Axis.vertical, children: [
        TabBar(
          tabs: List.generate(editorTabs.length, (index) => editorTabs[index]),
          isScrollable: true,
        ),
        Container(
          child: codeBox,
          constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
              minWidth: double.infinity),
        )
      ]),
    );

    return DefaultTabController(
        length: editorTabs.length,
        child: Scaffold(
          backgroundColor: const Color(0xFF363636),
          drawer: MyDrawer(documentList, project, (String filepath) {
            openFile(filepath);
          }),
          appBar: AppBar(
            backgroundColor: Color(0xff23241f),
            title: null,
            // title: Text("Recursive Fibonacci"),
            centerTitle: false,

            actions: [
              IconButton(
                onPressed: () => {Navigator.pop(context)},
                icon: const Icon(FontAwesomeIcons.timesCircle),
                tooltip: "Close Project",
              ),
              IconButton(
                  onPressed: () => {}, icon: Icon(FontAwesomeIcons.ellipsisV)),
              // TextButton.icon(
              //   style: TextButton.styleFrom(
              //     padding: EdgeInsets.symmetric(horizontal: 8.0),
              //     primary: Colors.white,
              //   ),
              //   icon: Icon(FontAwesomeIcons.github),
              //   onPressed: () =>
              //       _launchInBrowser("https://github.com/BertrandBev/code_field"),
              //   label: Text("GITHUB"),
              // ),
              SizedBox(width: 16.0),
            ],
          ),
          body: SingleChildScrollView(
            child: page,
            controller: ScrollController(),
          ),
        ));
  }
}
