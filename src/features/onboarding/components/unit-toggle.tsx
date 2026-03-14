import { Pressable, StyleSheet, View } from 'react-native';

import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type UnitOption = {
  label: string;
  value: string;
};

type UnitToggleProps = {
  options: readonly [UnitOption, UnitOption];
  onChange: (value: string) => void;
  selectedValue: string | null;
};

export function UnitToggle({ options, onChange, selectedValue }: UnitToggleProps) {
  return (
    <View style={styles.container}>
      {options.map((option) => {
        const isSelected = option.value === selectedValue;

        return (
          <Pressable
            key={option.value}
            onPress={() => onChange(option.value)}
            style={[styles.option, isSelected ? styles.selected : null]}>
            <AppText style={isSelected ? styles.selectedLabel : null}>{option.label}</AppText>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
    borderRadius: atlasTheme.radii.pill,
    flexDirection: 'row',
    padding: 4,
  },
  option: {
    alignItems: 'center',
    borderRadius: atlasTheme.radii.pill,
    flex: 1,
    paddingVertical: atlasTheme.spacing.sm,
  },
  selected: {
    backgroundColor: atlasTheme.colors.surface,
  },
  selectedLabel: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
  },
});
