import React, { useCallback } from 'react';
import { ActivityIndicator, Alert, Pressable, ScrollView, Switch, Text, View } from 'react-native';

import { profileStyles } from '@/constants/profileScreenStyles';
import { ProfileAuthGate } from '@/components/ProfileAuthGate';
import { Theme } from '@/constants/theme';
import { useNotifications } from '@/context/NotificationContext';

function SettingsContent() {
  const { loading, enabled, permissionGranted, expoPushToken, setEnabled, sendLocalTest } = useNotifications();
  const [saving, setSaving] = React.useState(false);

  const onToggleNotifications = useCallback(
    async (next: boolean) => {
      if (saving) return;
      setSaving(true);
      try {
        await setEnabled(next);
      } catch (e) {
        Alert.alert('Settings', e instanceof Error ? e.message : 'Could not update notification settings.');
      } finally {
        setSaving(false);
      }
    },
    [saving, setEnabled],
  );

  const sendTestNotification = useCallback(async () => {
    try {
      if (!enabled) {
        Alert.alert('Notifications off', 'Enable notifications first.');
        return;
      }
      await sendLocalTest();
      Alert.alert('Sent', 'Test notification sent.');
    } catch (e) {
      Alert.alert('Notification', e instanceof Error ? e.message : 'Could not send test notification.');
    }
  }, [enabled, sendLocalTest]);

  if (loading) {
    return (
      <View style={[profileStyles.safe, { justifyContent: 'center', alignItems: 'center' }]}>
        <ActivityIndicator color={Theme.primary} />
      </View>
    );
  }

  return (
    <ScrollView contentContainerStyle={profileStyles.scroll} keyboardShouldPersistTaps="handled">
      <Text style={profileStyles.h1}>Settings</Text>
      <Text style={profileStyles.sub}>
        Manage app notification permissions and alerts for orders and updates.
      </Text>

      <View style={profileStyles.card}>
        <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 }}>
          <View style={{ flex: 1 }}>
            <Text style={[profileStyles.cardTitle, { marginBottom: 2 }]}>Push notifications</Text>
            <Text style={profileStyles.hint}>
              Receive order updates and important pharmacy reminders.
            </Text>
            <Text style={[profileStyles.hint, { marginBottom: 0 }]}>
              {permissionGranted ? 'Permission granted' : 'Permission not granted'}
            </Text>
          </View>
          <Switch
            value={enabled}
            onValueChange={onToggleNotifications}
            disabled={saving}
            trackColor={{ false: Theme.gray300, true: Theme.primary }}
            thumbColor={Theme.white}
          />
        </View>
        <Text style={[profileStyles.hint, { marginTop: 10, marginBottom: 0 }]}>
          Expo push token: {expoPushToken || 'Not available yet'}
        </Text>

        <Pressable
          style={[profileStyles.outline, { marginTop: 14 }]}
          onPress={sendTestNotification}
          disabled={saving || !enabled}>
          <Text style={profileStyles.outlineText}>Send test notification</Text>
        </Pressable>
      </View>
    </ScrollView>
  );
}

export default function ProfileSettingsScreen() {
  return (
    <View style={profileStyles.safe}>
      <ProfileAuthGate>
        <SettingsContent />
      </ProfileAuthGate>
    </View>
  );
}
