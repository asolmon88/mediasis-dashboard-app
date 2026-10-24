import 'dart:async';
import 'dart:io';

import 'package:mediasis_dashboard_app/infrastructure/models.dart';

class PrinterTransport {
  Future<void> printBytes(PrinterConfiguration printer, List<int> bytes) async {
    final host = printer.host.trim().toLowerCase();
    if (host == '0.0.0.0' || host == '::' || host == '[::]' || host == '::0') {
      throw const PrinterConnectionException(
        '0.0.0.0 es una direccion de escucha, no la direccion de la impresora. Usa la direccion IPv4 del equipo donde esta ejecutandose la impresora, por ejemplo 192.168.x.x.',
      );
    }
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isWindows) {
      throw const PrinterConnectionException(
        'La impresion por IP no esta disponible en esta plataforma.',
      );
    }
    Socket? socket;
    try {
      socket = await Socket.connect(
        host,
        printer.port,
        timeout: const Duration(seconds: 5),
      );
      socket.add(bytes);
      await socket.flush().timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw const PrinterConnectionException(
        'La impresora no respondio. Revisa que ambos dispositivos esten en la misma red y que el firewall permita conexiones TCP entrantes al puerto configurado.',
      );
    } on SocketException catch (error) {
      throw PrinterConnectionException(_messageFor(error, printer.port));
    } finally {
      await socket?.close();
    }
  }

  String _messageFor(SocketException error, int port) {
    final message = '${error.message} ${error.osError?.message ?? ''}'
        .toLowerCase();
    final code = error.osError?.errorCode;
    if (message.contains('timed out') ||
        message.contains('timeout') ||
        code == 60 ||
        code == 110 ||
        code == 10060) {
      return 'La impresora no respondio. Confirma que este encendida, conectada a la misma red y que el puerto TCP $port permita conexiones entrantes.';
    }
    if (message.contains('refused') ||
        code == 61 ||
        code == 111 ||
        code == 10061) {
      return 'El dispositivo respondio, pero no hay una impresora disponible en el puerto $port. Confirma la direccion IP y el puerto configurado.';
    }
    if (message.contains('unreachable') ||
        code == 51 ||
        code == 65 ||
        code == 101 ||
        code == 10051) {
      return 'No hay una ruta de red hacia esa direccion. Confirma la IP y que ambos dispositivos esten conectados a la misma red Wi-Fi sin aislamiento de clientes.';
    }
    if (message.contains('not permitted') ||
        message.contains('permission') ||
        code == 1 ||
        code == 13) {
      return 'El sistema bloqueo el acceso a la red local. Activa Red local para Mediasis desde los ajustes del dispositivo e intenta nuevamente.';
    }
    return 'No se pudo conectar con la impresora. Confirma la direccion IP, el puerto $port y las reglas del firewall de la red.';
  }
}
