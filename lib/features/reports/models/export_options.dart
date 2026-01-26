enum ExportFormat {
  csv,
  pdf,
}

class ExportOptions {
  final ExportFormat format;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool includeItems;
  final bool includeCategories;
  final bool includeSplits;

  ExportOptions({
    this.format = ExportFormat.csv,
    this.startDate,
    this.endDate,
    this.includeItems = true,
    this.includeCategories = true,
    this.includeSplits = true,
  });

  ExportOptions copyWith({
    ExportFormat? format,
    DateTime? startDate,
    DateTime? endDate,
    bool? includeItems,
    bool? includeCategories,
    bool? includeSplits,
  }) {
    return ExportOptions(
      format: format ?? this.format,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      includeItems: includeItems ?? this.includeItems,
      includeCategories: includeCategories ?? this.includeCategories,
      includeSplits: includeSplits ?? this.includeSplits,
    );
  }
}

