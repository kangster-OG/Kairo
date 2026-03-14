import type { ReactNode } from 'react';

import { StyleSheet, View } from 'react-native';

import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type ShellHeaderProps = {
  eyebrow: string;
  title: string;
  description: string;
  trailing?: ReactNode;
};

export function ShellHeader({
  eyebrow,
  title,
  description,
  trailing,
}: ShellHeaderProps) {
  return (
    <View style={styles.container}>
      <View style={styles.copy}>
        <AppText style={styles.eyebrow} variant="caption">
          {eyebrow}
        </AppText>
        <AppText variant="title">{title}</AppText>
        <AppText variant="caption">{description}</AppText>
      </View>
      {trailing ? <View style={styles.trailing}>{trailing}</View> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.md,
  },
  copy: {
    gap: atlasTheme.spacing.xs,
  },
  eyebrow: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    letterSpacing: 0.8,
    textTransform: 'uppercase',
  },
  trailing: {
    alignItems: 'flex-start',
  },
});
