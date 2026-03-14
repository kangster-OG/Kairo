import { router } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { ShellHeader } from '@/src/features/app-shell/components/shell-header';
import { atlasTheme } from '@/src/theme/tokens';

export function NewProtocolPlaceholderScreen() {
  return (
    <AppScreen scroll>
      <View style={styles.container}>
        <ShellHeader
          description="This route establishes the real path into protocol creation without prematurely introducing schedule or logging logic."
          eyebrow="New protocol"
          title="Protocol setup is the next milestone"
        />

        <AppCard style={styles.heroCard}>
          <View style={styles.heroCopy}>
            <AppText style={styles.sectionLabel} variant="caption">
              Coming next
            </AppText>
            <AppText variant="heading">Choose the routine you want Atlas to track</AppText>
            <AppText variant="caption">
              The first implementation slice will add a structured local data layer and the actual protocol builder for GLP and peptide flows.
            </AppText>
          </View>
        </AppCard>

        <View style={styles.previewStack}>
          {[
            ['GLP protocol', 'Cadence, next due, logging, and inventory will anchor from this definition.'],
            ['Peptide protocol', 'Separate protocol records allow combined routines without merging history.'],
          ].map(([title, body]) => (
            <AppCard key={title} style={styles.previewCard}>
              <View style={styles.previewCopy}>
                <AppText variant="heading">{title}</AppText>
                <AppText variant="caption">{body}</AppText>
              </View>
            </AppCard>
          ))}
        </View>

        <AppButton
          label="Back to Library"
          onPress={() => {
            router.replace('/library');
          }}
          variant="secondary"
        />
      </View>
    </AppScreen>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.lg,
  },
  heroCard: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
  },
  heroCopy: {
    gap: atlasTheme.spacing.sm,
  },
  sectionLabel: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  previewStack: {
    gap: atlasTheme.spacing.md,
  },
  previewCard: {
    backgroundColor: atlasTheme.colors.surface,
  },
  previewCopy: {
    gap: atlasTheme.spacing.sm,
  },
});
