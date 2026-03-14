import { Component, type ErrorInfo, type ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';

import { AppText } from '@/src/components/ui/app-text';
import { atlasTheme } from '@/src/theme/tokens';

type Props = {
  children: ReactNode;
};

type State = {
  errorMessage: string | null;
};

export class AppErrorBoundary extends Component<Props, State> {
  state: State = {
    errorMessage: null,
  };

  static getDerivedStateFromError(error: Error): State {
    return {
      errorMessage: error.message,
    };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('[Atlas] Root render failed.', error, info.componentStack);
  }

  render() {
    if (!this.state.errorMessage) {
      return this.props.children;
    }

    return (
      <View style={styles.container}>
        <AppText variant="display">Atlas</AppText>
        <AppText variant="heading">A runtime error blocked the app shell.</AppText>
        <AppText variant="caption">{this.state.errorMessage}</AppText>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    backgroundColor: atlasTheme.colors.background,
    flex: 1,
    gap: atlasTheme.spacing.md,
    justifyContent: 'center',
    paddingHorizontal: atlasTheme.screenPadding,
  },
});
