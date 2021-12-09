/**
 * File: directory_widget.dart
 * Package:
 * Project: tree_view
 * Author: Ajil Oommen (ajil@altorumleren.com)
 * Description:
 * Date: 06 January, 2019 2:04 PM
 */

import 'package:corecoder_develop/util/theme_manager.dart';
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
    Widget titleWidget = Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: Text(directoryName,
            style: TextStyle(
                fontSize: 16,
                color: ThemeManager.getThemeColor("foreground"))));

    Icon folderIcon = const Icon(Icons.folder);

    IconButton expandButton = IconButton(
      icon: const Icon(Icons.navigate_next),
      onPressed: onPressedNext,
    );

    Widget lastModifiedWidget = Text(
      Utils.getFormattedDateTime(dateTime: lastModified),
    );

    return TextButton(
        onPressed: (() => onPressedNext!()),
        child: Row(children: [
          folderIcon,
          titleWidget,
          const Spacer(flex: 1),
          expandButton
        ]));
  }
}
