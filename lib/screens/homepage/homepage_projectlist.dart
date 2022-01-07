import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ProjectList extends StatelessWidget {
  final Function onRefresh;
  final Function(String) onAddProject;
  final List<Widget> children;
  final Function onToggleView;
  final bool isListView;

  const ProjectList(
      {Key? key,
      required this.onRefresh,
      required this.onAddProject,
      required this.onToggleView,
      required this.isListView,
      required this.children})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    const Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          "Recent Projects",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24.0,
                          ),
                        )),
                    const Spacer(flex: 1),
                    OutlinedButton(
                        onPressed: () {
                          onToggleView();
                        },
                        child: isListView
                            ? const Icon(Icons.grid_view_rounded)
                            : const Icon(Icons.checklist)),
                    const SizedBox(
                      width: 4,
                    ),
                    OutlinedButton(
                      onPressed: () {
                        onRefresh();
                      },
                      child: const Icon(Icons.refresh_rounded),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(allowMultiple: false);

                        if (result != null) {
                          var path = result.files.single.path;
                          if (path != null) {
                            onAddProject(path);
                          } else {
                            debugPrint(
                                "[Open Project] error: the resulting path is null");
                          }
                        } else {
                          // User canceled the picker
                        }
                      },
                      child: const Icon(Icons.folder_open_rounded),
                    ),
                  ]),
                  isListView
                      ? Column(
                          children: children,
                        )
                      : Wrap(
                          children: children,
                          direction: Axis.horizontal,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runAlignment: WrapAlignment.center,
                        )
                ])));
  }
}

class ProjectItem extends StatelessWidget{
  final bool isListView;
  final Widget icon;
  final String title,subtitle;
  final Function onPressed;
  final Widget? menuButton;

  const ProjectItem({Key? key, required this.isListView, required this.menuButton,
    required this.icon, required this.title, required this.subtitle, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      //TODO: refactor this as a widget elsewhere, then reference that widget from here
        child: isListView
            ? ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          onTap: () => onPressed(),
          leading: icon,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: menuButton,
          subtitle: (subtitle != "" ? Text(subtitle) : null))
            : SizedBox(
            width: 128,
            height: 160,
            child: OutlinedButton(
                onPressed: () => onPressed(),
                child: Stack(children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      icon,
                      const SizedBox(height: 8,),
                      Text(
                        title,
                        style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyText1!
                                .color!,
                            fontSize: 12.0),
                      ),
                      if(subtitle != "")
                      Text(subtitle,
                        style: TextStyle(
                            color: Theme.of(context).focusColor,
                            fontSize: 12.0),
                      )
                    ],
                  ),
                  if(menuButton != null)
                    Positioned(
                        top: 0,right: -16,
                        child: menuButton!)
                ]))));
  }

}