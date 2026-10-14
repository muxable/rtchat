import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/wallet_address.dart';

const address = '0x52908400098527886E0F7030069857D2E4169EE7';

void main() {
  test('plain addresses are lowercased', () {
    expect(parseWalletAddress(address), address.toLowerCase());
    expect(parseWalletAddress('  $address\n'), address.toLowerCase());
  });

  test('EIP-681 payment URIs are unwrapped', () {
    expect(parseWalletAddress('ethereum:$address'), address.toLowerCase());
    expect(parseWalletAddress('ethereum:$address@137'), address.toLowerCase());
    expect(parseWalletAddress('ethereum:pay-$address@1?value=1e18'),
        address.toLowerCase());
    expect(parseWalletAddress('ethereum:$address/transfer?address=0x0'),
        address.toLowerCase());
  });

  test('invalid values are rejected', () {
    expect(parseWalletAddress(null), isNull);
    expect(parseWalletAddress(''), isNull);
    expect(parseWalletAddress('https://rtirl.com'), isNull);
    expect(parseWalletAddress('0x1234'), isNull);
    expect(parseWalletAddress('[48, 120, 53, 50]'), isNull);
    expect(parseWalletAddress('bitcoin:$address'), isNull);
  });
}
