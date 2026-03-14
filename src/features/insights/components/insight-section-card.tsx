import type { PropsWithChildren } from 'react';

import { StyleSheet, View } from 'react-native';

import { AppCard } from '@/src/components/ui/app-card';
import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type InsightSectionCardProps = PropsWithChildren<{
  description?: string;
  eyebrow?: string;
  title: string;
}>;

export function InsightSectionCard({
  children,
  description,
  eyebrow,
  title,
}: InsightSectionCardProps) {
  return (
    <AppCard style={styles.card}>
      <View style={styles.header}>
        {eyebrow ? (
          <AppText style={styles.eyebrow} variant="caption">
            {eyebrow}
          </AppText>
        ) : null}
        <AppText variant="heading">{title}</AppText>
        {description ? <AppText variant="caption">{description}</AppText> : null}
      </View>
      <View style={styles.body}>{children}</View>
    </AppCard>
  );
}

const styles = StyleSheet.create({
  card: {
    gap: atlasTheme.spacing.md,
  },
  header: {
    gap: atlasTheme.spacing.xs,
  },
  eyebrow: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
  body: {
    gap: atlasTheme.spacing.md,
  },
});
