part of 'printing_cubit.dart';

enum PrintingStatus { initial, loading, ready, discovering, printing, failure }

class PrintingState extends Equatable {
  const PrintingState({
    this.status = PrintingStatus.initial,
    this.businessLocationId = '',
    this.printers = const [],
    this.discoveredPrinters = const [],
    this.jobs = const [],
    this.transientMessage = '',
    this.printingProgress,
    this.printingSecondsRemaining,
    this.printingLabel = '',
  });

  final PrintingStatus status;
  final String businessLocationId;
  final List<PrinterConfiguration> printers;
  final List<DiscoveredPrinter> discoveredPrinters;
  final List<PrintJob> jobs;
  final String transientMessage;
  final double? printingProgress;
  final int? printingSecondsRemaining;
  final String printingLabel;

  List<PrintJob> get failedJobs => jobs
      .where((job) => job.status == PrintJobStatus.failed)
      .toList(growable: false);
  int get automaticPrinterCount =>
      printers.where((printer) => printer.automaticPrinting).length;
  PrintJob? get lastAutomaticJob =>
      jobs.where((job) => job.trigger == PrintJobTrigger.automatic).firstOrNull;

  PrintingState copyWith({
    PrintingStatus? status,
    String? businessLocationId,
    List<PrinterConfiguration>? printers,
    List<DiscoveredPrinter>? discoveredPrinters,
    List<PrintJob>? jobs,
    String? transientMessage,
    bool clearTransientMessage = false,
    double? printingProgress,
    int? printingSecondsRemaining,
    String? printingLabel,
    bool clearPrintingProgress = false,
  }) => PrintingState(
    status: status ?? this.status,
    businessLocationId: businessLocationId ?? this.businessLocationId,
    printers: printers ?? this.printers,
    discoveredPrinters: discoveredPrinters ?? this.discoveredPrinters,
    jobs: jobs ?? this.jobs,
    transientMessage: clearTransientMessage
        ? ''
        : transientMessage ?? this.transientMessage,
    printingProgress: clearPrintingProgress
        ? null
        : printingProgress ?? this.printingProgress,
    printingSecondsRemaining: clearPrintingProgress
        ? null
        : printingSecondsRemaining ?? this.printingSecondsRemaining,
    printingLabel: clearPrintingProgress
        ? ''
        : printingLabel ?? this.printingLabel,
  );

  @override
  List<Object?> get props => [
    status,
    businessLocationId,
    printers,
    discoveredPrinters,
    jobs,
    transientMessage,
    printingProgress,
    printingSecondsRemaining,
    printingLabel,
  ];
}
