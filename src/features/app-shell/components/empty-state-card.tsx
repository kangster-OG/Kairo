import { StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type EmptyStateCardProps = {
  eyebrow: string;
  title: string;
  body: string;
  primaryActionLabel?: string;
  onPrimaryAction?: () => void;
  secondaryActionLabel?: string;
  onSecondaryAction?: () => void;
};

export function EmptyStateCard({
  eyebrow,
  title,
  body,
  primaryActionLabel,
  onPrimaryAction,
  secondaryActionLabel,
  onSecondaryAction,
}: EmptyStateCardProps) {
  return (
    <AppCard style={styles.card}>
      <View style={styles.copy}>
        <AppText style={styles.eyebrow} variant="caption">
          {eyebrow}
        </AppText>
        <AppText variant="heading">{title}</AppText>
        <AppText variant="caption">{body}</AppText>
      </View>

      {primaryActionLabel && onPrimaryAction ? (
        <View style={styles.actions}>
          <AppButton label={primaryActionLabel} onPress={onPrimaryAction} />
          {secondaryActionLabel && onSecondaryAction ? (
            <AppButton
              label={secondaryActionLabel}
              onPress={onSecondaryAction}
              variant="ghost"
            />
          ) : null}
        </View>
      ) : null}
    </AppCard>
  );
}

const styles = StyleSheet.create({
  card: {
    gap: atlasTheme.spacing.lg,
  },
  copy: {
    gap: atlasTheme.spacing.sm,
  },
  actions: {
    gap: atlasTheme.spacing.sm,
  },
  eyebrow: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    letterSpacing: 0.6,
    textTransform: 'uppercase',
  },
});
