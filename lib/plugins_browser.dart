import 'package:flutter/material.dart';
class PluginsBrowser extends StatefulWidget{
  static const routeName = "/Settings/PluginsManager/";

  const PluginsBrowser({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => PluginsBrowserState();
}
class PluginsItem {
  String name, author, repo, version, iconUrl;
  PluginsItem(this.name, this.author, this.repo, this.version, this.iconUrl);
}
class PluginsBrowserState extends State<PluginsBrowser>{
  List<PluginsItem> items = [];
  /*Future<PluginsItem?> pluginsItemFromFirebase(DatabaseReference ref)async{
    var event = await ref.once();
    if(event.snapshot.value == null) return null;
    var value = event.snapshot.value as Map;
    return PluginsItem(value["name"], value["author"], value["repo"], value["version"], value["icon"]);
  }

  void reloadPlugins({String query=""})async{
    items.clear();
    Query q = ref.orderByChild("downloads").limitToFirst(20);
    DataSnapshot event = await q.get();
    for(var data in event.children){
      var item = await pluginsItemFromFirebase(data.ref);
      if(item != null){
        items.add(item);
      }
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body:Column(
        children: List.generate(items.length, (index) {
          return ListTile(title: Text(items[index].name),);
        }),
      )
    );
  }
}