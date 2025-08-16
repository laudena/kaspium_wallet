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
    final parsed = Uri.tryParse(uri.trim());
    if (parsed == null || parsed.scheme != 'kaspaterminal') {
      return null;
    }

    // Support both forms:
    // 1) kaspaterminal://address/<kaspa address>/payment/<amount>
    //    -> host == 'address', pathSegments: [<address>, 'payment', <amount>]
    // 2) kaspaterminal:/address/<kaspa address>/payment/<amount>
    //    -> host empty, pathSegments: ['address', <address>, 'payment', <amount>]
    late final List<String> segs;
    late final int addrIdx;
    late final int paymentIdx;
    late final int amountIdx;

    if ((parsed.host == 'address') && parsed.pathSegments.length >= 3) {
      segs = parsed.pathSegments;
      addrIdx = 0;
      paymentIdx = 1;
      amountIdx = 2;
    } else if (parsed.pathSegments.length >= 4 &&
        parsed.pathSegments[0] == 'address' &&
        parsed.pathSegments[2] == 'payment') {
      segs = parsed.pathSegments;
      addrIdx = 1;
      paymentIdx = 2;
      amountIdx = 3;
    } else {
      return null;
    }

    final addressStr = Uri.decodeComponent(segs[addrIdx]);
    final address = Address.tryParse(addressStr, expectedPrefix: prefix);
    if (address == null) {
      return null;
    }

    Amount? amount;
    // Amount is optional; accept missing or malformed as null.
    if (segs.length > amountIdx && segs[paymentIdx] == 'payment') {
      final amountStr = Uri.decodeComponent(segs[amountIdx]);
      final amountDec = Decimal.tryParse(amountStr);
      if (amountDec != null) {
        amount = Amount.value(amountDec);
      }
    }

    return KaspaUri(address: address, amount: amount);
  }
}
