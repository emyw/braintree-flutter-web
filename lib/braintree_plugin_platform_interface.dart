import 'package:flutter/material.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'braintree_plugin_method_channel.dart';

abstract class BraintreePluginPlatform extends PlatformInterface {
  /// Constructs a BraintreePluginPlatform.
  BraintreePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static BraintreePluginPlatform _instance = MethodChannelBraintreePlugin();

  /// The default instance of [BraintreePluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelBraintreePlugin].
  static BraintreePluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BraintreePluginPlatform] when
  /// they register themselves.
  static set instance(BraintreePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<int?> init() {
    throw UnimplementedError('init() has not been implemented.');
  }

  Future<Widget?> createCreditCardForm({
    required int contextId,
    bool postalCode = false,
    Map<String, String>? fieldContainerStyles,
    Map<String, String>? focusedFieldContainerStyles,
    Map<String, String>? errorFieldContainerStyles,
    Map<String, String>? focusedErrorFieldContainerStyles,
    Map<String, String>? labelStyles,
    Map<String, String>? braintreeInputIframeStyles,
    Function? onMount,
  }) {
    throw UnimplementedError(
        'createCreditCardForm() has not been implemented.');
  }

  Future<Widget?> createPaypalButtonContainer({
    required int contextId,
    Function? onMount,
  }) {
    throw UnimplementedError(
        'createPaypalButtonContainer() has not been implemented.');
  }

  Future<void> initializeHostedFields({
    required int contextId,
    required String authorization,
    Object? inputStyles,
    dynamic Function(dynamic err)? onInitError,
  }) {
    throw UnimplementedError(
        'initializeHostedFields() has not been implemented.');
  }

  Future<void> requestPaymentMethod(
      int contextId, Function(dynamic err, [dynamic payload]) callback) {
    throw UnimplementedError(
        'requestPaymentMethod() has not been implemented.');
  }

  Future<void> initializePaypal({
    required int contextId,
    required String authorization,
    required Map<String, dynamic> paypalSdkOptions,
    required Map<String, dynamic> paymentOptions,
    void Function(dynamic err, [dynamic payload])? onPaymentRequest,
    void Function(dynamic data)? onPaymentCanceled,
    dynamic Function(dynamic data, dynamic actions)? onShippingChanged,
    dynamic Function(dynamic err)? onInitError,
    Map<String, dynamic>? buttonStyle,
  }) {
    throw UnimplementedError('initializePaypal() has not been implemented.');
  }
}

enum Field {
  number,
  exp,
  cvv,
  zip;

  String get code => switch (this) {
        number => 'number',
        exp => 'expirationDate',
        cvv => 'cvv',
        zip => 'postalCode',
      };

  String get title => switch (this) {
        number => 'Number',
        exp => 'Expiration',
        cvv => 'CVV',
        zip => 'Zip',
      };

  static Field? from(String code) {
    for (Field field in Field.values) {
      if (field.code == code) return field;
    }
    return null;
  }
}

enum FieldState {
  normal,
  focused,
  error,
  focusedError,
}
