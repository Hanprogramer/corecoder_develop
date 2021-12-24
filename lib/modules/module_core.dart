import 'dart:io' show File;
import 'package:corecoder_develop/util/modules_manager.dart';
import 'package:flutter/material.dart';
class CoreModule extends Module { //TODO doesnt work

  @override
  CoreModule()
      : super(
            "Built-in",
            "Provides core functionality",
            "skybird23333",
            "Corecoder 0.0.1",
            null,
            "com.corecoder.coremodule");

  Future<void> createSolution(String filepath, Map<String, dynamic> args, {String? bpPath, String? rpPath}) async {
    /// ---------------------------
    /// Create .ccsln.json file
    /// ---------------------------
    var obj = {
      "cc_version": "0.0.1",
      "name": "package name",
      "author": "youre name",
      "description": "package description",
      "identifier": identifier,
      // must be unique to every module
      "folders": {
      },
      "run_config": [
      ]
    };

    // Write the file asynchronously
    var slnFile = File(filepath);
    await slnFile.create(recursive: true);
    await slnFile.writeAsString(ModulesManager.encoder.convert(obj));
  }

  @override
  void onInitialized(ModulesManager modulesManager, BuildContext buildContext) async {
    super.onInitialized(modulesManager, buildContext);
    var template = Template(
        "Empty", //title
        "Empty project", //desc
        "",
        {},
            (Map<String, dynamic> args) async {
      //do absolutely nothing because this is empty
        },
        icon, "com.corecoder.empty");

    templates.add(template);
  }

  @override
  List<String> onAutoComplete(String language, String lastToken) {
    return [];
  }

}
