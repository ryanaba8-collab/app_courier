import 'dart:io';
import 'dart:ui';

import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/app_db.dart';

class ExportService {
  String _statusLabel(int s) {
    switch (s) {
      case 0:
        return 'LIVRE';
      case 1:
        return 'PAS_ACCES';
      default:
        return 'A_VERIFIER';
    }
  }

  Future<File> _writeFile(String filename, List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> exportCsv({
    required List<Deposit> rows,
    required String title,
  }) async {
    final csvRows = <List<dynamic>>[
      [
        'id',
        'createdAt',
        'addressLabel',
        'lat',
        'lon',
        'accuracy_m',
        'deliveryStatus',
        'buildingSuspected',
        'groupId',
        'tourId',
        'noAd',
      ],
      ...rows.map((d) => [
            d.id,
            d.createdAt.toIso8601String(),
            d.addressLabel ?? '',
            d.lat,
            d.lon,
            d.accuracy,
            _statusLabel(d.deliveryStatus),
            d.buildingSuspected ? '1' : '0',
            d.groupId?.toString() ?? '',
            d.tourId?.toString() ?? '',
            d.noAd ? '1' : '0',
          ]),
    ];

    final csv = const ListToCsvConverter().convert(csvRows);

    final safeTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filename =
        'export_${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.csv';

    final file = await _writeFile(filename, csv.codeUnits);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Export CSV - $title',
      text: 'Export CSV - $title',
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
    );
  }

  Future<void> exportPdf({
    required List<Deposit> rows,
    required String title,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text(
              'Export - $title',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: const [
                'Date',
                'Adresse',
                'Statut',
                'Acc(m)',
                'NoAd',
              ],
              data: rows.take(300).map((d) {
                return [
                  d.createdAt
                      .toIso8601String()
                      .replaceFirst('T', ' ')
                      .split('.')
                      .first,
                  (d.addressLabel ?? '').take(60),
                  _statusLabel(d.deliveryStatus),
                  d.accuracy.toStringAsFixed(0),
                  d.noAd ? 'Oui' : 'Non',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 8),
            if (rows.length > 300)
              pw.Text(
                'Note: PDF limité à 300 lignes (CSV contient tout).',
                style: const pw.TextStyle(fontSize: 10),
              ),
          ];
        },
      ),
    );

    final safeTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filename =
        'export_${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final file = await _writeFile(filename, await doc.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Export PDF - $title',
      text: 'Export PDF - $title',
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
    );
  }
}

extension _TakeString on String {
  String take(int n) => length <= n ? this : substring(0, n);
}