/**
 * File: file_widget.dart
 * Package:
 * Project: tree_view
 * Author: Ajil Oommen (ajil@altorumleren.com)
 * Description:
 * Date: 06 January, 2019 2:03 PM
 */

import 'package:flutter/material.dart';

import 'package:corecoder_develop/filebrowser/utils/utils.dart';

class FileWidget extends StatelessWidget {
  final String fileName;
  final DateTime lastModified;
  final String path;
  final void Function(String filepath) onTap;

  FileWidget({required this.path, required this.fileName, required this.lastModified, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget fileNameWidget = Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 4, 8),
        child: Text(fileName, style: const TextStyle(fontSize: 16)));
    Widget lastModifiedWidget = Text(
      Utils.getFormattedDateTime(dateTime: lastModified),
    );
    Icon fileIcon = const Icon(Icons.insert_drive_file);

    return TextButton(
        onPressed: (() => onTap(path)),
        child: Row(children: [
          fileIcon,
          fileNameWidget
        ]));
  }
}
