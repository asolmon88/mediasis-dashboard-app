import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:mediasis_dashboard_app/infrastructure/models.dart';

class PrinterDiscoveryService {
  bool get isSupported =>
      Platform.isAndroid || Platform.isIOS || Platform.isWindows;

  Future<List<DiscoveredPrinter>> discover({bool scanSubnet = false}) async {
    if (!isSupported) return const [];
    final found = <String, DiscoveredPrinter>{};
    for (final type in const ['_pdl-datastream._tcp', '_printer._tcp']) {
      await _discoverType(type, found);
    }
    if (scanSubnet) await _scanSubnet(found);
    return found.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> _discoverType(
    String type,
    Map<String, DiscoveredPrinter> found,
  ) async {
    final discovery = BonsoirDiscovery(type: type, printLogs: false);
    StreamSubscription<BonsoirDiscoveryEvent>? subscription;
    try {
      await discovery.initialize();
      subscription = discovery.eventStream?.listen((event) {
        if (event is BonsoirDiscoveryServiceFoundEvent) {
          event.service.resolve(discovery.serviceResolver);
        } else if (event is BonsoirDiscoveryServiceResolvedEvent ||
            event is BonsoirDiscoveryServiceUpdatedEvent) {
          final service = event.service;
          if (service == null) return;
          final host = service.hostAddresses.firstOrNull ?? service.hostname;
          if (host == null || host.isEmpty) return;
          found['$host:${service.port}'] = DiscoveredPrinter(
            name: service.name,
            host: host,
            port: service.port == 0 ? 9100 : service.port,
            source: 'Bonjour',
          );
        }
      });
      await discovery.start();
      await Future<void>.delayed(const Duration(seconds: 4));
    } catch (_) {
      // Manual entry and subnet scan remain available when mDNS is blocked.
    } finally {
      await discovery.stop().catchError((_) {});
      await subscription?.cancel();
    }
  }

  Future<void> _scanSubnet(Map<String, DiscoveredPrinter> found) async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    final local = interfaces
        .expand((item) => item.addresses)
        .where((address) => _isPrivateIpv4(address.address))
        .firstOrNull;
    if (local == null) return;
    final pieces = local.address.split('.');
    if (pieces.length != 4) return;
    final prefix = '${pieces[0]}.${pieces[1]}.${pieces[2]}';
    for (var start = 1; start < 255; start += 24) {
      await Future.wait(
        List.generate(
          24,
          (offset) => start + offset,
        ).where((last) => last < 255).map((last) async {
          final host = '$prefix.$last';
          if (host == local.address) return;
          Socket? socket;
          try {
            socket = await Socket.connect(
              host,
              9100,
              timeout: const Duration(milliseconds: 220),
            );
            found['$host:9100'] = DiscoveredPrinter(
              name: 'Impresora $host',
              host: host,
              port: 9100,
              source: 'Red local',
            );
          } catch (_) {
            // Closed ports are expected while scanning.
          } finally {
            await socket?.close();
          }
        }),
      );
    }
  }

  bool _isPrivateIpv4(String value) =>
      value.startsWith('10.') ||
      value.startsWith('192.168.') ||
      RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(value);
}
