import 'package:dio/dio.dart';

import 'url_fetcher.dart';

enum CommitKind { commit, pull }

class CommitRef {
  const CommitRef(this.owner, this.repo, this.kind, this.id);
  final String owner;
  final String repo;
  final CommitKind kind;
  final String id;
}

/// Parses github.com/{o}/{r}/commit/{sha} and /pull/{n} URLs.
CommitRef? parseCommitUrl(String input) {
  final m = RegExp(
    r'^https?://(?:www\.)?github\.com/([\w.-]+)/([\w.-]+)/(commit|pull)/([\w]+)',
    caseSensitive: false,
  ).firstMatch(input.trim());
  if (m == null) return null;
  final kind = m.group(3)!.toLowerCase() == 'pull'
      ? CommitKind.pull
      : CommitKind.commit;
  return CommitRef(m.group(1)!, m.group(2)!, kind, m.group(4)!);
}

class CommitInfo {
  const CommitInfo({required this.date, required this.summary});

  /// When the commit was made / the PR was opened.
  final DateTime date;
  final String summary;
}

const _maxPatch = 6000;

Future<CommitInfo> fetchCommitInfo(
  Dio dio,
  CommitRef r, {
  String? token,
}) async {
  final opts = Options(
    receiveTimeout: const Duration(seconds: 12),
    headers: {
      'Accept': 'application/vnd.github+json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    },
  );
  final base = 'https://api.github.com/repos/${r.owner}/${r.repo}';
  try {
    if (r.kind == CommitKind.commit) {
      final res = await dio.get<Map<String, dynamic>>(
        '$base/commits/${r.id}',
        options: opts,
      );
      final j = res.data!;
      final commit = j['commit'] as Map<String, dynamic>;
      final date = DateTime.parse(
        (commit['committer'] as Map)['date'] as String,
      );
      final files = (j['files'] as List? ?? const []).cast<Map>();
      final stats = j['stats'] as Map? ?? const {};
      return CommitInfo(
        date: date,
        summary:
            'Commit message: ${commit['message']}\n'
            'Committed: ${date.toIso8601String()}\n'
            '+${stats['additions'] ?? '?'} / -${stats['deletions'] ?? '?'} lines in ${files.length} files\n'
            '${_filesBlock(files)}',
      );
    }
    final pr = (await dio.get<Map<String, dynamic>>(
      '$base/pulls/${r.id}',
      options: opts,
    )).data!;
    final files =
        ((await dio.get<List<dynamic>>(
                  '$base/pulls/${r.id}/files',
                  options: opts,
                )).data ??
                const [])
            .cast<Map>();
    final date = DateTime.parse(pr['created_at'] as String);
    return CommitInfo(
      date: date,
      summary:
          'Pull request: ${pr['title']}\n${pr['body'] ?? ''}\n'
          'Opened: ${date.toIso8601String()}\n'
          '+${pr['additions']} / -${pr['deletions']} lines in ${pr['changed_files']} files\n'
          '${_filesBlock(files)}',
    );
  } on DioException catch (e) {
    final code = e.response?.statusCode;
    throw FetchException(switch (code) {
      404 => 'GitHub says that commit or PR does not exist (or is private; add a token in Settings).',
      403 || 429 => 'GitHub rate-limited the request. Add a token in Settings.',
      _ => 'Could not reach GitHub${code != null ? ' (HTTP $code)' : ''}.',
    });
  }
}

String _filesBlock(List<Map> files) {
  final b = StringBuffer();
  for (final f in files) {
    b.writeln('--- ${f['filename']} (${f['status']})');
    final patch = (f['patch'] as String?) ?? '';
    if (b.length + patch.length > _maxPatch) {
      b.writeln(
        patch.substring(0, (_maxPatch - b.length).clamp(0, patch.length)),
      );
      b.writeln('[diff truncated]');
      break;
    }
    b.writeln(patch);
  }
  return b.toString();
}
