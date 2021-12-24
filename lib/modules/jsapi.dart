import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:corecoder_develop/modules/module_jsplugins.dart';
import 'package:corecoder_develop/util/cc_project_structure.dart';
import 'package:corecoder_develop/util/modules_manager.dart';
import 'package:corecoder_develop/util/plugins_manager.dart';
import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_jscore/flutter_jscore.dart';
import 'package:flutter_jscore/jscore_bindings.dart' as js;

import '../screens/homepage/homepage.dart';

String jsStringToDartString(Pointer resultJsString) {
  var resultCString = js.jSStringGetCharactersPtr(resultJsString);
  int resultCStringLength = js.jSStringGetLength(resultJsString);
  if (resultCString == nullptr) {
    return 'null';
  }
  String result = String.fromCharCodes(Uint16List.view(
      resultCString.cast<Uint16>().asTypedList(resultCStringLength).buffer,
      0,
      resultCStringLength));
  return result;
}

String _getJsValue(Pointer _ctxPtr, Pointer jsValueRef) {
  if (js.jSValueIsNull(_ctxPtr, jsValueRef) == 1) {
    return 'null';
  } else if (js.jSValueIsUndefined(_ctxPtr, jsValueRef) == 1) {
    return 'undefined';
  } else if (js.jSValueIsObject(_ctxPtr, jsValueRef) == 1) {
    // Is object, convert to map
    return 'Object object';
  }

  /// Last resort, cast anything to string, like "[Object object]"
  var resultJsString = js.jSValueToStringCopy(_ctxPtr, jsValueRef, nullptr);
  var resultCString = js.jSStringGetCharactersPtr(resultJsString);
  int resultCStringLength = js.jSStringGetLength(resultJsString);
  if (resultCString == nullptr) {
    return 'null';
  }
  String result = String.fromCharCodes(Uint16List.view(
      resultCString.cast<Uint16>().asTypedList(resultCStringLength).buffer,
      0,
      resultCStringLength));
  js.jSStringRelease(resultJsString);
  return result;
}

/// Convert a javascript object to dart map
/// [jsValueRef] The pointer to JS obj
Map<String, String> jsObjectToDartMap(Pointer _ctxPtr, Pointer jsValueRef) {
  if (js.jSValueIsObject(_ctxPtr, jsValueRef) == 1) {
    // if is object
    Pointer obj = js.jSValueToObject(_ctxPtr, jsValueRef, nullptr);

    //(JSPropertyNameArrayRef)
    Pointer props = js.jSObjectCopyPropertyNames(_ctxPtr, obj);
    int propCount = js.jSPropertyNameArrayGetCount(props);
    Map<String, String> result = {};
    // debugPrint("JS PROPC $propCount");
    for (var i = 0; i < propCount; i++) {
      Pointer /*(JSStringRef)*/ propName =
          js.jSPropertyNameArrayGetNameAtIndex(props, i);
      Pointer /*JSValueRef*/ propValue =
          js.jSObjectGetProperty(_ctxPtr, obj, propName, nullptr);
      String name = jsStringToDartString(propName);
      js.jSStringRelease(propName);
      dynamic value;
      int propType = js.jSValueGetType(_ctxPtr, propValue);
      switch (propType) {
        case 4: //kJSTypeString:
          value = _getJsValue(_ctxPtr, propValue);
          break;
        case 3: //kJSTypeNumber:
          //TODO:not implemented
          break;
      }
      // debugPrint("JS NAME $name");
      // debugPrint("JS VALUE($propType) $value");
      result[name] = value;
    }
    return result;
  }
  int type = js.jSValueGetType(_ctxPtr, jsValueRef);
  debugPrint("jsObjectToDartMap error: value is not obj, type:$type");
  return {};
}

class CoreCoder {
  static late JsModule module; // set by the parent object
  static late JSContext context; // set by the parent object
  static CoreCoder? _instance;

  static CoreCoder get instance {
    _instance ??= CoreCoder();
    return _instance!;
  }

