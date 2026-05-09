import React from 'react';
import { Image, Linking, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { SafeAreaView } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import FontAwesome from '@expo/vector-icons/FontAwesome';
import { Ionicons } from '@expo/vector-icons';
import MaterialCommunityIcons from '@expo/vector-icons/MaterialCommunityIcons';
import type { Href } from 'expo-router';

import { NotificationPermissionBanner } from '@/components/NotificationPermissionBanner';
import { Fonts, Theme } from '@/constants/theme';
import { SHOP_PHONE_TEL, SHOP_WHATSAPP } from '@/lib/shopContact';

const MAPS_URL = 'https://maps.app.goo.gl/pvMjw454bA21VuQu9';
const STORE_ADDRESS = '120/A Poobalarayapuram 2nd Street,\nThoothukudi, Tamil Nadu 628001';

function ServiceCard({
  icon,
  title,
  body,
}: {
  icon: React.ComponentProps<typeof Ionicons>['name'];
  title: string;
  body: string;
}) {
  return (
    <View style={styles.svcCard}>
      <View style={styles.svcIconWrap}>
        <Ionicons name={icon} size={26} color={Theme.primary} />
      </View>
      <Text style={styles.svcTitle}>{title}</Text>
      <Text style={styles.svcBody}>{body}</Text>
    </View>
  );
}

export default function HomeScreen() {
  return (
    <View style={styles.root}>
      <SafeAreaView edges={['top']} style={styles.appHeader}>
        <View style={styles.appHeaderInner}>
          <Image
            source={require('@/assets/images/new_balan_logo.png')}
            style={styles.appHeaderLogo}
            resizeMode="contain"
            accessibilityLabel="New Balan Medical logo"
          />
          <View style={styles.appHeaderTextWrap}>
            <Text style={styles.appHeaderMain}>NEW BALAN</Text>
            <Text style={styles.appHeaderSub}>Medical & Clinic</Text>
          </View>
        </View>
      </SafeAreaView>

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.scroll}>
        <NotificationPermissionBanner />
        <LinearGradient colors={[...Theme.gradientHeroSoft]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.hero}>
          {/* Hero content: use View (not SafeAreaView) — top inset handled by app header */}
          <View style={styles.heroSafe}>
            <View style={styles.heroBadge}>
              <Text style={styles.heroBadgeText}>Trusted since 1997</Text>
            </View>
            <Text style={styles.heroHead}>Healthcare for your family</Text>
            <Text style={styles.heroLead}>
              Clinic consultations, genuine medicines with delivery, diagnostics, and Star Health insurance — together
              at NEW BALAN.
            </Text>
            <View style={styles.heroPills}>
              <View style={styles.pill}>
                <Ionicons name="shield-checkmark" size={16} color="rgba(255,255,255,0.95)" />
                <Text style={styles.pillText}> Star Health partner</Text>
              </View>
              <View style={styles.pill}>
                <Ionicons name="bicycle" size={16} color="rgba(255,255,255,0.95)" />
                <Text style={styles.pillText}> Home delivery</Text>
              </View>
            </View>
            <View style={styles.heroCtas}>
              <Pressable style={styles.btnPrimary} onPress={() => router.navigate('/pharmacy' as Href)}>
                <MaterialCommunityIcons name="pill" size={22} color={Theme.primary} />
                <Text style={styles.btnPrimaryLabel}>Order medicines</Text>
              </Pressable>
            </View>
          </View>
        </LinearGradient>

        <Text style={styles.sectionTitle}>Our services</Text>
        <Text style={styles.sectionSub}>Everything you need in one trusted place.</Text>
        <View style={styles.svcGrid}>
          <ServiceCard
            icon="medkit"
            title="Pharmacy"
            body="Genuine medicines with home delivery to your door."
          />
          <ServiceCard
            icon="medical"
            title="Clinic"
            body="Book consultations with our specialists."
          />
          <ServiceCard
            icon="flask"
            title="Polyclinic"
            body="Lab tests and diagnostics at the centre."
          />
          <ServiceCard
            icon="shield-half-outline"
            title="Insurance"
            body="Star Health plans and guidance."
          />
        </View>

        <Text style={[styles.sectionTitle, { marginTop: 28 }]}>Visit us</Text>
        <Text style={styles.sectionSub}>New Balan Medicals — Thoothukudi</Text>
        <View style={styles.locCard}>
          <View style={styles.locIcon}>
            <FontAwesome name="map-marker" size={28} color={Theme.primary} />
          </View>
          <Text style={styles.locAddr}>{STORE_ADDRESS}</Text>
          <View style={styles.locActions}>
            <Pressable style={styles.locBtn} onPress={() => Linking.openURL(MAPS_URL)}>
              <Ionicons name="navigate" size={18} color={Theme.white} />
              <Text style={styles.locBtnText}> Directions</Text>
            </Pressable>
            <Pressable style={styles.locBtnOutline} onPress={() => Linking.openURL(`tel:${SHOP_PHONE_TEL}`)}>
              <Ionicons name="call" size={18} color={Theme.primary} />
              <Text style={styles.locBtnOutlineText}> Call</Text>
            </Pressable>
          </View>
          <Pressable style={styles.waRow} onPress={() => Linking.openURL(SHOP_WHATSAPP)}>
            <Ionicons name="logo-whatsapp" size={20} color={Theme.secondaryDark} />
            <Text style={styles.waText}>Message on WhatsApp</Text>
          </Pressable>
          <Text style={styles.contactInfo}>Phone: {SHOP_PHONE_TEL}</Text>
          <Text style={styles.contactInfo}>Business hours: Daily 8:00 AM - 9:00 PM</Text>
        </View>

        <Text style={styles.footnote}>NEW BALAN Medical & Clinic</Text>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: Theme.white },
  appHeader: {
    backgroundColor: Theme.white,
    borderBottomWidth: 1,
    borderBottomColor: Theme.gray200,
    ...Theme.shadowCard,
    shadowOpacity: 0.06,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2,
  },
  appHeaderInner: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
    gap: 12,
  },
  appHeaderLogo: { width: 44, height: 44 },
  appHeaderTextWrap: { flex: 1, justifyContent: 'center' },
  appHeaderMain: {
    fontFamily: Fonts.display,
    fontSize: 17,
    fontWeight: '800',
    color: Theme.primary,
    letterSpacing: 0.6,
  },
  appHeaderSub: {
    fontFamily: Fonts.bodySemi,
    fontSize: 12,
    fontWeight: '600',
    color: Theme.gray600,
    marginTop: 2,
  },
  scroll: { paddingBottom: 32, backgroundColor: Theme.gray50 },
  hero: { paddingBottom: 14 },
  heroSafe: { paddingHorizontal: 20, paddingTop: 8 },
  heroBadge: {
    alignSelf: 'flex-start',
    backgroundColor: 'rgba(255,255,255,0.15)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: Theme.radiusFull,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.25)',
  },
  heroBadgeText: { color: 'rgba(255,255,255,0.95)', fontSize: 12, fontWeight: '700', letterSpacing: 0.8 },
  heroHead: {
    marginTop: 12,
    fontFamily: Fonts.display,
    fontSize: 26,
    lineHeight: 32,
    color: Theme.white,
    letterSpacing: -0.5,
  },
  heroLead: {
    marginTop: 8,
    fontFamily: Fonts.body,
    fontSize: 14,
    lineHeight: 21,
    color: 'rgba(255,255,255,0.88)',
    maxWidth: 520,
  },
  heroPills: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 12 },
  pill: { flexDirection: 'row', alignItems: 'center', backgroundColor: 'rgba(0,0,0,0.2)', paddingHorizontal: 10, paddingVertical: 6, borderRadius: Theme.radiusFull },
  pillText: { color: 'rgba(255,255,255,0.95)', fontSize: 12, fontWeight: '600' },
  heroCtas: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
    marginTop: 14,
    width: '100%',
    justifyContent: 'center',
    alignItems: 'center',
  },
  btnPrimary: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: Theme.white,
    paddingVertical: 11,
    paddingHorizontal: 18,
    borderRadius: Theme.radiusLg,
    ...Theme.shadowCard,
  },
  btnPrimaryLabel: { color: Theme.primary, fontFamily: Fonts.bodySemi, fontSize: 15, fontWeight: '800' },
  sectionTitle: {
    marginHorizontal: 20,
    marginTop: 28,
    fontFamily: Fonts.display,
    fontSize: 22,
    color: Theme.gray900,
    letterSpacing: -0.3,
  },
  sectionSub: { marginHorizontal: 20, marginTop: 6, fontSize: 15, color: Theme.gray600, lineHeight: 22 },
  svcGrid: {
    marginHorizontal: 16,
    marginTop: 16,
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    rowGap: 12,
  },
  svcCard: {
    width: '48.5%',
    backgroundColor: Theme.white,
    borderRadius: Theme.radiusXl,
    padding: 18,
    borderWidth: 1,
    borderColor: Theme.gray200,
    ...Theme.shadowCard,
  },
  svcIconWrap: {
    width: 48,
    height: 48,
    borderRadius: 14,
    backgroundColor: Theme.primaryLight,
    alignItems: 'center',
    justifyContent: 'center',
  },
  svcTitle: { marginTop: 14, fontFamily: Fonts.bodySemi, fontSize: 18, fontWeight: '800', color: Theme.gray900 },
  svcBody: { marginTop: 6, fontSize: 14, color: Theme.gray600, lineHeight: 20 },
  locCard: {
    marginHorizontal: 16,
    marginTop: 12,
    backgroundColor: Theme.white,
    borderRadius: Theme.radiusXl,
    padding: 20,
    borderWidth: 1,
    borderColor: Theme.gray200,
    ...Theme.shadowCard,
  },
  locIcon: {
    width: 52,
    height: 52,
    borderRadius: 16,
    backgroundColor: Theme.primaryLight,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  locAddr: { fontSize: 16, lineHeight: 24, color: Theme.gray800, fontWeight: '600' },
  locActions: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginTop: 16 },
  locBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Theme.primary,
    paddingVertical: 12,
    paddingHorizontal: 18,
    borderRadius: Theme.radiusLg,
  },
  locBtnText: { color: Theme.white, fontWeight: '800', fontSize: 15 },
  locBtnOutline: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1.5,
    borderColor: Theme.primary,
    paddingVertical: 12,
    paddingHorizontal: 18,
    borderRadius: Theme.radiusLg,
  },
  locBtnOutlineText: { color: Theme.primary, fontWeight: '800', fontSize: 15 },
  waRow: { flexDirection: 'row', alignItems: 'center', gap: 10, marginTop: 16 },
  waText: { fontSize: 15, fontWeight: '700', color: Theme.secondaryDark },
  contactInfo: { marginTop: 8, color: Theme.gray700, fontSize: 13, fontWeight: '600' },
  footnote: { textAlign: 'center', marginTop: 12, marginBottom: 0, fontSize: 12, color: Theme.gray500, fontWeight: '600' },
});
