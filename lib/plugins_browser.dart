import 'package:flutter/material.dart';
class PluginsBrowser extends StatefulWidget{
  static const routeName = "/Settings/PluginsManager/";

  const PluginsBrowser({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => PluginsBrowserState();
}

class PluginsBrowserState extends State<PluginsBrowser>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body:Column(
        children: [
          Text('Plugins Browser'),
        ],
      )
    );
  }
}