  void addTemplate(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception)  async {
    debugPrint("[Template] $argumentCount");
    if (argumentCount > 0){
      Pointer jsValueRef = arguments[0];
      if (js.jSValueIsObject(ctx, jsValueRef) == 1) {
        /// the provided argument 0 is an object, then parse it
        String name, description, version, identifier;
        Pointer _obj = js.jSValueToObject(ctx, jsValueRef, nullptr);
        var obj = JSObject(context, _obj);
        name = obj.getProperty('name').string!;
        debugPrint("[Template] $name");
        description = obj.getProperty('description').string!;
        version = obj.getProperty('version').string!;
        identifier = obj.getProperty('identifier').string!;
        var _options = obj.getProperty('options').pointer;
        var options = jsObjectToDartMap(ctx, _options);

        var onCreate = (Map<String, dynamic> args) async {};
        var _onCreate = obj.getProperty('onCreate');
        if (_onCreate.isObject) {
          onCreate = (Map<String, dynamic> args) async {
            var optionsObj = JSObject.make(context,
                JSClass.create(JSClassDefinition(className: "OptionsObj")));
            for (var key in args.keys) {
              var value = args[key];
              if (value is String) {
                optionsObj.setProperty(key, JSValue.makeString(context, value),
                    JSPropertyAttributes.kJSPropertyAttributeReadOnly);
              } else if (value is int || value is double) {
                optionsObj.setProperty(
                    key,
                    JSValue.makeNumber(context, value as double),
                    JSPropertyAttributes.kJSPropertyAttributeReadOnly);
              }
            }
            JSValuePointer? err;
            JSValue result = _onCreate.toObject().callAsFunction(
                JSObject(context, _obj),
                JSValuePointer.array([optionsObj.toValue()]),
                exception: err);
            if (err != null && err.getValue(context).isObject) {
              var errObj = err.getValue(context).toObject();
              var name = errObj.getProperty("name").string;
              var message = errObj.getProperty("message").string;
              var line = errObj.getProperty("line").string;
              debugPrint(
                  "[JSError] onCreate on Template ERROR.(line $line) $name : $message");
            }
            if (result.isString) {
              /// Project creation successful
              var slnPath = result.string!;
              debugPrint("Reading solution $slnPath");
              var sln = await CCSolution.loadFromFile(slnPath);
              if (sln != null) {
                debugPrint("Loading solution $slnPath");
                await RecentProjectsManager.instance.addSolution(slnPath);
                RecentProjectsManager.staticCommit();
                Navigator.pop(module.buildContext,2);
                loadSolution(sln, module.buildContext);
              }else{
                debugPrint("Error: Project solution is not found or corrupted");
              }
            } else {
              debugPrint("[JSError] onInitialized not returning string");
            }
          };
        }

        module.templates.add(Template(
          name,
          description,
          version,
          options,
          onCreate,
          module.icon,
          identifier,
        ));
      }else{
        debugPrint("[JSError] addTemplate error: input variable is not object");
      }
    }
  }

  static Pointer jsAddTemplate(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    instance.addTemplate(
        ctx, function, thisObject, argumentCount, arguments, exception);
    return nullptr;
  }
  static String getProjectFolder(String moduleFolderName, String folderName) {
    var result = PluginsManager.projectsPath +
        moduleFolderName +
        Platform.pathSeparator +
        folderName +
        Platform.pathSeparator;
    return result;
  }
  static Pointer jsGetProjectFolder(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    if (argumentCount != 2) {
      debugPrint(
          "JS Plugin Error: getProjectFolder: Argument Count expected: 2");
      return nullptr;
    }

    var result = PluginsManager.projectsPath +
        _getJsValue(ctx, arguments[0]) +
        Platform.pathSeparator +
        _getJsValue(ctx, arguments[1]) +
        Platform.pathSeparator;
    return JSValue.makeString(context, result).pointer;
  }

  /// # ======== THE PRINT FUNCTION ========== # ///
  static Pointer jsPrint(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    instance.print(
        ctx, function, thisObject, argumentCount, arguments, exception);
    return nullptr;
  }

  Pointer print(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    if (argumentCount > 0) {
      debugPrint("[JS]:${_getJsValue(ctx, arguments[0])}");
    }
    return nullptr;
  }

  /// # ======== THE PRINT FUNCTION - END ========== # ///

}

class FileIO {
  static late JsModule module; // set by the parent object
  static late JSContext context; // set by the parent object

  static FileIO? _instance;

  static FileIO get instance {
    _instance ??= FileIO();
    return _instance!;
  }

