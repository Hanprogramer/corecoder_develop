import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:corecoder_develop/modules/module_jsplugins.dart';
import 'package:corecoder_develop/util/modules_manager.dart';
import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_jscore/flutter_jscore.dart';
import 'package:flutter_jscore/jscore_bindings.dart' as js;


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
  static CoreCoder get instance{
    _instance ??= CoreCoder();
    return _instance!;
  }
  
  void addTemplate(Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception){
    if (argumentCount > 0) {
      Pointer jsValueRef = arguments[0];
      if (js.jSValueIsObject(ctx, jsValueRef) == 1) {
        /// the provided argument 0 is an object, then parse it
        String name, description, version, identifier;
        Pointer obj = js.jSValueToObject(ctx, jsValueRef, nullptr);
        name = _getJsValue(ctx,js.jSObjectGetProperty(ctx, obj,
            js.jSStringCreateWithUTF8CString('name'.toNativeUtf8()), nullptr));

        description = _getJsValue(ctx,js.jSObjectGetProperty(
            ctx,
            obj,
            js.jSStringCreateWithUTF8CString('description'.toNativeUtf8()),
            nullptr));

        version = _getJsValue(ctx,js.jSObjectGetProperty(ctx, obj,
            js.jSStringCreateWithUTF8CString('version'.toNativeUtf8()), nullptr));

        identifier = _getJsValue(ctx,js.jSObjectGetProperty(
            ctx,
            obj,
            js.jSStringCreateWithUTF8CString('identifier'.toNativeUtf8()),
            nullptr));

        var _options = js.jSObjectGetProperty(ctx, obj,
            js.jSStringCreateWithUTF8CString('options'.toNativeUtf8()), nullptr);
        var options = jsObjectToDartMap(ctx,_options);

        var onCreate = (Map<String, dynamic> args) async {};
        var _onCreate = js.jSObjectGetProperty(ctx, obj,
            js.jSStringCreateWithUTF8CString('onCreate'.toNativeUtf8()), nullptr);
        if (js.jSValueIsObject(ctx, _onCreate) == 1) {
          onCreate = (Map<String, dynamic> args) async {
            var optionsObj = JSObject.make(
                context,
                JSClass.create(
                    JSClassDefinition(className: "OptionsObj")));
            for (var key in args.keys) {
              var value = args[key];
              if (value is String) {
                optionsObj.setProperty(
                    key,
                    JSValue.makeString(context, value),
                    JSPropertyAttributes.kJSPropertyAttributeReadOnly);
              } else if (value is int || value is double) {
                optionsObj.setProperty(
                    key,
                    JSValue.makeNumber(context, value as double),
                    JSPropertyAttributes.kJSPropertyAttributeReadOnly);
              }
            }
            js.jSObjectCallAsFunction(
                ctx,
                _onCreate,
                obj,
                1,
                JSValuePointer.array([optionsObj.toValue()]).pointer,
                nullptr);
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
  
  static Pointer jsAddTemplate(Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception){
    instance.addTemplate(ctx,function, thisObject, argumentCount, arguments, exception);
    return nullptr;
  }


  /// # ======== THE PRINT FUNCTION ========== # ///
  static Pointer jsPrint(
      Pointer ctx,
      Pointer function,
      Pointer thisObject,
      int argumentCount,
      Pointer<Pointer> arguments,
      Pointer<Pointer> exception) {
    instance.print(ctx, function, thisObject, argumentCount, arguments, exception);
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
      debugPrint(_getJsValue(ctx,arguments[0]));
    }
    return nullptr;
  }

/// # ======== THE PRINT FUNCTION - END ========== # ///
  
}

class FileIO{
  static late JsModule module; // set by the parent object
  static late JSContext context; // set by the parent object
}