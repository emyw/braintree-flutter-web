import 'package:flutter_test/flutter_test.dart';
import 'package:braintree_flutter_web/braintree_plugin_platform_interface.dart';
import 'package:braintree_flutter_web/braintree_plugin_method_channel.dart';

void main() {
  final BraintreePluginPlatform initialPlatform =
      BraintreePluginPlatform.instance;

  test('$MethodChannelBraintreePlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBraintreePlugin>());
  });
}
