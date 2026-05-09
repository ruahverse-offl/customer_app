import React from 'react';
import FontAwesome from '@expo/vector-icons/FontAwesome';
import { Tabs } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import CartHeaderButton from '@/components/CartHeaderButton';
import { Theme } from '@/constants/theme';
import { useClientOnlyValue } from '@/components/useClientOnlyValue';

function TabBarIcon(props: { name: React.ComponentProps<typeof FontAwesome>['name']; color: string }) {
  return <FontAwesome size={22} style={{ marginBottom: -1 }} {...props} />;
}

/**
 * Main app shell: Home (marketing), Pharmacy, Checkout, Account hub. Cart is always in the header.
 */
export default function MainTabsLayout() {
  const insets = useSafeAreaInsets();
  // Lift tab bar above Android navigation buttons / iOS home indicator
  const tabBarBottomPad = 8 + insets.bottom;
  const tabBarHeight = 60 + insets.bottom;

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: Theme.primary,
        tabBarInactiveTintColor: Theme.gray400,
        tabBarLabelStyle: { fontSize: 11, fontWeight: '700', marginBottom: 2 },
        tabBarStyle: {
          backgroundColor: Theme.white,
          borderTopColor: Theme.gray200,
          height: tabBarHeight,
          paddingBottom: tabBarBottomPad,
          paddingTop: 6,
        },
        headerShown: useClientOnlyValue(false, true),
        headerStyle: {
          backgroundColor: Theme.white,
          elevation: 0,
          shadowOpacity: 0,
          borderBottomWidth: 1,
          borderBottomColor: Theme.gray100,
        },
        headerTitleStyle: { fontFamily: 'Inter_600SemiBold', fontWeight: '700', fontSize: 18, color: Theme.gray900 },
        headerRight: () => <CartHeaderButton />,
      }}>
      <Tabs.Screen
        name="home"
        options={{
          title: 'Home',
          headerShown: false,
          tabBarIcon: ({ color }) => <TabBarIcon name="home" color={color} />,
        }}
      />
      <Tabs.Screen
        name="pharmacy"
        options={{
          title: 'Pharmacy',
          tabBarIcon: ({ color }) => <TabBarIcon name="medkit" color={color} />,
        }}
      />
      <Tabs.Screen
        name="checkout"
        options={{
          title: 'Checkout',
          tabBarIcon: ({ color }) => <TabBarIcon name="credit-card" color={color} />,
        }}
      />
      <Tabs.Screen
        name="account"
        options={{
          title: 'Account',
          headerShown: false,
          tabBarIcon: ({ color }) => <TabBarIcon name="user-circle" color={color} />,
        }}
      />
    </Tabs>
  );
}
