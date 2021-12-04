import 'package:corecoder_develop/modules/module_minecraft.dart';
import 'package:flutter/material.dart';
class ModulesManager{
  static List<Module> modules = List.empty(growable: true);

  void initialize() {
    for (Module m in modules) {
      m.onInitialized(this);
    }
  }

  ModulesManager() {
    modules.add(MinecraftModule());
    initialize();
  }

  static Module? getModuleByIdentifier(String id){
    for(var m in modules){
      if(m.identifier == id){
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
class Template{
  String title = "Template.Title",
      desc = "Template.Desc",
      version = "Template.Version",
      identifier = "com.corecoder.templates.template1";
  Map<String, String> options;
  Image icon;
  Function(Map<String, dynamic> args) onCreated;

  Template(this.title, this.desc, this.version, this.options, this.onCreated,
      this.icon, this.identifier);
}

abstract class Module{
  List<Template> templates = List.empty(growable: true);
  String name="Module.name", desc="Module.desc", author="Module.author", version="Module.version";
  Image icon;
  String identifier;
  Module(this.name, this.desc, this.author, this.version, this.icon, this.identifier);
  void onInitialized(ModulesManager tm);
  void addTemplate(Template template){
    templates.add(template);
  }
  //TODO: void onGetAutoComplete(...)
}