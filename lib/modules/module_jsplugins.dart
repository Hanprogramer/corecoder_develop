import 'dart:ffi';
import 'dart:typed_data';
import 'package:corecoder_develop/modules/jsapi.dart';
import 'package:corecoder_develop/util/cc_project_structure.dart';
import 'package:corecoder_develop/util/modules_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jscore/jscore_bindings.dart';
import 'package:ffi/ffi.dart';
import 'package:corecoder_develop/homepage.dart';
import 'package:flutter_jscore/flutter_jscore.dart' as jscore
    show
        JSContext,
        JSContextGroup,
        JSObject,
        JSClass,
        JSClassDefinition,
        JSPropertyAttributes,
        JSClassAttributes,
        JSStaticFunction,
        JSValue,
        JSPropertyNameArray,
        JSStaticValueArray,
        JSTypedArrayType,
        JSValuePointer;

class JsModule extends Module {
  String mainScript;
  String moduleFolder;

  late jscore.JSContext context;
  late jscore.JSObject globalObj;
  late BuildContext buildContext;

  Pointer get _ctxPtr => context.pointer;
  late Pointer _globalObjPtr;
  List<String> Function(String lang, String lastToken)? onAutocomplete;

  //TODO: check if any parameter is invalid
  @override
  JsModule(String title, String desc, String author, String version,
      Uint8List? icon64, String identifier, this.mainScript, this.moduleFolder)
      : super(title, desc, author, version, icon64, identifier);
  /// Expose the CoreCoder class to js
  void initializeCC3JS() {
    //TODO: this doesn't use JSCore, which is easier to read, see `initializeCC3JSFileIO`
    Pointer<Utf8> ccClassName = 'CoreCoder'.toNativeUtf8();

    var staticFunctions = JSStaticFunctionPointer.allocateArray([
      JSStaticFunctionStruct(
        name: 'print'.toNativeUtf8(),
        callAsFunction: Pointer.fromFunction(CoreCoder.jsPrint),
        attributes: JSPropertyAttributes.kJSPropertyAttributeNone,
      ),
      JSStaticFunctionStruct(
        name: 'addTemplate'.toNativeUtf8(),
        callAsFunction: Pointer.fromFunction(CoreCoder.jsAddTemplate),
        attributes: JSPropertyAttributes.kJSPropertyAttributeNone,
      ),
      JSStaticFunctionStruct(
        name: 'getProjectFolder'.toNativeUtf8(),
        callAsFunction: Pointer.fromFunction(CoreCoder.jsGetProjectFolder),
        attributes: JSPropertyAttributes.kJSPropertyAttributeNone,
      ),
    ]);
    var definition = JSClassDefinitionPointer.allocate(
      version: 0,
      attributes: JSClassAttributes.kJSClassAttributeNone,
      className: ccClassName,
      parentClass: null,
      staticValues: null,
      staticFunctions: staticFunctions,
      initialize: null,
      finalize: null,
      hasProperty: null,
      getProperty: null,
      setProperty: null,
      deleteProperty: null,
      getPropertyNames: null,
      callAsFunction: null,
      callAsConstructor: null,
      hasInstance: null,
      convertToType: null,
    );
    var flutterJSClass = jSClassCreate(definition);
    var flutterJSObject = jSObjectMake(_ctxPtr, flutterJSClass, nullptr);
    jSObjectSetProperty(
        _ctxPtr,
        _globalObjPtr,
        jSStringCreateWithUTF8CString(ccClassName),
        flutterJSObject,
        JSPropertyAttributes.kJSPropertyAttributeDontDelete,
        nullptr);
    malloc.free(ccClassName);
  }

