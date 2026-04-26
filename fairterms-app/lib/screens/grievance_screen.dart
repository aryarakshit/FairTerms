/// Grievance letter and RTI application screen.
library;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/grievance.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/loading_overlay.dart';

/// Displays the grievance letter and RTI template for an analysis.
class GrievanceScreen extends ConsumerStatefulWidget {
  final String analysisId;

  const GrievanceScreen({super.key, required this.analysisId});

  @override
  ConsumerState<GrievanceScreen> createState() => _GrievanceScreenState();
}

class _GrievanceScreenState extends ConsumerState<GrievanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GrievanceData? _grievanceData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGrievanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGrievanceData() async {
    try {
      final data =
          await ApiService.instance.getGrievanceData(widget.analysisId);
      if (mounted) {
        setState(() {
          _grievanceData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Grievance Documents'),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: _grievanceData != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: AppColors.ink,
                labelColor: AppColors.ink,
                unselectedLabelColor: AppColors.inkMuted,
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(child: Text('Grievance Letter')),
                  Tab(child: Text('RTI Application')),
                ],
              )
            : null,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Loading documents...',
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline, width: 1),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Failed to load documents',
                    style: GoogleFonts.fraunces(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _error = null;
                        });
                        _loadGrievanceData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: AppColors.background,
                        shape: const StadiumBorder(),
                        textStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_grievanceData == null) {
      return const SizedBox.shrink();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _DocumentTab(
          subject: _grievanceData!.grievanceLetter.subject,
          body: _grievanceData!.grievanceLetter.body,
          pdfUrl: _grievanceData!.pdfUrl,
          legalReferences: _grievanceData!.legalReferences,
          isApplicable: true,
          onCopy: () => _copyToClipboard(
            'Subject: ${_grievanceData!.grievanceLetter.subject}\n\n${_grievanceData!.grievanceLetter.body}',
            'Grievance letter',
          ),
        ),
        _DocumentTab(
          subject: _grievanceData!.rtiTemplate.subject,
          body: _grievanceData!.rtiTemplate.body,
          pdfUrl: _grievanceData!.pdfUrl,
          legalReferences: _grievanceData!.legalReferences,
          isApplicable: _grievanceData!.rtiTemplate.applicable,
          notApplicableReason:
              _grievanceData!.rtiTemplate.reasonIfNotApplicable,
          onCopy: _grievanceData!.rtiTemplate.applicable
              ? () => _copyToClipboard(
                    'Subject: ${_grievanceData!.rtiTemplate.subject}\n\n${_grievanceData!.rtiTemplate.body}',
                    'RTI application',
                  )
              : null,
        ),
      ],
    );
  }
}

class _DocumentTab extends StatelessWidget {
  final String subject;
  final String body;
  final String? pdfUrl;
  final List<String> legalReferences;
  final bool isApplicable;
  final String? notApplicableReason;
  final VoidCallback? onCopy;

  const _DocumentTab({
    required this.subject,
    required this.body,
    required this.pdfUrl,
    required this.legalReferences,
    required this.isApplicable,
    this.notApplicableReason,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).size.width > 600 ? 32.0 : 20.0;
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline, width: 1),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subject',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkFaint,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subject,
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!isApplicable)
            _NotApplicableCard(reason: notApplicableReason)
          else ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline, width: 1),
              ),
              padding: const EdgeInsets.all(22),
              child: SelectableText(
                body,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.75,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (onCopy != null)
              ElevatedButton.icon(
                label: const Text('Copy to clipboard'),
                icon: const Icon(Icons.copy_outlined, size: 16),
                onPressed: onCopy!,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.background,
                  shape: const StadiumBorder(),
                  textStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              label: const Text('Download PDF'),
              icon: const Icon(Icons.download_outlined, size: 16),
              onPressed: () => _downloadDocument(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.background,
                shape: const StadiumBorder(),
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          const SizedBox(height: 28),
          if (legalReferences.isNotEmpty) ...[
            Text(
              'Legal references',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkFaint,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: legalReferences
                  .map((ref) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(
                            color: AppColors.outline,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.gavel_rounded,
                              size: 12,
                              color: AppColors.inkFaint,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ref,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.inkMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Future<void> _downloadDocument(BuildContext context) async {
    if (pdfUrl != null && pdfUrl!.isNotEmpty) {
      html.window.open(pdfUrl!, '_blank');
      return;
    }
    // No server-side PDF — generate one client-side and open print/save dialog.
    try {
      await Printing.layoutPdf(
        name: 'grievance_document.pdf',
        onLayout: (PdfPageFormat format) async {
          final doc = pw.Document();
          doc.addPage(
            pw.MultiPage(
              pageFormat: format,
              margin: const pw.EdgeInsets.all(48),
              build: (pw.Context ctx) => [
                pw.Text(
                  subject,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  body,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 4),
                ),
              ],
            ),
          );
          return doc.save();
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not generate PDF: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }
}

class _NotApplicableCard extends StatelessWidget {
  final String? reason;

  const _NotApplicableCard({this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RTI not applicable',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                    letterSpacing: 0.2,
                  ),
                ),
                if (reason != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    reason!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                      height: 1.55,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
