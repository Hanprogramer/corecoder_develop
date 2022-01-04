import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../util/cc_project_structure.dart';
import '../../filebrowser/models/document.dart';
import '../../filebrowser/widgets/directory_widget.dart';
import '../../filebrowser/widgets/file_widget.dart';
import '../../main.dart';
import 'package:tree_view/tree_view.dart';
class DrawerStateInfo with ChangeNotifier {
  int _currentDrawer = 0;

  int get getCurrentDrawer => _currentDrawer;

  void setCurrentDrawer(int drawer) {
    _currentDrawer = drawer;
    notifyListeners();
  }

  void increment() {
    notifyListeners();
  }
}

class MyDrawer extends StatelessWidget {

  final CCSolution project;
  final List<Document> documentList;
  final void Function(String filepath) onFileTap;
  final void Function(String filepath) onFileLongTap;
  final void Function(String filepath) onDirLongTap;

  const MyDrawer(this.documentList, this.project, this.onFileTap, this.onFileLongTap, this.onDirLongTap);

  @override
  Widget build(BuildContext context) {
    var currentDrawer = Provider.of<DrawerStateInfo>(context).getCurrentDrawer;
    return Drawer(
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
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Expanded(
              child: TreeView(
                startExpanded: false,
                children: _getChildList(documentList),
                key: const PageStorageKey("file_browser_tree"),
              ),
            ),
          ]),
    );
  }

  List<Widget> _getChildList(List<Document> childDocuments) {
    return childDocuments.map((document) {
      if (!document.isFile) {
        return Container(
          margin: const EdgeInsets.only(left: 16.0),
          child: TreeViewChild(
            parent: _getDocumentWidget(
              document: document,
              onPressedNext: () {
                document.isOpened = !document.isOpened;
              },
            ),
            children: _getChildList(document.childData),
            startExpanded: document.isOpened,
          ),
        );
      }
      return Container(
        margin: const EdgeInsets.only(left: 16.0),
        child: _getDocumentWidget(
          document: document,
          onPressedNext: () {},
        ),
      );
    }).toList();
  }

  Widget _getDocumentWidget(
          {required Document document,
          required void Function() onPressedNext}) =>
      document.isFile
          ? _getFileWidget(document: document)
          : _getDirectoryWidget(
              document: document, onPressedNext: onPressedNext);

  DirectoryWidget _getDirectoryWidget(
          {required Document document,
          required void Function() onPressedNext}) =>
      DirectoryWidget(
        path: document.path,
        directoryName: document.name,
        lastModified: document.dateModified,
        onPressedNext: onPressedNext,
        onLongTap: onDirLongTap
      );

  FileWidget _getFileWidget({required Document document}) => FileWidget(
        path: document.path,
        fileName: document.name,
        lastModified: document.dateModified,
        onTap: onFileTap,
        onLongTap: onFileLongTap,
      );
}
