import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:front/features/orders/providers/order_providers.dart';
import 'package:front/core/widgets/bottom_nav.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  late final MobileScannerController _scannerController;
  bool _isScanning = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner le QR Code'),
      ),
      bottomNavigationBar: const BottomNav(activeTab: 'scan', role: 'MERCHANT'),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) async {
              if (!_isScanning || _isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? qrCode = barcode.rawValue;
                if (qrCode != null && qrCode.isNotEmpty) {
                  setState(() {
                    _isScanning = false;
                    _isProcessing = true;
                  });
                  await _validatePickup(qrCode);
                  break;
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
          ),
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
            const SnackBar(content: Text('QR code invalide. Veuillez reessayer.')),
          );
          setState(() {
            _isScanning = true;
            _isProcessing = false;
          });
        }
        return;
      }

      final orderId = payload['orderId']!;
      final qrCode = payload['qrCode']!;

      await ref.read(orderServiceProvider).validatePickup(orderId, qrCode);

      if (mounted) {
        if (context.canPop()) {
          context.pop('validated');
        } else {
          context.go('/merchant-sales?tab=completed&validated=1');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la validation: ${e.toString()}')),
        );
        setState(() {
          _isScanning = true;
          _isProcessing = false;
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
