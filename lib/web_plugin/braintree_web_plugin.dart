import 'dart:async';
import 'dart:html' as html;
import 'dart:js';
import 'dart:js_util';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:braintree_web/braintree_plugin_platform_interface.dart';
import 'package:flutter/material.dart';

import './shims/dart_ui.dart' as ui;
import './braintree_js_interface.dart' as braintree;
import './paypal_js_interface.dart' as paypal;

int _contextCounter = 0;

const _formIdBase = 'braintree-form-container';

class FieldRef {
  FieldRef({required this.field, required this.elementRef});

  Field field;
  html.DivElement elementRef;
}

class _BraintreeState {
  _BraintreeState();

  dynamic clientInstance;

  bool hostedFieldsInitialized = false;
  bool paypalInitialized = false;

  HtmlElementView? ccForm;
  final List<FieldRef> inputContainers = [];
  braintree.HostedFields? hostedFieldsInstance;
  bool includeZipInCCForm = false;
  bool hasFieldError = false;

  HtmlElementView? ppButtonContainer;
}

class BraintreePlugin extends BraintreePluginPlatform {
  static void registerWith(Registrar registrar) {
    BraintreePluginPlatform.instance = BraintreePlugin();
  }

  @override
  Future<int> init() async {
    final contextId = ++_contextCounter;
    _state[contextId] = _BraintreeState();
    return contextId;
  }

  final Map<int, _BraintreeState> _state = {};

  String htmlInputContainerId(int contextId, Field field) =>
      'braintree-${field.name}-container-$contextId';

  String htmlPaypalButtonContainerId(int contextId) =>
      'paypal-button-container-$contextId';

  String stylesToCss(Map<String, String> styles) =>
      styles.keys.map((item) => '$item: ${styles[item]}').join(';');

  dynamic callbackWrapper(Function callback) =>
      braintree.callbackWrapper(allowInterop(callback));

  /// Create and register an html credit card form, and create and return an HtmlElementView for it
  @override
  Future<Widget> createCreditCardForm({
    required int contextId,
    bool postalCode = false,
    Map<String, String>? fieldContainerStyles,
    Map<String, String>? focusedFieldContainerStyles,
    Map<String, String>? errorFieldContainerStyles,
    Map<String, String>? focusedErrorFieldContainerStyles,
    Map<String, String>? labelStyles,
    Map<String, String>? braintreeInputIframeStyles,
    Function? onMount,
  }) async {
    final instanceState = _state[contextId];
    if (instanceState == null) {
      throw Exception('Invalid contextId');
    }
    if (instanceState.ccForm != null) {
      return instanceState.ccForm!;
    }

    instanceState.includeZipInCCForm = postalCode;

    /* HTML layout:

      <form id="braintree-form-container-1" action="/" method="post">
        <div> (flex row)
          <div style="padding: (margin)"> (outer container)
            <div id="braintree-number-container-1" style="background-color: (bg); padding: (padding)"> (Braintree input container)
              <label for="braintree-number-container-1">(Field title)</label>
              (Braintree iframe will be placed here)
            </div>
          </div>
          (...other fields)
        </div>
        (...other field rows)
      </form>

    */

    html.DivElement newFieldContainer(Field field) {
      final id = htmlInputContainerId(contextId, field);

      final inputContainer = html.DivElement()
        ..attributes = {
          'id': id,
          'class': 'braintree-field-container-$contextId'
        }
        ..children = [
          html.LabelElement()
            ..text = field.title
            ..attributes = {
              'for': id,
            },
        ];

      instanceState.inputContainers
          .add(FieldRef(field: field, elementRef: inputContainer));

      final fieldContainer = html.DivElement()
        ..children = [
          inputContainer,
        ];

      return fieldContainer;
    }

    html.DivElement newFieldRow(List<html.Element> children) {
      final rowContainer = html.DivElement()
        ..attributes = {
          'class': 'braintree-field-row-$contextId',
        }
        ..children = children;

      return rowContainer;
    }

    final numberRowContainer = newFieldRow([
      newFieldContainer(Field.number),
    ]);

    final expCvvRowContainer = newFieldRow([
      newFieldContainer(Field.exp),
      newFieldContainer(Field.cvv),
    ]);

    final zipRowContainer = instanceState.includeZipInCCForm
        ? newFieldRow([
            newFieldContainer(Field.zip),
          ])
        : null;

    final formChildren = [numberRowContainer, expCvvRowContainer];
    if (instanceState.includeZipInCCForm) formChildren.add(zipRowContainer!);

    final ccFormId = '$_formIdBase-$contextId';
    final formElement = html.FormElement()
      ..attributes = {
        'id': ccFormId,
        'action': '/',
        'method': 'post',
        'style': 'display: flex; flex-direction: column',
      }
      ..children = formChildren;
    instanceState.ccForm =
        HtmlElementView(viewType: ccFormId, key: ObjectKey(formElement));
    ui.platformViewRegistry
        .registerViewFactory(ccFormId, (int viewId) => formElement);

    _applyCCFormStyles(
      contextId: contextId,
      fieldContainerStylesProp: fieldContainerStyles,
      focusedFieldContainerStylesProp: focusedFieldContainerStyles,
      errorFieldContainerStylesProp: errorFieldContainerStyles,
      focusedErrorFieldContainerStylesProp: focusedErrorFieldContainerStyles,
      labelStylesProp: labelStyles,
      braintreeInputIframeStylesProp: braintreeInputIframeStyles,
    );

    return WidgetWrapper(onMount: onMount, child: instanceState.ccForm!);
  }

