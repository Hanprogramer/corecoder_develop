import 'package:flutter/material.dart';

class ProjectList extends StatelessWidget{
  final Function onRefresh;
  final Function onAddProject;
  final List<Widget> children;
  const ProjectList({Key? key,required this.onRefresh, required this.onAddProject, required this.children}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Text(
                  "Recent Projects",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                  ),
                ),
                const Spacer(flex: 1),
                OutlinedButton(
                  onPressed: () {
                    onRefresh();
                  },
                  child: const Text("Refresh"),
                ),
                const SizedBox(width: 4,),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text("Open"),
                ),
              ]),
              Column(
                children: children,
              )
            ]));
  }

}