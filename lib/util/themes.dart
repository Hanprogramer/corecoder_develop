import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:flutter_highlight/themes/agate.dart';
import 'package:flutter_highlight/themes/an-old-hope.dart';
import 'package:flutter_highlight/themes/androidstudio.dart';
import 'package:flutter_highlight/themes/arduino-light.dart';
import 'package:flutter_highlight/themes/arta.dart';
import 'package:flutter_highlight/themes/ascetic.dart';
import 'package:flutter_highlight/themes/atelier-cave-dark.dart';
import 'package:flutter_highlight/themes/atelier-cave-light.dart';
import 'package:flutter_highlight/themes/atelier-dune-dark.dart';
import 'package:flutter_highlight/themes/atelier-dune-light.dart';
import 'package:flutter_highlight/themes/atelier-estuary-dark.dart';
import 'package:flutter_highlight/themes/atelier-estuary-light.dart';
import 'package:flutter_highlight/themes/atelier-forest-dark.dart';
import 'package:flutter_highlight/themes/atelier-forest-light.dart';
import 'package:flutter_highlight/themes/atelier-heath-dark.dart';
import 'package:flutter_highlight/themes/atelier-heath-light.dart';
import 'package:flutter_highlight/themes/atelier-lakeside-dark.dart';
import 'package:flutter_highlight/themes/atelier-lakeside-light.dart';
import 'package:flutter_highlight/themes/atelier-plateau-dark.dart';
import 'package:flutter_highlight/themes/atelier-plateau-light.dart';
import 'package:flutter_highlight/themes/atelier-savanna-dark.dart';
import 'package:flutter_highlight/themes/atelier-savanna-light.dart';
import 'package:flutter_highlight/themes/atelier-seaside-dark.dart';
import 'package:flutter_highlight/themes/atelier-seaside-light.dart';
import 'package:flutter_highlight/themes/atelier-sulphurpool-dark.dart';
import 'package:flutter_highlight/themes/atelier-sulphurpool-light.dart';
import 'package:flutter_highlight/themes/atom-one-dark-reasonable.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/brown-paper.dart';
import 'package:flutter_highlight/themes/codepen-embed.dart';
import 'package:flutter_highlight/themes/color-brewer.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:flutter_highlight/themes/dark.dart';
import 'package:flutter_highlight/themes/default.dart';
import 'package:flutter_highlight/themes/docco.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:flutter_highlight/themes/far.dart';
import 'package:flutter_highlight/themes/foundation.dart';
import 'package:flutter_highlight/themes/github-gist.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/gml.dart';
import 'package:flutter_highlight/themes/googlecode.dart';
import 'package:flutter_highlight/themes/gradient-dark.dart';
import 'package:flutter_highlight/themes/grayscale.dart';
import 'package:flutter_highlight/themes/gruvbox-dark.dart';
import 'package:flutter_highlight/themes/gruvbox-light.dart';
import 'package:flutter_highlight/themes/hopscotch.dart';
import 'package:flutter_highlight/themes/hybrid.dart';
import 'package:flutter_highlight/themes/idea.dart';
import 'package:flutter_highlight/themes/ir-black.dart';
import 'package:flutter_highlight/themes/isbl-editor-dark.dart';
import 'package:flutter_highlight/themes/isbl-editor-light.dart';
import 'package:flutter_highlight/themes/kimbie.dark.dart';
import 'package:flutter_highlight/themes/kimbie.light.dart';
import 'package:flutter_highlight/themes/lightfair.dart';
import 'package:flutter_highlight/themes/magula.dart';
import 'package:flutter_highlight/themes/mono-blue.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/monokai.dart';
import 'package:flutter_highlight/themes/night-owl.dart';
import 'package:flutter_highlight/themes/nord.dart';
import 'package:flutter_highlight/themes/obsidian.dart';
import 'package:flutter_highlight/themes/ocean.dart';
import 'package:flutter_highlight/themes/paraiso-dark.dart';
import 'package:flutter_highlight/themes/paraiso-light.dart';
import 'package:flutter_highlight/themes/pojoaque.dart';
import 'package:flutter_highlight/themes/purebasic.dart';
import 'package:flutter_highlight/themes/qtcreator_dark.dart';
import 'package:flutter_highlight/themes/qtcreator_light.dart';
import 'package:flutter_highlight/themes/railscasts.dart';
import 'package:flutter_highlight/themes/rainbow.dart';
import 'package:flutter_highlight/themes/routeros.dart';
import 'package:flutter_highlight/themes/school-book.dart';
import 'package:flutter_highlight/themes/shades-of-purple.dart';
import 'package:flutter_highlight/themes/solarized-dark.dart';
import 'package:flutter_highlight/themes/solarized-light.dart';
import 'package:flutter_highlight/themes/sunburst.dart';
import 'package:flutter_highlight/themes/tomorrow-night-blue.dart';
import 'package:flutter_highlight/themes/tomorrow-night-bright.dart';
import 'package:flutter_highlight/themes/tomorrow-night-eighties.dart';
import 'package:flutter_highlight/themes/tomorrow-night.dart';
import 'package:flutter_highlight/themes/tomorrow.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_highlight/themes/xcode.dart';
import 'package:flutter_highlight/themes/xt256.dart';
import 'package:flutter_highlight/themes/zenburn.dart';

