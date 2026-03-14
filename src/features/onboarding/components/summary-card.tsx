import { StyleSheet, View } from 'react-native';

import { AppCard } from '@/src/components/ui/app-card';
import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type SummaryItem = {
  label: string;
  value: string;
};

type SummaryCardProps = {
  items: SummaryItem[];
  title: string;
};

export function SummaryCard({ items, title }: SummaryCardProps) {
  return (
    <AppCard>
      <View style={styles.container}>
        <AppText style={styles.title} variant="heading">
          {title}
        </AppText>
        {items.map((item) => (
          <View key={item.label} style={styles.row}>
            <AppText variant="caption">{item.label}</AppText>
            <AppText>{item.value}</AppText>
          </View>
        ))}
      </View>
    </AppCard>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.sm,
  },
  title: {
    fontSize: 20,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
});