  /// Create a style element for styling the credit card form, and inject it into the document head
  void _applyCCFormStyles({
    required int contextId,
    Map<String, String>? fieldContainerStylesProp,
    Map<String, String>? focusedFieldContainerStylesProp,
    Map<String, String>? errorFieldContainerStylesProp,
    Map<String, String>? focusedErrorFieldContainerStylesProp,
    Map<String, String>? labelStylesProp,
    Map<String, String>? braintreeInputIframeStylesProp,
  }) {
    final Map<String, String> rowStyles = {
      'display': 'flex',
      'height': '100%',
      'min-height': '0',
      'width': '100%',
      'box-sizing': 'border-box',
    };

    final Map<String, String> outerContainerStyles = {
      'width': '100%',
      'height': '100%',
      'padding': '1em', // Acts as field outer margin
      'box-sizing': 'border-box',
    };

    final Map<String, String> fieldContainerStyles = {
      'display': 'flex',
      'flex-direction': 'column',
      'justify-content': 'space-between',
      'width': '100%',
      'height': '100%',
      'padding': '0.5em 1em 0.75em 1em', // Acts as field inner padding
      'box-sizing': 'border-box',
      'border': 'solid 1px gray',
      'background-color': 'rgb(200, 200, 200)',
      'border-radius': '0.5em',
    };

    final Map<String, String> labelStyles = {
      // 'position': 'absolute',
      'display': 'flex',
      'align-items': 'center',
      'color': 'gray',
      'font-size': '0.75em',
      'height': '20%',
    };

    final Map<String, String> braintreeInputIframeStyles = {
      'height': '60% !important',
      'min-height': '0',
    };

    final Map<String, String> focusedFieldContainerStyles = {
      'border': 'solid 1px rgba(0, 192, 240, 0.75)',
    };

    final Map<String, String> errorFieldContainerStyles = {
      'background-color': 'rgba(193, 128, 128, 0.5)',
    };

    final Map<String, String> focusedErrorFieldContainerStyles = {
      'border': 'solid 1px rgba(255, 194, 194, 0.5)',
    };

    void applyProvidedFieldStyles(
        Map<String, String> stylesProp, FieldState fieldState) {
      List<dynamic> styleKeys = stylesProp.keys.toList();
      for (var name in styleKeys) {
        if (name == null) continue;
        final dynamic value = stylesProp[name];
        if (value == null) continue;
        if ([
          'width',
          'min-width',
          'max-width',
          'height',
          'min-height',
          'max-height',
          'font-size'
        ].contains(name)) {
          if (fieldState != FieldState.normal) return;
          rowStyles[name] = value;
        } else if (['margin'].contains(name)) {
          if (fieldState != FieldState.normal) return;
          if (name == 'margin') {
            // Apply margin prop as padding to outer container to avoid flex child sizing issues
            outerContainerStyles['padding'] = value;
          } else {
            outerContainerStyles[name] = value;
          }
        } else {
          switch (fieldState) {
            case FieldState.normal:
              fieldContainerStyles[name] = value;
            case FieldState.focused:
              focusedFieldContainerStyles[name] = value;
            case FieldState.error:
              errorFieldContainerStyles[name] = value;
            case FieldState.focusedError:
              focusedErrorFieldContainerStyles[name] = value;
          }
        }
      }
    }

    // Apply any provided styles:
    if (fieldContainerStylesProp != null) {
      applyProvidedFieldStyles(fieldContainerStylesProp, FieldState.normal);
    }
    if (focusedFieldContainerStylesProp != null) {
      applyProvidedFieldStyles(
          focusedFieldContainerStylesProp, FieldState.focused);
    }
    if (errorFieldContainerStylesProp != null) {
      applyProvidedFieldStyles(errorFieldContainerStylesProp, FieldState.error);
    }
    if (focusedErrorFieldContainerStylesProp != null) {
      applyProvidedFieldStyles(
          focusedErrorFieldContainerStylesProp, FieldState.focusedError);
    }

    if (labelStylesProp != null) {
      List<dynamic> styleKeys = labelStylesProp.keys.toList();
      for (var name in styleKeys) {
        if (name == null) continue;
        final dynamic value = labelStylesProp[name];
        if (value == null) continue;
        labelStyles[name] = value;
      }
    }

    if (braintreeInputIframeStylesProp != null) {
      List<dynamic> styleKeys = braintreeInputIframeStylesProp.keys.toList();
      for (var name in styleKeys) {
        if (name == null) continue;
        final dynamic value = braintreeInputIframeStylesProp[name];
        if (value == null) continue;
        braintreeInputIframeStyles[name] = value;
      }
    }

    final rowStylesString = stylesToCss(rowStyles);
    final outerContainerStylesString = stylesToCss(outerContainerStyles);
    final fieldContainerStylesString = stylesToCss(fieldContainerStyles);
    final focusedFieldContainerStylesString =
        stylesToCss(focusedFieldContainerStyles);
    final errorFieldContainerStylesString =
        stylesToCss(errorFieldContainerStyles);
    final focusedErrorFieldContainerStylesString =
        stylesToCss(focusedErrorFieldContainerStyles);
    final labelStylesString = stylesToCss(labelStyles);
    final braintreeInputIframeStylesString =
        stylesToCss(braintreeInputIframeStyles);

    html.StyleElement? styleElement =
        html.document.head!.querySelector('style#braintree-styles-$contextId')
            as html.StyleElement?;
    if (styleElement == null) {
      styleElement = html.StyleElement()..id = 'braintree-styles-$contextId';
      html.document.head!.append(styleElement);
    }

    styleElement.text = '.braintree-field-row-$contextId { $rowStylesString }'
        '.braintree-field-row-$contextId > div { $outerContainerStylesString }'
        '.braintree-field-container-$contextId { $fieldContainerStylesString }'
        '.braintree-field-container-$contextId > label { $labelStylesString }'
        '.braintree-field-container-$contextId > iframe { $braintreeInputIframeStylesString }'
        '.braintree-field-container-$contextId > :nth-child(3) { display: none }'
        '.braintree-field-container-$contextId.braintree-hosted-fields-focused { $focusedFieldContainerStylesString }'
        '.braintree-field-container-$contextId.braintree-hosted-fields-error { $errorFieldContainerStylesString }'
        '.braintree-field-container-$contextId.braintree-hosted-fields-focused.braintree-hosted-fields-error { $focusedErrorFieldContainerStylesString }';
  }

