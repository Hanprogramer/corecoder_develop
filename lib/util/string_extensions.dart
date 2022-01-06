import 'dart:math';

import 'package:flutter/material.dart';
extension StringExt on String{
  /// Checks whether the version is LOWER than the provided argument
  /// //TODO: this is very inaccurate way to do it but kinda fast
  bool compareVersion(String b){
    var strSplitA = substring(1).split(".");
    var strSplitB = b.substring(1).split(".");
    int versionA = 0, versionB = 0;

    // Version A as int
    int multiplier = 1000000;
    for(int i = 0; i < strSplitA.length; i++){
      multiplier = multiplier ~/ 10;
      try {
        versionA += int.parse(strSplitA[i]) * multiplier;
      }on FormatException catch (e){
        debugPrint(e.message);
        continue;
      }
    }


    // Version B as int
    multiplier = 1000000;
    for(int i = 0; i < strSplitB.length; i++){
      multiplier = multiplier ~/ 10;
      try {
        versionB += int.parse(strSplitB[i]) * multiplier;
      }on FormatException catch (e){
        debugPrint(e.message);
        continue;
      }
    }
    // debugPrint("versionA $versionA : $this");
    // debugPrint("versionB $versionB : $b");
    return versionA < versionB;
  }
}