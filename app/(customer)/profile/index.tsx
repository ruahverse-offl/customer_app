import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Modal,
  Pressable,
  ScrollView,
  Text,
  TextInput,
  View,
} from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import type { Href } from 'expo-router';

import { NotificationPermissionBanner } from '@/components/NotificationPermissionBanner';
import { ProfileAuthGate } from '@/components/ProfileAuthGate';
import { useAuth } from '@/context/AuthContext';
import { profileStyles } from '@/constants/profileScreenStyles';
import { HREF_PROFILE_CHANGE_PASSWORD } from '@/lib/navigation';
import { verifyCurrentPassword } from '@/services/auth';
import { updateUserProfile } from '@/services/users';

/**
 * Customer profile details only. Save requires the account password in a confirmation modal.
 */
function ProfileIndexContent() {
  const insets = useSafeAreaInsets();
  const { user, token, updateLocalUser } = useAuth();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [saving, setSaving] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [accountPassword, setAccountPassword] = useState('');

  useEffect(() => {
    if (user) {
      setName(user.name || '');
      setEmail(user.email || '');
      setPhone(user.mobile_number ? String(user.mobile_number).replace(/\D/g, '') : '');
    }
  }, [user]);

  const hasEdits = () => {
    if (!user) return false;
    const digits = phone.replace(/\D/g, '');
    const origPhone = user.mobile_number ? String(user.mobile_number).replace(/\D/g, '') : '';
    return (
      name.trim() !== (user.name || '').trim() ||
      email.trim() !== (user.email || '').trim() ||
      digits !== origPhone
    );
  };

  const onRequestSave = () => {
    if (!hasEdits()) {
      Alert.alert('No changes', 'Update your details before saving.');
      return;
    }
    setAccountPassword('');
    setConfirmOpen(true);
  };

  const onConfirmSave = async () => {
    if (!user?.id || !token) return;
    if (!accountPassword.trim()) {
      Alert.alert('Password required', 'Enter your account password to save changes.');
      return;
    }
    setSaving(true);
    try {
      await verifyCurrentPassword((user.email || '').trim(), accountPassword);
      const digits = phone.replace(/\D/g, '');
      await updateUserProfile(user.id, {
        full_name: name.trim(),
        email: email.trim(),
        mobile_number: digits.length >= 10 ? digits.slice(-10) : undefined,
      });
      await updateLocalUser({
        name: name.trim(),
        email: email.trim(),
        mobile_number: digits.length >= 10 ? digits.slice(-10) : user.mobile_number,
      });
      setConfirmOpen(false);
      setAccountPassword('');
      Alert.alert('Saved', 'Your profile was updated.');
    } catch (e) {
      Alert.alert('Could not save', e instanceof Error ? e.message : 'Please try again.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      <ScrollView contentContainerStyle={profileStyles.scroll} keyboardShouldPersistTaps="handled">
        <NotificationPermissionBanner />
        <Text style={profileStyles.h1}>Your details</Text>
        <Text style={profileStyles.sub}>Name, email, and mobile used for orders and sign-in. Saving changes requires your password.</Text>
        <View style={profileStyles.card}>
          <Text style={profileStyles.label}>Full name</Text>
          <TextInput style={profileStyles.input} value={name} onChangeText={setName} />
          <Text style={profileStyles.label}>Email</Text>
          <TextInput style={profileStyles.input} value={email} onChangeText={setEmail} autoCapitalize="none" />
          <Text style={profileStyles.label}>Mobile (10 digits)</Text>
          <TextInput style={profileStyles.input} value={phone} onChangeText={setPhone} keyboardType="phone-pad" />
          <Pressable style={profileStyles.primary} onPress={onRequestSave} disabled={saving}>
            {saving && !confirmOpen ? <ActivityIndicator color="#fff" /> : <Text style={profileStyles.primaryText}>Save changes</Text>}
          </Pressable>
        </View>

        <Text style={[profileStyles.label, { marginTop: 8, marginLeft: 2 }]}>More</Text>
        <View style={profileStyles.card}>
          <Pressable onPress={() => router.push(HREF_PROFILE_CHANGE_PASSWORD as Href)} style={profileStyles.outline}>
            <Text style={profileStyles.outlineText}>Change password</Text>
          </Pressable>
        </View>
      </ScrollView>

      <Modal visible={confirmOpen} animationType="slide" transparent onRequestClose={() => setConfirmOpen(false)}>
        <Pressable style={{ flex: 1, backgroundColor: 'rgba(15,23,42,0.4)', justifyContent: 'flex-end' }} onPress={() => setConfirmOpen(false)}>
          <Pressable onPress={() => {}}>
            <SafeAreaView style={{ backgroundColor: 'transparent' }} edges={['bottom']}>
              <View style={[profileStyles.modalCard, { paddingBottom: Math.max(12, insets.bottom) }]}>
                <Text style={profileStyles.modalTitle}>Confirm with password</Text>
                <Text style={profileStyles.modalSub}>Enter your current account password to save profile changes.</Text>
                <Text style={profileStyles.label}>Password</Text>
                <TextInput
                  style={profileStyles.input}
                  value={accountPassword}
                  onChangeText={setAccountPassword}
                  secureTextEntry
                  autoCapitalize="none"
                />
                <View style={profileStyles.modalRow}>
                  <Pressable
                    style={[profileStyles.modalBtn, profileStyles.modalGhost]}
                    onPress={() => {
                      setConfirmOpen(false);
                      setAccountPassword('');
                    }}>
                    <Text style={profileStyles.outlineText}>Cancel</Text>
                  </Pressable>
                  <Pressable style={[profileStyles.modalBtn, profileStyles.primary]} onPress={onConfirmSave} disabled={saving}>
                    {saving ? <ActivityIndicator color="#fff" /> : <Text style={profileStyles.primaryText}>Save</Text>}
                  </Pressable>
                </View>
              </View>
            </SafeAreaView>
          </Pressable>
        </Pressable>
      </Modal>
    </>
  );
}

export default function ProfileIndexScreen() {
  return (
    <View style={profileStyles.safe}>
      <ProfileAuthGate>
        <ProfileIndexContent />
      </ProfileAuthGate>
    </View>
  );
}
