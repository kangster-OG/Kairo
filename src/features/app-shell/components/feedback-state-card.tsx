import { ActivityIndicator, StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type FeedbackStateCardProps = {
  actionLabel?: string;
  body: string;
  isLoading?: boolean;
  onAction?: () => void;
  title: string;
};

export function FeedbackStateCard({
  actionLabel,
  body,
  isLoading = false,
  onAction,
  title,
}: FeedbackStateCardProps) {
  return (
    <AppCard style={styles.card}>
      <View style={styles.copy}>
        {isLoading ? <ActivityIndicator color={atlasTheme.colors.primary} /> : null}
        <AppText variant="heading">{title}</AppText>
        <AppText variant="caption">{body}</AppText>
      </View>
      {actionLabel && onAction ? (
        <AppButton
          accessibilityHint={body}
          label={actionLabel}
          onPress={onAction}
          variant="secondary"
        />
      ) : null}
    </AppCard>
  );
}

const styles = StyleSheet.create({
  card: {
    gap: atlasTheme.spacing.md,
  },
  copy: {
    gap: atlasTheme.spacing.sm,
  },
});
