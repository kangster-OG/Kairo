import * as LocalAuthentication from 'expo-local-authentication';

import type { BiometricGateMode } from '@/src/lib/database/schemas';

export type BiometricGateClient = {
  authenticateAsync: typeof LocalAuthentication.authenticateAsync;
  getEnrolledLevelAsync: typeof LocalAuthentication.getEnrolledLevelAsync;
  hasHardwareAsync: typeof LocalAuthentication.hasHardwareAsync;
  isEnrolledAsync: typeof LocalAuthentication.isEnrolledAsync;
};

export type BiometricGateResult = {
  attempted: boolean;
  granted: boolean;
  reason: 'disabled' | 'no_hardware' | 'not_enrolled' | 'granted' | 'denied';
};

export async function runSensitiveActionGate(
  {
    client = LocalAuthentication,
    gateMode,
    promptMessage,
    requiresLock,
  }: {
    client?: BiometricGateClient;
    gateMode: BiometricGateMode;
    promptMessage: string;
    requiresLock: boolean;
  }
): Promise<BiometricGateResult> {
  if (!requiresLock || gateMode === 'off') {
    return {
      attempted: false,
      granted: true,
      reason: 'disabled',
    };
  }

  const [hasHardware, isEnrolled] = await Promise.all([
    client.hasHardwareAsync(),
    client.isEnrolledAsync(),
  ]);

  if (!hasHardware) {
    return {
      attempted: false,
      granted: gateMode !== 'required_when_available',
      reason: 'no_hardware',
    };
  }

  if (!isEnrolled) {
    return {
      attempted: false,
      granted: gateMode !== 'required_when_available',
      reason: 'not_enrolled',
    };
  }

  const result = await client.authenticateAsync({
    promptMessage,
  });

  return {
    attempted: true,
    granted: result.success,
    reason: result.success ? 'granted' : 'denied',
  };
}
