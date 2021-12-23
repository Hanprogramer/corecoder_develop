import 'package:corecoder_develop/util/theme_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tabbed_view/tabbed_view.dart';

class DesktopTabBar extends StatefulWidget {
  final double tabSize;
  final List<Widget> content;
  final List<DesktopTabData> tabs;

  const DesktopTabBar(
      {Key? key,
      this.tabSize = 256.0,
      required this.content,
      required this.tabs})
      : super(key: key);

  @override
  State createState() => DesktopTabBarState();
}

class DesktopTabBarState extends State<DesktopTabBar> {
  Color? colorBackground;
  Color? colorBackgroundSecondary;
  int selectedTab = 0;

  List<Widget> get tabs {
    return List.generate(widget.tabs.length, (index) {
      var item = widget.tabs[index];
      return DesktopTab(
          icon: item.icon, title: item.title, onClick: () {
            setState(() {
              selectedTab = index;
            });
      }, isActive: selectedTab == index);
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var query = MediaQuery.of(context);

    colorBackground = ThemeManager.getThemeSchemeColor("backgroundTertiary");
    colorBackgroundSecondary =
        ThemeManager.getThemeSchemeColor("backgroundSecondary");
    return Container(
        color: colorBackground,
        constraints: BoxConstraints(maxHeight: query.size.height - 200),
        child: Flex(
          direction: Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: tabs,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                ),
              ),
              constraints: BoxConstraints(
                  minWidth: widget.tabSize, maxWidth: widget.tabSize),
            ),
            Expanded(
                child: Container(
              color: colorBackgroundSecondary,
              child: widget.content[selectedTab],
            ))
          ],
        ));
  }
}

class DesktopTabData {
  final Widget icon, title;

  DesktopTabData({required this.icon, required this.title});
}

class DesktopTab extends StatelessWidget {
  final Widget icon, title;
  final Function() onClick;
  final bool isActive;

  const DesktopTab(
      {Key? key,
      required this.icon,
      required this.title,
      required this.onClick,
      required this.isActive})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: ButtonStyle(
        backgroundColor:(isActive)? MaterialStateProperty.all(Theme.of(context).canvasColor) : null,
          padding: MaterialStateProperty.all(const EdgeInsets.all(16.0)),
          foregroundColor: MaterialStateProperty.all(
              Theme.of(context).textTheme.bodyText1?.color)),
      onPressed: onClick,
      child: Row(
        children: [
          icon,
          const SizedBox(
            width: 16.0,
          ),
          title
        ],
      ),
    );
  }
}