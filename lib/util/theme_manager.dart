import 'package:flutter/material.dart';
import './themes.dart';

class ThemeManager {
  static ValueNotifier<String> currentTheme =
      ValueNotifier<String>("atom-one-dark");

  static void setTheme(String themeName) {
    currentTheme.value = themeName;
    debugPrint("Set theme: $themeName");
  }

  static Color? getThemeSchemeColor(String name, {String? themeName}){
    themeName ??= currentTheme.value; // if name is not mentioned
    var editor = editorThemes[themeName];
    var scheme = editor!["scheme"] as Map<String, Color>;
    return scheme[name];
  }

  static Color? getThemeColor(String name, {String? themeName}){
    themeName ??= currentTheme.value; // if name is not mentioned
    var editor = editorThemes[themeName];
    var value = editor![name];
    return value != null? value as Color : null;
  }

  static ThemeData getThemeData({String? themeName}) {
    themeName ??= currentTheme.value; // if name is not mentioned
    var editor = editorThemes[themeName];
    var scheme = editor!["scheme"] as Map<String, Color>;
    var isDark = editor["brightness"] == "dark";
    var brightness = isDark ? Brightness.dark : Brightness.light;
    var backgroundColor = scheme["background"] as Color;
    var backgroundSecondary = scheme["backgroundSecondary"] as Color;
    var foregroundColor = scheme["foreground"] as Color;
    var primaryColor = scheme["purple"] as Color;
    debugPrint("Loading theme $themeName:dark=$isDark");
    var theme = ThemeData(
      brightness: brightness,
      backgroundColor: backgroundColor,
      canvasColor: backgroundSecondary,
      colorScheme: ColorScheme.fromSwatch(brightness: brightness).copyWith(
        primary: primaryColor,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: backgroundSecondary,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        toolbarHeight: 48,elevation: 0
      ),
      tabBarTheme: TabBarTheme(
        labelColor: foregroundColor,
        indicator: BoxDecoration(
          border: Border(bottom: BorderSide(color: primaryColor, width: 2)),
        ),
      ),
      cardColor: backgroundColor,

    );
    return theme;
  }

  static dynamic getHighlighting({String? name}) {
    if (name != null) {
      return editorThemes[name]!["highlight"];
    } else {
      return editorThemes[currentTheme.value]!["highlight"];
    }
  }
}