import 'package:flutter/painting.dart';
const THEMES = {
  'a11y-dark': a11yDarkTheme,
  'a11y-light': a11yLightTheme,
  'agate': agateTheme,
  'an-old-hope': anOldHopeTheme,
  'androidstudio': androidstudioTheme,
  'arduino-light': arduinoLightTheme,
  'arta': artaTheme,
  'ascetic': asceticTheme,
  'atelier-cave-dark': atelierCaveDarkTheme,
  'atelier-cave-light': atelierCaveLightTheme,
  'atelier-dune-dark': atelierDuneDarkTheme,
  'atelier-dune-light': atelierDuneLightTheme,
  'atelier-estuary-dark': atelierEstuaryDarkTheme,
  'atelier-estuary-light': atelierEstuaryLightTheme,
  'atelier-forest-dark': atelierForestDarkTheme,
  'atelier-forest-light': atelierForestLightTheme,
  'atelier-heath-dark': atelierHeathDarkTheme,
  'atelier-heath-light': atelierHeathLightTheme,
  'atelier-lakeside-dark': atelierLakesideDarkTheme,
  'atelier-lakeside-light': atelierLakesideLightTheme,
  'atelier-plateau-dark': atelierPlateauDarkTheme,
  'atelier-plateau-light': atelierPlateauLightTheme,
  'atelier-savanna-dark': atelierSavannaDarkTheme,
  'atelier-savanna-light': atelierSavannaLightTheme,
  'atelier-seaside-dark': atelierSeasideDarkTheme,
  'atelier-seaside-light': atelierSeasideLightTheme,
  'atelier-sulphurpool-dark': atelierSulphurpoolDarkTheme,
  'atelier-sulphurpool-light': atelierSulphurpoolLightTheme,
  'atom-one-dark-reasonable': atomOneDarkReasonableTheme,
  'atom-one-dark': atomOneDarkTheme,
  'atom-one-light': atomOneLightTheme,
  'brown-paper': brownPaperTheme,
  'codepen-embed': codepenEmbedTheme,
  'color-brewer': colorBrewerTheme,
  'darcula': darculaTheme,
  'dark': darkTheme,
  'default': defaultTheme,
  'docco': doccoTheme,
  'dracula': draculaTheme,
  'far': farTheme,
  'foundation': foundationTheme,
  'github-gist': githubGistTheme,
  'github': githubTheme,
  'gml': gmlTheme,
  'googlecode': googlecodeTheme,
  'gradient-dark': gradientDarkTheme,
  'grayscale': grayscaleTheme,
  'gruvbox-dark': gruvboxDarkTheme,
  'gruvbox-light': gruvboxLightTheme,
  'hopscotch': hopscotchTheme,
  'hybrid': hybridTheme,
  'idea': ideaTheme,
  'ir-black': irBlackTheme,
  'isbl-editor-dark': isblEditorDarkTheme,
  'isbl-editor-light': isblEditorLightTheme,
  'kimbie.dark': kimbieDarkTheme,
  'kimbie.light': kimbieLightTheme,
  'lightfair': lightfairTheme,
  'magula': magulaTheme,
  'mono-blue': monoBlueTheme,
  'monokai-sublime': monokaiSublimeTheme,
  'monokai': monokaiTheme,
  'night-owl': nightOwlTheme,
  'nord': nordTheme,
  'obsidian': obsidianTheme,
  'ocean': oceanTheme,
  'paraiso-dark': paraisoDarkTheme,
  'paraiso-light': paraisoLightTheme,
  'pojoaque': pojoaqueTheme,
  'purebasic': purebasicTheme,
  'qtcreator_dark': qtcreatorDarkTheme,
  'qtcreator_light': qtcreatorLightTheme,
  'railscasts': railscastsTheme,
  'rainbow': rainbowTheme,
  'routeros': routerosTheme,
  'school-book': schoolBookTheme,
  'shades-of-purple': shadesOfPurpleTheme,
  'solarized-dark': solarizedDarkTheme,
  'solarized-light': solarizedLightTheme,
  'sunburst': sunburstTheme,
  'tomorrow-night-blue': tomorrowNightBlueTheme,
  'tomorrow-night-bright': tomorrowNightBrightTheme,
  'tomorrow-night-eighties': tomorrowNightEightiesTheme,
  'tomorrow-night': tomorrowNightTheme,
  'tomorrow': tomorrowTheme,
  'vs': vsTheme,
  'vs2015': vs2015Theme,
  'xcode': xcodeTheme,
  'xt256': xt256Theme,
  'zenburn': zenburnTheme,
};


