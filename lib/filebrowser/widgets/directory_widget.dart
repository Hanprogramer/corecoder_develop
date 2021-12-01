/**
 * File: directory_widget.dart
 * Package:
 * Project: tree_view
 * Author: Ajil Oommen (ajil@altorumleren.com)
 * Description:
 * Date: 06 January, 2019 2:04 PM
 */

import 'package:flutter/material.dart';

import 'package:corecoder_develop/filebrowser/utils/utils.dart';

class DirectoryWidget extends StatelessWidget {
  final String path;
  final String directoryName;
  final DateTime lastModified;
  final VoidCallback? onPressedNext;

  DirectoryWidget({
    required this.path,
    required this.directoryName,
    required this.lastModified,
    this.onPressedNext,
  });

  @override
  Widget build(BuildContext context) {
    Widget titleWidget = Text(directoryName);
    Icon folderIcon = Icon(Icons.folder);

    IconButton expandButton = IconButton(
      icon: Icon(Icons.navigate_next),
      onPressed: onPressedNext,
    );

    Widget lastModifiedWidget = Text(
      Utils.getFormattedDateTime(dateTime: lastModified),
    );

    return Card(
      child: ListTile(
        leading: folderIcon,
        title: titleWidget,
        subtitle: lastModifiedWidget,
        trailing: expandButton,
        onTap: (()=> onPressedNext!()),
      ),
    );
  }
}