  /// Create and register an html div for the paypal button to be placed inside, and create and return an HtmlElementView for it
  @override
  Future<Widget> createPaypalButtonContainer({
    required int contextId,
    Function? onMount,
  }) async {
    final instanceState = _state[contextId];
    if (instanceState == null) {
      throw Exception('Invalid contextId');
    }
    if (instanceState.ppButtonContainer != null) {
      return instanceState.ppButtonContainer!;
    }

    final buttonContainerId = htmlPaypalButtonContainerId(contextId);
    final buttonContainer = html.DivElement()..id = buttonContainerId;

    instanceState.ppButtonContainer = HtmlElementView(
        viewType: buttonContainerId, key: ObjectKey(buttonContainer));
    ui.platformViewRegistry.registerViewFactory(
        buttonContainerId, (int viewId) => buttonContainer);

    return WidgetWrapper(
        onMount: onMount, child: instanceState.ppButtonContainer!);
  }

  /// Initialize the braintree client
  void _initializeBraintree({
    required int contextId,
    required String authorization,
    braintree.ClientCallback? callback,
  }) {
    final instanceState = _state[contextId]!;
    if (html.document.head!
            .querySelector('script#braintree-script-$contextId') ==
        null) {
      // Inject script to wrap callback function
      final scriptElement = html.ScriptElement()
        ..id = 'braintree-script-$contextId'
        ..text = braintreeCallbackWrapperScript;
      html.document.head!.append(scriptElement);
    }

    if (instanceState.clientInstance != null) {
      if (callback != null) callback(null, instanceState.clientInstance);
      return;
    }
    final clientOptions = jsify({'authorization': authorization});
    braintree.client.create(
        clientOptions, callbackWrapper(callback ?? (err, [instance]) => null));
  }

