import { useMutation } from '@tanstack/react-query';

import {
  createAtlasExport,
  type AtlasExportFormat,
} from '@/src/lib/export/service';

export function useCreateAtlasExportMutation(format: AtlasExportFormat) {
  return useMutation({
    mutationFn: () => createAtlasExport(format),
  });
}
