import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../components/app_widgets.dart';

/// PDF asset paths by language. Used to load the correct instructions PDF for the selected language.
const _assetPdfByLanguage = <String, String>{
  'en': 'assets/images/instructions provider - en.pdf',
  'ro': 'assets/images/instructions provider - ro.pdf',
  'ru': 'assets/images/instructions provider - ru.pdf',
};

/// Returns the instructions PDF asset path for [languageCode]. Falls back to English if unknown.
String providerInstructionsPdfAsset(String? languageCode) {
  final code = languageCode ?? 'en';
  return _assetPdfByLanguage[code] ?? _assetPdfByLanguage['en']!;
}

class InstructionsPdfScreen extends StatefulWidget {
  final String assetPath;

  const InstructionsPdfScreen({Key? key, required this.assetPath})
      : super(key: key);

  @override
  State<InstructionsPdfScreen> createState() => _InstructionsPdfScreenState();
}

class _InstructionsPdfScreenState extends State<InstructionsPdfScreen> {
  final PdfViewerController _controller = PdfViewerController();
  bool _loaded = false;
  String? _tempPath;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/instructions_provider_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      if (mounted) {
        setState(() {
          _tempPath = file.path;
          _loaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with placeholder and title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                      Image.asset(
                      "assets/images/instruction screen provider.png",
                      height: context.height() * 0.35,
                      fit: BoxFit.contain,
                    ),
                  12.width,
                  Expanded(
                    child: Text(
                      languages.providerInstructionsTitle,
                      style: boldTextStyle(size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(context),
            ),
            // Bottom button(s)
            Padding(
              padding: EdgeInsets.all(24),
              child: AppButton(
                text: languages.lblOk,
                color: primaryColor,
                textStyle: boldTextStyle(color: Colors.white),
                onTap: () => finish(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                  Image.asset(
                      "assets/images/instruction screen provider.png",
                      height: context.height() * 0.35,
                      fit: BoxFit.contain,
                    ),
              16.height,
              Text(
                languages.providerInstructionsText,
                textAlign: TextAlign.center,
                style: secondaryTextStyle(size: 14),
              ),
              16.height,
              Text(
                'Could not load instructions.',
                textAlign: TextAlign.center,
                style: primaryTextStyle(),
              ),
            ],
          ),
        ),
      );
    }
    if (!_loaded || _tempPath == null) {
      return Center(child: LoaderWidget());
    }
    return SfPdfViewer.file(
      File(_tempPath!),
      controller: _controller,
    );
  }
}
