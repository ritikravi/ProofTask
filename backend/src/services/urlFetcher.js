'use strict';

const axios = require('axios');

/**
 * Server-side SSRF guard — mirrors the Flutter url_guard.dart logic.
 * Blocks private/loopback/link-local/metadata addresses.
 */
function isSafePublicUrl(url) {
  if (url.protocol !== 'http:' && url.protocol !== 'https:') return false;
  const h = url.hostname.toLowerCase();
  if (!h) return false;
  if (h === 'localhost' || h.endsWith('.localhost') || h.endsWith('.local') || h.endsWith('.internal')) return false;

  // IPv6
  if (h.includes(':')) {
    return !(h === '::' || h === '::1' || h.startsWith('fc') || h.startsWith('fd') || h.startsWith('fe80'));
  }

  // IPv4
  const parts = h.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
  if (parts) {
    const o = parts.slice(1).map(Number);
    if (o.some((x) => x > 255)) return false;
    if (o[0] === 0 || o[0] === 10 || o[0] === 127) return false;
    if (o[0] === 169 && o[1] === 254) return false;
    if (o[0] === 172 && o[1] >= 16 && o[1] <= 31) return false;
    if (o[0] === 192 && o[1] === 168) return false;
  }
  return true;
}

async function fetchPage(rawUrl) {
  const res = await axios.get(rawUrl, {
    timeout: 10_000,
    maxRedirects: 4,
    responseType: 'text',
    headers: { 'User-Agent': 'ProofTask-Verifier/1.0' },
  });
  const html = res.data || '';
  // Extract title
  const titleMatch = html.match(/<title[^>]*>([^<]*)<\/title>/i);
  const title = titleMatch ? titleMatch[1].trim() : '';
  // Extract meta description
  const descMatch = html.match(/<meta[^>]+name=["']description["'][^>]+content=["']([^"']*)["']/i)
    || html.match(/<meta[^>]+content=["']([^"']*)["'][^>]+name=["']description["']/i);
  const description = descMatch ? descMatch[1].trim() : '';
  // Strip tags and normalize text
  const text = html
    .replace(/<script[\s\S]*?<\/script>/gi, '')
    .replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 6000);

  if (!text && !title) throw new Error('The page had no readable text.');
  return { title, description, text, summary: `Title: ${title}\nDescription: ${description}\nContent:\n${text}` };
}

module.exports = { isSafePublicUrl, fetchPage };
