import 'package:js/js.dart';

@JS()
class Promise {
  external Promise(void Function(void Function([dynamic result]) resolve, void Function([dynamic error]) reject) executor);
  external Promise then(void Function([dynamic result]) onFulfilled, [void Function([dynamic error]) reject]);
}

@JS()
class NativeError {
  external String code;
  external String message;
  external String name;
  external String type;
}
