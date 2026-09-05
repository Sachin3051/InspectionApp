import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/form_provider.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart'; // Ensure ApiService is imported

class ReportPreviewScreen extends StatefulWidget {
  final String entryId;

  const ReportPreviewScreen({super.key, required this.entryId});

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchReportDetails();
  }

  Future<void> _fetchReportDetails() async {
    try {
      final provider = context.read<FormProvider>();
      await provider.loadForm(entryId: widget.entryId, readOnly: true);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Date Formatting Helper (Format: DD-MM-YYYY)
  String _formatDate(dynamic dateInput) {
    if (dateInput == null) return '-';
    DateTime? dt;

    if (dateInput is DateTime) {
      dt = dateInput;
    } else if (dateInput is String && dateInput.trim().isNotEmpty) {
      dt = DateTime.tryParse(dateInput.trim());
    }

    if (dt == null) return dateInput.toString().trim().isEmpty ? '-' : dateInput.toString();

    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();

    return '$day-$month-$year';
  }

  String _getAns(String searchText) {
    final provider = context.read<FormProvider>();
    final form = provider.form;
    if (form == null) return '';

    for (var section in form.sections) {
      for (var q in section.questions) {
        final qCode = q.questionCode.trim().toLowerCase();
        final qText = q.questionText.trim().toLowerCase();
        final search = searchText.trim().toLowerCase();

        if (qCode == search || qText == search || qText.contains(search)) {
          final ans = provider.answerFor(q.questionId);
          if (q.controlType == 'Date' && ans.dateValue != null) {
            return _formatDate(ans.dateValue);
          }
          final rawText = ans.selectedOptionValue ?? ans.textValue ?? '';
          if (q.controlType == 'Date' || qText.contains('date')) {
            return _formatDate(rawText);
          }
          return rawText;
        }
      }
    }
    return '';
  }

  String _combineValues(String val1, String val2) {
    final clean1 = val1.trim();
    final clean2 = val2.trim();
    if (clean1.isEmpty && clean2.isEmpty) return '-';
    if (clean1.isNotEmpty && clean2.isNotEmpty) return '$clean1 / $clean2';
    return clean1.isNotEmpty ? clean1 : clean2;
  }

  String _mapAnswerValue(String? rawVal) {
    if (rawVal == null || rawVal.trim().isEmpty) return '-';
    final val = rawVal.trim().toUpperCase();
    switch (val) {
      case 'A':
        return 'Accepted';
      case 'R':
        return 'Rejected';
      case 'AC':
        return 'Accepted with condition';
      case 'NA':
        return 'Not Applicable';
      default:
        return rawVal;
    }
  }

  // Safe File Name Extractor
  String _extractFileName(dynamic img) {
    if (img == null) return 'Image';
    String strPath = '';

    if (img is String) {
      strPath = img;
    } else {
      try {
        final dynamic name = (img as dynamic).name ??
            (img as dynamic).fileName ??
            (img as dynamic).url ??
            (img as dynamic).path ??
            (img as dynamic).filePath;
        strPath = name?.toString() ?? '';
      } catch (_) {
        strPath = '';
      }
    }

    if (strPath.isEmpty || strPath.contains("Instance of")) return 'Image File';

    try {
      final uri = Uri.parse(strPath);
      final name = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : strPath;
      return name.isEmpty ? 'Image File' : name;
    } catch (_) {
      final parts = strPath.split(RegExp(r'[/\\]'));
      return parts.isNotEmpty ? parts.last : strPath;
    }
  }

  // Safe Image URL Extractor using ApiService
  String _extractImageUrl(dynamic img) {
    if (img == null) return '';
    String rawPath = '';

    if (img is String) {
      rawPath = img;
    } else {
      try {
        final dynamic urlVal = (img as dynamic).url ??
            (img as dynamic).imageUrl ??
            (img as dynamic).path ??
            (img as dynamic).filePath ??
            (img as dynamic).fileUrl;

        rawPath = urlVal?.toString() ?? '';
      } catch (_) {
        return '';
      }
    }

    if (rawPath.isEmpty || rawPath.contains("Instance of")) return '';

    // Pass directly to ApiService
    return ApiService.resolveImageUrl(rawPath);
  }

  // Image Preview Modal
  void _showImageModal(BuildContext context, String imageUrl, String fileName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modal Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black54),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),
                    // Modal Body
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.8,
                            maxScale: 4.0,
                            child: imageUrl.isEmpty
                                ? _buildErrorWidget()
                                : Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const SizedBox(
                                  height: 250,
                                  child: Center(
                                    child: CircularProgressIndicator(strokeWidth: 2.5),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Failed to load image preview',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // PDF Generator
  Future<Uint8List> _generateReportPDF() async {
    final provider = context.read<FormProvider>();
    final form = provider.form;

    if (form == null) {
      throw Exception('Report data unavailable');
    }

    final pdf = pw.Document();

    final filteredSections = form.sections.where((section) {
      final name = section.sectionName.trim().toLowerCase();
      return name != 'inspection details' &&
          name != 'inspection detail' &&
          name != 'overall decision' &&
          name != 'general remark' &&
          name != 'general remarks';
    }).toList();

    final overallDecision = _mapAnswerValue(_getAns('Overall Decision'));
    final generalRemark = _getAns('General Remark').isEmpty
        ? _getAns('General Remarks')
        : _getAns('General Remark');

    final leftColumn = [
      {'label': 'Report No', 'val': widget.entryId, 'isValBold': false},
      {'label': 'Invoice No', 'val': _getAns('Invoice No'), 'isValBold': false},
      {'label': 'Shipping Line / Trucking Co.', 'val': _getAns('Shipping Line'), 'isValBold': false},
      {
        'label': 'Container No / Type',
        'val': _combineValues(_getAns('Container No'), _getAns('Container Type')),
        'isValBold': true,
      },
      {'label': 'Sender / Shipper', 'val': _getAns('Sender'), 'isValBold': false},
      {'label': 'LR / Bilty No', 'val': _getAns('LR'), 'isValBold': false},
      {
        'label': 'Truck No / Type',
        'val': _combineValues(_getAns('Truck Number'), _getAns('Truck Type')),
        'isValBold': false,
      },
    ];

    final rightColumn = [
      {'label': 'Invoice Date', 'val': _formatDate(_getAns('Invoice Date')), 'isValBold': false},
      {'label': 'Shipping Line Booking Id', 'val': _getAns('Booking'), 'isValBold': false},
      {'label': 'Receiver / Buyer', 'val': _getAns('Receiver'), 'isValBold': false},
      {'label': 'Bilty Date', 'val': _formatDate(_getAns('Bilty Date')), 'isValBold': false},
      {'label': 'Overall Decision', 'val': overallDecision, 'isValBold': true},
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (pw.Context context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Container Inspection Report',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        footer: (pw.Context context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Generated by Inspection System', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
        build: (pw.Context context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: leftColumn.map((item) {
                      final val = (item['val'] as String? ?? '').trim();
                      final isValBold = item['isValBold'] == true;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              '${item['label']}: ',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                val.isEmpty ? '-' : val,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: isValBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: rightColumn.map((item) {
                      final val = (item['val'] as String? ?? '').trim();
                      final isValBold = item['isValBold'] == true;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              '${item['label']}: ',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                val.isEmpty ? '-' : val,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: isValBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            columnWidths: const {
              0: pw.FlexColumnWidth(2.0),
              1: pw.FlexColumnWidth(3.0),
              2: pw.FlexColumnWidth(1.8),
              3: pw.FlexColumnWidth(2.0),
              4: pw.FlexColumnWidth(1.8),
            },
            headers: ['Section', 'Question', 'Answer', 'Remarks', 'Images'],
            data: [
              for (var section in filteredSections)
                for (var q in section.questions)
                  [
                    section.sectionName.isEmpty ? '-' : section.sectionName,
                    q.questionText.isEmpty ? '-' : q.questionText,
                    _mapAnswerValue(
                      provider.answerFor(q.questionId).selectedOptionValue ??
                          provider.answerFor(q.questionId).textValue,
                    ),
                    provider.answerFor(q.questionId).remark ?? '',
                    provider.answerFor(q.questionId).images.isNotEmpty
                        ? provider
                        .answerFor(q.questionId)
                        .images
                        .map((img) => _extractFileName(img))
                        .join('\n')
                        : '-',
                  ]
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('General Remark: ', style: const pw.TextStyle(fontSize: 9)),
              pw.Expanded(
                child: pw.Text(
                  generalRemark.isEmpty ? '-' : generalRemark,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> _handlePdfAction({bool isShare = false}) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final pdfBytes = await _generateReportPDF();
      final filename = 'Inspection_Report_${widget.entryId}.pdf';

      if (isShare) {
        await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: filename,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FormProvider>();
    final form = provider.form;

    final String overallDecisionRaw = _getAns('Overall Decision');
    final String overallDecision = _mapAnswerValue(overallDecisionRaw);
    final String generalRemark = _getAns('General Remark').isEmpty
        ? _getAns('General Remarks')
        : _getAns('General Remark');

    final filteredSections = form?.sections.where((section) {
      final name = section.sectionName.trim().toLowerCase();
      return name != 'inspection details' &&
          name != 'inspection detail' &&
          name != 'overall decision' &&
          name != 'general remark' &&
          name != 'general remarks';
    }).toList() ?? [];

    final leftColumn = [
      {'label': 'Report No', 'val': widget.entryId, 'isValBold': false},
      {'label': 'Invoice No', 'val': _getAns('Invoice No'), 'isValBold': false},
      {'label': 'Shipping Line / Trucking Co.', 'val': _getAns('Shipping Line'), 'isValBold': false},
      {
        'label': 'Container No / Type',
        'val': _combineValues(_getAns('Container No'), _getAns('Container Type')),
        'isValBold': true,
      },
      {'label': 'Sender / Shipper', 'val': _getAns('Sender'), 'isValBold': false},
      {'label': 'LR / Bilty No', 'val': _getAns('LR'), 'isValBold': false},
      {
        'label': 'Truck No / Type',
        'val': _combineValues(_getAns('Truck Number'), _getAns('Truck Type')),
        'isValBold': false,
      },
    ];

    final rightColumn = [
      {'label': 'Invoice Date', 'val': _formatDate(_getAns('Invoice Date')), 'isValBold': false},
      {'label': 'Shipping Line Booking Id', 'val': _getAns('Booking'), 'isValBold': false},
      {'label': 'Receiver / Buyer', 'val': _getAns('Receiver'), 'isValBold': false},
      {'label': 'Bilty Date', 'val': _formatDate(_getAns('Bilty Date')), 'isValBold': false},
      {'label': 'Overall Decision', 'val': overallDecision, 'isValBold': true},
    ];

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): () {
          _handlePdfAction(isShare: false);
        },
        const SingleActivator(LogicalKeyboardKey.keyP, meta: true): () {
          _handlePdfAction(isShare: false);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: const Text('Inspection Report', style: TextStyle(color: Colors.black87, fontSize: 18)),
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : () => _handlePdfAction(isShare: false),
                icon: _isProcessing
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.print, size: 18),
                label: Text(_isProcessing ? 'Processing...' : 'Print / Save PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: _isLoading || provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : form == null
              ? const Center(child: Text('Failed to load inspection report'))
              : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: leftColumn.map((item) {
                                return _infoRow(
                                  item['label'] as String,
                                  item['val'] as String,
                                  isValBold: item['isValBold'] == true,
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: rightColumn.map((item) {
                                return _infoRow(
                                  item['label'] as String,
                                  item['val'] as String,
                                  isValBold: item['isValBold'] == true,
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Table(
                        border: TableBorder.all(color: Colors.grey.shade200),
                        columnWidths: const {
                          0: FlexColumnWidth(2.2),
                          1: FlexColumnWidth(3.5),
                          2: FlexColumnWidth(2.2),
                          3: FlexColumnWidth(2.0),
                          4: FlexColumnWidth(1.8),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade100),
                            children: const [
                              _TableHeaderCell('Section'),
                              _TableHeaderCell('Question'),
                              _TableHeaderCell('Answer'),
                              _TableHeaderCell('Remarks'),
                              _TableHeaderCell('Images'),
                            ],
                          ),
                          for (var section in filteredSections)
                            for (var q in section.questions)
                              TableRow(
                                children: [
                                  _TableCell(section.sectionName.isEmpty ? '-' : section.sectionName),
                                  _TableCell(q.questionText.isEmpty ? '-' : q.questionText),
                                  _TableCell(
                                    _mapAnswerValue(
                                      provider.answerFor(q.questionId).selectedOptionValue ??
                                          provider.answerFor(q.questionId).textValue,
                                    ),
                                    isAnswer: true,
                                  ),
                                  _TableCell(provider.answerFor(q.questionId).remark ?? ''),
                                  _ImageCell(
                                    images: provider.answerFor(q.questionId).images,
                                    onImageTap: (url, name) => _showImageModal(context, url, name),
                                    extractNameFunc: _extractFileName,
                                    extractUrlFunc: _extractImageUrl,
                                  ),
                                ],
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'General Remark: ',
                          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 13, color: Colors.black87),
                        ),
                        Expanded(
                          child: Text(
                            generalRemark.isEmpty ? '-' : generalRemark,
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isValBold = false}) {
    final cleanVal = value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              cleanVal.isEmpty ? '-' : cleanVal,
              style: TextStyle(
                fontWeight: isValBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isAnswer;

  const _TableCell(this.text, {this.isAnswer = false});

  @override
  Widget build(BuildContext context) {
    final String cleanText = text.trim();

    Color getAnswerColor() {
      if (!isAnswer) return Colors.black87;
      final lower = cleanText.toLowerCase();
      if (lower == 'accepted') return Colors.green;
      if (lower == 'rejected') return Colors.red;
      if (lower == 'accepted with condition') return Colors.orange;
      return Colors.black87;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        cleanText.isEmpty ? '-' : cleanText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isAnswer ? FontWeight.bold : FontWeight.normal,
          color: getAnswerColor(),
        ),
      ),
    );
  }
}

class _ImageCell extends StatelessWidget {
  final List<dynamic> images;
  final Function(String url, String name) onImageTap;
  final String Function(dynamic) extractNameFunc;
  final String Function(dynamic) extractUrlFunc;

  const _ImageCell({
    required this.images,
    required this.onImageTap,
    required this.extractNameFunc,
    required this.extractUrlFunc,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text('-', style: TextStyle(fontSize: 12, color: Colors.black87)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: images.map((img) {
          final fileName = extractNameFunc(img);
          final imageUrl = extractUrlFunc(img);

          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: InkWell(
              onTap: () => onImageTap(imageUrl, fileName),
              hoverColor: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.image_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}