  /// Initialize the Braintree hosted fields
  @override
  Future<void> initializeHostedFields({
    required int contextId,
    required String authorization,
    Object? inputStyles,
    dynamic Function(dynamic err)? onInitError,
  }) async {
    final instanceState = _state[contextId];
    if (instanceState == null) {
      throw Exception('Invalid contextId');
    }
    if (instanceState.hostedFieldsInitialized) {
      // Remove previous field error states
      if (instanceState.hasFieldError) _clearFieldErrorStates(instanceState);
      // Remove any previous braintree iframes
      for (var container in instanceState.inputContainers) {
        final children = container.elementRef.children.toList();
        bool firstChild = true;
        for (var child in children) {
          if (firstChild) {
            firstChild = false;
          } else {
            child.remove();
          }
        }
      }
    }
    instanceState.hostedFieldsInitialized = true;

    final completer = Completer<void>();

    Map<String, dynamic> createFieldsOption(List<Field> fields) =>
        Map.fromEntries(fields.map((field) => MapEntry(field.code, {
              'container': '#${htmlInputContainerId(contextId, field)}',
              'placeholder': ''
            })));

    _initializeBraintree(
        contextId: contextId,
        authorization: authorization,
        callback: (clientErr, [clientInstance]) {
          if (clientErr != null) {
            if (onInitError != null) {
              onInitError(clientErr);
            }
            return;
          }
          final fields = createFieldsOption([
            Field.number,
            Field.exp,
            Field.cvv,
            ...instanceState.includeZipInCCForm ? [Field.zip] : []
          ]);
          final fieldsOptions = jsify({
            'client': clientInstance,
            'styles': inputStyles,
            'fields': fields,
          });
          braintree.hostedFields.create(fieldsOptions, callbackWrapper(
              (fieldsErr, [braintree.HostedFields? fieldsInstance]) {
            instanceState.hostedFieldsInstance = fieldsInstance;
            if (fieldsErr != null) {
              if (onInitError != null) {
                onInitError(fieldsErr);
              }
              completer.complete();
              return;
            }
            completer.complete();
          }));
        });
    return completer.future;
  }

