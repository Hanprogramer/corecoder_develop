import 'package:corecoder_develop/custom_code_box.dart';
// import 'package:example/readme/readme_examples.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'main.dart';

class EditorPage extends StatefulWidget {
  static const String routeName = "/EditorPage";
  const EditorPage({Key? key}) : super(key: key);

  @override
  _EditorPageState createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future _launchInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
        headers: <String, String>{'my_header_key': 'my_header_value'},
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as CCProject;
    final codeBox = InnerField(
      language: 'json',
      theme: 'atom-one-dark',
      source: args.name
    );
    final page = Expanded(
      child: Container(
        constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height, minWidth: double.infinity),
        child: codeBox,
      ),
    );
    return Scaffold(
      backgroundColor: Color(0xFF363636),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black87,
              ),
              child: Text('No Project Opened', style: TextStyle(color: Colors.white),),
            ),
            ListTile(
              title: const Text('Item 1'),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: const Text('Item 2'),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Color(0xff23241f),
        title: null,
        // title: Text("Recursive Fibonacci"),
        centerTitle: false,
        actions: [
          IconButton(onPressed: () => {Navigator.pop(context)}, icon: const Icon(FontAwesomeIcons.timesCircle), tooltip: "Close Project",),
          IconButton(onPressed: () => {

          }, icon: Icon(FontAwesomeIcons.ellipsisV)),
          // TextButton.icon(
          //   style: TextButton.styleFrom(
          //     padding: EdgeInsets.symmetric(horizontal: 8.0),
          //     primary: Colors.white,
          //   ),
          //   icon: Icon(FontAwesomeIcons.github),
          //   onPressed: () =>
          //       _launchInBrowser("https://github.com/BertrandBev/code_field"),
          //   label: Text("GITHUB"),
          // ),
          SizedBox(width: 16.0),
        ],
      ),
      body: SingleChildScrollView(child: page),
    );
  }
}
