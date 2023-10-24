import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'braintree_plugin_platform_interface.dart';

/// An implementation of [BraintreePluginPlatform] that uses method channels.
class MethodChannelBraintreePlugin extends BraintreePluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('braintree_plugin');

  @override
  Future<int?> init() async {
    final contextId = await methodChannel.invokeMethod<int>(
      'init',
    );
    return contextId;
  }

  @override
  Future<Widget?> createCreditCardForm({
    required int contextId,
    bool postalCode = false,
    Map<String, String>? fieldContainerStyles,
    Map<String, String>? focusedFieldContainerStyles,
    Map<String, String>? errorFieldContainerStyles,
    Map<String, String>? focusedErrorFieldContainerStyles,
    Map<String, String>? labelStyles,
    Map<String, String>? braintreeInputIframeStyles,
  }) async {
    final view = await methodChannel
        .invokeMethod<Widget>('createCreditCardForm', <String, dynamic>{
      'contextId': contextId,
      'postalCode': postalCode,
      'fieldContainerStyles': fieldContainerStyles,
      'focusedFieldContainerStyles': focusedFieldContainerStyles,
      'errorFieldContainerStyles': errorFieldContainerStyles,
      'focusedErrorFieldContainerStyles': focusedErrorFieldContainerStyles,
      'labelStyles': labelStyles,
      'braintreeInputIframeStyles': braintreeInputIframeStyles,
    });
    return view;
  }

  @override
  Future<Widget?> createPaypalButtonContainer(int contextId) async {
    final view = await methodChannel
        .invokeMethod<Widget>('createPaypalButtonContainer', <String, dynamic>{
      'contextId': contextId,
    });
    return view;
  }

  @override
  Future<void> initializeHostedFields({
    required int contextId,
    required String authorization,
    Object? inputStyles,
    dynamic Function(dynamic err)? onInitError,
  }) {
    return methodChannel
        .invokeMethod<void>('initializeHostedFields', <String, dynamic>{
      'contextId': contextId,
      'authorization': authorization,
      'inputStyles': inputStyles,
      'onInitError': onInitError,
    });
  }

  @override
  Future<void> requestPaymentMethod(
      int contextId, Function(dynamic err, [dynamic payload]) callback) async {
    return methodChannel
        .invokeMethod<void>('requestPaymentMethod', <String, dynamic>{
      'contextId': contextId,
      'callback': callback,
    });
  }

  @override
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
    return methodChannel
        .invokeMethod<void>('initializePaypal', <String, dynamic>{
      'contextId': contextId,
      'authorization': authorization,
      'paypalSdkOptions': paypalSdkOptions,
      'paymentOptions': paymentOptions,
      'onPaymentRequest': onPaymentRequest,
      'onPaymentCanceled': onPaymentCanceled,
      'onShippingChanged': onShippingChanged,
      'buttonStyle': buttonStyle,
      'onInitError': onInitError,
    });
  }
}