  /// Validate the provided credit card information and prepare payment by creating a nonce
  @override
  Future<void> requestPaymentMethod(
    int contextId,
    Function(dynamic err, [dynamic payload]) callback,
  ) async {
    final instanceState = _state[contextId];
    if (instanceState == null) {
      throw Exception('Invalid contextId');
    }
    instanceState.hostedFieldsInstance
        ?.tokenize(braintree.callbackWrapper(allowInterop((err, [payload]) {
      if (err != null) {
        List<Field> invalidFields = [];
        if (err.code == 'HOSTED_FIELDS_FIELDS_EMPTY') {
          invalidFields = [
            Field.number,
            Field.exp,
            Field.cvv,
            ...instanceState.includeZipInCCForm ? [Field.zip] : []
          ];
        } else if (err.code == 'HOSTED_FIELDS_FIELDS_INVALID') {
          try {
            final iList = (err.details.invalidFieldKeys as List<dynamic>)
                .map((item) => Field.from(item))
                .where((item) => item != null)
                .toList();
            invalidFields = iList.cast<Field>();
          } catch (err2) {
            callback(err2);
            return;
          }
        }
        _applyFieldErrorStates(instanceState, invalidFields);
      } else {
        _clearFieldErrorStates(instanceState);
      }
      callback(err, payload);
    })));
  }

