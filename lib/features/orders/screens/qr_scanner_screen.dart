import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:front/features/orders/providers/order_providers.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner le QR Code'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.normal,
              detectionTimeoutMs: 1000,
              returnImage: false,
            ),
            onDetect: (capture) async {
              if (_isScanning) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String? qrCode = barcode.rawValue;
                  if (qrCode != null) {
                    setState(() {
                      _isScanning = false; // Stop scanning after first detection
                    });
                    await _validatePickup(qrCode);
                    break; // Process only the first QR code
                  }
                }
              }
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: (_isScanning)
                    ? const Text(
                        'Scannez le QR Code de la commande...',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _validatePickup(String rawValue) async {
    try {
      final payload = _parseQrPayload(rawValue);
      if (payload == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR code invalide. Veuillez réessayer.')),
          );
          setState(() {
            _isScanning = true;
          });
        }
        return;
      }

      final orderId = payload['orderId']!;
      final qrCode = payload['qrCode']!;

      await ref.read(orderServiceProvider).validatePickup(orderId, qrCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande validée avec succès!')),
        );
        context.go('/merchant-sales'); // Go back to sales history after validation
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la validation: ${e.toString()}')),
        );
        setState(() {
          _isScanning = true; // Resume scanning on error
        });
      }
    }
  }

  Map<String, String>? _parseQrPayload(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map && decoded['orderId'] != null && decoded['qrCode'] != null) {
        return {
          'orderId': decoded['orderId'].toString(),
          'qrCode': decoded['qrCode'].toString(),
        };
      }
    } catch (_) {
      // ignore and try fallback
    }

    if (value.contains('|')) {
      final parts = value.split('|');
      if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return {
          'orderId': parts[0],
          'qrCode': parts[1],
        };
      }
    }

    return null;
  }

}
