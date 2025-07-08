import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:firmador/src/presentation/theme/app_theme.dart';
import 'dart:io';

class SignaturePosition {
  final double x;
  final double y;
  final int pageNumber;
  final double pdfWidth;
  final double pdfHeight;
  final double viewerWidth;
  final double viewerHeight;
  final double signatureWidth;
  final double signatureHeight;

  SignaturePosition({
    required this.x,
    required this.y,
    required this.pageNumber,
    required this.pdfWidth,
    required this.pdfHeight,
    required this.viewerWidth,
    required this.viewerHeight,
    this.signatureWidth = 150.0,
    this.signatureHeight = 50.0,
  });

  // Convert Flutter coordinates (top-left origin, pixels) to PDF coordinates (bottom-left origin, points)
  SignaturePosition toPdfCoordinates() {
    // Calculate scale factors
    final double scaleX = pdfWidth / viewerWidth;
    final double scaleY = pdfHeight / viewerHeight;
    
    // Convert to PDF coordinates
    final double pdfX = x * scaleX;
    final double pdfY = pdfHeight - (y * scaleY); // Flip Y coordinate
    
    return SignaturePosition(
      x: pdfX,
      y: pdfY,
      pageNumber: pageNumber,
      pdfWidth: pdfWidth,
      pdfHeight: pdfHeight,
      viewerWidth: viewerWidth,
      viewerHeight: viewerHeight,
      signatureWidth: signatureWidth,
      signatureHeight: signatureHeight,
    );
  }

  @override
  String toString() {
    return 'SignaturePosition(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, page: $pageNumber, pdfSize: ${pdfWidth.toStringAsFixed(1)}x${pdfHeight.toStringAsFixed(1)}, viewerSize: ${viewerWidth.toStringAsFixed(1)}x${viewerHeight.toStringAsFixed(1)}, signatureSize: ${signatureWidth.toStringAsFixed(1)}x${signatureHeight.toStringAsFixed(1)})';
  }
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
  
  // PDF document properties
  double _pdfPageWidth = 612.0; // Default letter size in points
  double _pdfPageHeight = 792.0; // Default letter size in points
  bool _documentLoaded = false;

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
        actions: [
          if (_selectedPosition != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showCoordinateInfo,
              tooltip: 'Ver información de coordenadas',
            ),
        ],
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        SfPdfViewer.file(
                          widget.pdfFile,
                          controller: _pdfViewerController,
                          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                            setState(() {
                              _totalPages = details.document.pages.count;
                              _documentLoaded = true;
                              
                              // Get actual PDF page dimensions (in points)
                              if (details.document.pages.count > 0) {
                                final page = details.document.pages[0];
                                _pdfPageWidth = page.size.width;
                                _pdfPageHeight = page.size.height;
                              }
                            });
                            
                                                          // PDF loaded successfully with dimensions and page count
                          },
                          onPageChanged: (PdfPageChangedDetails details) {
                            setState(() {
                              _currentPage = details.newPageNumber;
                            });
                          },
                        ),
                        // Overlay for tap detection
                        if (_documentLoaded)
                          GestureDetector(
                            onTapDown: (TapDownDetails details) {
                              _handleTap(details, constraints);
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
                        // Loading indicator
                        if (!_documentLoaded)
                          const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryCyan),
                            ),
                          ),
                      ],
                    );
                  },
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryNavy,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
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
                      if (_selectedPosition != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Coordenadas: X=${_selectedPosition!.x.toStringAsFixed(1)}, Y=${_selectedPosition!.y.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: AppTheme.primaryNavy,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
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
                                final pdfPosition = _selectedPosition!.toPdfCoordinates();
                                
                                widget.onPositionSelected?.call(pdfPosition);
                                Navigator.pop(context, pdfPosition);
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

  void _handleTap(TapDownDetails details, BoxConstraints constraints) {
    if (!_documentLoaded) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    
    // Calculate the available area for PDF display
    final double availableWidth = constraints.maxWidth;
    final double availableHeight = constraints.maxHeight;
    
    // Calculate PDF display dimensions (accounting for aspect ratio preservation)
    final double pdfAspectRatio = _pdfPageWidth / _pdfPageHeight;
    final double availableAspectRatio = availableWidth / availableHeight;
    
    double displayWidth, displayHeight;
    double offsetX = 0, offsetY = 0;
    
    if (pdfAspectRatio > availableAspectRatio) {
      // PDF is wider - fit to width
      displayWidth = availableWidth;
      displayHeight = availableWidth / pdfAspectRatio;
      offsetY = (availableHeight - displayHeight) / 2;
    } else {
      // PDF is taller - fit to height
      displayHeight = availableHeight;
      displayWidth = availableHeight * pdfAspectRatio;
      offsetX = (availableWidth - displayWidth) / 2;
    }
    
    // Calculate relative position within the PDF display area
    final double relativeX = localPosition.dx - offsetX;
    final double relativeY = localPosition.dy - offsetY;
    
    // Check if tap is within PDF bounds
    if (relativeX >= 0 && relativeX <= displayWidth && 
        relativeY >= 0 && relativeY <= displayHeight) {
      
      setState(() {
        _selectedPosition = SignaturePosition(
          x: relativeX,
          y: relativeY,
          pageNumber: _currentPage,
          pdfWidth: _pdfPageWidth,
          pdfHeight: _pdfPageHeight,
          viewerWidth: displayWidth,
          viewerHeight: displayHeight,
        );
              });
    }
  }

  void _showCoordinateInfo() {
    if (_selectedPosition == null) return;
    
    final pdfCoords = _selectedPosition!.toPdfCoordinates();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de Coordenadas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Página: ${_selectedPosition!.pageNumber}'),
            const SizedBox(height: 8),
            const Text('Coordenadas de pantalla:'),
            Text('X: ${_selectedPosition!.x.toStringAsFixed(2)} px'),
            Text('Y: ${_selectedPosition!.y.toStringAsFixed(2)} px'),
            const SizedBox(height: 8),
            const Text('Coordenadas PDF:'),
            Text('X: ${pdfCoords.x.toStringAsFixed(2)} puntos'),
            Text('Y: ${pdfCoords.y.toStringAsFixed(2)} puntos'),
            const SizedBox(height: 8),
            const Text('Tamaño PDF:'),
            Text('${_pdfPageWidth.toStringAsFixed(1)} x ${_pdfPageHeight.toStringAsFixed(1)} puntos'),
            const SizedBox(height: 8),
            const Text('Tamaño visor:'),
            Text('${_selectedPosition!.viewerWidth.toStringAsFixed(1)} x ${_selectedPosition!.viewerHeight.toStringAsFixed(1)} px'),
            const SizedBox(height: 8),
            const Text('Tamaño firma:'),
            Text('${_selectedPosition!.signatureWidth.toStringAsFixed(1)} x ${_selectedPosition!.signatureHeight.toStringAsFixed(1)} puntos'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
} 