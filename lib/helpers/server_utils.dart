import 'dart:io';

Future<String?> getLocalIpAddress() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );

  for (var interface in interfaces) {
    for (var addr in interface.addresses) {
      if (!addr.isLoopback) {
        return addr.address;
      }
    }
  }

  return null;
}
