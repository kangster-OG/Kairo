import { useLocalSearchParams } from 'expo-router';

import { ProtocolDetailScreen } from '@/src/features/protocol-changes/screens/protocol-detail-screen';

export default function ProtocolDetailRoute() {
  const params = useLocalSearchParams<{ protocolId?: string | string[] }>();
  const protocolId = Array.isArray(params.protocolId) ? params.protocolId[0] : params.protocolId;

  if (!protocolId) {
    return null;
  }

  return <ProtocolDetailScreen protocolId={protocolId} />;
}
