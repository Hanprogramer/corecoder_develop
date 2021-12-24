import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'modules_manager.dart';

/* Class for storing project information */
class CCSolution {
  final String name, desc, author, identifier, slnPath, slnFolderPath;
  DateTime dateModified;
  List<RunConfiguration> runConfig;
  int currentRunConfig = 0;

  Widget? get image {
    var module = ModulesManager.getModuleByIdentifier(identifier);
    if (module != null) {
      return module.icon;
    }
  }

  Map<String, String> folders = {};
  List<CCProject> projects = [];

  static const decoder = JsonDecoder();

  CCSolution(this.name, this.desc, this.author, this.identifier, this.slnPath,
      this.slnFolderPath, this.dateModified, this.runConfig);

  void run() async {

    if (Platform.isWindows && currentRunConfig < runConfig.length) {
      debugPrint(
          "[CC Debug] starting project on windows config `${runConfig[currentRunConfig].executable}` on $slnFolderPath");
      if (runConfig[currentRunConfig].type == "process") {
        var result = await Process.run(
            runConfig[currentRunConfig].executable, runConfig[currentRunConfig].arguments,
            workingDirectory: slnFolderPath);
        debugPrint("[STDOUT] ${result.stdout}");
        debugPrint("[STDERR] ${result.stderr}");
      }
    }
  }

  static Future<CCSolution?> loadFromFile(String filepath) async {
    var file = File(filepath);
    if (await file.exists()) {
      var stat = await file.stat();
      String input = await file.readAsString();
      try {
        var obj = decoder.convert(input);
        List<RunConfiguration> runConfigs = [];
        if(obj["run_config"] is Map) {
          runConfigs = RunConfiguration.loadFromJSON(obj["run_config"]);
        }
        var result = CCSolution(
            obj["name"],
            obj["description"] ?? "",
            obj["author"],
            obj["identifier"],
            filepath,
            file.parent.path,
            stat.modified,
            runConfigs);

        /// Add the solution project folders
        var folders = (obj["folders"] as Map);
        for (var key in folders.keys) {
          result.folders[key] = folders[key];
        }
        return result;
      } on Exception catch (e) {
        //debugPrint("Error: error parsing solution: $filepath #${e.toString()}");
        return null;
      }
    } else {
      //debugPrint("Error: project can't be found: $filepath");
      return null;
    }
  }
}

class CCProject {
  final String name, desc, author, identifier, slnPath, slnFolderPath, projPath;

  CCProject(this.name, this.desc, this.author, this.identifier, this.slnPath,
      this.slnFolderPath, this.projPath);
}

class RunConfiguration {
  String name, type, executable;
  List<String> arguments;

  RunConfiguration(this.name, this.type, this.executable, this.arguments);

  static List<RunConfiguration> loadFromJSON(Map json) {
    var result = <RunConfiguration>[];
    if (json.containsKey("windows") && Platform.isWindows) {
      try {
        for (var obj in json["windows"] as List) {
          var name = obj["name"] ?? "runConfig.name";
          var type = obj["type"] ?? "unknown";
          var executable = obj["executable"] ?? "runConfig.executable";
          var _args = (obj["args"] ?? []) as List;
          var args = <String>[];
          for(var arg in _args){
            args.add(arg);
          }
          result.add(RunConfiguration(name, type, executable, args));
        }
      } catch (err) {
        debugPrint(err.toString());
      }
    }

    //TODO: implement android run config
    return result;
  }
}
