import 'dart:io';
import 'package:corecoder_develop/screens/homepage/homepage_project_wizard.dart';
import 'package:corecoder_develop/util/cc_project_structure.dart';
import 'package:corecoder_develop/util/modules_manager.dart';
import 'package:corecoder_develop/util/theme_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'homepage.dart';

class HomePageProjectCreate extends StatelessWidget {
  final Function refreshProjects;

  const HomePageProjectCreate({Key? key, required this.refreshProjects})
      : super(key: key);

  Future<SharedPreferences> get _pref async {
    return await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    /// -------------------------------------------------
    /// Template Selection
    /// -------------------------------------------------
    List<Widget> options = List.empty(growable: true);
    for (Module m in ModulesManager.modules) {
      options.add(Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: Text(m.name,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))));
      for (Template t in m.templates) {
        /// -------------------------------------------------
        /// Project Options
        ///  -------------------------------------------------
        options.add(Card(
            child: ListTile(
          leading: t.icon,
          title: Text(t.title),
          subtitle: Text(t.desc),
          tileColor: ThemeManager.getThemeData().backgroundColor,
          onTap: () async {
            Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => ProjectWizard(t,refreshProjects)));
          },
        )));
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Create new project')),
      ),
      body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: options,
                crossAxisAlignment: CrossAxisAlignment.stretch,
              ))),
      //contentPadding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      backgroundColor: ThemeManager.getThemeData().canvasColor,
    );
  }
}
