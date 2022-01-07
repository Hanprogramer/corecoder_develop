import 'package:corecoder_develop/util/cc_project_structure.dart';
import 'package:corecoder_develop/util/modules_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'homepage.dart';

class ProjectWizard extends StatelessWidget {
  final Template template;
  final List<Widget> children;

  const ProjectWizard(this.template, {Key? key, required this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Create ${template.title}'),
        ),
        body: SingleChildScrollView(
            child: Column(
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: children,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                ))
          ],
        )));
  }
}
