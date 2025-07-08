import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:firmador/src/presentation/theme/app_theme.dart';
import 'dart:io';

class SignaturePosition {
  final double x;
  final double y;
  final int pageNumber;

  SignaturePosition({
    required this.x,
    required this.y,
    required this.pageNumber,
  });
}

class PdfPreviewScreen extends StatefulWidget {
  final File pdfFile;
  final Function(SignaturePosition?)? onPositionSelected;

  const PdfPreviewScreen({
    super.key,
    required this.pdfFile,
    this.onPositionSelected,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  SignaturePosition? _selectedPosition;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: AppTheme.white,
        title: const Text('Seleccionar Posición de Firma'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Page indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryNavy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Página $_currentPage de $_totalPages',
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                  ),
                ),
                if (_selectedPosition != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Posición seleccionada',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // PDF Viewer
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    SfPdfViewer.file(
                      widget.pdfFile,
                      controller: _pdfViewerController,
                      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                        setState(() {
                          _totalPages = details.document.pages.count;
                        });
                      },
                      onPageChanged: (PdfPageChangedDetails details) {
                        setState(() {
                          _currentPage = details.newPageNumber;
                        });
                      },
                    ),
                    // Overlay for tap detection
                    GestureDetector(
                      onTapDown: (TapDownDetails details) {
                        _handleTap(details);
                      },
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.transparent,
                      ),
                    ),
                    // Signature position indicator
                    if (_selectedPosition != null &&
                        _selectedPosition!.pageNumber == _currentPage)
                      Positioned(
                        left: _selectedPosition!.x - 25,
                        top: _selectedPosition!.y - 25,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                            border: Border.all(
                              color: AppTheme.primaryCyan,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.draw,
                            color: AppTheme.primaryCyan,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Instructions and buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryNavy,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Toque en el documento donde desea colocar la firma',
                          style: TextStyle(
                            color: AppTheme.primaryNavy,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onPositionSelected?.call(null);
                          Navigator.pop(context, null);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.lightGrey,
                          foregroundColor: AppTheme.primaryNavy,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedPosition != null
                            ? () {
                                widget.onPositionSelected?.call(_selectedPosition);
                                Navigator.pop(context, _selectedPosition);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryCyan,
                          foregroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Confirmar Posición'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(TapDownDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    
    // Calculate relative position accounting for app bar and page indicator
    const double appBarHeight = 56; // AppBar height
    const double pageIndicatorHeight = 64; // Page indicator height
    const double margin = 16; // Container margin
    
    final double adjustedY = localPosition.dy - appBarHeight - pageIndicatorHeight - margin;
    final double adjustedX = localPosition.dx - margin;
    
    // Only allow taps within the PDF viewer area
    if (adjustedY > 0 && adjustedX > 0) {
      setState(() {
        _selectedPosition = SignaturePosition(
          x: adjustedX,
          y: adjustedY,
          pageNumber: _currentPage,
        );
      });
    }
  }
} 