  void fileExists(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    if (argumentCount > 0) {
      Pointer jsValueRef = arguments[0];
      if (js.jSValueIsObject(ctx, jsValueRef) == 1) {
        /// the provided argument 0 is an object, then parse it
        String name, description, version, identifier;
        Pointer obj = js.jSValueToObject(ctx, jsValueRef, nullptr);
        name = _getJsValue(
            ctx,
            js.jSObjectGetProperty(
                ctx,
                obj,
                js.jSStringCreateWithUTF8CString('name'.toNativeUtf8()),
                nullptr));

        description = _getJsValue(
            ctx,
            js.jSObjectGetProperty(
                ctx,
                obj,
                js.jSStringCreateWithUTF8CString('description'.toNativeUtf8()),
                nullptr));

        version = _getJsValue(
            ctx,
            js.jSObjectGetProperty(
                ctx,
                obj,
                js.jSStringCreateWithUTF8CString('version'.toNativeUtf8()),
                nullptr));

        identifier = _getJsValue(
            ctx,
            js.jSObjectGetProperty(
                ctx,
                obj,
                js.jSStringCreateWithUTF8CString('identifier'.toNativeUtf8()),
                nullptr));

        var _options = js.jSObjectGetProperty(
            ctx,
            obj,
            js.jSStringCreateWithUTF8CString('options'.toNativeUtf8()),
            nullptr);
        var options = jsObjectToDartMap(ctx, _options);

        var onCreate = (Map<String, dynamic> args) async {};
        var _onCreate = js.jSObjectGetProperty(
            ctx,
            obj,
            js.jSStringCreateWithUTF8CString('onCreate'.toNativeUtf8()),
            nullptr);
        if (js.jSValueIsObject(ctx, _onCreate) == 1) {
          onCreate = (Map<String, dynamic> args) async {
            var optionsObj = JSObject.make(context,
                JSClass.create(JSClassDefinition(className: "OptionsObj")));
            for (var key in args.keys) {
              var value = args[key];
              if (value is String) {
                optionsObj.setProperty(key, JSValue.makeString(context, value),
                    JSPropertyAttributes.kJSPropertyAttributeReadOnly);
              } else if (value is int || value is double) {
                optionsObj.setProperty(
                    key,
                    JSValue.makeNumber(context, value as double),
                    JSPropertyAttributes.kJSPropertyAttributeReadOnly);
              }
            }
            js.jSObjectCallAsFunction(ctx, _onCreate, obj, 1,
                JSValuePointer.array([optionsObj.toValue()]).pointer, nullptr);
          };
        }

        module.templates.add(Template(
          name,
          description,
          version,
          options,
          onCreate,
          module.icon,
          identifier,
        ));
      }
    }
  }

  static Pointer jsIsExists(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    bool exists = false;
    if (argumentCount == 1) {
      //TODO: better exception handling
      var path = _getJsValue(context.pointer, arguments[0]);
      exists = File(path).existsSync();
    }
    return JSValue.makeBoolean(context, exists).pointer;
  }

  static Pointer jsIsFile(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    bool exists = false;
    if (argumentCount == 1) {
      //TODO: better exception handling
      var path = _getJsValue(context.pointer, arguments[0]);
      exists = File(path).existsSync();
    }
    return JSValue.makeBoolean(context, exists).pointer;
  }

  static Pointer jsIsDirectory(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    bool exists = false;
    if (argumentCount == 1) {
      //TODO: better exception handling
      var path = _getJsValue(context.pointer, arguments[0]);
      exists = Directory(path).existsSync();
    }
    return JSValue.makeBoolean(context, exists).pointer;
  }

  static Pointer jsWriteFile(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    if (argumentCount == 2) {
      //TODO: better exception handling
      //TODO: check if successfully written the file
      var path = _getJsValue(context.pointer, arguments[0]);
      var content = _getJsValue(context.pointer, arguments[1]);
      File(path).writeAsStringSync(content);
    }
    return nullptr;
  }

  static Pointer jsAppendFile(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    if (argumentCount == 2) {
      //TODO: better exception handling
      //TODO: check if successfully written the file
      var path = _getJsValue(context.pointer, arguments[0]);
      var content = _getJsValue(context.pointer, arguments[1]);
      File(path).writeAsStringSync(content, mode: FileMode.append);
    }
    return nullptr;
  }

  static Pointer jsReadFile(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    var content = "";
    if (argumentCount == 1) {
      //TODO: better exception handling
      var path = _getJsValue(context.pointer, arguments[0]);
      content = File(path).readAsStringSync();
    }
    return JSValue.makeString(context, content).pointer;
  }

  static Pointer jsMkdir(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    if (argumentCount == 1) {
      //TODO: better exception handling
      var path = _getJsValue(context.pointer, arguments[0]);
      Directory(path).createSync();
    }
    return nullptr;
  }

  static Pointer jsMkdirRecursive(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    if (argumentCount == 1) {
      //TODO: better exception handling
      var path = _getJsValue(context.pointer, arguments[0]);
      Directory(path).createSync(recursive: true);
    }
    return nullptr;
  }

  static Pointer jsRmdir(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    if (argumentCount == 1) {
      //TODO: better exception handling
      var path = _getJsValue(context.pointer, arguments[0]);
      Directory(path).deleteSync(recursive: true);
    }
    return nullptr;
  }
}