const editorThemes = {
  'core-coder-dark': {
    "brightness" : "dark",
    "highlight": {
      'root': TextStyle(color: Color(0xffabb2bf), backgroundColor: Color(0xFF202020)),
      'comment': TextStyle(color: Color(0xff5c6370), fontStyle: FontStyle.italic),
      'quote': TextStyle(color: Color(0xff5c6370), fontStyle: FontStyle.italic),
      'doctag': TextStyle(color: Color(0xffc678dd)),
      'keyword': TextStyle(color: Color(0xffc678dd)),
      'formula': TextStyle(color: Color(0xffc678dd)),
      'section': TextStyle(color: Color(0xffe06c75)),
      'name': TextStyle(color: Color(0xffe06c75)),
      'selector-tag': TextStyle(color: Color(0xffe06c75)),
      'deletion': TextStyle(color: Color(0xffe06c75)),
      'subst': TextStyle(color: Color(0xffe06c75)),
      'literal': TextStyle(color: Color(0xff56b6c2)),
      'string': TextStyle(color: Color(0xff98c379)),
      'regexp': TextStyle(color: Color(0xff98c379)),
      'addition': TextStyle(color: Color(0xff98c379)),
      'attribute': TextStyle(color: Color(0xff98c379)),
      'meta-string': TextStyle(color: Color(0xff98c379)),
      'built_in': TextStyle(color: Color(0xffe6c07b)),
      'attr': TextStyle(color: Color(0xffd19a66)),
      'variable': TextStyle(color: Color(0xffd19a66)),
      'template-variable': TextStyle(color: Color(0xffd19a66)),
      'type': TextStyle(color: Color(0xffd19a66)),
      'selector-class': TextStyle(color: Color(0xffd19a66)),
      'selector-attr': TextStyle(color: Color(0xffd19a66)),
      'selector-pseudo': TextStyle(color: Color(0xffd19a66)),
      'number': TextStyle(color: Color(0xffd19a66)),
      'symbol': TextStyle(color: Color(0xff61aeee)),
      'bullet': TextStyle(color: Color(0xff61aeee)),
      'link': TextStyle(color: Color(0xff61aeee)),
      'meta': TextStyle(color: Color(0xff61aeee)),
      'selector-id': TextStyle(color: Color(0xff61aeee)),
      'title': TextStyle(color: Color(0xff61aeee)),
      'emphasis': TextStyle(fontStyle: FontStyle.italic),
      'strong': TextStyle(fontWeight: FontWeight.bold),
    },
    "scheme": {
      // Color settings
      "primaryColour": Color(0xff13BB67),
      "secondaryColour": Color(0xff0d8c4c),

      // Controls
      "background": Color(0xFF191919),
      "backgroundSecondary": Color(0xFF202020),
      "backgroundTertiary": Color(0xFF2B2B2B),
      "foreground": Color(0xFFFFFFFF),

      // Color symbols
      "info": Color(0xFF108FE8),
      "success": Color(0xFF87DB4A),
      "error": Color(0xFFDC1F2D),
      "warn": Color(0xFFF8D952)
    },
  },
  'core-coder-light': {
    "brightness" : "light",
    "highlight": atomOneLightTheme,
    "scheme": {
      // Color settings
      "primaryColour": Color(0xff13BB67),
      "secondaryColour": Color(0xff0d8c4c),

      // Controls
      "background": Color(0xFFE5E5E5),
      "backgroundSecondary": Color(0xFFFFFFFF),
      "backgroundTertiary": Color(0xFFDCDCDC),
      "foreground": Color(0xFF000000),

      // Color symbols
      "info": Color(0xFF108FE8),
      "success": Color(0xFF87DB4A),
      "error": Color(0xFFDC1F2D),
      "warn": Color(0xFFF8D952)

    },
  },
};

