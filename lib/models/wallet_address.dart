final _addressPattern = RegExp(r'^0x[0-9a-fA-F]{40}$');

/// Extracts an Ethereum wallet address from a scanned QR code value.
///
/// Accepts a plain address or an EIP-681 payment URI such as
/// `ethereum:0xabc...@137?value=1`. Returns the address lowercased, which is
/// how the backend matches incoming donations, or null if [raw] does not
/// contain a valid address.
String? parseWalletAddress(String? raw) {
  if (raw == null) {
    return null;
  }
  var address = raw.trim();
  if (address.toLowerCase().startsWith('ethereum:')) {
    address = address.substring('ethereum:'.length);
    // strip the EIP-681 "pay-" prefix, chain id and query parameters.
    if (address.startsWith('pay-')) {
      address = address.substring('pay-'.length);
    }
    address = address.split(RegExp(r'[@/?]')).first;
  }
  if (!_addressPattern.hasMatch(address)) {
    return null;
  }
  return address.toLowerCase();
}
