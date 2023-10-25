import 'dart:async';

import 'package:flutter/material.dart';
import 'braintree_plugin_platform_interface.dart';

final BraintreePluginPlatform _braintreePluginPlatform =
    BraintreePluginPlatform.instance;

class BraintreePlugin {
  BraintreePlugin() {
    _init();
  }

  int? _contextId;
  final List<Completer<void>> _initListeners = [];

  Future<void> _init() async {
    _contextId = await _braintreePluginPlatform.init();
    if (_contextId == null) {
      throw Exception('Unknown error initializing plugin');
    }
    for (Completer<void> listener in _initListeners) {
      listener.complete();
    }
  }

  Future<void> _awaitInit() {
    final completer = Completer<void>();
    if (_contextId != null) {
      completer.complete();
    } else {
      _initListeners.add(completer);
    }
    return completer.future;
  }

  Future<Widget?> createCreditCardForm({
    bool postalCode = false,
    Map<String, String>? fieldContainerStyles,
    Map<String, String>? focusedFieldContainerStyles,
    Map<String, String>? errorFieldContainerStyles,
    Map<String, String>? focusedErrorFieldContainerStyles,
    Map<String, String>? labelStyles,
    Map<String, String>? braintreeInputIframeStyles,
  }) async {
    await _awaitInit();
    return _braintreePluginPlatform.createCreditCardForm(
      contextId: _contextId!,
      postalCode: postalCode,
      fieldContainerStyles: fieldContainerStyles,
      focusedFieldContainerStyles: focusedFieldContainerStyles,
      errorFieldContainerStyles: errorFieldContainerStyles,
      focusedErrorFieldContainerStyles: focusedErrorFieldContainerStyles,
      labelStyles: labelStyles,
      braintreeInputIframeStyles: braintreeInputIframeStyles,
    );
  }

  Future<Widget?> createPaypalButtonContainer() async {
    await _awaitInit();
    return _braintreePluginPlatform.createPaypalButtonContainer(_contextId!);
  }

  Future<void> initializeHostedFields({
    required String authorization,
    Object? inputStyles,
    dynamic Function(dynamic err)? onInitError,
  }) async {
    await _awaitInit();
    return _braintreePluginPlatform.initializeHostedFields(
      contextId: _contextId!,
      authorization: authorization,
      inputStyles: inputStyles,
      onInitError: onInitError,
    );
  }

  Future<void> requestPaymentMethod(
      Function(dynamic err, [dynamic payload]) callback) async {
    await _awaitInit();
    return _braintreePluginPlatform.requestPaymentMethod(_contextId!, callback);
  }

  Future<void> initializePaypal({
    required String authorization,
    required Map<String, dynamic> paypalSdkOptions,
    required Map<String, dynamic> paymentOptions,
    void Function(dynamic err, [dynamic payload])? onPaymentRequest,
    void Function(dynamic data)? onPaymentCanceled,
    dynamic Function(dynamic data, dynamic actions)? onShippingChanged,
    dynamic Function(dynamic err)? onInitError,
    Map<String, dynamic>? buttonStyle,
  }) async {
    await _awaitInit();
    return _braintreePluginPlatform.initializePaypal(
      contextId: _contextId!,
      authorization: authorization,
      paypalSdkOptions: paypalSdkOptions,
      paymentOptions: paymentOptions,
      onPaymentRequest: onPaymentRequest,
      onPaymentCanceled: onPaymentCanceled,
      onShippingChanged: onShippingChanged,
      buttonStyle: buttonStyle,
      onInitError: onInitError,
    );
  }
}
