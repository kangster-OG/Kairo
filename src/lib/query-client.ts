import { QueryClient } from '@tanstack/react-query';

export const atlasQueryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 30_000,
    },
  },
});
