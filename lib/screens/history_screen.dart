import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';
import '../models/history_model.dart';
import '../providers/auth_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/common_app_bar.dart';
import 'form_screen.dart';
import '../widgets/history_card.dart';
import 'report_preview_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 🟢 Stage tab filter options: "ALL", "EMP", "CFS"
  String _selectedStageTab = 'ALL';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final provider = context.read<HistoryProvider>();
      provider.resetState();
      provider.loadHistory();
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    try {
      return value.toString();
    } catch (_) {
      return '';
    }
  }

  Future<void> _navigateToForm({
    String? entryId,
    bool readOnly = false,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormScreen(
          entryId: entryId,
          readOnly: readOnly,
        ),
      ),
    );

    if (result == true && mounted) {
      await context.read<HistoryProvider>().loadHistory();
    }
  }

  void _navigateToReport(String entryId) {
    if (entryId.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewScreen(
          entryId: entryId,
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    final String raw = _safeString(value).trim();
    if (raw.isEmpty) return '';

    try {
      final String dateOnly = raw.contains('T') ? raw.split('T').first : raw;
      final List<String> parts = dateOnly.split('-');

      if (parts.length == 3) {
        final String year = parts[0];
        final String month = parts[1];
        final String day = parts[2];

        if (year.length >= 2) {
          return '$day/$month/${year.substring(2)}';
        }
        return '$day/$month/$year';
      }
      return raw;
    } catch (_) {
      return raw;
    }
  }

  bool _matchesSearch(InspectionHistory item) {
    final String query = _safeString(_searchQuery).trim().toLowerCase();
    if (query.isEmpty) return true;

    bool contains(dynamic value) {
      return _safeString(value).trim().toLowerCase().contains(query);
    }

    return contains(item.containerNumber) ||
        contains(item.invoiceNo) ||
        contains(item.shippingLine) ||
        contains(item.truckNo) ||
        contains(item.trucktype) ||
        contains(item.overallDecision) ||
        contains(item.checkedBy) ||
        contains(_formatDate(item.inspectionDate)) ||
        contains(item.status);
  }

  List<InspectionHistory> _getFilteredItems(
      List<InspectionHistory> items,
      int? currentUserId,
      String currentUsername,
      ) {
    final userOnlyItems = items.where((item) {
      // 🟢 Null-safe Stage Filtering
      if (_selectedStageTab != 'ALL') {
        dynamic rawStage;
        try {
          rawStage = item.inspectionStage;
        } catch (_) {
          rawStage = 'EMP';
        }

        final String stageStr = _safeString(rawStage);
        final String itemStage = stageStr.trim().isEmpty ? 'EMP' : stageStr.toUpperCase().trim();

        if (itemStage != _selectedStageTab) {
          return false;
        }
      }

      // Existing user filter logic
      if (currentUserId == null && currentUsername.isEmpty) return true;

      final String itemCreatorId = _safeString(item.createdBy).trim();
      if (currentUserId != null && itemCreatorId.isNotEmpty) {
        return itemCreatorId == currentUserId.toString();
      }

      final String checkedBy = _safeString(item.checkedBy).trim().toLowerCase();
      final String currentUser = currentUsername.trim().toLowerCase();
      if (currentUser.isNotEmpty && checkedBy.isNotEmpty) {
        return checkedBy == currentUser;
      }

      return false;
    }).toList();

    if (_safeString(_searchQuery).trim().isEmpty) {
      return userOnlyItems;
    }

    return userOnlyItems.where(_matchesSearch).toList();
  }
  Widget _buildStageTabButton(String stage, String label) {
    final isSelected = _selectedStageTab == stage;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStageTab = stage;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();

    final authProvider = context.watch<AuthProvider>();
    final int? currentUserId = authProvider.userId;
    final String currentUsername = authProvider.userName ?? '';

    final List<InspectionHistory> filteredList = _getFilteredItems(
      provider.history,
      currentUserId,
      currentUsername,
    );

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Survey Form',
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadHistory(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: Responsive.pagePadding(context),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.contentMaxWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inspection History',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Track and review all container inspections',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🟢 TOP STAGE FILTER TABS (ALL, EMP, CFS)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildStageTabButton('ALL', 'All'),
                        _buildStageTabButton('EMP', 'EMP'),
                        _buildStageTabButton('CFS', 'CFS'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SEARCH FIELD
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search across all fields...',
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                      ),
                      isDense: true,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                          : null,
                    ),
                    onChanged: (String value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // STATE HANDLING
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (filteredList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No matching inspections found',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 1;

                        if (constraints.maxWidth >= 1100) {
                          crossAxisCount = 3;
                        } else if (constraints.maxWidth >= 700) {
                          crossAxisCount = 2;
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredList.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 220,
                          ),
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            final String entryId = _safeString(item.id).trim();

                            return HistoryCard(
                              item: item,
                              formattedDate: _formatDate(item.inspectionDate),
                              onTap: () {
                                _navigateToForm(
                                  entryId: entryId.isEmpty ? null : entryId,
                                  readOnly: false,
                                );
                              },
                              onView: () {
                                if (entryId.isNotEmpty) {
                                  _navigateToReport(entryId);
                                }
                              },
                              onEdit: () {
                                _navigateToForm(
                                  entryId: entryId.isEmpty ? null : entryId,
                                  readOnly: false,
                                );
                              },
                              onCFS: () {
                                // Add CFS action logic here
                              },
                              onEIR: () {
                                // Add EIR action logic here
                              },
                              onChecklist: () {
                                // Add Checklist action logic here
                              },
                            );
                          },
                        );
                      },
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        icon: const Icon(Icons.add),
        label: const Text('New Inspection'),
      ),
    );
  }
}