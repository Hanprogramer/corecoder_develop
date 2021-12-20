import 'package:corecoder_develop/editor.dart';
import 'package:corecoder_develop/plugins_browser.dart';
import 'package:corecoder_develop/settings.dart';
import 'package:corecoder_develop/util/theme_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'homepage.dart';
import 'editor_drawer.dart';

void main() async{
  runApp(const CoreCoderApp());
}


class CoreCoderApp extends StatefulWidget {
  const CoreCoderApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CoreCoderAppState();
  }
}

class CoreCoderAppState extends State<CoreCoderApp>{
  String themeName = "core-coder-dark";
  @override
  void initState(){
    super.initState();
    ThemeManager.currentTheme.addListener(() {
      setState(() {
        themeName = ThemeManager.currentTheme.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CoreCoder Develop',
        theme: ThemeManager.getThemeData(themeName:themeName),
        //home: HomePage(),
        initialRoute: "/",
        routes: {
          "/": (context) => HomePage(),
          EditorPage.routeName: (context) => const EditorPage(),
          SettingsPage.routeName: (context) => SettingsPage(),
          PluginsBrowser.routeName: (context) => const PluginsBrowser()
        },
      ),
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<DrawerStateInfo>(
            create: (_) => DrawerStateInfo()),
      ],
    );
  }
}
