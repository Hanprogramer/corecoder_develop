import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:corecoder_develop/modules/module_jsplugins.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'modules_manager.dart';

class PluginsManager {
  static bool isInitialized = false;
  static String syncPluginsPath = "";
  static String projectsPath = ""; // todo: move this somewhere more general

  static Future<String> get pluginsPath async {
    if (!isInitialized) {
      await initialize();
    }
    return syncPluginsPath;
  }

  static Future<bool> checkPluginsExist(String identifier, String version)async{
    var path = await pluginsPath;
    if(await Directory(path + Platform.pathSeparator + identifier+"@"+version).exists()){
      return true;
    }
    return false;
  }

  static Future<void> initialize() async {
    String path = (await getApplicationDocumentsDirectory()).path +
        Platform.pathSeparator +
        "CoreCoder" +
        Platform.pathSeparator;
    if (Platform.isAndroid) {
      path = (await getExternalStorageDirectory())!.path +
          Platform.pathSeparator +
          "CoreCoder" +
          Platform.pathSeparator;
    } else {
      //TODO: add more platforms
    }
    projectsPath = path+"projects"+
        Platform.pathSeparator;
    Directory dir;
    dir = Directory(projectsPath);
    if(await dir.exists() == false){
      dir.createSync(recursive: true);
    }
    syncPluginsPath = path+"plugins"+
        Platform.pathSeparator;

    dir = Directory(syncPluginsPath);
    if(await dir.exists() == false){
      dir.createSync(recursive: true);
    }
    // Check if the folder is created or not
    dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    isInitialized = true;
  }

  static Future<void> reloadPlugins(ModulesManager modulesManager,BuildContext context) async {
    if (!isInitialized) {
      await initialize();
    }
    ModulesManager.externalModules.clear();
    var dir = Directory(await pluginsPath);
    var list = <FileSystemEntity>[];
    try {
      dir.list().listen((FileSystemEntity entity) {
        list.add(entity);
      }).onDone(() async {
        for(var file in list){
          JsModule? module = await importModuleFromFolder(path: file.path);
          if (module != null) {
            debugPrint("Loaded JSModule ${module.name}");
            ModulesManager.externalModules.add(module);
          } //TODO:warn user if module not loaded
        }
        modulesManager.onInitialized(context);
      });
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  /// Reads the module from a file asynchronously
  static Future<JsModule?> importModuleFromFolder({required String path}) async {
    try {
      // the required files
      var folder = Directory(path);
      var manifest =
          File(folder.path + Platform.pathSeparator + "manifest.json");
      var icon = File(folder.path + Platform.pathSeparator + "icon.png");
      var hasIcon = await icon.exists();
      var main = File(folder.path + Platform.pathSeparator + "main.js");

      // check if the files exists
      if (await folder.exists() == false) throw IOException;
      if (await manifest.exists() == false) throw IOException;
      if (await main.exists() == false) throw IOException;

      // loading the manifest json
      var manifestJSON =
          ModulesManager.decoder.convert(await manifest.readAsString());
      String title = manifestJSON["title"];
      String version = manifestJSON["version"];
      String description = manifestJSON["description"];
      String author = manifestJSON["author"];
      String identifier = manifestJSON["identifier"];
      Uint8List? icon64;
      if (hasIcon) {
        icon64 = await icon.readAsBytes();
      }
      JsModule module = JsModule(title, description, author, version, icon64,
          identifier, await main.readAsString(), path);
      return module;
    } on IOException catch (error) {
      debugPrint("IOException:${error.toString()}");
    } on Exception catch (error) {
      debugPrint("Unknown exception:${error.toString()}");
    }
  }
}
