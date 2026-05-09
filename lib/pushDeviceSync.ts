import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';

import { getStoredAuth } from '@/lib/api';
import { getOrCreateInstallationId } from '@/lib/deviceInstallationId';
import {
  registerMeNotificationDevice,
  revokeMeNotificationDevices,
  type DevicePlatform,
} from '@/services/meNotificationSettings';

export const NOTIFICATIONS_ENABLED_KEY = 'nb_notifications_enabled';

export const LAST_EXPO_PUSH_TOKEN_KEY = 'nb_last_expo_push_token';

function getDevicePlatform(): DevicePlatform {
  if (Platform.OS === 'android') return 'android';
  if (Platform.OS === 'ios') return 'ios';
  if (Platform.OS === 'web') return 'web';
  return 'unknown';
}

export async function syncPushRegistrationWithServer(): Promise<void> {
  const auth = await getStoredAuth();
  if (!auth?.token) return;
  const expo = await AsyncStorage.getItem(LAST_EXPO_PUSH_TOKEN_KEY);
  if (!expo) return;
  const enabledPref = (await AsyncStorage.getItem(NOTIFICATIONS_ENABLED_KEY)) !== '0';
  const device_id = await getOrCreateInstallationId();
  try {
    await registerMeNotificationDevice({
      expo_push_token: expo,
      device_platform: getDevicePlatform(),
      device_id,
      is_push_enabled: enabledPref,
    });
  } catch {
    /* offline */
  }
}

export async function revokePushRegistrationOnServer(): Promise<void> {
  const auth = await getStoredAuth();
  if (!auth?.token) return;
  const expo = await AsyncStorage.getItem(LAST_EXPO_PUSH_TOKEN_KEY);
  const device_id = await getOrCreateInstallationId();
  try {
    await revokeMeNotificationDevices({
      device_id,
      ...(expo ? { expo_push_token: expo } : {}),
    });
  } catch {
    /* still sign out */
  }
}
