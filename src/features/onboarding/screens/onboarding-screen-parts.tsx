import { StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppText } from '@/src/components/ui/app-text';
import { AnswerOptionButton } from '@/src/features/onboarding/components/answer-option-button';
import { BottomCTA } from '@/src/features/onboarding/components/bottom-cta';
import { MultiSelectOptionButton } from '@/src/features/onboarding/components/multi-select-option-button';
import { OnboardingScaffold } from '@/src/features/onboarding/components/onboarding-scaffold';
import { UnitToggle } from '@/src/features/onboarding/components/unit-toggle';
import { WheelPickerField } from '@/src/features/onboarding/components/wheel-picker-field';
import type { HeightUnit, WeightUnit } from '@/src/features/onboarding/helpers';
import { atlasTheme } from '@/src/theme/tokens';

type BaseScreenProps = {
  currentStep: number;
  description: string;
  onBackPress?: () => void;
  title: string;
  totalSteps: number;
};

type Option<T extends string> = {
  description?: string;
  label: string;
  value: T;
};

export type SingleSelectScreenProps<T extends string> = BaseScreenProps & {
  onContinue: () => void;
  onSelect: (value: T) => void;
  options: Option<T>[];
  selectedValue: T | null | undefined;
};

export function SingleSelectScreen<T extends string>({
  currentStep,
  description,
  onBackPress,
  onContinue,
  onSelect,
  options,
  selectedValue,
  title,
  totalSteps,
}: SingleSelectScreenProps<T>) {
  return (
    <OnboardingScaffold
      currentStep={currentStep}
      description={description}
      footer={<BottomCTA disabled={!selectedValue} label="Continue" onPress={onContinue} />}
      onBackPress={onBackPress}
      title={title}
      totalSteps={totalSteps}>
      <View style={styles.optionStack}>
        {options.map((option) => (
          <AnswerOptionButton
            key={option.value}
            description={option.description}
            isSelected={selectedValue === option.value}
            label={option.label}
            onPress={() => onSelect(option.value)}
          />
        ))}
      </View>
    </OnboardingScaffold>
  );
}

export type MultiToggleScreenProps = BaseScreenProps & {
  onContinue: () => void;
  onToggle: (value: string) => void;
  options: Option<string>[];
  selectedValues: Record<string, boolean>;
  useCheckboxStyle?: boolean;
};

export function MultiToggleScreen({
  currentStep,
  description,
  onBackPress,
  onContinue,
  onToggle,
  options,
  selectedValues,
  title,
  totalSteps,
  useCheckboxStyle = false,
}: MultiToggleScreenProps) {
  return (
    <OnboardingScaffold
      currentStep={currentStep}
      description={description}
      footer={<BottomCTA label="Continue" onPress={onContinue} />}
      onBackPress={onBackPress}
      title={title}
      totalSteps={totalSteps}>
      <View style={styles.optionStack}>
        {options.map((option) =>
          useCheckboxStyle ? (
            <MultiSelectOptionButton
              key={option.value}
              isSelected={selectedValues[option.value] ?? false}
              label={option.label}
              onPress={() => onToggle(option.value)}
            />
          ) : (
            <AnswerOptionButton
              key={option.value}
              description={option.description}
              isSelected={selectedValues[option.value] ?? false}
              label={option.label}
              onPress={() => onToggle(option.value)}
            />
          )
        )}
      </View>
    </OnboardingScaffold>
  );
}

export type NumberQuestionScreenProps = BaseScreenProps & {
  helperText: string;
  onChange: (value: number | null) => void;
  onContinue: () => void;
  onSkip: () => void;
  step: number;
  unitLabel: string;
  value: number | null;
  valueRange: {
    max: number;
    min: number;
  };
};

