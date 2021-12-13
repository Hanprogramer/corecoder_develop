import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:corecoder_develop/util/modules_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jscore/jscore_bindings.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_jscore/flutter_jscore.dart' as jscore
    show
        JSValuePointer,
        JSStringPointer,
        JSValue,
        JSContext,
        JSContextGroup,
        JSObject,
        JSObjectPointer,
        JSClass,
        JSClassDefinition,
        JSPropertyAttributes;

class JsModule extends Module {
  String mainScript = "";

  // Pointer _context;
  // JSContext? get jsContext{
  //   _context ??= jSGlobalContextCreateInGroup();
  //   return _context;
  // }
  late jscore.JSContext _globalContext;
  late Pointer contextGroup;

  Pointer get globalContext => _globalContext.pointer;
  late Pointer globalObject;

  static Pointer alert(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    if (_alertDartFunc != null) {
      _alertDartFunc!(
          ctx, function, thisObject, argumentCount, arguments, exception);
    }
    return nullptr;
  }

  static JSObjectCallAsFunctionCallbackDart? _alertDartFunc;

  Pointer _alert(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    String msg = 'No Message';
    if (argumentCount != 0) {
      msg = '';
      for (int i = 0; i < argumentCount; i++) {
        if (i != 0) {
          msg += '\n';
        }
        var jsValueRef = arguments[i];
        msg += _getJsValue(jsValueRef);
      }
    }
    // showDialog(
    //     context: context,
    //     builder: (context) {
    //       return AlertDialog(
    //         title: Text('Alert'),
    //         content: Text(msg),
    //       );
    //     });
    return nullptr;
  }

  String jsStringToDartString(Pointer resultJsString) {
    var resultCString = jSStringGetCharactersPtr(resultJsString);
    int resultCStringLength = jSStringGetLength(resultJsString);
    if (resultCString == nullptr) {
      return 'null';
    }
    String result = String.fromCharCodes(Uint16List.view(
        resultCString.cast<Uint16>().asTypedList(resultCStringLength).buffer,
        0,
        resultCStringLength));
    return result;
  }

  String _getJsValue(Pointer jsValueRef) {
    if (jSValueIsNull(globalContext, jsValueRef) == 1) {
      return 'null';
    } else if (jSValueIsUndefined(globalContext, jsValueRef) == 1) {
      return 'undefined';
    } else if (jSValueIsObject(globalContext, jsValueRef) == 1) {
      // Is object, convert to map
      return 'Object object';
    }

    /// Last resort, cast anything to string, like "[Object object]"
    var resultJsString =
        jSValueToStringCopy(globalContext, jsValueRef, nullptr);
    var resultCString = jSStringGetCharactersPtr(resultJsString);
    int resultCStringLength = jSStringGetLength(resultJsString);
    if (resultCString == nullptr) {
      return 'null';
    }
    String result = String.fromCharCodes(Uint16List.view(
        resultCString.cast<Uint16>().asTypedList(resultCStringLength).buffer,
        0,
        resultCStringLength));
    jSStringRelease(resultJsString);
    return result;
  }

  /// # ======== THE PRINT FUNCTION ========== # ///
  static Pointer flutterPrint(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    if (_printDartFunc != null) {
      _printDartFunc!(
          ctx, function, thisObject, argumentCount, arguments, exception);
    }
    return nullptr;
  }

  static JSObjectCallAsFunctionCallbackDart? _printDartFunc;

  Pointer _print(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    if (argumentCount > 0) {
      debugPrint(_getJsValue(arguments[0]));
    }
    return nullptr;
  }

  /// # ======== THE PRINT FUNCTION - END ========== # ///

  /// # ======== THE addTemplate FUNCTION ========== # ///
  static Pointer ccAddTemplate(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    if (_ccAddTemplateFunc != null) {
      _ccAddTemplateFunc!(
          ctx, function, thisObject, argumentCount, arguments, exception);
    }
    return nullptr;
  }

  static JSObjectCallAsFunctionCallbackDart? _ccAddTemplateFunc;

