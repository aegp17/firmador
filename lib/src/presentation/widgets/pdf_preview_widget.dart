import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Position for PDF signature placement with conversion capabilities
class PdfPosition {
  final double x;
  final double y;
  final int pageNumber;
  final double pdfWidth;
  final double pdfHeight;
  final double viewerWidth;
  final double viewerHeight;

  const PdfPosition({
    required this.x,
    required this.y,
    required this.pageNumber,
    required this.pdfWidth,
    required this.pdfHeight,
    required this.viewerWidth,
    required this.viewerHeight,
  });

  // Convert Flutter coordinates to PDF coordinates
  SignaturePosition toPdfCoordinates() {
    final double scaleX = pdfWidth / viewerWidth;
    final double scaleY = pdfHeight / viewerHeight;
    
    final double pdfX = x * scaleX;
    final double pdfY = pdfHeight - (y * scaleY);
    
    return SignaturePosition(
      x: pdfX,
      y: pdfY,
      pageNumber: pageNumber,
      pdfWidth: pdfWidth,
      pdfHeight: pdfHeight,
      viewerWidth: viewerWidth,
      viewerHeight: viewerHeight,
    );
  }

  // Convert to Map for Windows native calls
  Map<String, dynamic> toMap() {
    final pdfCoords = toPdfCoordinates();
    return {
      'x': pdfCoords.x,
      'y': pdfCoords.y,
      'pageNumber': pageNumber,
      'width': pdfCoords.signatureWidth,
      'height': pdfCoords.signatureHeight,
    };
  }

  // Compatibility with pdf_provider SignaturePosition
  int get page => pageNumber;
  Offset get position => Offset(x, y);

  @override
  String toString() => 'PdfPosition(x: $x, y: $y, page: $pageNumber)';
}

/// SignaturePosition class for compatibility with existing code
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
}

/// Widget for previewing PDF and selecting signature position
class PdfPreviewWidget extends StatefulWidget {
  final File pdfFile;
  final Function(PdfPosition)? onPositionSelected;
  final PdfPosition? selectedPosition;

  const PdfPreviewWidget({
    super.key,
    required this.pdfFile,
    this.onPositionSelected,
    this.selectedPosition,
  });

  @override
  State<PdfPreviewWidget> createState() => _PdfPreviewWidgetState();
}

class _PdfPreviewWidgetState extends State<PdfPreviewWidget> {
  final PdfViewerController _controller = PdfViewerController();
  PdfPosition? _tapPosition;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // PDF Viewer
        GestureDetector(
          onTapDown: _handleTapDown,
          child: SfPdfViewer.file(
            widget.pdfFile,
            controller: _controller,
          ),
        ),
        
        // Selected position indicator
        if (widget.selectedPosition != null)
          Positioned(
            left: widget.selectedPosition!.x - 10,
            top: widget.selectedPosition!.y - 10,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }

  void _handleTapDown(TapDownDetails details) {
    // For now, use placeholder dimensions - these should be obtained from the PDF viewer
    // In a real implementation, you'd get these from the PDF document and viewer size
    final position = PdfPosition(
      x: details.localPosition.dx,
      y: details.localPosition.dy,
      pageNumber: _controller.pageNumber,
      pdfWidth: 612.0, // Standard PDF page width in points
      pdfHeight: 792.0, // Standard PDF page height in points  
      viewerWidth: 400.0, // Placeholder - should be actual viewer width
      viewerHeight: 600.0, // Placeholder - should be actual viewer height
    );

    setState(() {
      _tapPosition = position;
    });

    widget.onPositionSelected?.call(position);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
} 