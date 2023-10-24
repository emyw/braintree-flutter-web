@JS('braintree')
library braintree;

import 'package:js/js.dart';

/// Braintree Client ///

typedef ClientCallback = void Function(dynamic err, [dynamic instance]);

@JS()
external BraintreeClient get client;

@JS()
class BraintreeClient {
  external void create(Object options, ClientCallback callback);
}

@JS()
class Client {
  external void requestPaymentMethod(
      void Function(dynamic err, [dynamic payload]) callback);
}

/// Braintree Hosted Fields ///

typedef HostedFieldsCallback = void Function(dynamic err,
    [HostedFields? instance]);
typedef PaypalCheckoutCallback = void Function(dynamic err, [PayPal? instance]);

@JS()
external BraintreeHostedFields get hostedFields;

@JS()
class BraintreeHostedFields {
  external void create(Object options, HostedFieldsCallback callback);
}

@JS()
class HostedFields {
  external void tokenize(
      void Function(dynamic err, [dynamic payload]) callback);
}

@JS()
class PayPal {
  external void loadPayPalSDK(
      Object options, void Function(dynamic err, [dynamic payload]) callback);
  external void createPayment(Object options);
  external void updatePayment(Object options);
  external void tokenizePayment(
      dynamic data, void Function(dynamic err, [dynamic payload]) callback);
}

@JS()
external BraintreePaypalCheckout get paypalCheckout;

@JS()
class BraintreePaypalCheckout {
  external void create(Object options, PaypalCheckoutCallback callback);
}

@JS()
class TokenizePayload {
  external String nonce;
}

/// Custom callback wrapper ///

@JS()
external dynamic callbackWrapper(Function callback);
