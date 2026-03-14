import { StyleSheet, View } from 'react-native';

import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type StatusPillTone = 'default' | 'success' | 'muted';

type StatusPillProps = {
  label: string;
  tone?: StatusPillTone;
};

export function StatusPill({ label, tone = 'default' }: StatusPillProps) {
  return (
    <View style={[styles.pill, containerToneStyles[tone]]}>
      <AppText style={labelToneStyles[tone]} variant="caption">
        {label}
      </AppText>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    alignSelf: 'flex-start',
    borderRadius: atlasTheme.radii.pill,
    paddingHorizontal: 14,
    paddingVertical: 8,
  },
});

const containerToneStyles = StyleSheet.create({
  default: {
    backgroundColor: atlasTheme.colors.surfaceGlow,
  },
  success: {
    backgroundColor: '#EAF8F0',
  },
  muted: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
  },
});

const labelToneStyles = StyleSheet.create({
  default: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
  },
  success: {
    color: atlasTheme.colors.success,
    fontWeight: '700',
  },
  muted: {
    color: atlasTheme.colors.textSecondary,
    fontWeight: '700',
  },
});
