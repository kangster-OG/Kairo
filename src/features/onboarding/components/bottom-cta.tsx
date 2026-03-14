import { StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { atlasTheme } from '@/src/theme/tokens';

type BottomCTAProps = {
  disabled?: boolean;
  label: string;
  onPress: () => void;
};

export function BottomCTA({ disabled = false, label, onPress }: BottomCTAProps) {
  return (
    <View style={styles.container}>
      <AppButton disabled={disabled} label={label} onPress={onPress} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingBottom: atlasTheme.spacing.xl,
    width: '100%',
  },
});
