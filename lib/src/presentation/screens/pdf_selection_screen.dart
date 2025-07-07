import 'package:firmador/src/presentation/providers/pdf_provider.dart';
import 'package:firmador/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

class PdfSelectionScreen extends ConsumerWidget {
  const PdfSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfState = ref.watch(pdfProvider);
    final pdfNotifier = ref.read(pdfProvider.notifier);

    ref.listen<PdfState>(pdfProvider, (previous, next) {
      // Handle signing success
      if (next.signedPdfFile != null && previous?.signedPdfFile == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Firma Exitosa'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.success,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'El documento se ha firmado exitosamente',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Guardado en: ${next.signedPdfFile!.path}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.mediumGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  OpenFile.open(next.signedPdfFile!.path);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir Archivo'),
              ),
            ],
          ),
        );
      }
      // Handle errors
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('Firmar PDF'),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          if (pdfState.pageCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Página ${pdfState.currentPage + 1} de ${pdfState.pageCount}',
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (pdfState.pdfFile == null)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(24),
                child: Card(
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.primaryGradient,
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 64,
                            color: AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Selecciona un PDF para firmar',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Elige el documento PDF que deseas firmar digitalmente',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.mediumGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: pdfNotifier.pickPdf,
                            icon: const Icon(Icons.folder_open_rounded),
                            label: const Text('Seleccionar PDF'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (pdfState.pdfFile != null)
            // PDF Info Card
            Container(
              margin: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: AppTheme.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pdfState.pdfFile!.path.split('/').last,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pdfState.pageCount > 0 
                                  ? '${pdfState.pageCount} página${pdfState.pageCount > 1 ? 's' : ''}'
                                  : 'Cargando...',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.mediumGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (pdfState.signaturePosition != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.success,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, color: AppTheme.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Listo',
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (pdfState.pdfFile != null)
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Card(
                  elevation: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        PDFView(
                          filePath: pdfState.pdfFile!.path,
                          onRender: pdfNotifier.onPdfRender,
                          onPageChanged: pdfNotifier.onPageChanged,
                          onError: pdfNotifier.onPdfError,
                          onViewCreated: pdfNotifier.setController,
                        ),
                        // Overlay transparente para capturar el tap
                        Positioned.fill(
                          child: GestureDetector(
                            onTapUp: (details) {
                              // Tap detected on overlay, setting signature position
                              pdfNotifier.setSignaturePosition(details.localPosition);
                            },
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                        // Signature Position Indicator
                        if (pdfState.signaturePosition != null &&
                            pdfState.signaturePosition!.page == pdfState.currentPage)
                          Positioned(
                            left: pdfState.signaturePosition!.position.dx - 30,
                            top: pdfState.signaturePosition!.position.dy - 30,
                            child: GestureDetector(
                              onTap: pdfNotifier.clearSignaturePosition,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.draw_sharp,
                                  color: AppTheme.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        // Loading Indicator
                        if (pdfState.isLoading)
                          Container(
                            color: AppTheme.white.withValues(alpha: 0.8),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryCyan,
                              ),
                            ),
                          ),
                        // Instructions Overlay
                        if (pdfState.signaturePosition == null && !pdfState.isLoading)
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                                                 color: AppTheme.primaryNavy.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.touch_app_rounded,
                                    color: AppTheme.primaryCyan,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Toca en el documento donde quieres colocar tu firma',
                                      style: TextStyle(
                                        color: AppTheme.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: pdfState.pdfFile != null &&
              !pdfState.isLoading &&
              pdfState.signaturePosition != null
          ? Container(
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: !pdfState.isSigning ? pdfNotifier.signPdf : null,
                backgroundColor: Colors.transparent,
                elevation: 0,
                label: pdfState.isSigning
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Firmando...',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.draw_rounded, color: AppTheme.white),
                          SizedBox(width: 8),
                          Text(
                            'Firmar Documento',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            )
          : null,
    );
  }
} 