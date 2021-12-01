import 'dart:convert';
import 'dart:io' show Directory, File, FileMode, Platform;
import 'package:corecoder_develop/modules_manager.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class MinecraftModule extends Module {
  String comMojang = ""; // platform dependent

  static const JsonDecoder decoder = JsonDecoder();
  static const JsonEncoder encoder = JsonEncoder.withIndent('\t');

  @override
  MinecraftModule()
      : super(
            "Minecraft Bedrock Edition",
            "Adds in minecraft addon template projects",
            "Hanprogramer",
            "Minecraft 1.16.0+",
            Image.memory(base64Decode(
                "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")),
            "com.corecoder.mcbedrock");

  @override
  void onInitialized(ModulesManager tm) {
    if (Platform.isWindows) {
      comMojang = Platform.environment['LOCALAPPDATA'] as String;
      comMojang +=
          "\\Packages\\Microsoft.MinecraftUWP_8wekyb3d8bbwe\\LocalState\\games\\com.mojang\\";
    } else if (Platform.isAndroid) {
      comMojang = "/storage/emulated/0/games/com.mojang/";
    } else {
      comMojang = "UNKNOWN";
    }

    var addonTemplate = Template("Minecraft Addon",
        "Minecraft behavior + resource packs", "Minecraft 1.16.0+", {
      // Options : Type
      "Name": "String",
      "Description": "String",
      "Author": "String"
    }, (Map<String, dynamic> args) async {
      // OnCreated

      // Create the BP first
      Uuid uuid = Uuid();
      var bpUuid = uuid.v4();
      var bpPath = comMojang +
          "development_behavior_packs" +
          Platform.pathSeparator +
          args["Name"] +
          Platform.pathSeparator;
      var bpManifest = encoder.convert({
        "format_version": 2,
        "header": {
          "name": args["Name"],
          "description": args["Description"],
          "uuid": bpUuid,
          "version": [1, 0, 0],
          "min_engine_version": [1, 16, 0]
        },
        "modules": [
          {
            "type": "data",
            "uuid": uuid.v4(),
            "version": [1, 0, 0]
          }
        ]
      });

      // Create the manifest
      File fBpManifest = File(bpPath + "manifest.json");
      await fBpManifest.create(recursive: true);
      await fBpManifest.writeAsString(bpManifest);

      // Create the scaffolding folder
      var folders = [
        "animation_controllers",
        "entities",
        "items",
        "blocks",
        "functions",
        "recipes",
        "texts"
      ];
      for (String folderName in folders) {
        await Directory(bpPath + folderName).create(recursive: true);
      }
      // -- Create BP END

      // Create the RP first
      var rpUuid = uuid.v4();
      var rpPath = comMojang +
          "development_resource_packs" +
          Platform.pathSeparator +
          args["Name"] +
          Platform.pathSeparator;
      var rpManifest = encoder.convert({
        "format_version": 2,
        "header": {
          "name": args["Name"],
          "description": args["Description"],
          "uuid": rpUuid,
          "version": [1, 0, 0],
          "min_engine_version": [1, 16, 0]
        },
        "modules": [
          {
            "type": "resources",
            "uuid": uuid.v4(),
            "version": [1, 0, 0]
          }
        ]
      });

      // Create the manifest
      File fRpManifest = File(rpPath + "manifest.json");
      await fRpManifest.create(recursive: true);
      await fRpManifest.writeAsString(rpManifest);

      // Create the scaffolding folder
      var rpFolders = [
        "animation_controllers",
        "entities",
        "items",
        "blocks",
        "functions",
        "recipes",
        "texts"
      ];
      for (String folderName in rpFolders) {
        await Directory(rpPath + folderName).create(recursive: true);
      }

      // -- Create RP END
      /// ---------------------------
      /// Create .ccsln.json file
      /// ---------------------------
      var obj = encoder.convert({
        "cc_version": "0.0.1",
        "name": args["Name"],
        "author": args["Author"],
        "description": args["Desc"],
        "identifier": "com.hanprogramer.ccminecraft.addon",
        // must be unique to every module
        "folders": {
          "Behavior Pack": bpPath.replaceAll(comMojang, ""),
          "Resource Pack": rpPath.replaceAll(comMojang, ""),
        },
        "run_config": [
          {
            "type": "launch",
            "android": "com.mojang.minecraftpe",
            "windows": "undefined", //TODO: add windows 10 launch
            "args": []
          }
        ]
      });
      var slnFile = File(
          comMojang + Platform.pathSeparator + args["Name"] + ".ccsln.json");
      await slnFile.create(recursive: true);
      await slnFile.writeAsString(obj);
      return slnFile.path;
    }, icon, "com.hanprogramer.ccminecraft.addon");

    /// -------------------------
    /// BP Template
    /// -------------------------
    var bpTemplate = Template("Minecraft Behavior Pack",
        "Minecraft behavior pack only", "Minecraft 1.16.0+", {
      // Options : Type
      "Name": "String",
      "Description": "String",
      "Author": "String"
    }, (Map<String, dynamic> args) async {
      // OnCreated

      // Create the BP first
      Uuid uuid = Uuid();
      var bpUuid = uuid.v4();
      var bpPath = comMojang +
          "development_behavior_packs" +
          Platform.pathSeparator +
          args["Name"] +
          Platform.pathSeparator;
      var bpManifest = encoder.convert({
        "format_version": 2,
        "header": {
          "name": args["Name"],
          "description": args["Description"],
          "uuid": bpUuid,
          "version": [1, 0, 0],
          "min_engine_version": [1, 16, 0]
        },
        "modules": [
          {
            "type": "data",
            "uuid": uuid.v4(),
            "version": [1, 0, 0]
          }
        ]
      });

      // Create the manifest
      File fBpManifest = File(bpPath + "manifest.json");
      await fBpManifest.create(recursive: true);
      await fBpManifest.writeAsString(bpManifest);

      // Create the scaffolding folder
      var folders = [
        "animation_controllers",
        "entities",
        "items",
        "blocks",
        "functions",
        "recipes",
        "texts"
      ];
      for (String folderName in folders) {
        await Directory(bpPath + folderName).create(recursive: true);
      }
      // -- Create BP END

      /// ---------------------------
      /// Create .ccsln.json file
      /// ---------------------------
      var obj = encoder.convert({
        "cc_version": "0.0.1",
        "name": args["Name"],
        "author": args["Author"],
        "description": args["Desc"],
        "identifier": "com.hanprogramer.ccminecraft.bp",
        // must be unique to every module
        "folders": {
          "Behavior Pack": bpPath.replaceAll(comMojang, ""),
        },
        "run_config": [
          {
            "type": "launch",
            "android": "com.mojang.minecraftpe",
            "windows": "undefined", //TODO: add windows 10 launch
            "args": []
          }
        ]
      });
      var slnFile = File(
          comMojang + Platform.pathSeparator + args["Name"] + ".ccsln.json");
      await slnFile.create(recursive: true);
      await slnFile.writeAsString(obj);
      return slnFile.path;
    }, icon, "com.hanprogramer.ccminecraft.bp");

    /// -------------------------
    /// RP Template
    /// -------------------------
    var rpTemplate = Template("Minecraft Resource Pack",
        "Minecraft resource pack only", "Minecraft 1.16.0+", {
      // Options : Type
      "Name": "String",
      "Description": "String",
      "Author": "String"
    }, (Map<String, dynamic> args) async {
      // OnCreated
      Uuid uuid = Uuid();
      // Create the RP first
      var rpUuid = uuid.v4();
      var rpPath = comMojang +
          "development_resource_packs" +
          Platform.pathSeparator +
          args["Name"] +
          Platform.pathSeparator;
      var rpManifest = encoder.convert({
        "format_version": 2,
        "header": {
          "name": args["Name"],
          "description": args["Description"],
          "uuid": rpUuid,
          "version": [1, 0, 0],
          "min_engine_version": [1, 16, 0]
        },
        "modules": [
          {
            "type": "resources",
            "uuid": uuid.v4(),
            "version": [1, 0, 0]
          }
        ]
      });

      // Create the manifest
      File fRpManifest = File(rpPath + "manifest.json");
      await fRpManifest.create(recursive: true);
      await fRpManifest.writeAsString(rpManifest);

      // Create the scaffolding folder
      var rpFolders = [
        "animation_controllers",
        "entities",
        "items",
        "blocks",
        "functions",
        "recipes",
        "texts"
      ];
      for (String folderName in rpFolders) {
        await Directory(rpPath + folderName).create(recursive: true);
      }

      // -- Create RP END
      /// ---------------------------
      /// Create .ccsln.json file
      /// ---------------------------
      var obj = encoder.convert({
        "cc_version": "0.0.1",
        "name": args["Name"],
        "author": args["Author"],
        "description": args["Desc"],
        "identifier": "com.hanprogramer.ccminecraft.rp",
        // must be unique to every
        "folders": {
          "Resource Pack": rpPath.replaceAll(comMojang, ""),
        },
        "run_config": [
          {
            "type": "launch",
            "android": "com.mojang.minecraftpe",
            "windows": "undefined", //TODO: add windows 10 launch
            "args": []
          }
        ]
      });
      var slnFile = File(
          comMojang + Platform.pathSeparator + args["Name"] + ".ccsln.json");
      await slnFile.create(recursive: true);
      await slnFile.writeAsString(obj);
      return slnFile.path;
    }, icon, "com.hanprogramer.ccminecraft.rp");
    templates.add(addonTemplate);
    templates.add(bpTemplate);
    templates.add(rpTemplate);
  }
}
