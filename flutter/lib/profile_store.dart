import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'profile_models.dart';

class ProfileStore {
  static final _pendingSaves = <String, _PendingProfileSave>{};
  Future<Directory> _profilesDirectory() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final directory = Directory('${supportDirectory.path}/profiles');
    await directory.create(recursive: true);
    return directory;
  }

  Future<List<WorkspaceProfile>> loadProfiles() async {
    final directory = await _profilesDirectory();
    final profiles = <WorkspaceProfile>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final json = jsonDecode(await entity.readAsString());
        profiles.add(WorkspaceProfile.fromJson(json as Map<String, dynamic>));
      } on FormatException {
        // Ignore malformed profile files and keep loading usable profiles.
      }
    }
    profiles.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return profiles;
  }

  Future<void> saveProfile(WorkspaceProfile profile) async {
    final pending = _pendingSaves.putIfAbsent(
      profile.id,
      () => _PendingProfileSave(profile),
    );
    pending.profile = profile;
    pending.timer?.cancel();
    pending.timer = Timer(const Duration(milliseconds: 500), () async {
      try {
        await _writeProfile(pending.profile);
        pending.completer.complete();
      } catch (error, stackTrace) {
        pending.completer.completeError(error, stackTrace);
      } finally {
        _pendingSaves.remove(profile.id);
      }
    });
    return pending.completer.future;
  }

  Future<void> _writeProfile(WorkspaceProfile profile) async {
    final directory = await _profilesDirectory();
    final file = File('${directory.path}/${profile.id}.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(profile.toJson()),
    );
    if (kDebugMode) {
      debugPrint(
        '[ProfileStore] Stored workspace profile "${profile.name}" '
        '(${profile.id}).',
      );
    }
  }

  /// Immediately writes a profile and cancels any pending debounced write.
  Future<void> flushProfile(WorkspaceProfile profile) async {
    final pending = _pendingSaves.remove(profile.id);
    pending?.timer?.cancel();
    try {
      await _writeProfile(profile);
      if (pending != null && !pending.completer.isCompleted) {
        pending.completer.complete();
      }
    } catch (error, stackTrace) {
      if (pending != null && !pending.completer.isCompleted) {
        pending.completer.completeError(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> deleteProfile(String id) async {
    final pending = _pendingSaves.remove(id);
    pending?.timer?.cancel();
    pending?.completer.complete();
    final directory = await _profilesDirectory();
    final file = File('${directory.path}/$id.json');
    if (await file.exists()) await file.delete();
  }
}

class _PendingProfileSave {
  _PendingProfileSave(this.profile);

  WorkspaceProfile profile;
  Timer? timer;
  final completer = Completer<void>();
}
