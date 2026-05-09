import { API_ORIGIN } from './config';

function normalizeRelativeStorageKey(rel: string): string {
  const r = rel.replace(/^\//, '');
  if (!r.includes('/') && /\.(jpe?g|png|gif|webp|svg)$/i.test(r)) {
    return `medicine/${r}`;
  }
  return r;
}

function fixLegacyAbsoluteStorageUrl(urlString: string): string {
  try {
    const u = new URL(urlString);
    const path = u.pathname;
    if (path.startsWith('/storage/')) return urlString;
    if (/^\/(medicine|prescription|others)\//.test(path)) {
      u.pathname = `/storage${path}`;
      return u.toString();
    }
  } catch {
    /* ignore */
  }
  return urlString;
}

/** Same rules as `new_balan_fe` `getStorageFileUrl` for medicine images / uploads */
export function getStorageFileUrl(storedPath: string | null | undefined): string {
  if (!storedPath || typeof storedPath !== 'string') return '';
  const p = storedPath.trim();
  if (!p) return '';

  if (/^https?:\/\//i.test(p)) {
    return fixLegacyAbsoluteStorageUrl(p);
  }

  const base = API_ORIGIN.replace(/\/$/, '');
  const rel = normalizeRelativeStorageKey(p.replace(/^\//, ''));

  if (/^(medicines|prescriptions|others)\//.test(rel)) {
    return `${base}/api/v1/storage/signed?path=${encodeURIComponent(rel)}`;
  }

  if (p.startsWith('/storage/')) return `${base}${p}`;
  if (rel.startsWith('storage/')) return `${base}/${rel}`;
  return `${base}/storage/${rel}`;
}
