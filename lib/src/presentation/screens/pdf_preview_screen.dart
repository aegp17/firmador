import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // Cache display dimensions to avoid recalculating on every tap
  double _displayWidth = 0;
  double _displayHeight = 0;
  double _offsetX = 0;
  double _offsetY = 0;
  bool _dimensionsCalculated = false;
  
  // Performance optimization: Debounce rapid taps
  DateTime? _lastTapTime;
  static const Duration _tapDebounceTime = Duration(milliseconds: 100);

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  // Optimized dimension calculation with caching
  void _calculateDisplayDimensions(BoxConstraints constraints) {
    if (_dimensionsCalculated) return; // Use cached values if available
    
    try {
      // Calculate PDF aspect ratio
      final double pdfAspectRatio = _pdfPageWidth / _pdfPageHeight;
      final double viewerAspectRatio = constraints.maxWidth / constraints.maxHeight;
      
      if (pdfAspectRatio > viewerAspectRatio) {
        // PDF is wider than viewer - fit to width
        _displayWidth = constraints.maxWidth;
        _displayHeight = constraints.maxWidth / pdfAspectRatio;
        _offsetX = 0;
        _offsetY = (constraints.maxHeight - _displayHeight) / 2;
      } else {
        // PDF is taller than viewer - fit to height
        _displayWidth = constraints.maxHeight * pdfAspectRatio;
        _displayHeight = constraints.maxHeight;
        _offsetX = (constraints.maxWidth - _displayWidth) / 2;
        _offsetY = 0;
      }
      
      _dimensionsCalculated = true;
      debugPrint('Calculated display dimensions: ${_displayWidth.toStringAsFixed(1)}x${_displayHeight.toStringAsFixed(1)}, offset: (${_offsetX.toStringAsFixed(1)}, ${_offsetY.toStringAsFixed(1)})');
    } catch (e) {
      debugPrint('Error calculating display dimensions: $e');
      // Fallback to full constraints if calculation fails
      _displayWidth = constraints.maxWidth;
      _displayHeight = constraints.maxHeight;
      _offsetX = 0;
      _offsetY = 0;
    }
  }

  // Optimized validation with early returns
  bool _isValidTapPosition(double x, double y) {
    return x >= 0 && x <= _displayWidth && y >= 0 && y <= _displayHeight;
  }

  // Optimized document loading callback
  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _documentLoaded = true;
      _totalPages = details.document.pages.count;
      
      // Get page dimensions from the first page
      final page = details.document.pages[0];
      _pdfPageWidth = page.size.width;
      _pdfPageHeight = page.size.height;
      
      // Reset dimensions cache when new document loads
      _dimensionsCalculated = false;
    });
    
    debugPrint('PDF loaded: ${_totalPages} pages, size: ${_pdfPageWidth.toStringAsFixed(1)}x${_pdfPageHeight.toStringAsFixed(1)}');
  }

  // Optimized page change callback
  void _onPageChanged(int page) {
    if (_currentPage != page) {
      setState(() {
        _currentPage = page;
      });
    }
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
                    // Calculate dimensions once for this build
                    if (_documentLoaded) {
                      _calculateDisplayDimensions(constraints);
                    }
                    
                    return Stack(
                      children: [
                        SfPdfViewer.file(
                          widget.pdfFile,
                          controller: _pdfViewerController,
                          onDocumentLoaded: _onDocumentLoaded,
                          onPageChanged: (PdfPageChangedDetails details) => _onPageChanged(details.newPageNumber),
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
                            _selectedPosition!.pageNumber == _currentPage &&
                            _dimensionsCalculated)
                          Positioned(
                            left: _selectedPosition!.x - 25,
                            top: _selectedPosition!.y - 25,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                                border: Border.all(
                                  color: AppTheme.primaryCyan,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryCyan.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
    // Debounce rapid taps to improve performance
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) < _tapDebounceTime) {
      return;
    }
    _lastTapTime = now;
    
    if (!_documentLoaded) return;
    
    // Calculate dimensions only if not cached
    if (!_dimensionsCalculated) {
      _calculateDisplayDimensions(constraints);
    }
    
    try {
      // Get tap position relative to the PDF viewer widget
      final double relativeX = details.localPosition.dx - _offsetX;
      final double relativeY = details.localPosition.dy - _offsetY;
      
      // Validate tap position with early return for performance
      if (!_isValidTapPosition(relativeX, relativeY)) {
        return;
      }
      
      // Create signature position with optimized calculation
      final newPosition = SignaturePosition(
        x: relativeX,
        y: relativeY,
        pageNumber: _currentPage,
        pdfWidth: _pdfPageWidth,
        pdfHeight: _pdfPageHeight,
        viewerWidth: _displayWidth,
        viewerHeight: _displayHeight,
      );
      
      // Update state only if position actually changed
      if (_selectedPosition?.x != relativeX || 
          _selectedPosition?.y != relativeY || 
          _selectedPosition?.pageNumber != _currentPage) {
        setState(() {
          _selectedPosition = newPosition;
        });
        
        // Provide haptic feedback for better UX
        try {
          HapticFeedback.lightImpact();
        } catch (e) {
          // Ignore haptic feedback errors on unsupported platforms
        }
      }
    } catch (e) {
      debugPrint('Error handling tap: $e');
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