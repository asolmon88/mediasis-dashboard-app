import 'dart:convert';

import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterStorageService {
  static const _printersKey = 'receipt_printers_v1';
  static const _jobsKey = 'receipt_print_jobs_v1';
  static const _orderBaselineKey = 'receipt_print_order_baseline_v1';

  Future<List<PrinterConfiguration>> readPrinters(String locationId) async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeList(prefs.getString(_printersKey))
        .map(PrinterConfiguration.fromMap)
        .where((printer) => printer.businessLocationId == locationId)
        .toList();
  }

  Future<void> savePrinter(PrinterConfiguration printer) async {
    final all = await _readAllPrinters();
    final index = all.indexWhere((item) => item.id == printer.id);
    if (index < 0) {
      all.add(printer);
    } else {
      all[index] = printer;
    }
    await _savePrinters(all);
  }

  Future<void> deletePrinter(String printerId) async {
    final all = await _readAllPrinters();
    all.removeWhere((printer) => printer.id == printerId);
    await _savePrinters(all);
  }

  Future<List<PrintJob>> readJobs(String locationId) async {
    final prefs = await SharedPreferences.getInstance();
    final jobs = _decodeList(prefs.getString(_jobsKey))
        .map(PrintJob.fromMap)
        .where((job) => job.businessLocationId == locationId)
        .map(
          (job) => job.status == PrintJobStatus.printing
              ? job.copyWith(
                  status: PrintJobStatus.failed,
                  error: 'La impresion fue interrumpida.',
                )
              : job,
        )
        .toList();
    await _replaceLocationJobs(locationId, jobs);
    return jobs;
  }

  Future<void> saveJob(PrintJob job) async {
    final all = await _readAllJobs();
    final index = all.indexWhere((item) => item.id == job.id);
    if (index < 0) {
      all.add(job);
    } else {
      all[index] = job;
    }
    all.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
    final bounded = all.take(250).map((item) => item.toMap()).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_jobsKey, jsonEncode(bounded));
  }

  Future<Set<String>> readOrderBaseline(String locationId) async {
    final prefs = await SharedPreferences.getInstance();
    final decoded = _decodeObject(prefs.getString(_orderBaselineKey));
    return (decoded[locationId] as List<dynamic>? ?? const [])
        .map((value) => '$value')
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  Future<void> saveOrderBaseline(
    String locationId,
    Iterable<String> orderIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final decoded = _decodeObject(prefs.getString(_orderBaselineKey));
    decoded[locationId] = orderIds.toSet().toList();
    await prefs.setString(_orderBaselineKey, jsonEncode(decoded));
  }

  Future<List<PrinterConfiguration>> _readAllPrinters() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeList(
      prefs.getString(_printersKey),
    ).map(PrinterConfiguration.fromMap).toList();
  }

  Future<List<PrintJob>> _readAllJobs() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeList(
      prefs.getString(_jobsKey),
    ).map(PrintJob.fromMap).toList();
  }

  Future<void> _savePrinters(List<PrinterConfiguration> printers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _printersKey,
      jsonEncode(printers.map((printer) => printer.toMap()).toList()),
    );
  }

  Future<void> _replaceLocationJobs(
    String locationId,
    List<PrintJob> jobs,
  ) async {
    final all = await _readAllJobs();
    all.removeWhere((job) => job.businessLocationId == locationId);
    all.addAll(jobs);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _jobsKey,
      jsonEncode(all.map((job) => job.toMap()).toList()),
    );
  }

  List<Map<String, dynamic>> _decodeList(String? value) {
    if (value == null || value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      return decoded is List
          ? decoded
                .whereType<Map>()
                .map((item) => item.cast<String, dynamic>())
                .toList()
          : const [];
    } catch (_) {
      return const [];
    }
  }

  Map<String, dynamic> _decodeObject(String? value) {
    if (value == null || value.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(value);
      return decoded is Map
          ? decoded.cast<String, dynamic>()
          : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
