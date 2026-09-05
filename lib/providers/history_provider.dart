import 'package:flutter/foundation.dart';

import '../models/history_model.dart';
import '../services/api_service.dart';

class HistoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<InspectionHistory> _allHistory = [];
  List<InspectionHistory> _filtered = [];

  bool _isLoading = false;
  String _searchQuery = '';

  List<InspectionHistory> get history =>
      List.unmodifiable(_filtered);

  bool get isLoading => _isLoading;

  String get searchQuery => _searchQuery;

  // ============================================================
  // SAFE STRING
  // ============================================================

  String _safeString(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is String) {
      return value;
    }

    try {
      return value.toString();
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // LOAD HISTORY
  // ============================================================

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result =
      await _apiService.getInspectionHistory();

      // Defensive copy
      _allHistory =
      List<InspectionHistory>.from(result);

      // Default date sorting
      _sortByDateDescending();

      _applyFilter();
    } catch (e) {
      debugPrint(
        'HistoryProvider.loadHistory ERROR: $e',
      );

      _allHistory = [];
      _filtered = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // DEFAULT DATE SORT
  // ============================================================

  void _sortByDateDescending() {
    _allHistory.sort(
          (InspectionHistory a, InspectionHistory b) {
        final String dateA =
        _safeString(a.inspectionDate).trim();

        final String dateB =
        _safeString(b.inspectionDate).trim();

        if (dateA.isEmpty && dateB.isEmpty) {
          return 0;
        }

        if (dateA.isEmpty) {
          return 1;
        }

        if (dateB.isEmpty) {
          return -1;
        }

        final int result =
        dateB.compareTo(dateA);

        if (result < 0) {
          return -1;
        }

        if (result > 0) {
          return 1;
        }

        return 0;
      },
    );
  }

  // ============================================================
  // RESET
  // ============================================================

  void resetState() {
    _searchQuery = '';

    _filtered = [];

    _allHistory = [];

    notifyListeners();
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void search(String query) {
    _searchQuery = _safeString(query);

    _applyFilter();

    notifyListeners();
  }

  // ============================================================
  // FILTER
  // ============================================================

  void _applyFilter() {
    final String q =
    _safeString(_searchQuery).trim().toLowerCase();

    if (q.isEmpty) {
      _filtered =
      List<InspectionHistory>.from(
        _allHistory,
      );

      return;
    }

    _filtered = _allHistory.where(
          (InspectionHistory h) {
        return _contains(
          h.containerNumber,
          q,
        ) ||
            _contains(
              h.invoiceNo,
              q,
            ) ||
            _contains(
              h.shippingLine,
              q,
            ) ||
            _contains(
              h.truckNo,
              q,
            ) ||
            _contains(
              h.trucktype,
              q,
            ) ||
            _contains(
              h.overallDecision,
              q,
            ) ||
            _contains(
              h.checkedBy,
              q,
            ) ||
            _contains(
              h.inspectionDate,
              q,
            ) ||
            _contains(
              h.status,
              q,
            );
      },
    ).toList();
  }

  // ============================================================
  // SAFE CONTAINS
  // ============================================================

  bool _contains(
      dynamic value,
      String query,
      ) {
    return _safeString(value)
        .trim()
        .toLowerCase()
        .contains(query);
  }
}