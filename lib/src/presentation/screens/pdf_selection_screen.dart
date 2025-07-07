import 'package:firmador/src/presentation/providers/pdf_provider.dart';
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
            content: Text('El documento se ha firmado y guardado en: ${next.signedPdfFile!.path}'),
            actions: [
              TextButton(
                onPressed: () {
                  OpenFile.open(next.signedPdfFile!.path);
                  Navigator.of(context).pop();
                },
                child: const Text('Abrir Archivo'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
      // Handle errors
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firmar PDF'),
        actions: [
          if (pdfState.pageCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  'Página ${pdfState.currentPage + 1} de ${pdfState.pageCount}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (pdfState.pdfFile == null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: pdfNotifier.pickPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Seleccionar PDF'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          if (pdfState.pdfFile != null)
            Expanded(
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
                  if (pdfState.signaturePosition != null &&
                      pdfState.signaturePosition!.page == pdfState.currentPage)
                    Positioned(
                      left: pdfState.signaturePosition!.position.dx - 24,
                      top: pdfState.signaturePosition!.position.dy - 24,
                      child: GestureDetector(
                        onTap: pdfNotifier.clearSignaturePosition,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.draw_sharp,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  if (pdfState.isLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          if (pdfState.pdfFile == null)
            const Expanded(
              child: Center(
                child: Text('Por favor, selecciona un documento PDF para firmar.'),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: pdfState.pdfFile != null &&
                !pdfState.isLoading &&
                pdfState.signaturePosition != null &&
                !pdfState.isSigning
            ? pdfNotifier.signPdf
            : null,
        label: pdfState.isSigning
            ? const Text('Firmando...')
            : const Text('Firmar Documento'),
        icon: pdfState.isSigning
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.draw),
        backgroundColor: pdfState.pdfFile != null &&
                !pdfState.isLoading &&
                pdfState.signaturePosition != null
            ? Theme.of(context).colorScheme.primary
            : Colors.grey,
      ),
    );
  }
} 