import React, { useState } from 'react';
import { ActivityIndicator, Alert, Pressable, ScrollView, Text, TextInput, View } from 'react-native';

import { ProfileAuthGate } from '@/components/ProfileAuthGate';
import { profileStyles } from '@/constants/profileScreenStyles';
import { useAuth } from '@/context/AuthContext';
import { changePassword } from '@/services/auth';

function ChangePasswordContent() {
  const { token } = useAuth();
  const [curPw, setCurPw] = useState('');
  const [newPw, setNewPw] = useState('');
  const [confirmPw, setConfirmPw] = useState('');
  const [pwBusy, setPwBusy] = useState(false);

  const onChangePassword = async () => {
    if (!token) return;
    if (newPw.length < 6) {
      Alert.alert('Password', 'New password must be at least 6 characters.');
      return;
    }
    if (newPw !== confirmPw) {
      Alert.alert('Password', 'New password and confirmation do not match.');
      return;
    }
    setPwBusy(true);
    try {
      await changePassword(token, curPw, newPw);
      setCurPw('');
      setNewPw('');
      setConfirmPw('');
      Alert.alert('Success', 'Password changed.');
    } catch (e) {
      Alert.alert('Password', e instanceof Error ? e.message : 'Failed');
    } finally {
      setPwBusy(false);
    }
  };

  return (
    <ScrollView contentContainerStyle={profileStyles.scroll} keyboardShouldPersistTaps="handled">
      <Text style={profileStyles.sub}>Use a strong password. You will stay signed in on this device.</Text>
      <View style={profileStyles.card}>
        <Text style={profileStyles.label}>Current password</Text>
        <TextInput
          style={profileStyles.input}
          value={curPw}
          onChangeText={setCurPw}
          secureTextEntry
          autoCapitalize="none"
        />
        <Text style={profileStyles.label}>New password</Text>
        <TextInput
          style={profileStyles.input}
          value={newPw}
          onChangeText={setNewPw}
          secureTextEntry
          autoCapitalize="none"
        />
        <Text style={profileStyles.label}>Confirm new password</Text>
        <TextInput
          style={profileStyles.input}
          value={confirmPw}
          onChangeText={setConfirmPw}
          secureTextEntry
          autoCapitalize="none"
        />
        <Pressable style={profileStyles.secondary} onPress={onChangePassword} disabled={pwBusy}>
          {pwBusy ? <ActivityIndicator color="#fff" /> : <Text style={profileStyles.primaryText}>Update password</Text>}
        </Pressable>
      </View>
    </ScrollView>
  );
}

export default function ChangePasswordScreen() {
  return (
    <View style={profileStyles.safe}>
      <ProfileAuthGate>
        <ChangePasswordContent />
      </ProfileAuthGate>
    </View>
  );
}