  /// Convert a javascript object to dart map
  /// [jsValueRef] The pointer to JS obj
  Map<String, String> jsObjectToDartMap(Pointer jsValueRef) {
    if (jSValueIsObject(globalContext, jsValueRef) == 1) {
      // if is object
      Pointer obj = jSValueToObject(globalContext, jsValueRef, nullptr);

      //(JSPropertyNameArrayRef)
      Pointer props = jSObjectCopyPropertyNames(globalContext, obj);
      int propCount = jSPropertyNameArrayGetCount(props);
      Map<String, String> result = {};
      // debugPrint("JS PROPC $propCount");
      for (var i = 0; i < propCount; i++) {
        Pointer /*(JSStringRef)*/ propName =
            jSPropertyNameArrayGetNameAtIndex(props, i);
        Pointer /*JSValueRef*/ propValue =
            jSObjectGetProperty(globalContext, obj, propName, nullptr);
        String name = jsStringToDartString(propName);
        jSStringRelease(propName);
        dynamic value;
        int propType = jSValueGetType(globalContext, propValue);
        switch (propType) {
          case 4: //kJSTypeString:
            value = _getJsValue(propValue);
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
    int type = jSValueGetType(globalContext, jsValueRef);
    debugPrint("jsObjectToDartMap error: value is not obj, type:$type");
    return {};
  }

  Pointer _ccAddTemplate(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    if (argumentCount > 0) {
      Pointer jsValueRef = arguments[0];
      if (jSValueIsObject(globalContext, jsValueRef) == 1) {
        /// the provided argument 0 is an object, then parse it
        String name, description, version, identifier;
        Pointer obj = jSValueToObject(globalContext, jsValueRef, nullptr);
        name = _getJsValue(jSObjectGetProperty(globalContext, obj,
            jSStringCreateWithUTF8CString('name'.toNativeUtf8()), nullptr));
        description = _getJsValue(jSObjectGetProperty(
            globalContext,
            obj,
            jSStringCreateWithUTF8CString('description'.toNativeUtf8()),
            nullptr));
        version = _getJsValue(jSObjectGetProperty(globalContext, obj,
            jSStringCreateWithUTF8CString('version'.toNativeUtf8()), nullptr));
        identifier = _getJsValue(jSObjectGetProperty(
            globalContext,
            obj,
            jSStringCreateWithUTF8CString('identifier'.toNativeUtf8()),
            nullptr));
        var _options = jSObjectGetProperty(globalContext, obj,
            jSStringCreateWithUTF8CString('options'.toNativeUtf8()), nullptr);
        var options = jsObjectToDartMap(_options);

        var onCreate = (Map<String, dynamic> args) async {};
        var _onCreate = jSObjectGetProperty(globalContext, obj,
            jSStringCreateWithUTF8CString('onCreate'.toNativeUtf8()), nullptr);
        if (jSValueIsObject(globalContext, _onCreate) == 1) {
          onCreate = (Map<String, dynamic> args) async {
            var optionsObj = jscore.JSObject.make(
                _globalContext,
                jscore.JSClass.create(
                    jscore.JSClassDefinition(className: "OptionsObj")));
            for (var key in args.keys) {
              var value = args[key];
              if (value is String) {
                optionsObj.setProperty(
                    key,
                    jscore.JSValue.makeString(_globalContext, value),
                    jscore.JSPropertyAttributes.kJSPropertyAttributeReadOnly);
              }else if(value is int || value is double){
                optionsObj.setProperty(
                    key,
                    jscore.JSValue.makeNumber(_globalContext, value as double),
                    jscore.JSPropertyAttributes.kJSPropertyAttributeReadOnly);
              }
            }
            jSObjectCallAsFunction(
                globalContext,
                _onCreate,
                obj,
                1,
                jscore.JSValuePointer.array([optionsObj.toValue()]).pointer,
                nullptr);
          };
        }

        templates.add(Template(
          name,
          description,
          version,
          options,
          onCreate,
          icon,
          identifier,
        ));
      }
    }
    return nullptr;
  }

  /// # ======== THE PRINT FUNCTION - END ========== # ///

  /// Expose the CoreCoder class to js
  void initializeCC3JS() {
    Pointer<Utf8> ccClassName = 'CoreCoder'.toNativeUtf8();

    // Registering alert function
    Pointer<Utf8> funcNameCString = 'alert'.toNativeUtf8();
    contextGroup = jSContextGroupCreate();
    // globalContext = jSGlobalContextCreateInGroup(contextGroup, nullptr);
    _globalContext =
        jscore.JSContext.createInGroup(group: jscore.JSContextGroup.create());
    globalObject = jSContextGetGlobalObject(globalContext);

    _alertDartFunc = _alert;
    var functionObject = jSObjectMakeFunctionWithCallback(
        globalContext,
        jSStringCreateWithUTF8CString(funcNameCString),
        Pointer.fromFunction(alert));
    jSObjectSetProperty(
        globalContext,
        globalObject,
        jSStringCreateWithUTF8CString(funcNameCString),
        functionObject,
        JSPropertyAttributes.kJSPropertyAttributeNone,
        nullptr);
    malloc.free(funcNameCString);

    // Registering other function
    _printDartFunc = _print;
    _ccAddTemplateFunc = _ccAddTemplate;

    var staticFunctions = JSStaticFunctionPointer.allocateArray([
      JSStaticFunctionStruct(
        name: 'print'.toNativeUtf8(),
        callAsFunction: Pointer.fromFunction(flutterPrint),
        attributes: JSPropertyAttributes.kJSPropertyAttributeNone,
      ),
      JSStaticFunctionStruct(
        name: 'addTemplate'.toNativeUtf8(),
        callAsFunction: Pointer.fromFunction(ccAddTemplate),
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
    var flutterJSObject = jSObjectMake(globalContext, flutterJSClass, nullptr);
    jSObjectSetProperty(
        globalContext,
        globalObject,
        jSStringCreateWithUTF8CString(ccClassName),
        flutterJSObject,
        JSPropertyAttributes.kJSPropertyAttributeDontDelete,
        nullptr);
    malloc.free(ccClassName);
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
    initializeCC3JS();
    debugPrint("Initializing JSModule $name");
    jSEvaluateScript(
        globalContext,
        jSStringCreateWithUTF8CString(mainScript.toNativeUtf8()),
        nullptr,
        nullptr,
        1,
        nullptr);
    Pointer onInitializedValueRef = jSObjectGetProperty(
      globalContext,
      globalObject,
      jSStringCreateWithUTF8CString('onInitialized'.toNativeUtf8()),
      nullptr,
    );
    Pointer onInitializedObj =
        jSValueToObject(globalContext, onInitializedValueRef, nullptr);
    jSObjectCallAsFunction(
        globalContext, onInitializedObj, nullptr, 0, nullptr, nullptr);
    // var global = jsContext!.globalObject;
    // var onInitialized = global.getProperty("onInitialized").toObject();
    // onInitialized.callAsFunction(global, JSValuePointer.array([]));
    // debugPrint(hey);
  }
}
