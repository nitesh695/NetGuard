import 'package:flutter/foundation.dart';

void logger(dynamic message){
  if (kDebugMode) {
    print('$message');
  }
}