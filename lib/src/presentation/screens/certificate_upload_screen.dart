import 'package:firmador/src/presentation/providers/certificate_provider.dart';
import 'package:firmador/src/presentation/screens/pdf_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CertificateUploadScreen extends ConsumerWidget {
  const CertificateUploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(certificateUploadProvider);
    final notifier = ref.read(certificateUploadProvider.notifier);

    // Listen for errors and show a snackbar
    ref.listen<CertificateUploadState>(certificateUploadProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargar Certificado'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: state.isLoading ? null : notifier.pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Seleccionar archivo .p12'),
            ),
            const SizedBox(height: 16),
            Text(
              state.file?.name ?? 'No se ha seleccionado ningún archivo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // Show Certificate Info if available
            if (state.certificateInfo != null)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Información del Certificado', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      _InfoTile(title: 'Nombre Común', value: state.certificateInfo!.commonName.isNotEmpty 
                          ? state.certificateInfo!.commonName 
                          : 'N/A'),
                      _InfoTile(title: 'Emitido para', value: state.certificateInfo!.subject),
                      _InfoTile(title: 'Emitido por', value: state.certificateInfo!.issuer),
                      _InfoTile(title: 'Número de Serie', value: state.certificateInfo!.serialNumber.isNotEmpty 
                          ? state.certificateInfo!.serialNumber 
                          : 'N/A'),
                      _InfoTile(
                        title: 'Válido desde',
                        value: DateFormat.yMd().add_Hms().format(state.certificateInfo!.validFrom),
                      ),
                      _InfoTile(
                        title: 'Válido hasta',
                        value: DateFormat.yMd().add_Hms().format(state.certificateInfo!.validTo),
                      ),
                      if (state.certificateInfo!.keyUsages.isNotEmpty)
                        _InfoTile(
                          title: 'Usos de Clave',
                          value: state.certificateInfo!.keyUsages.join(', '),
                      ),
                      if (state.certificateInfo!.isTrusted)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            children: [
                              Icon(Icons.verified, color: Colors.green, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                'Certificado validado por CA confiable',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            
            if (state.certificateInfo == null)
              TextField(
                onChanged: notifier.updatePassword,
                obscureText: true,
                enabled: !state.isLoading,
                decoration: const InputDecoration(
                  labelText: 'Contraseña del Certificado',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: state.isLoading || state.certificateInfo != null ? null : () => notifier.loadCertificate(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: state.isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Cargar Certificado'),
            ),

            if (state.certificateInfo != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const PdfSelectionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Continuar'),
              )
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
} 