export function NumberQuestionScreen({
  currentStep,
  description,
  helperText,
  onBackPress,
  onChange,
  onContinue,
  onSkip,
  step,
  title,
  totalSteps,
  unitLabel,
  value,
  valueRange,
}: NumberQuestionScreenProps) {
  const displayValue = value === null ? `-${unitLabel ? ` ${unitLabel}` : ''}` : `${value} ${unitLabel}`;
  const canDecrease = value !== null && value > valueRange.min;

  return (
    <OnboardingScaffold
      currentStep={currentStep}
      description={description}
      footer={
        <View style={styles.footerStack}>
          <BottomCTA label="Continue" onPress={onContinue} />
          <AppButton label="Skip for now" onPress={onSkip} variant="ghost" />
        </View>
      }
      onBackPress={onBackPress}
      title={title}
      totalSteps={totalSteps}>
      <WheelPickerField
        decrementDisabled={!canDecrease}
        helperText={helperText}
        label="Mocked wheel picker"
        onDecrease={() => {
          onChange(value === null ? valueRange.min : Math.max(value - step, valueRange.min));
        }}
        onIncrease={() => {
          onChange(value === null ? valueRange.min : Math.min(value + step, valueRange.max));
        }}
        valueLabel={displayValue.trim()}
      />
    </OnboardingScaffold>
  );
}

export type DualMetricScreenProps = BaseScreenProps & {
  heightDisplay: string;
  heightUnit: HeightUnit;
  onChangeHeightUnit: (unit: HeightUnit) => void;
  onChangeWeightUnit: (unit: WeightUnit) => void;
  onContinue: () => void;
  onDecreaseHeight: () => void;
  onDecreaseWeight: () => void;
  onIncreaseHeight: () => void;
  onIncreaseWeight: () => void;
  onSkip: () => void;
  weightDisplay: string;
  weightUnit: WeightUnit;
};

export function DualMetricScreen({
  currentStep,
  description,
  heightDisplay,
  heightUnit,
  onBackPress,
  onChangeHeightUnit,
  onChangeWeightUnit,
  onContinue,
  onDecreaseHeight,
  onDecreaseWeight,
  onIncreaseHeight,
  onIncreaseWeight,
  onSkip,
  title,
  totalSteps,
  weightDisplay,
  weightUnit,
}: DualMetricScreenProps) {
  return (
    <OnboardingScaffold
      currentStep={currentStep}
      description={description}
      footer={
        <View style={styles.footerStack}>
          <BottomCTA label="Continue" onPress={onContinue} />
          <AppButton label="Skip for now" onPress={onSkip} variant="ghost" />
        </View>
      }
      onBackPress={onBackPress}
      title={title}
      totalSteps={totalSteps}>
      <AppCard style={styles.metricCard}>
        <AppText style={styles.metricLabel}>Height unit</AppText>
        <UnitToggle
          onChange={(value) => onChangeHeightUnit(value as HeightUnit)}
          options={[
            { label: 'CM', value: 'cm' },
            { label: 'FT/IN', value: 'ft_in' },
          ]}
          selectedValue={heightUnit}
        />
      </AppCard>

      <WheelPickerField
        helperText="Mocked wheel-style control for current height."
        label="Height"
        onDecrease={onDecreaseHeight}
        onIncrease={onIncreaseHeight}
        tone="muted"
        valueLabel={heightDisplay}
      />

      <AppCard style={styles.metricCard}>
        <AppText style={styles.metricLabel}>Weight unit</AppText>
        <UnitToggle
          onChange={(value) => onChangeWeightUnit(value as WeightUnit)}
          options={[
            { label: 'KG', value: 'kg' },
            { label: 'LB', value: 'lb' },
          ]}
          selectedValue={weightUnit}
        />
      </AppCard>

      <WheelPickerField
        helperText="Mocked wheel-style control for current weight."
        label="Weight"
        onDecrease={onDecreaseWeight}
        onIncrease={onIncreaseWeight}
        tone="muted"
        valueLabel={weightDisplay}
      />
    </OnboardingScaffold>
  );
}

const styles = StyleSheet.create({
  footerStack: {
    gap: atlasTheme.spacing.sm,
  },
  optionStack: {
    gap: atlasTheme.spacing.sm,
  },
  metricCard: {
    gap: atlasTheme.spacing.sm,
  },
  metricLabel: {
    color: atlasTheme.colors.textSecondary,
    fontWeight: '600',
  },
});
