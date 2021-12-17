import 'package:corecoder_develop/util/code_snippets.dart';
import 'package:corecoder_develop/util/themes.dart';
import 'package:flutter/material.dart';
import 'package:corecoder_develop/contrib/code_text_field-1.0.2m/lib/code_text_field.dart';
import 'package:highlight/languages/all.dart';
class CustomCodeBox extends StatefulWidget {
  final String language;
  final Map<String, TextStyle> theme;
  final String source;

  const CustomCodeBox({Key? key, required this.language, required this.theme, required this.source})
      : super(key: key);

  @override
  _CustomCodeBoxState createState() => _CustomCodeBoxState();
}

class _CustomCodeBoxState extends State<CustomCodeBox> {
  String? language;
  late Map<String,TextStyle> theme;
  String? source;

  @override
  void initState() {
    super.initState();
    language = widget.language;
    theme = widget.theme;
    source = widget.source;
  }

  List<String?> get languageList {
    const TOP = <String>{
      "java",
      "cpp",
      "python",
      "javascript",
      "cs",
      "dart",
      "haskell",
      "ruby",
    };
    return <String?>[
      ...TOP,
      null, // Divider
      ...CODE_SNIPPETS.keys.where((el) => !TOP.contains(el))
    ];
  }

  List<String?> get themeList {
    const TOP = <String>{
      "monokai-sublime",
      "a11y-dark",
      "an-old-hope",
      "vs2015",
      "vs",
      "atom-one-dark",
    };
    return <String?>[
      ...TOP,
      null, // Divider
      ...THEMES.keys.where((el) => !TOP.contains(el))
    ];
  }

  Widget buildDropdown(Iterable<String?> choices, String value, IconData icon,
      Function(String?) onChanged) {
    return DropdownButton<String>(
      value: value,
      items: choices.map((String? value) {
        return new DropdownMenuItem<String>(
          value: value,
          child: value == null
              ? Divider()
              : Text(value, style: TextStyle(color: Colors.white)),
        );
      }).toList(),
      icon: Icon(icon, color: Colors.white),
      onChanged: onChanged,
      dropdownColor: Colors.black87,
    );
  }

  @override
  Widget build(BuildContext context) {
    // final codeDropdown =
    //     buildDropdown(languageList, language!, Icons.code, (val) {
    //   if (val == null) return;
    //   setState(() => language = val);
    // });
    // final themeDropdown =
    //     buildDropdown(themeList, theme!, Icons.color_lens, (val) {
    //   if (val == null) return;
    //   setState(() => theme = val);
    // });
    // final dropdowns = Row(children: [
    //   SizedBox(width: 12.0),
    //   codeDropdown,
    //   SizedBox(width: 12.0),
    //   themeDropdown,
    // ]);
    final codeField = InnerField(
      key: ValueKey("$language"),
      language: language!,
      theme: theme,
      source: source!,
      filePath: "",
    );
    // return Column(children: [
    //   dropdowns,
    //   codeField,
    // ]);
    return codeField;
  }
}

class InnerField extends StatelessWidget {
  late CodeController codeController;

  final String language;
  final Map<String, TextStyle> theme;
  final String source;
  Function(String filePath, String source)? onChange;
  Function(Offset offset)? setCursorOffset;
  Function(String lastToken)? onAutoComplete;
  final String filePath;
  late CodeField codeField;


  InnerField({Key? key, required this.language, required this.theme, required this.source, required this.filePath, this.onChange, this.onAutoComplete, this.setCursorOffset})
      : super(key: key){
    codeController = CodeController(
      text: source,
      params: EditorParams(tabSpaces: 4),
      patternMap: {
        r"\B#[a-zA-Z0-9]+\b": TextStyle(color: Colors.red),
        r"\B@[a-zA-Z0-9]+\b": TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.blue,
        ),
        r"\B![a-zA-Z0-9]+\b":
        TextStyle(color: Colors.yellow, fontStyle: FontStyle.italic),
      },
      stringMap: {
        "bev": TextStyle(color: Colors.indigo),
      },
      language: allLanguages[language],
      theme: theme,
      onAutoComplete: (String lastToken){
        if(onAutoComplete != null) {
          onAutoComplete!.call(lastToken);
        }
      });
    codeField = CodeField(
      onCursorPosChanged: setCursorOffset,
      controller: codeController,
      textStyle: const TextStyle(fontFamily: 'SourceCode'),

    );
  }

  @override
  Widget build(BuildContext context) {
    return codeField;
  }

}
