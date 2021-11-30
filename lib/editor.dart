import 'dart:io';

import 'package:corecoder_develop/custom_code_box.dart';

// import 'package:example/readme/readme_examples.dart';
import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';

class EditorPage extends StatefulWidget {
  static const String routeName = "/EditorPage";

  const EditorPage({Key? key}) : super(key: key);

  @override
  _EditorPageState createState() => _EditorPageState();
}

class FolderNode {
  final String name;
  final String path;

  FolderNode({required this.name, required this.path});
}

class FileNode {
  final String name;
  final String path;

  FileNode({required this.name, required this.path});
}

class _EditorPageState extends State<EditorPage> {
  late CCProject project;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> readFolder(Directory dir, Node node, List<Node> children) async {
    /// Walk the dir and add it to the parent node
    dir.list(recursive: false).listen((file) async {
      var stat = await file.stat();
      if (stat.type == FileSystemEntityType.directory) {
        List<Node> _children = List.empty(growable: true);
        FolderNode data =
            FolderNode(name: path.basename(file.path), path: file.path);
        Node newNode = Node(
            label: path.basename(file.path),
            key: file.hashCode.toString(),
            data: data,
            children: _children,
            icon: Icons.folder);
        children.add(newNode);
        // Recursively call this method
        await readFolder(Directory(file.path), newNode, _children);
      } else {
        // Is File
        FileNode data =
            FileNode(name: path.basename(file.path), path: file.path);

        children.add(Node(
            label: path.basename(file.path),
            key: file.hashCode.toString(),
            data: data,
            icon: Icons.insert_drive_file));
      }
    });
  }

  void initializeTreeView() {
    fileBrowserNodes.clear();
    for (var key in project.folders.keys) {
      var dir = project.slnFolderPath +
          Platform.pathSeparator +
          (project.folders[key])!;
      FolderNode data = FolderNode(name: path.basename(dir), path: dir);

      List<Node> children = List.empty(growable: true);
      Node node = Node(label: key, key: dir, data: data, children: children);
      fileBrowserNodes.add(node);
      readFolder(Directory(dir), node, children);
    }
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

  List<Node> fileBrowserNodes = List.empty(growable: true);

  @override
  Widget build(BuildContext context) {
    TreeViewController _treeViewController =
        TreeViewController(children: fileBrowserNodes);
    project = ModalRoute.of(context)!.settings.arguments as CCProject;
    initializeTreeView();
    final codeBox = InnerField(
        language: 'json', theme: 'atom-one-dark', source: project.name);
    final page = Container(
      constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
          minWidth: double.infinity),
      child: codeBox,
    );

    return Scaffold(
      backgroundColor: Color(0xFF363636),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.

        child: Flex(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            direction: Axis.vertical,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.black87,
                ),
                child: Text(
                  project.name,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Expanded(
                  child: TreeView(
                controller: _treeViewController,
                onNodeTap: (key) {
                  Node? selectedNode = _treeViewController.getNode(key);
                  var selectedModel = selectedNode!.data;
                },
              )),
            ]),
      ),
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
    );
  }
}
