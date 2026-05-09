import React from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { SafeAreaView } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import type { Href } from 'expo-router';

import { NotificationPermissionBanner } from '@/components/NotificationPermissionBanner';
import { Fonts, Theme } from '@/constants/theme';
import { useAuth } from '@/context/AuthContext';
import {
  HREF_AUTH_LOGIN,
  HREF_PROFILE,
  HREF_PROFILE_ADDRESSES,
  HREF_PROFILE_ORDERS,
  HREF_PROFILE_SETTINGS,
} from '@/lib/navigation';

type RowProps = {
  icon: React.ComponentProps<typeof Ionicons>['name'];
  label: string;
  hint?: string;
  onPress: () => void;
};

function Row({ icon, label, hint, onPress }: RowProps) {
  return (
    <Pressable style={({ pressed }) => [styles.row, pressed && styles.rowPressed]} onPress={onPress}>
      <View style={styles.rowIcon}>
        <Ionicons name={icon} size={22} color={Theme.primary} />
      </View>
      <View style={{ flex: 1 }}>
        <Text style={styles.rowLabel}>{label}</Text>
        {hint ? <Text style={styles.rowHint}>{hint}</Text> : null}
      </View>
      <Ionicons name="chevron-forward" size={18} color={Theme.gray400} />
    </Pressable>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>{title}</Text>
      <View style={styles.sectionCard}>{children}</View>
    </View>
  );
}

export default function AccountHubScreen() {
  const { user, token, logout } = useAuth();
  const signedIn = Boolean(user && token);

  return (
    <View style={styles.root}>
      <LinearGradient colors={[...Theme.gradientHero]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.top}>
        <SafeAreaView edges={['top']}>
          <Text style={styles.topKicker}>Account</Text>
          <Text style={styles.topTitle}>{signedIn ? user!.name : 'Welcome'}</Text>
          <Text style={styles.topSub}>
            {signedIn ? user!.email : 'Sign in to track orders, save addresses, and checkout faster.'}
          </Text>
        </SafeAreaView>
      </LinearGradient>

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        <NotificationPermissionBanner />
        {!signedIn ? (
          <Pressable
            style={styles.signInBanner}
            onPress={() => router.push({ pathname: HREF_AUTH_LOGIN, params: { intent: 'customer' } } as Href)}>
            <Ionicons name="log-in-outline" size={22} color={Theme.white} />
            <Text style={styles.signInBannerText}>Sign in or create account</Text>
            <Ionicons name="chevron-forward" size={20} color="rgba(255,255,255,0.9)" />
          </Pressable>
        ) : null}

        <Section title="Customer pages">
          <Row icon="person-outline" label="My profile" hint="Your name, email, phone" onPress={() => router.push(HREF_PROFILE)} />
          <View style={styles.divider} />
          <Row
            icon="location-outline"
            label="My addresses"
            hint="Add or edit delivery addresses"
            onPress={() => router.push(HREF_PROFILE_ADDRESSES as Href)}
          />
          <View style={styles.divider} />
          <Row
            icon="receipt-outline"
            label="My orders"
            hint="Order history and status"
            onPress={() => router.push(HREF_PROFILE_ORDERS as Href)}
          />
          <View style={styles.divider} />
          <Row
            icon="notifications-outline"
            label="Settings"
            hint="Notification preferences"
            onPress={() => router.push(HREF_PROFILE_SETTINGS as Href)}
          />
        </Section>

        {signedIn ? (
          <View style={styles.signOutWrap}>
            <Pressable
              style={({ pressed }) => [styles.signOutBtn, pressed && styles.signOutBtnPressed]}
              onPress={() => logout()}>
              <Text style={styles.signOutText}>Sign out</Text>
            </Pressable>
          </View>
        ) : null}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: Theme.gray50 },
  top: { paddingBottom: 52 },
  topKicker: { paddingHorizontal: 20, marginTop: 4, fontSize: 12, fontWeight: '800', color: 'rgba(255,255,255,0.75)', letterSpacing: 1.2 },
  topTitle: {
    paddingHorizontal: 20,
    marginTop: 6,
    fontFamily: Fonts.display,
    fontSize: 28,
    color: Theme.white,
    letterSpacing: -0.5,
  },
  topSub: { paddingHorizontal: 20, marginTop: 8, fontSize: 15, lineHeight: 22, color: 'rgba(255,255,255,0.88)', maxWidth: 400 },
  scroll: { paddingHorizontal: 16, paddingTop: 12, paddingBottom: 100 },
  signInBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: Theme.accentBlue,
    borderRadius: Theme.radiusXl,
    padding: 16,
    marginBottom: 20,
    ...Theme.shadowCard,
  },
  signInBannerText: { flex: 1, color: Theme.white, fontSize: 16, fontWeight: '800' },
  section: { marginBottom: 20 },
  sectionTitle: {
    marginLeft: 4,
    marginBottom: 8,
    fontSize: 12,
    fontWeight: '800',
    color: Theme.gray500,
    textTransform: 'uppercase',
    letterSpacing: 0.6,
  },
  sectionCard: {
    backgroundColor: Theme.white,
    borderRadius: Theme.radiusXl,
    borderWidth: 1,
    borderColor: Theme.gray200,
    overflow: 'hidden',
    ...Theme.shadowCard,
  },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: 14, paddingHorizontal: 14, gap: 12 },
  rowPressed: { backgroundColor: Theme.gray50 },
  rowIcon: {
    width: 44,
    height: 44,
    borderRadius: 12,
    backgroundColor: Theme.primaryLight,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rowLabel: { fontSize: 16, fontWeight: '700', color: Theme.gray900 },
  rowHint: { marginTop: 2, fontSize: 13, color: Theme.gray500 },
  divider: { height: 1, backgroundColor: Theme.gray100, marginLeft: 70 },
  signOutWrap: { width: '100%', alignItems: 'center', marginTop: 20, marginBottom: 4 },
  signOutBtn: {
    minWidth: 200,
    paddingVertical: 14,
    paddingHorizontal: 28,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#fecaca',
    backgroundColor: Theme.white,
  },
  signOutBtnPressed: { backgroundColor: '#fef2f2' },
  signOutText: { textAlign: 'center', color: '#b91c1c', fontSize: 16, fontWeight: '800' },
});
