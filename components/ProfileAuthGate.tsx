import React from 'react';
import { Pressable, Text, View } from 'react-native';
import { router } from 'expo-router';
import type { Href } from 'expo-router';

import { profileStyles } from '@/constants/profileScreenStyles';
import { HREF_AUTH_LOGIN } from '@/lib/navigation';
import { useAuth } from '@/context/AuthContext';

type Props = { children: React.ReactNode };

/**
 * Renders a sign-in prompt when the customer is not authenticated; otherwise renders children.
 */
export function ProfileAuthGate({ children }: Props) {
  const { user, token } = useAuth();
  if (!user || !token) {
    return (
      <View style={[profileStyles.safe, { padding: 16 }]}>
        <Text style={profileStyles.msg}>Sign in to use your account.</Text>
        <Pressable style={profileStyles.primary} onPress={() => router.push({ pathname: HREF_AUTH_LOGIN, params: { intent: 'customer' } } as Href)}>
          <Text style={profileStyles.primaryText}>Sign in</Text>
        </Pressable>
      </View>
    );
  }
  return <>{children}</>;
}
