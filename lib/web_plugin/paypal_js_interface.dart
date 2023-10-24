@JS('paypal')
library paypal;

import 'package:js/js.dart';
import './native_js_interface.dart';

@JS()
external PayPalButtons Buttons(Object options);

@JS()
class PayPalButtons {
  // external factory PayPalButtons();
  external Promise render(String htmlButtonId);
}
