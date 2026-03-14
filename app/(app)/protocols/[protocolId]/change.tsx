import { useLocalSearchParams } from 'expo-router';

import { ProtocolChangeStudioScreen } from '@/src/features/protocol-changes/screens/protocol-change-studio-screen';

export default function ProtocolChangeStudioRoute() {
  const params = useLocalSearchParams<{ protocolId?: string | string[] }>();
  const protocolId = Array.isArray(params.protocolId) ? params.protocolId[0] : params.protocolId;

  if (!protocolId) {
    return null;
  }

  return <ProtocolChangeStudioScreen protocolId={protocolId} />;
}
