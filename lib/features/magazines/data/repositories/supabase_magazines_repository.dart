import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/magazine.dart';
import '../../domain/repositories/magazines_repository.dart';
import '../models/magazine_model.dart';

class SupabaseMagazinesRepository implements MagazinesRepository {
  SupabaseMagazinesRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'magazines';
  static const _bucket = 'magazines';

  /// Reads never fail the UI: a missing table, column or policy (migration
  /// not applied yet) or a network error reads as "no magazines".
  @override
  Future<List<Magazine>> fetchActiveMagazines() async {
    final today = MagazineModel.dateOnly(DateTime.now());
    return _readOrEmpty(
      () => _client
          .from(_table)
          .select()
          .lte('start_date', today)
          .gte('end_date', today)
          .order('start_date', ascending: false),
    );
  }

  @override
  Future<List<Magazine>> fetchAllMagazines() {
    return _readOrEmpty(
      () => _client
          .from(_table)
          .select()
          .order('start_date', ascending: false)
          .order('created_at', ascending: false),
    );
  }

  static Future<List<Magazine>> _readOrEmpty(
    Future<List<Map<String, dynamic>>> Function() query,
  ) async {
    try {
      final rows = await query();
      return rows.map(MagazineModel.fromJson).toList();
    } catch (error, stackTrace) {
      developer.log(
        'Could not load magazines; showing none',
        name: 'magazines',
        error: error,
        stackTrace: stackTrace,
      );
      return const [];
    }
  }

  @override
  Future<Magazine> createMagazine({
    required String title,
    required Uint8List coverBytes,
    required String coverFileName,
    required Uint8List pdfBytes,
    required String pdfFileName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final coverExt = _extension(coverFileName, fallback: 'jpg');
    final coverPath = 'covers/$stamp.$coverExt';
    final pdfPath = 'pdfs/$stamp.pdf';

    final storage = _client.storage.from(_bucket);
    await storage.uploadBinary(
      coverPath,
      coverBytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: switch (coverExt) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        },
      ),
    );
    await storage.uploadBinary(
      pdfPath,
      pdfBytes,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'application/pdf',
      ),
    );

    final row = await _client
        .from(_table)
        .insert(
          MagazineModel.toInsertJson(
            title: title.trim(),
            coverImageUrl: storage.getPublicUrl(coverPath),
            pdfUrl: storage.getPublicUrl(pdfPath),
            startDate: startDate,
            endDate: endDate,
          ),
        )
        .select()
        .single();
    return MagazineModel.fromJson(row);
  }

  @override
  Future<void> deleteMagazine(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  static String _extension(String fileName, {required String fallback}) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return fallback;
    final ext = fileName.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'jpg',
      'png' => 'png',
      'webp' => 'webp',
      _ => fallback,
    };
  }
}
