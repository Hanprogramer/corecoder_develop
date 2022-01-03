import 'dart:io' show File;
import 'package:corecoder_develop/modules/jsapi.dart';
import 'package:corecoder_develop/util/modules_manager.dart';
import 'package:flutter/material.dart';

import '../main.dart';
class CoreModule extends Module {

  @override
  CoreModule()
      : super(
            "Built-in",
            "Provides core functionality",
            "skybird23333",
            "Corecoder 0.0.1",
            null,
            "com.corecoder.coremodule");

  @override
  void onInitialized(ModulesManager modulesManager, BuildContext buildContext) async {
    super.onInitialized(modulesManager, buildContext);
    var template = Template(
        "Empty", //title
        "Empty project with no workspace plugins or files", //desc
        "",
        {
          "Project Name" : "String",
          "Author" : "String",
        },
            (Map<String, dynamic> args) async {
      //do absolutely nothing because this is empty
              /// ---------------------------
              /// Create .ccsln.json file
              /// ---------------------------
              var obj = {
                "cc_version": CoreCoderApp.version,
                "name": args["Project Name"],
                "author": args["Author"],
                "description": "",
                "identifier": identifier,
                // must be unique to every module
                "folders": {
                },
                "run_config": []
              };
              obj["folders"]["Workspace"] = ".";


              // Write the file asynchronously
              var slnFilePath = CoreCoder.getProjectFolder("core", args["Project Name"]) + "solution.ccsln.json";
              var slnFile = File(slnFilePath);
              await slnFile.create(recursive: true);
              await slnFile.writeAsString(ModulesManager.encoder.convert(obj));
              // Return the filepath so it loads the project automatically
              return slnFilePath;
        },
        icon, "com.corecoder.empty");

    templates.add(template);
  }

  @override
  List<String> onAutoComplete(String language, String lastToken) {
    return [];
  }

}
