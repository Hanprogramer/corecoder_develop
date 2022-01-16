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

class HomePageProjectCreate extends StatefulWidget {
  final Function refreshProjects;
  const HomePageProjectCreate({Key? key, required this.refreshProjects})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => HomePageProjectCreateState();

}
class HomePageProjectCreateState extends State<HomePageProjectCreate>{
  Widget? dialog;
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
        List<Widget> controls = List.empty(growable: true);

        /// The options changed later after the window closed
        Map<String, dynamic> values = {};

        /// Add Options
        for (var argName in t.options.keys) {
          controls.add(Row(children: [
            const Icon(Icons.subdirectory_arrow_right_outlined),
            Text(
              argName,
              textAlign: TextAlign.start,
            )
          ]));
          var optionVal = (t.options[argName] ?? "");
          if (optionVal.startsWith("String")) {
            var splt = optionVal.split("|");
            var hint = splt.length > 1 ? splt[1] : argName;
            controls.add(Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextField(
                    decoration: InputDecoration(hintText: hint),
                    maxLines: 1,
                    autofocus: true,
                    onChanged: (change) {
                      values[argName] = change;
                    })));
            values[argName] = "";
          }
        }

        /// Add Buttons
        var row = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                setState(() {
                  dialog = null;
                });
              },
            ),
            ElevatedButton(
              child: const Text("Create"),
              onPressed: () async {
                /// Go Ahead and create project asynchronously
                var slnPath = await t.onCreated(
                    values); //TODO: This is prone to error (not checking if the file existed first)
                if (slnPath == null) return;

                /// Add it to recent projects
                CCSolution? project =
                    await RecentProjectsManager.instance.addSolution(slnPath);
                if (project != null) {
                  await RecentProjectsManager.instance
                      .commit(SharedPreferences.getInstance());
                  //Navigator.pop(context, 3);
                  //refreshProjects();
                  loadSolution(project, context);
                }
              },
            )
          ],
        );
        controls.add(row);

        /// -------------------------------------------------
        /// Project Options
        ///  -------------------------------------------------
        options.add(Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            child: ListTile(
          leading: t.icon,
          title: Text(t.title),
          subtitle: Text(t.desc),
          tileColor: ThemeManager.getThemeData().backgroundColor,
          onTap: () async {
            setState(() {
              dialog = ProjectWizard(
                t,
                children: controls,
              );
            });
          },
        )));
      }
    }
    return Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('Create new project')),
        ),
        body: Stack(children: [
          SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: options,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                  ))),
          if(dialog != null)
            Positioned.fill(child: dialog!)
        ]));
  }
}
