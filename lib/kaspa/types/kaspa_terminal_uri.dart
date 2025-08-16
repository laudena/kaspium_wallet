import 'package:decimal/decimal.dart';

import 'address.dart';
import 'address_prefix.dart';
import 'amount.dart';
import 'kaspa_uri.dart';

/// Utility for parsing kaspaterminal URIs produced by NFC terminals.
///
/// Expected format: `kaspaterminal://address/<kaspa address>/payment/<amount>`.
/// The amount is expressed in KAS (decimal) and will be converted to [Amount].
class KaspaTerminalUri {
  /// Tries to parse [uri] and return a [KaspaUri] with the embedded
  /// address and amount. Returns `null` if the format is invalid.
  static KaspaUri? tryParse(
    String uri, {
    AddressPrefix prefix = AddressPrefix.unknown,
  }) {
    final parsed = Uri.tryParse(uri);
    if (parsed == null || parsed.scheme != 'kaspaterminal') {
      return null;
    }

    final segments = parsed.pathSegments;
    if (segments.length < 4) {
      return null;
    }
    if (segments[0] != 'address' || segments[2] != 'payment') {
      return null;
    }

    final addressStr = Uri.decodeComponent(segments[1]);
    final address = Address.tryParse(addressStr, expectedPrefix: prefix);
    if (address == null) {
      return null;
    }

    Amount? amount;
    final amountStr = Uri.decodeComponent(segments[3]);
    final amountDec = Decimal.tryParse(amountStr);
    if (amountDec != null) {
      amount = Amount.value(amountDec);
    }

    return KaspaUri(address: address, amount: amount);
  }
}

