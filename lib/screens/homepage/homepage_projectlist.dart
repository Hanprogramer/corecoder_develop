import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ProjectList extends StatelessWidget {
  final Function onRefresh;
  final Function(String) onAddProject;
  final List<Widget> children;

  const ProjectList(
      {Key? key,
      required this.onRefresh,
      required this.onAddProject,
      required this.children})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
            const SizedBox(
              width: 4,
            ),
            OutlinedButton(
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles(
                      allowMultiple: false
                    );

                if (result != null) {
                  var path = result.files.single.path;
                  if(path != null) {
                    onAddProject(path);
                  }else{
                    debugPrint("[Open Project] error: the resulting path is null");
                  }
                } else {
                  // User canceled the picker
                }
              },
              child: const Text("Open"),
            ),
          ]),
          Column(
            children: children,
          )
        ]));
  }
}
