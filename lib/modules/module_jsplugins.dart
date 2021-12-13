import 'dart:ffi';
import 'dart:typed_data';
import 'package:corecoder_develop/modules/jsapi.dart';
import 'package:corecoder_develop/util/modules_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jscore/jscore_bindings.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_jscore/flutter_jscore.dart' as jscore
    show
        JSContext,
        JSContextGroup,
        JSObject,
        JSClass,
        JSClassDefinition,
        JSPropertyAttributes,
        JSClassAttributes,
        JSStaticFunction;

class JsModule extends Module {
  String mainScript = "";

  late jscore.JSContext context;
  late jscore.JSObject globalObj;

  Pointer get _ctxPtr => context.pointer;
  late Pointer _globalObjPtr;


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

  //TODO: check if any parameter is invalid
  @override
  JsModule(String title, String desc, String author, String version,
      Uint8List? icon64, String identifier, this.mainScript)
      : super(title, desc, author, version, icon64, identifier);

  Future<void> createSolution(String filepath, Map<String, dynamic> args,
      {String? bpPath, String? rpPath}) async {
    /// ---------------------------
    /// Create .ccsln.json file
    /// ---------------------------
    ///TODO: NOT IMPLEMENTED
  }

  @override
  void onInitialized(ModulesManager modulesManager) {
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
    jSEvaluateScript(
        _ctxPtr,
        jSStringCreateWithUTF8CString(mainScript.toNativeUtf8()),
        nullptr,
        nullptr,
        1,
        nullptr);
    Pointer onInitializedValueRef = jSObjectGetProperty(
      _ctxPtr,
      _globalObjPtr,
      jSStringCreateWithUTF8CString('onInitialized'.toNativeUtf8()),
      nullptr,
    );
    Pointer onInitializedObj =
        jSValueToObject(_ctxPtr, onInitializedValueRef, nullptr);
    jSObjectCallAsFunction(
        _ctxPtr, onInitializedObj, nullptr, 0, nullptr, nullptr);
  }
}