  void initializeCC3JSFileIO() {
    var staticFunctions = <jscore.JSStaticFunction>[
      jscore.JSStaticFunction(
          name: "writeFile",
          attributes: jscore.JSPropertyAttributes.kJSPropertyAttributeReadOnly,
          callAsFunction: Pointer.fromFunction(FileIO.jsWriteFile)),
      jscore.JSStaticFunction(
          name: "appendFile",
          attributes: jscore.JSPropertyAttributes.kJSPropertyAttributeReadOnly,
          callAsFunction: Pointer.fromFunction(FileIO.jsAppendFile)),
      jscore.JSStaticFunction(
          name: "readFile",
          attributes: jscore.JSPropertyAttributes.kJSPropertyAttributeReadOnly,
          callAsFunction: Pointer.fromFunction(FileIO.jsReadFile)),
      jscore.JSStaticFunction(
          name: "isExists",
          attributes: jscore.JSPropertyAttributes.kJSPropertyAttributeReadOnly,
          callAsFunction: Pointer.fromFunction(FileIO.jsIsExists)),
      jscore.JSStaticFunction(
          name: "isFile",
          attributes: jscore.JSPropertyAttributes.kJSPropertyAttributeReadOnly,
          callAsFunction: Pointer.fromFunction(FileIO.jsIsFile)),
      jscore.JSStaticFunction(
          name: "isDirectory",
          attributes: jscore.JSPropertyAttributes.kJSPropertyAttributeReadOnly,
          callAsFunction: Pointer.fromFunction(FileIO.jsIsDirectory)),
      jscore.JSStaticFunction(
          name: "mkdir",
          attributes: jscore.JSPropertyAttributes.kJSPropertyAttributeReadOnly,
          callAsFunction: Pointer.fromFunction(FileIO.jsMkdir)),
      jscore.JSStaticFunction(
          name: "mkdirRecursive",
          attributes: jscore.JSPropertyAttributes.kJSPropertyAttributeReadOnly,
          callAsFunction: Pointer.fromFunction(FileIO.jsMkdirRecursive)),
      jscore.JSStaticFunction(
          name: "rmdir",
          attributes: jscore.JSPropertyAttributes.kJSPropertyAttributeReadOnly,
          callAsFunction: Pointer.fromFunction(FileIO.jsRmdir)),
    ];
    var classDef = jscore.JSClassDefinition(
      version: 0,
      attributes: jscore.JSClassAttributes.kJSClassAttributeNone,
      className: "FileIO",
      parentClass: null,
      staticValues: null,
      staticFunctions: staticFunctions,
      initialize: null,
      finalize: null,
      hasProperty: null,
      getProperty: null,
      setProperty: null,
      deleteProperty: null,
      getPropertyNames: null,
      callAsFunction: null,
      callAsConstructor: null,
      hasInstance: null,
      convertToType: null,
    );
    globalObj.setProperty(
        "FileIO",
        jscore.JSObject.make(context, jscore.JSClass.create(classDef))
            .toValue(),
        jscore.JSPropertyAttributes.kJSPropertyAttributeDontDelete);
  }


  Future<void> createSolution(String filepath, Map<String, dynamic> args,
      {String? bpPath, String? rpPath}) async {
    /// ---------------------------
    /// Create .ccsln.json file
    /// ---------------------------
    ///TODO: NOT IMPLEMENTED
  }

  @override
  void onInitialized(
      ModulesManager modulesManager, BuildContext buildContext) async {
    this.buildContext = buildContext;
    context =
        jscore.JSContext.createInGroup(group: jscore.JSContextGroup.create());
    globalObj = context.globalObject;
    _globalObjPtr = globalObj.pointer;
    CoreCoder.module = this;
    FileIO.module = this;
    CoreCoder.context = context;
    FileIO.context = context;
    initializeCC3JS();
    initializeCC3JSFileIO();
    debugPrint("Initializing JSModule $name");
    jSCheckScriptSyntax(
        _ctxPtr,
        jSStringCreateWithUTF8CString(mainScript.toNativeUtf8()),
        nullptr,
        1,
        context.exception.pointer);

    if (context.exception.getValue(context).isNull == false) {
      var errorObj = context.exception.getValue(context).toObject();
      var name = errorObj.getProperty("name").string;
      var message = errorObj.getProperty("message").string;
      var lineNumber = errorObj.getProperty("line").string;
      debugPrint("[JSError](line $lineNumber) $name : $message");
    }
    context.evaluate(mainScript);

    /// ************************
    /// Overridable functions
    /// ************************

    if (globalObj.hasProperty("onInitialized")) {
      jscore.JSValue onInitializedValue =
          globalObj.getProperty("onInitialized");
      jscore.JSObject onInitializedObj = onInitializedValue.toObject();
      jscore.JSValuePointer? err;
      onInitializedObj.callAsFunction(
          globalObj, jscore.JSValuePointer.array([]),
          exception: err);
      if (err != null && err.getValue(context).isNull == false) {
        debugPrint("[JSError] ${err.getValue(context).toString()}");
      }
    }

    if (globalObj.hasProperty("onGetAutocomplete")) {
      jscore.JSValue onGetAutoComplete =
          globalObj.getProperty("onGetAutocomplete");
      jscore.JSObject funcObj = onGetAutoComplete.toObject();
      onAutocomplete = (String lang, String lastToken) {
        var result = <String>[];
        jscore.JSValuePointer? err;
        var jsResult = funcObj.callAsFunction(
            globalObj,
            jscore.JSValuePointer.array([
              jscore.JSValue.makeString(context, lang),
              jscore.JSValue.makeString(context, lastToken),
            ]),
            exception: err);
        if (err != null && err.getValue(context).isNull == false) {
          debugPrint("[JSError] ${err.getValue(context).toString()}");
        }
        if (jsResult.isObject) {
          var arr = jsResult.toObject();
          var props = arr.copyPropertyNames();
          for (var i = 0; i < props.count; i++) {
            var name = props.propertyNameArrayGetNameAtIndex(i);
            result.add(name);
          }
        } else {
          debugPrint("It's not an object");
        }
        return result;
      };
    }
  }

  @override
  List<String> onAutoComplete(String language, String lastToken) {
    if (onAutocomplete != null) {
      List<String>? list = onAutocomplete?.call(language, lastToken);
      if (list != null) {
        return list;
      }
    }
    return [];
  }
}
