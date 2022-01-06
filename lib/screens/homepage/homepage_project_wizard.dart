import 'package:corecoder_develop/util/cc_project_structure.dart';
import 'package:corecoder_develop/util/modules_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'homepage.dart';

class ProjectWizard extends StatelessWidget {
  final Template template;
  final Function refreshProjects;

  const ProjectWizard(this.template, this.refreshProjects, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    List<Widget> controls = List.empty(growable: true);
    /// The options changed later after the window closed
    Map<String, dynamic> values = {};

    /// Add Options
    for (var argName in template.options.keys) {
      controls.add(Row(children: [
        const Icon(Icons.subdirectory_arrow_right_outlined),
        Text(
          argName,
          textAlign: TextAlign.start,
        )
      ]));
      var optionVal = (template.options[argName] ?? "");
      if (optionVal.startsWith("String")) {
        var splt = optionVal.split("|");
        var hint = splt.length > 1? splt[1] : argName;
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
            Navigator.pop(context, 1);
          },
        ),
        ElevatedButton(
          child: const Text("Create"),
          onPressed: () async {
            /// Go Ahead and create project asynchronously
            var slnPath = await template.onCreated(
                values); //TODO: This is prone to error (not checking if the file existed first)
            if (slnPath == null) return;

            /// Add it to recent projects
            CCSolution? project = await RecentProjectsManager
                .instance
                .addSolution(slnPath);
            if (project != null) {
              await RecentProjectsManager.instance.commit(SharedPreferences.getInstance());
              Navigator.pop(context, 3);
              refreshProjects();
              loadSolution(project, context);
            }
          },
        )
      ],
    );
    controls.add(row);

    return Scaffold(
        appBar: AppBar(
          title: Text('Create ${template.title}'),
        ),
        body: SingleChildScrollView(
            child: Column(
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: controls,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                ))
          ],
        )));
  }
}
