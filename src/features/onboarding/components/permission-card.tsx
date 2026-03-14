import { StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type PermissionCardProps = {
  actionLabel: string;
  body: string;
  onPress: () => void;
  title: string;
};

export function PermissionCard({ actionLabel, body, onPress, title }: PermissionCardProps) {
  return (
    <AppCard>
      <View style={styles.container}>
        <AppText style={styles.title} variant="heading">
          {title}
        </AppText>
        <AppText variant="caption">{body}</AppText>
        <AppButton label={actionLabel} onPress={onPress} variant="secondary" />
      </View>
    </AppCard>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.md,
  },
  title: {
    fontSize: 20,
  },
});
