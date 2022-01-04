import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:corecoder_develop/main.dart';
import 'package:corecoder_develop/screens/editor/editor_console.dart';
import 'package:flutter/material.dart';
import 'modules_manager.dart';
import 'dart:isolate';
import 'package:process_runner/process_runner.dart';
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

  void run(EditorConsoleController controller) async {
    if(currentRunConfig > runConfig.length){
      debugPrint("[Error] can't find that run configuration index");
      return;
    }
    if (Platform.isWindows) {
      debugPrint(
          "[CC Debug] starting project on windows config `${runConfig[currentRunConfig].executable}` on $slnFolderPath");
      if (runConfig[currentRunConfig].type == "process") {

        var proc = await Process.start(
            runConfig[currentRunConfig].executable, runConfig[currentRunConfig].arguments,
            workingDirectory: slnFolderPath, runInShell: true, mode: ProcessStartMode.detachedWithStdio);
        controller.setText("");
        // stdout.addStream(proc.stdout);
        //proc.stdout.pipe(stdout);

        proc.stdout.transform(utf8.decoder).listen((event) {
          controller.appendText(event);
          debugPrint(event);
        });
        proc.stderr.transform(utf8.decoder).forEach((event) {
          controller.appendText(event);
          debugPrint(event);
        });
        //debugPrint("[STDERR] ${result.stderr}");
      }
    }else if(Platform.isAndroid){
      if (runConfig[currentRunConfig].type == "open_with") {
        var pathType = runConfig[currentRunConfig].arguments[0];
        assert(pathType == "relative" || pathType == "absolute");
        CoreCoderAppState.methodChannel.invokeMethod("androidOpenFileWith", {
          "package": runConfig[currentRunConfig].executable,
          "filepath": (pathType == "absolute")
              ? runConfig[currentRunConfig].arguments[1]
              : slnFolderPath + runConfig[currentRunConfig].arguments[1], // the filepath
        });
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
