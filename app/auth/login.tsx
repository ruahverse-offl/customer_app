import React, { useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import FontAwesome from '@expo/vector-icons/FontAwesome';
import { LinearGradient } from 'expo-linear-gradient';
import { router, useLocalSearchParams } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Theme } from '@/constants/theme';
import { useAuth } from '@/context/AuthContext';
import { HREF_AGENT_DELIVERIES, HREF_HOME } from '@/lib/navigation';
import type { Href } from 'expo-router';

/**
 * Unified sign-in aligned with the web app: after password login or register,
 * loads `GET /auth/me/permissions` and routes by role (customer vs delivery agent).
 */
export default function AuthLoginScreen() {
  const params = useLocalSearchParams<{ intent?: string; mode?: string; returnTo?: string }>();
  const intent = params.intent === 'delivery' ? 'delivery' : 'customer';
  const returnToRaw = params.returnTo;
  const returnTo = Array.isArray(returnToRaw) ? returnToRaw[0] : returnToRaw;

  const { login, register } = useAuth();
  const [mode, setMode] = useState<'login' | 'register'>(() =>
    intent === 'customer' && params.mode === 'register' ? 'register' : 'login',
  );
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [phone, setPhone] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [busy, setBusy] = useState(false);

  const goAfterSuccess = () => {
    if (intent === 'delivery') {
      router.replace(HREF_AGENT_DELIVERIES);
      return;
    }
    const dest = returnTo && returnTo.startsWith('/') ? returnTo : HREF_HOME;
    router.replace(dest as Href);
  };

  const onSubmit = async () => {
    setBusy(true);
    try {
      if (intent === 'delivery') {
        await login(email.trim(), password, 'delivery');
        goAfterSuccess();
        return;
      }
      if (mode === 'login') {
        await login(email.trim(), password, 'customer');
        goAfterSuccess();
        return;
      }
      if (!name.trim()) {
        Alert.alert('Validation', 'Full name is required.');
        return;
      }
      if (!email.trim()) {
        Alert.alert('Validation', 'Email is required.');
        return;
      }
      if (password.length < 6) {
        Alert.alert('Validation', 'Password must be at least 6 characters.');
        return;
      }
      const digits = phone.replace(/\D/g, '');
      if (digits.length !== 10) {
        Alert.alert('Validation', 'Please enter a valid 10-digit mobile number.');
        return;
      }
      await register({
        full_name: name.trim(),
        email: email.trim(),
        password,
        mobile_number: digits,
      });
      goAfterSuccess();
    } catch (e) {
      Alert.alert('Could not continue', e instanceof Error ? e.message : 'Something went wrong');
    } finally {
      setBusy(false);
    }
  };

  return (
    <SafeAreaView style={styles.safe} edges={['bottom']}>
        <KeyboardAvoidingView
          style={styles.flex}
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
          <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
            <LinearGradient colors={[...Theme.gradientHero]} style={styles.hero}>
              <Text style={styles.heroTitle}>
                {intent === 'delivery' ? 'Delivery partner' : mode === 'register' ? 'Create account' : 'Sign in'}
              </Text>
              <Text style={styles.heroSub}>
                {intent === 'delivery'
                  ? 'Use the delivery account issued by the pharmacy.'
                  : mode === 'register'
                    ? 'Create your account — you can still browse the pharmacy catalog as a guest.'
                    : 'Welcome back — browse as a guest anytime.'}
              </Text>
            </LinearGradient>

            <View style={styles.card}>
              {intent === 'customer' && mode === 'register' ? (
                <TextInput
                  style={styles.input}
                  placeholder="Full name"
                  value={name}
                  onChangeText={setName}
                  autoCapitalize="words"
                />
              ) : null}
              <TextInput
                style={styles.input}
                placeholder="Email"
                value={email}
                onChangeText={setEmail}
                autoCapitalize="none"
                keyboardType="email-address"
              />
              <View style={styles.passwordRow}>
                <TextInput
                  style={styles.passwordInput}
                  placeholder="Password"
                  value={password}
                  onChangeText={setPassword}
                  secureTextEntry={!showPassword}
                  autoCapitalize="none"
                />
                <Pressable
                  style={styles.passwordToggle}
                  onPress={() => setShowPassword((v) => !v)}
                  hitSlop={8}
                  accessibilityLabel={showPassword ? 'Hide password' : 'Show password'}
                  accessibilityRole="button">
                  <FontAwesome
                    name={showPassword ? 'eye-slash' : 'eye'}
                    size={20}
                    color={Theme.gray500}
                  />
                </Pressable>
              </View>
              {intent === 'customer' && mode === 'register' ? (
                <TextInput
                  style={styles.input}
                  placeholder="Mobile (10 digits)"
                  value={phone}
                  onChangeText={setPhone}
                  keyboardType="phone-pad"
                />
              ) : null}

              <Pressable style={styles.primary} onPress={onSubmit} disabled={busy}>
                {busy ? (
                  <ActivityIndicator color={Theme.white} />
                ) : (
                  <Text style={styles.primaryText}>{mode === 'register' ? 'Create account' : 'Continue'}</Text>
                )}
              </Pressable>

              {intent === 'customer' ? (
                <Pressable
                  style={styles.switch}
                  onPress={() => {
                    setMode((m) => (m === 'login' ? 'register' : 'login'));
                  }}
                  disabled={busy}>
                  <Text style={styles.switchText}>
                    {mode === 'login' ? 'New here? Create an account' : 'Already have an account? Sign in'}
                  </Text>
                </Pressable>
              ) : null}

              <Pressable style={styles.cancel} onPress={() => router.back()} disabled={busy}>
                <Text style={styles.cancelText}>Close</Text>
              </Pressable>
            </View>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Theme.gray50 },
  flex: { flex: 1 },
  scroll: { padding: 16, paddingBottom: 40 },
  hero: { borderRadius: Theme.radiusLg, padding: 22, marginBottom: 16 },
  heroTitle: { fontSize: 24, fontWeight: '800', color: Theme.white },
  heroSub: { marginTop: 8, color: 'rgba(255,255,255,0.9)', fontSize: 14, lineHeight: 20 },
  card: {
    backgroundColor: Theme.white,
    borderRadius: 14,
    padding: 16,
    borderWidth: 1,
    borderColor: Theme.gray200,
  },
  input: {
    borderWidth: 1,
    borderColor: Theme.gray200,
    borderRadius: 10,
    padding: 12,
    marginBottom: 10,
    fontSize: 16,
    color: Theme.gray900,
  },
  passwordRow: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Theme.gray200,
    borderRadius: 10,
    marginBottom: 10,
    paddingRight: 4,
  },
  passwordInput: {
    flex: 1,
    paddingVertical: 12,
    paddingLeft: 12,
    paddingRight: 8,
    fontSize: 16,
    color: Theme.gray900,
  },
  passwordToggle: {
    padding: 10,
    justifyContent: 'center',
    alignItems: 'center',
  },
  primary: {
    backgroundColor: Theme.accentBlue,
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: 'center',
    marginTop: 4,
  },
  primaryText: { color: Theme.white, fontWeight: '800', fontSize: 16 },
  switch: { marginTop: 16, alignItems: 'center' },
  switchText: { color: Theme.primary, fontWeight: '700' },
  cancel: { marginTop: 12, alignItems: 'center' },
  cancelText: { color: Theme.gray500, fontWeight: '600' },
});
