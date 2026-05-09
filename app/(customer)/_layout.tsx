import React from 'react';
import { ActivityIndicator, StyleSheet, View } from 'react-native';
import { Redirect, Stack } from 'expo-router';

import { Theme } from '@/constants/theme';
import { useAuth } from '@/context/AuthContext';
import { HREF_AGENT_DELIVERIES } from '@/lib/navigation';

/**
 * Customer area: bottom tabs under `(main)` plus stack screens for the rest of the native site.
 */
export default function CustomerStackLayout() {
  const { loading, token, roleCode } = useAuth();

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={Theme.primary} />
      </View>
    );
  }

  if (token && roleCode === 'DELIVERY_AGENT') {
    return <Redirect href={HREF_AGENT_DELIVERIES} />;
  }

  return (
    <Stack
      screenOptions={{
        headerStyle: { backgroundColor: Theme.white },
        headerTintColor: Theme.gray900,
        headerTitleStyle: { fontWeight: '700' },
        headerShadowVisible: false,
        contentStyle: { backgroundColor: Theme.gray50 },
      }}>
      <Stack.Screen name="(main)" options={{ headerShown: false }} />
      <Stack.Screen name="medicine/[id]" options={{ title: 'Medicine' }} />
      <Stack.Screen name="profile" options={{ headerShown: false }} />
    </Stack>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: Theme.gray50 },
});
