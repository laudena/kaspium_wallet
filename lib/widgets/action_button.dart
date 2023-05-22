import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core_providers.dart';
import '../kaspa/types/address.dart';
import '../kaspa/types/address_prefix.dart';
import '../l10n/l10n.dart';
import '../receive/receive_sheet.dart';
import '../send_sheet/send_sheet.dart';
import '../util/ui_util.dart';
import '../util/user_data_util.dart';
import 'sheet_util.dart';

class ActionButton extends ConsumerWidget {
  final String title;
  final VoidCallback? onPressed;

  const ActionButton({
    Key? key,
    required this.title,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final styles = ref.watch(stylesProvider);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        boxShadow: [theme.boxShadowButton],
      ),
      height: 55,
      child: TextButton(
        style: styles.primaryButtonStyle,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: styles.textStyleButtonPrimary,
            maxLines: 1,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class ReceiveActionButton extends ConsumerWidget {
  final VoidCallback? onPressed;

  const ReceiveActionButton({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final l10n = l10nOf(context);

    return ActionButton(
      title: l10n.receive,
      onPressed: () {
        onPressed?.call();
        Sheets.showAppHeightEightSheet(
          context: context,
          widget: const ReceiveSheet(),
          theme: theme,
        );
      },
    );
  }
}

class SendActionButton extends ConsumerWidget {
  final VoidCallback? onPressed;

  const SendActionButton({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final l10n = l10nOf(context);

    return ActionButton(
      title: l10n.send,
      onPressed: () {
        onPressed?.call();
        Sheets.showAppHeightNineSheet(
          context: context,
          widget: const SendSheet(),
          theme: theme,
        );
      },
    );
  }
}


class PayActionButton extends ConsumerWidget {
  final VoidCallback? onPressed;

  const PayActionButton({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final styles = ref.watch(stylesProvider);
    final l10n = l10nOf(context);

    void handleQrCodeError() {
      UIUtil.showSnackbar(l10n.scanQrCodeError, context);
    }
    void handleAddressData(String data, AddressPrefix prefix) {
      final address = Address.tryParse(data, expectedPrefix: prefix);

      if (address == null) {
        handleQrCodeError();
        return;
      }

      Sheets.showAppHeightNineSheet(
        context: context,
        theme: theme,
        widget: SendSheet(address: address.encoded),
      );
    }

    void handleMultipartData(List<String> parts, AddressPrefix prefix) {
      final addressPart = Address.tryParse(parts[0], expectedPrefix: prefix);
      if (addressPart == null) {
        handleQrCodeError();
        return;
      }

      var amountPart = BigInt.tryParse(parts[1]);
      if (amountPart == null) {
        handleQrCodeError();
        return;
      }

      amountPart = BigInt.parse((amountPart ~/ BigInt.from(1000000) * BigInt.from(1000000)).toString());
      final amount = amountPart;
      final notePart = parts[2];

      Sheets.showAppHeightNineSheet(
        context: context,
        theme: theme,
        widget: SendSheet(address: addressPart.encoded, amountRaw: amount, note: notePart),
      );
    }

    Future<void> scanQrCode() async {
      final qrCode = await UserDataUtil.scanQrCode(context);
      final data = qrCode?.code;
      if (data == null) {
        return;
      }

      final prefix = ref.read(addressPrefixProvider);
      final parts = data.split(';');

      if (parts.length <= 1) {
        handleAddressData(data, prefix);
      } else {
        handleMultipartData(parts, prefix);
      }
    }

    return TextButton(
        style: styles.primaryButtonStyle,
        child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(

                children: [
                  Text(
                    'Pay',
                    textAlign: TextAlign.center,
                    style: styles.textStyleButtonPrimary,
                    maxLines: 1,
                  ),
                  Icon(
                    Icons.mobile_friendly,
                    size: 40,
                  )]
            )
        ),
        onPressed: scanQrCode
    );
  }
}
