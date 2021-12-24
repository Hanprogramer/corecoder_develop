import 'dart:io';

import 'package:corecoder_develop/screens/editor/editor.dart';
import 'package:corecoder_develop/screens/settings/plugins_browser.dart';
import 'package:corecoder_develop/util/cc_project_structure.dart';
import 'package:corecoder_develop/util/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/homepage/homepage.dart';
import 'screens/editor/editor_drawer.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

void main() async {
  runApp(const CoreCoderApp());
  if (CoreCoderApp.isDesktop) {
    doWhenWindowReady(() {
      const initialSize = Size(800, 600);
      appWindow.minSize = const Size(256, 256);
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
      appWindow.show();
    });
  }
}

const borderColor = Color(0xFF3BBA73);

class CoreCoderApp extends StatefulWidget {
  const CoreCoderApp({Key? key}) : super(key: key);
  static const String version = "v0.0.2";
  static bool isDesktop = (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  static bool isLandscape(BuildContext context){
    var q = MediaQuery.of(context);
    return q.orientation == Orientation.landscape || q.size.width > q.size.height;
  }
  @override
  State<StatefulWidget> createState() {
    return CoreCoderAppState();
  }
}

class CoreCoderAppState extends State<CoreCoderApp> {
  String themeName = "core-coder-dark";
  var borderColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _pref.then((value) {
      setState(() {
        themeName = value.getString("theme") ?? themeName;
        ThemeManager.currentTheme = ValueNotifier(themeName);
      });
      ThemeManager.currentTheme.addListener(() {
        setState(() {
          themeName = ThemeManager.currentTheme.value;
        });
      });
    });
    if (Platform.isWindows) {
      /// On windows, get the runtime arguments
      /// this is provided by windows when you "Open with" CoreCoder
      /// the result is a string to the absolute path of the file
      /// then handle the filepath to open
      MethodChannel channel = const MethodChannel('corecoder_develop');
      channel.invokeMethod('getRunArgs').then((result) async {
        debugPrint(result as String);
      });
    }


  }
  static final Future<SharedPreferences> _pref =
  SharedPreferences.getInstance();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      child: WindowBorder(
          color: borderColor,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'CoreCoder Develop',
            theme: ThemeManager.getThemeData(themeName: themeName),
            //home: HomePage(),
            initialRoute: "/",
            routes: {
              "/": (context) => HomePage(),
              EditorPage.routeName: (context) => const EditorPage(),
              PluginsBrowser.routeName: (context) => const PluginsBrowser()
            },
            builder: (BuildContext context, Widget? widget) {
              borderColor = Theme.of(context).primaryColor;
              return Container(
                  color: Theme.of(context).colorScheme.background,
                  child: Column(
                    children: [
                      // The title bar
                      if(CoreCoderApp.isDesktop)
                      WindowTitleBarBox(
                          child: Row(children: [
                        Expanded(
                            child: MoveWindow(
                          child: Row(children: [
                            const SizedBox(
                              width: 16.0,
                            ),
                            Image.asset(
                              "assets/logo.png",
                              isAntiAlias: true,
                              filterQuality: FilterQuality.high,
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(
                              width: 16.0,
                            ),
                            Text(
                              "CoreCoder:Develop ${CoreCoderApp.version}",
                              style: Theme.of(context).textTheme.bodyText1!,
                            )
                          ]),
                        )),
                        const WindowButtons()
                      ])),
                      if (widget != null) Expanded(child: widget)
                    ],
                  ));
            },
          )),
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<DrawerStateInfo>(
            create: (_) => DrawerStateInfo()),
      ],
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var buttonColors = WindowButtonColors(
        mouseOver: theme.canvasColor,
        mouseDown: theme.backgroundColor,
        iconNormal: theme.textTheme.bodyText1?.color,
        iconMouseOver: theme.textTheme.bodyText1?.color,
        iconMouseDown: theme.textTheme.bodyText1?.color);

    var closeButtonColors = WindowButtonColors(
        mouseOver: const Color(0xFFD32F2F),
        mouseDown: const Color(0xFFB71C1C),
        iconNormal: theme.textTheme.bodyText1?.color,
        iconMouseOver: theme.textTheme.bodyText1?.color);

    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}
