// Lightweight typed data-fetching hooks for the ClickerPro web app.
//
// These wrap the existing `api()` client and the `unwrapList`/`unwrap`
// helpers to give pages a typed, consistent { data, loading, error, reload }
// shape — removing the per-page loading/error boilerplate and `any` usage.
//
// Existing pages keep working as-is; new code should prefer these hooks.
// (No external dep; for caching/dedup, consider TanStack Query later.)

import { useCallback, useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { unwrapList, unwrap } from '@/types/api';

interface ListState<T> {
  data: T[];
  loading: boolean;
  error: string;
  reload: () => void;
}

/** Fetch a list endpoint, typed. */
export function useApiList<T>(path: string): ListState<T> {
  const [data, setData] = useState<T[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api<unknown>(path);
      setData(unwrapList<T>(res));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load');
    } finally {
      setLoading(false);
    }
  }, [path]);

  useEffect(() => { load(); }, [load]);

  return { data, loading, error, reload: load };
}

interface ItemState<T> {
  data: T | null;
  loading: boolean;
  error: string;
  reload: () => void;
}

/** Fetch a single-item endpoint, typed. */
export function useApiItem<T>(path: string | null): ItemState<T> {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(!!path);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    if (!path) return;
    setLoading(true);
    setError('');
    try {
      const res = await api<unknown>(path);
      setData(unwrap<T>(res));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load');
    } finally {
      setLoading(false);
    }
  }, [path]);

  useEffect(() => { load(); }, [load]);

  return { data, loading, error, reload: load };
}
