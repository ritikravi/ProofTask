'use strict';

const axios = require('axios');

function parseCommitUrl(input) {
  const m = input
    .trim()
    .match(/^https?:\/\/(?:www\.)?github\.com\/([\w.-]+)\/([\w.-]+)\/(commit|pull)\/([\w]+)/i);
  if (!m) return null;
  return { owner: m[1], repo: m[2], kind: m[3].toLowerCase(), id: m[4] };
}

async function fetchCommitInfo(ref, token = '') {
  const base = `https://api.github.com/repos/${ref.owner}/${ref.repo}`;
  const headers = {
    Accept: 'application/vnd.github+json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };

  try {
    if (ref.kind === 'commit') {
      const res = await axios.get(`${base}/commits/${ref.id}`, { headers, timeout: 12_000 });
      const { commit, files = [], stats = {} } = res.data;
      const date = new Date(commit.committer.date);
      const patchBlock = files
        .slice(0, 10)
        .map((f) => `--- ${f.filename} (${f.status})\n${(f.patch || '').slice(0, 800)}`)
        .join('\n');
      return {
        date,
        summary:
          `Commit message: ${commit.message}\n` +
          `Committed: ${date.toISOString()}\n` +
          `+${stats.additions ?? '?'} / -${stats.deletions ?? '?'} lines in ${files.length} files\n` +
          patchBlock,
      };
    }

    const [prRes, filesRes] = await Promise.all([
      axios.get(`${base}/pulls/${ref.id}`, { headers, timeout: 12_000 }),
      axios.get(`${base}/pulls/${ref.id}/files`, { headers, timeout: 12_000 }),
    ]);
    const pr = prRes.data;
    const prFiles = filesRes.data || [];
    const date = new Date(pr.created_at);
    const patchBlock = prFiles
      .slice(0, 10)
      .map((f) => `--- ${f.filename} (${f.status})\n${(f.patch || '').slice(0, 800)}`)
      .join('\n');
    return {
      date,
      summary:
        `Pull request: ${pr.title}\n${pr.body || ''}\n` +
        `Opened: ${date.toISOString()}\n` +
        `+${pr.additions} / -${pr.deletions} lines in ${pr.changed_files} files\n` +
        patchBlock,
    };
  } catch (err) {
    const code = err.response?.status;
    throw new Error(
      code === 404
        ? 'GitHub says that commit or PR does not exist (or is private).'
        : code === 403 || code === 429
        ? 'GitHub rate-limited the request.'
        : `Could not reach GitHub${code ? ` (HTTP ${code})` : ''}.`,
    );
  }
}

module.exports = { parseCommitUrl, fetchCommitInfo };