  /// Initialize PayPal and create a PayPal button
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
  }) async {
    final instanceState = _state[contextId];
    if (instanceState == null) {
      throw Exception('Invalid contextId');
    }
    instanceState.paypalInitialized = true;

    final completer = Completer<void>();

    _initializeBraintree(
        contextId: contextId,
        authorization: authorization,
        callback: (clientErr, [clientInstance]) {
          if (clientErr != null) {
            if (onInitError != null) onInitError(clientErr);
            completer.complete();
            return;
          }

          final paypalCheckoutOptions = jsify({'client': clientInstance});
          braintree.paypalCheckout.create(paypalCheckoutOptions,
              callbackWrapper((paypalErr, [braintree.PayPal? paypalInstance]) {
            if (paypalErr != null) {
              if (onInitError != null) onInitError(paypalErr);
              completer.complete();
              return;
            }

            final ppSdkOptions = jsify(paypalSdkOptions);
            paypalInstance!.loadPayPalSDK(ppSdkOptions,
                callbackWrapper((loadSDKErr, [_ /* paypalInstance */]) {
              if (loadSDKErr != null) {
                if (onInitError != null) onInitError(loadSDKErr);
                completer.complete();
                return;
              }
              // The PayPal script is now loaded on the page and
              // window.paypal.Buttons is now available to use

              _initializePaypalButton(
                  contextId: contextId,
                  paymentOptions: paymentOptions,
                  paypalInstance: paypalInstance,
                  onPaymentRequest: onPaymentRequest,
                  onPaymentCanceled: onPaymentCanceled,
                  onShippingChanged: onShippingChanged,
                  onInitError: onInitError,
                  style: buttonStyle);
              completer.complete();
            }));
          }));
        });
    return completer.future;
  }

  /// Initialize the PayPal button that will request PayPal payment when clicked
  Future<void> _initializePaypalButton({
    required int contextId,
    required Map<String, dynamic> paymentOptions,
    required braintree.PayPal paypalInstance,
    void Function(dynamic err, [dynamic payload])? onPaymentRequest,
    void Function(dynamic data)? onPaymentCanceled,
    dynamic Function(dynamic data, dynamic actions)? onShippingChanged,
    dynamic Function(dynamic err)? onInitError,
    Map<String, dynamic>? style,
  }) {
    final completer = Completer<void>();
    final buttonsOptions = jsify({
      'fundingSource': context['paypal']['FUNDING']['PAYPAL'],
      'createBillingAgreement': allowInterop((arg1, arg2) {
        return paypalInstance.createPayment(jsify(paymentOptions));
      }),
      'style': style,
      'onShippingChange': allowInterop((data, actions) {
        // Can add some validation or calculation logic on 'data'
        // if ( /* need to update shipping options or lineItems */ ) {
        //   return _paypalInstance!.updatePayment({
        //     'amount': 10.00,              // Required
        //     'currency': 'USD',
        //     'lineItems': [...],           // Required
        //     'paymentId': data.paymentId,  // Required
        //     'shippingOptions': [...],     // Optional
        //   });
        // } else if (/* address not supported */) {
        //   return actions.reject();
        // }
        if (onShippingChanged != null) {
          return onShippingChanged(data, actions);
        } else {
          return actions.resolve();
        }
      }),
      'onApprove': allowInterop((data, actions) {
        return paypalInstance.tokenizePayment(data,
            callbackWrapper((err, [payload]) {
          // Submit 'payload.nonce' to your server
          if (onPaymentRequest != null) {
            onPaymentRequest(err, payload);
          }
        }));
      }),
      'onCancel': allowInterop((data, arg2) {
        if (onPaymentCanceled != null) {
          onPaymentCanceled(data);
        }
      }),
      'onError': callbackWrapper((err) {
        if (onPaymentRequest != null) {
          onPaymentRequest(err);
        }
      })
    });
    final button = paypal.Buttons(buttonsOptions);

    final renderPromise =
        button.render('#${htmlPaypalButtonContainerId(contextId)}');
    renderPromise.then(allowInterop(([res]) {
      // The PayPal button will be rendered in an html element with the ID
      // 'paypal-button'. This function will be called when the PayPal button
      // is set up and ready to be used
      completer.complete();
    }), allowInterop(([err]) {
      if (onInitError != null) {
        onInitError(err);
      }
      completer.complete();
    }));
    return completer.future;
  }

  /// Handle credit card field errors, such as missing or invalid info
  void _applyFieldErrorStates(
      _BraintreeState instanceState, List<Field> fields) {
    instanceState.hasFieldError = true;
    for (var container in instanceState.inputContainers) {
      if (fields.contains(container.field)) {
        container.elementRef.classes.add('braintree-hosted-fields-error');
      } else {
        container.elementRef.classes.remove('braintree-hosted-fields-error');
      }
    }
  }

  /// Clear credit card field error states
  void _clearFieldErrorStates(_BraintreeState instanceState) {
    instanceState.hasFieldError = false;
    for (var container in instanceState.inputContainers) {
      container.elementRef.classes.remove('braintree-hosted-fields-error');
    }
  }
}

/// Wrap credit card form and paypal button container in widget that calls onMount when mounted
class WidgetWrapper extends StatelessWidget {
  const WidgetWrapper({
    super.key,
    required this.child,
    this.onMount,
  });

  final Widget child;
  final Function? onMount;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onMount != null) onMount!();
    });
    return SizedBox(
      child: child,
    );
  }
}

/// A js wrapper for Braintree function callbacks when the first argument is a js error.
/// This wrapper converts the error to a json object that exposes .message and other props.
const braintreeCallbackWrapperScript = '''(() => {
  if (!window.braintree) window.braintree = {};
  window.braintree.callbackWrapper = (callback) => function() {
    const err = arguments[0];
    let errMod = err;
    if (err && typeof err == 'object') {
        errMod = {};
        const errKeys = Object.keys(err);
        for (let i = 0; i < errKeys.length; i += 1) {
          const key = errKeys[i];
          errMod[key] = err[key];
        }
        const errMsg = err.message;
        if (errMsg && ! errMod.message) errMod.message = errMsg;
    }
    const argsMod = [];
    for (let i = 0; i < arguments.length; i += 1) {
      argsMod[i] = arguments[i];
    };
    argsMod[0] = errMod;
    return callback.apply(null, argsMod);
  }
})()''';
