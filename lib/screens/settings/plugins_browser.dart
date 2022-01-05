import 'dart:convert';
import 'dart:io';

import 'package:corecoder_develop/modules/module_jsplugins.dart';
import 'package:corecoder_develop/util/modules_manager.dart';
import 'package:corecoder_develop/util/plugins_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:github/github.dart';
import 'package:archive/archive.dart';

class PluginsBrowser extends StatefulWidget {
  static const routeName = "/Settings/PluginsManager/";
  final ModulesManager modulesManager;

  const PluginsBrowser({Key? key, required this.modulesManager}) : super(key: key);

  @override
  State<StatefulWidget> createState() => PluginsBrowserState();
}

class PluginsItem {
  String name, author, repo, version, iconUrl, desc, identifier;
  bool isInstalled = false;
  bool isProcessing = false;
  String processingMessage = "";

  String get folderName {
    return identifier + "@" + version;
  }

  PluginsItem(this.name, this.author, this.repo, this.version, this.iconUrl,
      this.desc, this.identifier, this.isInstalled);
}

class PluginsBrowserState extends State<PluginsBrowser> {
  List<PluginsItem> items = [];

  JsonDecoder decoder = const JsonDecoder();
  GitHub github = GitHub(); // Create an anonymous github client
  bool _isLoadingVisible = false;

  Future<bool> uninstallPlugins(PluginsItem item) async {
    debugPrint("Uninstalling ${item.identifier}");
    setState(() {
      item.isProcessing = true;
    });
    JsModule? module;
    for (var m in ModulesManager.externalModules) {
      if (m.identifier == item.identifier) {
        module = m;
      }
    }
    if (module != null) {
      debugPrint("Found module. deleting files...");
      var path = module.moduleFolder;
      await Directory(path).delete(recursive: true);
      ModulesManager.externalModules.remove(module);
      // Refresh the modules manager
      widget.modulesManager.onInitialized(context);
      setState(() {
        item.isProcessing = false;
        item.isInstalled = false;
      });
    } else {
      setState(() {
        item.isInstalled = false;
        item.isProcessing = false;
      });
      return false;
    }
    setState(() {
      item.isInstalled = false;
      item.isProcessing = false;
    });
    // Refresh the modules manager
    PluginsManager.reloadPlugins(widget.modulesManager, context);
    widget.modulesManager.onInitialized(context);
    return true;
  }

  Future<bool> installPlugins(PluginsItem item) async {
    setState(() {
      item.isProcessing = true;
    });
    if (!await PluginsManager.checkPluginsExist(
        item.identifier, item.version)) {
      try {
        setState(() {
          item.processingMessage = "Fetching data";
        });
        Repository repo = await github.repositories.getRepository(
            RepositorySlug.full(
                item.repo.replaceAll("https://github.com/", "")));

        setState(() {
          item.processingMessage = "Processing releases";
        });
        List<Release> releases =
            await github.repositories.listReleases(repo.slug()).toList();

        if (repo.hasDownloads) {
          setState(() {
            item.processingMessage = "Getting latest update";
          });
          var r = releases.first;
          if (r.zipballUrl != null) {
            setState(() {
              item.processingMessage = "Downloading data";
            });
            var bytes = (await http.get(Uri.parse(r.zipballUrl!))).bodyBytes;
            var path = await PluginsManager.pluginsPath +
                item.folderName +
                Platform.pathSeparator;
            var archive = ZipDecoder().decodeBytes(bytes);

            // Create the folder if not exists
            await Directory(path).create(recursive: true);

            setState(() {
              item.processingMessage = "Extracting data";
            });
            // Extract the contents of the Zip archive to disk.
            for (final file in archive) {
              final filename = (file.name.split("/")..removeAt(0)).join("/");
              if (file.isFile) {
                final data = file.content as List<int>;
                File(path + filename)
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(data);
              } else {
                Directory(path + filename).create(recursive: true);
              }
              debugPrint(filename);
              setState(() {
                item.isInstalled = true;
                item.isProcessing = false;
              });
            }
          } else {
            debugPrint("[Plugins Manager] This repository has no zip url");
            return false;
          }
        } else {
          debugPrint(
              "[Plugins Manager] Error: Plugins have no downloads available");
        }
      } on GitHubError catch (err) {
        debugPrint(
            "[Plugins Manager] Can't find plugins repository ${item.identifier}");
        return false;
      }
    } else {
      debugPrint("[PluginsManager] The plugins is already installed");
      setState(() {
        item.isInstalled = true;
        item.isProcessing = false;
      });
      return false;
    }

    setState(() {
      item.isProcessing = false;
    });
    // Refresh the modules manager
    PluginsManager.reloadPlugins(widget.modulesManager, context);
    widget.modulesManager.onInitialized(context);


    /* Do Something with repo */
    if (!item.isInstalled) {
      return false;
    }

    return true;
  }

  void reloadPlugins({String query = ""}) async {
    items.clear();
    _isLoadingVisible = true;
    Response resp = await http.get(Uri.parse(
        "https://raw.githubusercontent.com/CoreCoder-Devs/corecoder_plugins/main/plugins.json"));
    _isLoadingVisible = false;
    if (resp.statusCode == 200) {
      // OK
      Map obj = decoder.convert(resp.body);
      for (var key in obj.keys) {
        var isInstalled = false;
        var identifier = obj[key]["identifier"];
        for (Module m in ModulesManager.externalModules) {
          if (m.identifier == identifier) {
            isInstalled = true;
          }
        }
        items.add(PluginsItem(
            obj[key]["name"],
            obj[key]["author"],
            obj[key]["repo"],
            obj[key]["version"],
            obj[key]["icon"],
            obj[key]["desc"],
            obj[key]["identifier"],
            isInstalled));
        setState(() {}); // refresh
      }
    }
  }

  @override
  void initState() {
    super.initState();
    reloadPlugins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Install Plugins"),
        ),
        body: Column(children: [
          Visibility(
              visible: _isLoadingVisible, child: const Text('Loading...')),
          Column(
            children: List.generate(items.length, (index) {
              var item = items[index];
              return ListTile(
                title: Text(item.name),
                leading: Image.network(item.iconUrl),
                subtitle: Text(item.desc),
                trailing: (item.isProcessing)
                    ? Container(
                        constraints: const BoxConstraints(maxWidth: 256),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                          Text(item.processingMessage),
                          const CircularProgressIndicator(
                            value: null,
                          ),
                        ]))
                    : (item.isInstalled)
                        ? ElevatedButton(
                            onPressed: () {
                              uninstallPlugins(item);
                            },
                            child: const Text("Uninstall"),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              installPlugins(item);
                            },
                            child: const Text("Install")),
                onTap: () {},
              );
            }),
          )
        ]));
  }
}
