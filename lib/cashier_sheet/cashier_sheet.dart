import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app_icons.dart';
import '../app_providers.dart';
import '../kaspa/kaspa.dart';
import '../l10n/l10n.dart';
import '../send_sheet/account_address_widget.dart';
import '../themes/kaspium_light_theme.dart';
import '../wallet_address/address_providers.dart';
import '../wallet_balance/wallet_balance_providers.dart';
import '../widgets/app_text_field.dart';
import '../widgets/sheet_handle.dart';

enum AddressStyle { TEXT60, TEXT90, PRIMARY }

class CashierSheet extends ConsumerStatefulWidget {
  final String? title;
  final BigInt? amountRaw;
  final Decimal? amount;
  final String? note;

  const CashierSheet({
    Key? key,
    this.title,
    this.amountRaw,
    this.amount,
    this.note,
  }) : super(key: key);

  _CashierSheetState createState() => _CashierSheetState();
}

class _CashierSheetState extends ConsumerState<CashierSheet> {
  final _amountFocusNode = FocusNode();
  final _amountController = TextEditingController();
  
  // States
  String? _amountHint;
  String _amountValidationText = '';
  late BigInt? amountRaw = widget.amountRaw;
  late Decimal? amount = widget.amount;
  late String? _note = widget.note;

  bool get hasNote => _note != null;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final l10n = l10nOf(context);
    final styles = ref.watch(stylesProvider);
    final kasProvider = ref.watch(kaspaPriceProvider);
    final currency = ref.watch(currencyProvider);
    final receiveAddress = ref.watch(receiveWalletAddressProvider);
    final address = receiveAddress.encoded;
    var kaspaValue = 0.0;
    if (amount != null && kasProvider.price > Decimal.zero)
      kaspaValue = (amount!.shift(8).toDouble() ~/ kasProvider.price.toDouble()).toDouble();
    else
      kaspaValue = 0.toDouble();


    return Card(

      child: Container(

          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 10, height: 10),
                  Column(
                    children: [
                      const SheetHandle(),
                      Container(
                        margin: const EdgeInsets.only(top: 15),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 140,
                        ),
                        child: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                ('Point of Sale').toUpperCase(),
                                style: styles.textStyleHeader(context),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10, height: 10),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(
                  top: 10,
                  left: 10,
                  right: 10,
                  bottom: 4,
                ),
              ),
              // A main container that holds everything
              Expanded(
                child: Stack(
                    children: [
                      // A column for Enter Amount, Enter Address, Error containers and the pop up list
                      SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: max(
                            0,
                            MediaQuery.of(context).viewInsets.bottom - 180,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 5),
                                // ******* Enter Amount Container ******* //
                                getEnterAmountContainer(),
                                // ******* Enter Amount Container End ******* //
                                Text(currency.getDisplayName(context),
                                textAlign: TextAlign.left,
                                  style: styles.textStyleParagraphThinPrimary,
                                ),
                                // ******* Enter Amount Error Container ******* //
                                Container(
                                  alignment: const AlignmentDirectional(0, 0),
                                  margin: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    _amountValidationText,
                                    style: styles.textStyleParagraphThinPrimary,
                                  ),
                                ),
                                // ******* Enter Amount Error Container End ******* //
                                // ******* Kaspa calculated amount ******* //
                                Column(
                                  children:[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/kaspa_transparent_180.png',
                                          width: 18,
                                          color: theme is KaspiumLightTheme
                                              ? theme.primary
                                              : null,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          (kaspaValue/(100000000.0).toDouble()).toStringAsFixed(2),
                                          textAlign: TextAlign.end,
                                          style: styles.textStyleDialogHeader,
                                        ),
                                      ],
                                    )
                                  ]),
                                // ******* Kaspa calculated amount End******* //
                                  Padding(
                                      padding: const EdgeInsets.only(
                                        top: 5,
                                        bottom: 5,
                                        left: 20,
                                        right: 20,
                                      ),
                                      child: Center(
                                        child: Stack(
                                          children: [
                                            Center(
                                              child: Container(
                                                width: 260,
                                                height: 150,
                                                color: theme.backgroundDark,
                                              ),
                                            ),
                                            Center(
                                              child: Container(
                                                constraints: BoxConstraints(maxWidth: 280),
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10),
                                                  shape: BoxShape.rectangle,
                                                  border: Border.all(color: theme.primary, width: 2),
                                                ),
                                                child: QrImageView(
                                                    data: ('$address') + ';' + kaspaValue.toStringAsFixed(0) + ';' + 'a1003',
                                                    version: QrVersions.auto,
                                                    errorCorrectionLevel: QrErrorCorrectLevel.Q,
                                                    gapless: false,
                                                    embeddedImage: AssetImage('assets/qr_code_icon.png'),
                                                    embeddedImageStyle: QrEmbeddedImageStyle(
                                                      size: const Size(40, 40),
                                                    ),
                                                    backgroundColor: Colors.white,
                                                    semanticsLabel: 'QR code for address $address',
                                                ),
                                              ),
                                            ),
                                          ],
                                      ),
                                    ),
                                  ),
                                  const SheetHandle(),
                                  const AccountAddressWidget(),
                                  const SizedBox(width: 60, height: 60),

                              ],
                            ),
                            // Column for Enter Address container + Enter Address Error container
                              ],
                            ),
                      )
                    ]
                  )
                )
            ])
      )
    );
  }

  Widget getEnterAmountContainer() {
    return Consumer(builder: (context, ref, _) {
      final theme = ref.watch(themeProvider);
      final styles = ref.watch(stylesProvider);
      final l10n = l10nOf(context);

      final formatter = ref.watch(kaspaFormatterProvider);
      final maxSend = ref.watch(maxSendProvider);
      final isMaxSend = amountRaw == maxSend;

      void onValueChanged(String text) {
        final value = formatter.tryParse(text);
        if (value == null) {
          amountRaw = null;
          return;
        }

        amountRaw = Amount
            .value(value)
            .raw;
        amount = Amount
            .value(value)
            .value;
        // Always reset the error message to be less annoying
        setState(() => _amountValidationText = '');
      }
      final currency = ref.watch(currencyProvider);
      return AppTextField(
        focusNode: _amountFocusNode,
        controller: _amountController,
        topMargin: 0,
        cursorColor: theme.primary,
        style: styles.textStyleHeader2Colored,
        inputFormatters: [formatter],
        onChanged: onValueChanged,
        textInputAction: TextInputAction.done,
        maxLines: null,
        autocorrect: false,
        hintText: _amountHint ?? l10n.enterAmount,
        prefixButton: TextFieldButton(
          icon: AppIcons.swapcurrency,
          widget: AutoSizeText(
            currency.getCurrencySymbol(),
            style: styles.textStyleHeaderColored,
            stepGranularity: 0.1,
            maxLines: 1,
            minFontSize: 8,
          ),
          onPressed: () {},
        ),
        fadeSuffixOnCondition: true,
        suffixShowFirstCondition: !isMaxSend,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
      );
    });
  }
}
