import 'package:flutter/material.dart';
import 'package:braintree_web/braintree_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Braintree/Paypal Payment Integration Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Braintree Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _btAuthorization;
  String? _currentBtAuthValue;
  BraintreePlugin? braintreePlugin;
  Widget? ccForm;
  String? ccRequestMessage;
  Widget? ppButtonContainer;
  bool initialized = false;

  void onAuthTokenChanged(String value) {
    _currentBtAuthValue = value;
  }

  Future<void> initializeBraintree() async {
    _btAuthorization = _currentBtAuthValue;
    braintreePlugin = BraintreePlugin();
    await Future.wait([
      initializeCreditCardForm(),
      initializePaypal(),
    ]);
    setState(() {
      initialized = true;
    });
  }

  void onCCSubmitPressed() {
    braintreePlugin?.requestPaymentMethod((err, [payload]) async {
      if (err != null) {
        final errorText = [
          'HOSTED_FIELDS_FIELDS_EMPTY',
          'HOSTED_FIELDS_FIELDS_INVALID'
        ].contains(err.code)
            ? 'Missing or invalid fields'
            : 'Unknown error processing payment';
        setState(() {
          ccRequestMessage = errorText;
        });
        return;
      }
      final String nonce = payload?.nonce ?? '';
      if (nonce.isEmpty) {
        setState(() {
          ccRequestMessage = 'Unknown error processing payment';
        });
        return;
      }

      setState(() {
        // Send nonce to server
        ccRequestMessage = 'Card accepted';
      });
    });
  }

  Future<void> initializeCreditCardForm() async {
    final Map<String, String> fieldContainerStyles = {
      'font-size': '18px',
      'background-color': 'rgba(210, 210, 210, 0.5)',
      'border-color': 'rgba(0, 0, 0, 0.1)',
      'margin': '0.5em',
    };
    final Map<String, String> focusedFieldContainerStyles = {
      'border-color': 'rgba(0, 126, 255, 1)',
    };
    final Map<String, String> errorFieldContainerStyles = {
      'background-color': 'rgba(255, 193, 193, 0.5)',
    };
    final Map<String, String> focusedErrorFieldContainerStyles = {
      'border-color': 'rgba(255, 0, 0, 1)',
    };
    final Map<String, String> labelStyles = {
      'font-size': '12px',
      'color': 'rgba(0, 0, 0, 0.5)',
    };
    // final Map<String, String> inputStyles = {
    //   'font-size': '18px',
    //   'color': 'rgba(0, 0, 0, 0.85)',
    // };
    // final Map<String, String> errorInputStyles = {
    //   'color': 'rgba(255, 93, 93, 1)',
    // };

    final inputStyles = {
      'input': {'font-size': '18px', 'color': 'rgba(0, 0, 0, 0.85)'},
      'input.invalid': {'color': 'rgba(255, 93, 93, 1)'},
    };
    void onInitError(dynamic err) {
      debugPrint('Error initializing credit card fields: ${err.message}');
    }

    ccForm = await braintreePlugin!.createCreditCardForm(
      postalCode: true,
      fieldContainerStyles: fieldContainerStyles,
      focusedFieldContainerStyles: focusedFieldContainerStyles,
      errorFieldContainerStyles: errorFieldContainerStyles,
      focusedErrorFieldContainerStyles: focusedErrorFieldContainerStyles,
      labelStyles: labelStyles,
        onMount: () {
          braintreePlugin!.initializeHostedFields(
              authorization: _btAuthorization!,
              inputStyles: inputStyles,
              onInitError: onInitError);
        });
  }

  Future<void> initializePaypal() async {
    final Map<String, dynamic> paypalSdkOptions = {'vault': true};
    final Map<String, dynamic> paymentOptions = {
      'flow': 'vault', // Required

      // The following are optional params
      'enableShippingAddress': true,
      // 'billingAgreementDescription': 'Your agreement description',
      // 'shippingAddressEditable': false,
      // 'shippingAddressOverride': {
      //   'recipientName': 'Scruff McGruff',
      //   'line1': '1234 Main St.',
      //   'line2': 'Unit 1',
      //   'city': 'Chicago',
      //   'countryCode': 'US',
      //   'postalCode': '60652',
      //   'state': 'IL',
      //   'phone': '123.456.7890'
      // }
    };
    final Map<String, dynamic> buttonStyle = {
      'color': 'blue',
      'size': 'responsive',
      'shape': 'rect',
      'height': 48,
      'label': 'pay',
      'tagline': false,
    };
    void onPaymentRequest(dynamic err, [dynamic payload]) async {
      if (err != null) {
        debugPrint('Error requesting paypal payment: ${err.message}');
        return;
      }
      final String nonce = payload?.nonce ?? '';
      if (nonce.isEmpty) {
        debugPrint('Error requesting paypal payment: no nonce value returned');
        return;
      }

      // Send nonce to server
      debugPrint('PayPal request accepted');
    }

    void onInitError(dynamic err) {
      debugPrint('Error initializing paypal: ${err.message}');
    }

    ppButtonContainer =
        await braintreePlugin!.createPaypalButtonContainer(onMount: () {
      braintreePlugin!.initializePaypal(
        authorization: _btAuthorization!,
        paypalSdkOptions: paypalSdkOptions,
        paymentOptions: paymentOptions,
        buttonStyle: buttonStyle,
        onPaymentRequest: onPaymentRequest,
        onInitError: onInitError,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              const Text(
                'Enter your Braintree auth token to initialize payment options:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // const Text('Braintree authorization:'),
                  // const SizedBox(width: 24),
                  SizedBox(
                    width: 350,
                    child: TextFormField(
                      textInputAction: TextInputAction.go,
                      onChanged: onAuthTokenChanged,
                      autofocus: true,
                      maxLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'sandbox_token',
                        filled: true,
                        fillColor: Color.fromRGBO(210, 210, 210, 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  ElevatedButton(
                    onPressed: initializeBraintree,
                    child: const Text('Load'),
                  ),
                ],
              ),
              const SizedBox(height: 64),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: !initialized
                    ? []
                    : [
                        SizedBox(
                          width: 400,
                          height: 250,
                          child: ccForm!,
                        ),
                        const SizedBox(height: 8),
                        Text(ccRequestMessage ?? ''),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: onCCSubmitPressed,
                          child: const Text('Submit'),
                        ),
                        const SizedBox(height: 36),
                        const Text('OR'),
                        const SizedBox(height: 36),
                        SizedBox(
                          width: 400,
                          height: 100,
                          child: Padding(
                            padding: const EdgeInsets.all(9.0),
                            child: ppButtonContainer!,
                          ),
                        ),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
