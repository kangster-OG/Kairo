import type { ComponentProps } from 'react';

import { Ionicons } from '@expo/vector-icons';
import { Tabs } from 'expo-router';

import { atlasTheme } from '@/src/theme/tokens';

export default function AppTabsLayout() {
  return (
    <Tabs
      screenOptions={({ route }) => ({
        headerShown: false,
        tabBarActiveTintColor: atlasTheme.colors.primary,
        tabBarInactiveTintColor: atlasTheme.colors.textSecondary,
        tabBarLabelStyle: {
          fontFamily: atlasTheme.typography.bodyFamily,
          fontSize: 12,
          fontWeight: '700',
          paddingBottom: 4,
        },
        tabBarStyle: {
          backgroundColor: atlasTheme.colors.surface,
          borderTopColor: atlasTheme.colors.border,
          height: 78,
          paddingBottom: 10,
          paddingTop: 8,
        },
        tabBarIcon: ({ color, size }) => (
          <Ionicons color={color} name={getTabIcon(route.name)} size={size} />
        ),
      })}>
      <Tabs.Screen name="today" options={{ title: 'Today' }} />
      <Tabs.Screen name="timeline" options={{ title: 'Timeline' }} />
      <Tabs.Screen name="library" options={{ title: 'Library' }} />
      <Tabs.Screen name="insights" options={{ title: 'Insights' }} />
      <Tabs.Screen name="settings" options={{ title: 'Settings' }} />
    </Tabs>
  );
}

function getTabIcon(routeName: string): ComponentProps<typeof Ionicons>['name'] {
  switch (routeName) {
    case 'today':
      return 'sparkles-outline';
    case 'timeline':
      return 'time-outline';
    case 'library':
      return 'library-outline';
    case 'insights':
      return 'stats-chart-outline';
    default:
      return 'settings-outline';
  }
}
