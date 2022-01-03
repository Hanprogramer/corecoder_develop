import 'dart:convert';
import 'dart:typed_data';

import 'package:corecoder_develop/modules/module_jsplugins.dart';
import 'package:corecoder_develop/modules/module_minecraft.dart';
import 'package:corecoder_develop/modules/module_core.dart';
import 'package:corecoder_develop/util/plugins_manager.dart';
import 'package:flutter/material.dart';

class ModulesManager {
  static List<Module> internalModules = List.empty(growable: true);
  static List<JsModule> externalModules = List.empty(growable: true);
  Function? onFinishedLoading;

  static List<Module> get modules {
    return List.from(internalModules)..addAll(externalModules);
  }

  static const JsonDecoder decoder = JsonDecoder();
  static const JsonEncoder encoder = JsonEncoder.withIndent('\t');

  Future<void> initialize(BuildContext context) async {
    await PluginsManager.reloadPlugins(this, context);
  }

  void onInitialized(BuildContext context) {
    /// called by PluginsManager so the timing is right
    debugPrint("Initializing modules (${modules.length})");
    for (Module m in modules) {
      m.onInitialized(this, context);
    }
    if (onFinishedLoading != null) {
      onFinishedLoading!();
    }
  }

  ModulesManager(BuildContext context) {
    internalModules.clear();
    internalModules.add(CoreModule());
    internalModules.add(MinecraftModule());
  }

  static Module? getModuleByIdentifier(String id) {
    for (var m in modules) {
      if (m.identifier == id) {
        return m;
      }
    }
    return null;
  }

  Template? getTemplateByIdentifier(String templateID) {
    for (var module in modules) {
      for (var template in module.templates) {
        if (template.identifier == templateID) {
          return template;
        }
      }
    }
    return null;
  }
}

class Template {
  String title = "Template.Title",
      desc = "Template.Desc",
      version = "Template.Version",
      identifier = "com.corecoder.templates.template1";
  Map<String, String> options;
  Widget icon;
  Function(Map<String, dynamic> args) onCreated;

  Template(this.title, this.desc, this.version, this.options, this.onCreated,
      this.icon, this.identifier);
}

abstract class Module {
  List<Template> templates = List.empty(growable: true);
  String name = "Module.name",
      desc = "Module.desc",
      author = "Module.author",
      version = "Module.version";
  Uint8List? imageRaw;

  Widget get icon {
    if (imageRaw != null) {
      return Image(
          image: ResizeImage.resizeIfNeeded(
              48, 48, Image.memory(imageRaw!,
            isAntiAlias: true,
            filterQuality: FilterQuality.high,).image,
          ),

      );
    }
    return const Icon(Icons.extension, size: 48,);
  }

  String identifier;

  Module(this.name, this.desc, this.author, this.version, this.imageRaw,
      this.identifier);

  void onInitialized(ModulesManager modulesManager, BuildContext buildContext){
    templates.clear();
  }
  List<String> onAutoComplete(String language, String lastToken);
  void addTemplate(Template template) {
    templates.add(template);
  }
//TODO: void onGetAutoComplete(...)
}
