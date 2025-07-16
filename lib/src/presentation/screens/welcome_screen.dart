import 'dart:io';
import 'package:firmador/src/presentation/screens/certificate_upload_screen.dart';
import 'package:firmador/src/presentation/screens/backend_signature_screen.dart';
import 'package:firmador/src/presentation/screens/android_signature_screen.dart';
import 'package:firmador/src/presentation/screens/windows_signature_screen.dart';
import 'package:firmador/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.navyGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                  MediaQuery.of(context).padding.top - 
                  MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: <Widget>[
                    // Header
                    const Center(
                      child: Text(
                        'FirmaSeguraEC',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.white,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isSmallScreen ? 20 : 40),

                    // Logo and Brand Section
                    Column(
                      children: [
                        // Security Icon with Gradient
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.security,
                            size: isSmallScreen ? 60 : 80,
                            color: AppTheme.white,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        
                        // App Title
                        Text(
                          'FirmaSeguraEC',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 28 : 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Subtitle with gradient text effect
                        ShaderMask(
                          shaderCallback: (bounds) => AppGradients.primaryGradient.createShader(bounds),
                          child: Text(
                            'La firma electrónica más segura y confiable del Ecuador',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isSmallScreen ? 24 : 32),

                    // Features Section
                    Column(
                      children: [
                        _FeatureTile(
                          icon: Icons.verified_user,
                          title: 'Certificados Validados',
                          description: 'Usa tu certificado digital (.p12) con validación CA',
                          isCompact: isSmallScreen,
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        _FeatureTile(
                          icon: Icons.security,
                          title: 'Firma Segura',
                          description: 'Firma documentos directamente en tu dispositivo',
                          isCompact: isSmallScreen,
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        _FeatureTile(
                          icon: Icons.speed,
                          title: 'Rápido y Fácil',
                          description: 'Proceso simplificado en pocos pasos',
                          isCompact: isSmallScreen,
                        ),
                      ],
                    ),

                    SizedBox(height: isSmallScreen ? 24 : 32),

                    // CTA Section
                    Column(
                      children: [
                        // Backend Mode Button (Recommended)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const BackendSignatureScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 16 : 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(
                              Icons.cloud,
                              color: AppTheme.white,
                              size: 24,
                            ),
                            label: Column(
                              children: [
                                Text(
                                  'Firmar con Servidor',
                                  style: TextStyle(
                                    color: AppTheme.white,
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Recomendado para iOS',
                                  style: TextStyle(
                                    color: AppTheme.white.withValues(alpha: 0.8),
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        // Android Hybrid Mode Button (only show on Android)
                        if (Platform.isAndroid) ...[
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade600, Colors.green.shade400],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const AndroidSignatureScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 16 : 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.phone_android,
                                color: AppTheme.white,
                                size: 24,
                              ),
                              label: Column(
                                children: [
                                  Text(
                                    'Firmador Android',
                                    style: TextStyle(
                                      color: AppTheme.white,
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Local + Backend híbrido',
                                    style: TextStyle(
                                      color: AppTheme.white.withValues(alpha: 0.8),
                                      fontSize: isSmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                        ],
                        
                        // Windows Hybrid Mode Button (only show on Windows)
                        if (Platform.isWindows) ...[
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade700, Colors.blue.shade500],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const WindowsSignatureScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 16 : 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.desktop_windows,
                                color: AppTheme.white,
                                size: 24,
                              ),
                              label: Column(
                                children: [
                                  Text(
                                    'Firmador Windows',
                                    style: TextStyle(
                                      color: AppTheme.white,
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Certificate Store + Backend',
                                    style: TextStyle(
                                      color: AppTheme.white.withValues(alpha: 0.8),
                                      fontSize: isSmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                        ],
                        
                        // Legacy Local Mode Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const CertificateUploadScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 16 : 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(
                              Icons.security,
                              color: AppTheme.white,
                              size: 24,
                            ),
                            label: Column(
                              children: [
                                Text(
                                  'Modo Compatibilidad',
                                  style: TextStyle(
                                    color: AppTheme.white,
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  Platform.isAndroid ? 'Simulación básica' : 'Solo disponible en Android',
                                  style: TextStyle(
                                    color: AppTheme.white.withValues(alpha: 0.8),
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        
                        // Trust Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified,
                                color: AppTheme.primaryCyan,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Certificado por FIRMASEGURA S.A.S.',
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontSize: isSmallScreen ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
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


}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isCompact;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryCyan.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 10 : 12),
            decoration: BoxDecoration(
              gradient: AppGradients.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.white,
              size: isCompact ? 20 : 24,
            ),
          ),
          SizedBox(width: isCompact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: isCompact ? 13 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: isCompact ? 2 : 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.white.withValues(alpha: 0.8),
                    fontSize: isCompact ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 