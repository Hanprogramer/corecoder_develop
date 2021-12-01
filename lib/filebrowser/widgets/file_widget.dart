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
    Widget fileNameWidget = Text(this.fileName);
    Widget lastModifiedWidget = Text(
      Utils.getFormattedDateTime(dateTime: lastModified),
    );
    Icon fileIcon = Icon(Icons.insert_drive_file);

    return Card(
      elevation: 0.0,
      child: ListTile(
        leading: fileIcon,
        title: fileNameWidget,
        subtitle: lastModifiedWidget,
        onTap: (){onTap(path);},
      ),
    );
  }
}
