
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../editor.dart';
import 'modules_manager.dart';

/* Class for storing project information */
class CCSolution {
  final String name, desc, author, identifier, slnPath, slnFolderPath;
  DateTime dateModified;
  Image? get image{
    var module = ModulesManager.getModuleByIdentifier(identifier);
    if(module != null) {
      return module.icon;
    }
  }
  Map<String, String> folders = {};
  List<CCProject> projects = [];

  static const decoder = JsonDecoder();

  CCSolution(this.name, this.desc, this.author, this.identifier, this.slnPath,
      this.slnFolderPath, this.dateModified);

  static Future<CCSolution?> loadFromFile(String filepath) async{
    var file = File(filepath);
    var stat = await file.stat();
    if (await file.exists()) {
      String input = await file.readAsString();
      var obj = decoder.convert(input);
      try {

        var result = CCSolution(obj["name"], obj["description"] ?? "",
            obj["author"], obj["identifier"], filepath, file.parent.path, stat.modified);

        /// Add the solution project folders
        var folders = (obj["folders"] as Map);
        for (var key in folders.keys) {
          result.folders[key] = folders[key];
        }
        return result;
      } on Exception catch (e) {
        debugPrint("Error: error parsing solution: $filepath #${e.toString()}");
        return null;
      }
    } else {
      debugPrint("Error: project can't be found: $filepath");
      return null;
    }
  }
}

class CCProject {
  final String name, desc, author, identifier, slnPath, slnFolderPath, projPath;
  CCProject(this.name, this.desc, this.author, this.identifier, this.slnPath,
      this.slnFolderPath, this.projPath);
}