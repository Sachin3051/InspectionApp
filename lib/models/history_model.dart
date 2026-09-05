class InspectionHistory {
  final String id;
  final String createdBy;
  final String containerNumber;
  final String invoiceNo;
  final String shippingLine;
  final String truckNo;
  final String trucktype;
  final String overallDecision;
  final String checkedBy;
  final String inspectionDate;
  final String status;
  final String inspectionStage;

  const InspectionHistory({
    required this.id,
    required this.createdBy,
    required this.containerNumber,
    required this.invoiceNo,
    required this.shippingLine,
    required this.truckNo,
    required this.trucktype,
    required this.overallDecision,
    required this.checkedBy,
    required this.inspectionDate,
    required this.status,
    this.inspectionStage = 'EMP', // 🟢 Default fallback 'EMP' diya taaki null na rahe
  });

  static String _safeValue(Map<String, dynamic> json, String key) {
    try {
      final dynamic value = json[key];
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    } catch (_) {
      return '';
    }
  }

  factory InspectionHistory.fromJson(Map<String, dynamic> json) {
    final String stage = _safeValue(json, 'inspectionStage');

    return InspectionHistory(
      id: _safeValue(json, 'entryId'),
      createdBy: _safeValue(json, 'createdBy'),
      containerNumber: _safeValue(json, 'containerNo'),
      invoiceNo: _safeValue(json, 'invoiceNo'),
      shippingLine: _safeValue(json, 'shippingLine'),
      truckNo: _safeValue(json, 'truckNo'),
      trucktype: _safeValue(json, 'trucktype'),
      overallDecision: _safeValue(json, 'overallDecision'),
      checkedBy: _safeValue(json, 'checkedBy'),
      inspectionDate: _safeValue(json, 'inspectionDate'),
      status: _safeValue(json, 'status'),
      inspectionStage: stage.trim().isEmpty ? 'EMP' : stage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entryId': id,
      'createdBy': createdBy,
      'containerNo': containerNumber,
      'invoiceNo': invoiceNo,
      'shippingLine': shippingLine,
      'truckNo': truckNo,
      'trucktype': trucktype,
      'overallDecision': overallDecision,
      'checkedBy': checkedBy,
      'inspectionDate': inspectionDate,
      'status': status,
      'inspectionStage': inspectionStage,
    };
  }
}