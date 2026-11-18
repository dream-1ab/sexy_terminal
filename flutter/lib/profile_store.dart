import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'profile_models.dart';

class ProfileStore {
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
    profiles.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return profiles;
  }

  Future<void> saveProfile(WorkspaceProfile profile) async {
    final directory = await _profilesDirectory();
    final file = File('${directory.path}/${profile.id}.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(profile.toJson()),
    );
  }

  Future<void> deleteProfile(String id) async {
    final directory = await _profilesDirectory();
    final file = File('${directory.path}/$id.json');
    if (await file.exists()) await file.delete();
  }
}
