import React, { useCallback, useEffect, useState } from 'react';
import { ActivityIndicator, Alert, Pressable, ScrollView, Text, TextInput, View } from 'react-native';

import { ProfileAuthGate } from '@/components/ProfileAuthGate';
import { Theme } from '@/constants/theme';
import { profileStyles } from '@/constants/profileScreenStyles';
import { useAuth } from '@/context/AuthContext';
import { SHOP_CITY, SHOP_PINCODE, SHOP_STATE } from '@/lib/shopLocation';
import {
  createAddress,
  deleteAddress,
  getMyAddresses,
  setDefaultAddress,
  updateAddress,
  type AddressRow,
} from '@/services/addresses';

function AddressesContent() {
  const { token } = useAuth();
  const [addresses, setAddresses] = useState<AddressRow[]>([]);
  const [addressesLoading, setAddressesLoading] = useState(false);
  const [addrLabel, setAddrLabel] = useState('');
  const [addrStreet, setAddrStreet] = useState('');
  const [editingAddressId, setEditingAddressId] = useState<string | null>(null);
  const [addrSaving, setAddrSaving] = useState(false);

  const loadAddresses = useCallback(async () => {
    if (!token) return;
    setAddressesLoading(true);
    try {
      const rows = await getMyAddresses();
      setAddresses(rows || []);
    } catch {
      setAddresses([]);
    } finally {
      setAddressesLoading(false);
    }
  }, [token]);

  useEffect(() => {
    loadAddresses();
  }, [loadAddresses]);

  const resetAddressForm = () => {
    setEditingAddressId(null);
    setAddrLabel('');
    setAddrStreet('');
  };

  const onSaveAddress = async () => {
    if (!addrStreet.trim()) {
      Alert.alert('Address', 'Please enter street / flat / landmark.');
      return;
    }
    setAddrSaving(true);
    try {
      const payload = {
        label: addrLabel.trim() || undefined,
        street: addrStreet.trim(),
        city: SHOP_CITY,
        state: SHOP_STATE,
        pincode: SHOP_PINCODE,
        country: 'India',
      };
      if (editingAddressId) {
        await updateAddress(editingAddressId, payload);
      } else {
        await createAddress(payload);
      }
      await loadAddresses();
      resetAddressForm();
      Alert.alert('Saved', 'Address saved successfully.');
    } catch (e) {
      Alert.alert('Address', e instanceof Error ? e.message : 'Could not save address');
    } finally {
      setAddrSaving(false);
    }
  };

  return (
    <ScrollView contentContainerStyle={profileStyles.scroll} keyboardShouldPersistTaps="handled">
      <View style={profileStyles.card}>
        <Text style={profileStyles.cardTitle}>{editingAddressId ? 'Edit address' : 'Add address'}</Text>
        <Text style={profileStyles.hint}>
          City, state and PIN are fixed to our shop service area. Only your street/flat and label can be edited.
        </Text>
        <TextInput style={profileStyles.input} placeholder="Label (Home/Office)" value={addrLabel} onChangeText={setAddrLabel} />
        <TextInput
          style={profileStyles.input}
          placeholder="Street / flat / landmark"
          value={addrStreet}
          onChangeText={setAddrStreet}
        />
        <Text style={profileStyles.label}>City (service area)</Text>
        <TextInput style={profileStyles.inputFrozen} value={SHOP_CITY} editable={false} selectTextOnFocus={false} />
        <Text style={profileStyles.label}>State (service area)</Text>
        <TextInput style={profileStyles.inputFrozen} value={SHOP_STATE} editable={false} selectTextOnFocus={false} />
        <Text style={profileStyles.label}>PIN code (service area)</Text>
        <TextInput style={profileStyles.inputFrozen} value={SHOP_PINCODE} editable={false} selectTextOnFocus={false} />
        <View style={profileStyles.inlineActions}>
          <Pressable style={profileStyles.primaryMini} onPress={onSaveAddress} disabled={addrSaving}>
            {addrSaving ? <ActivityIndicator color="#fff" /> : <Text style={profileStyles.primaryText}>Save</Text>}
          </Pressable>
          <Pressable style={profileStyles.outlineMini} onPress={resetAddressForm}>
            <Text style={profileStyles.outlineText}>Reset</Text>
          </Pressable>
        </View>
      </View>
      {addressesLoading ? (
        <ActivityIndicator color={Theme.primary} style={{ marginVertical: 16 }} />
      ) : addresses.length === 0 ? (
        <Text style={profileStyles.empty}>No saved addresses.</Text>
      ) : (
        addresses.map((addr) => (
          <View key={addr.id} style={profileStyles.orderCard}>
            <Text style={profileStyles.orderRef}>{addr.label || 'Address'}</Text>
            <Text style={profileStyles.hint}>
              {addr.street}, {addr.city}, {addr.state} - {addr.pincode}
            </Text>
            {addr.is_default ? <Text style={profileStyles.orderStatus}>Default</Text> : null}
            <View style={profileStyles.inlineActions}>
              {!addr.is_default ? (
                <Pressable style={profileStyles.secondaryMini} onPress={() => setDefaultAddress(addr.id).then(loadAddresses)}>
                  <Text style={profileStyles.primaryText}>Set default</Text>
                </Pressable>
              ) : null}
              <Pressable
                style={profileStyles.outlineMini}
                onPress={() => {
                  setEditingAddressId(addr.id);
                  setAddrLabel(addr.label || '');
                  setAddrStreet(addr.street || '');
                }}>
                <Text style={profileStyles.outlineText}>Edit</Text>
              </Pressable>
              <Pressable
                style={profileStyles.outlineMini}
                onPress={() =>
                  Alert.alert('Delete address', 'Are you sure?', [
                    { text: 'Cancel', style: 'cancel' },
                    {
                      text: 'Delete',
                      style: 'destructive',
                      onPress: async () => {
                        await deleteAddress(addr.id);
                        await loadAddresses();
                      },
                    },
                  ])
                }>
                <Text style={[profileStyles.outlineText, { color: '#b91c1c' }]}>Delete</Text>
              </Pressable>
            </View>
          </View>
        ))
      )}
    </ScrollView>
  );
}

export default function ProfileAddressesScreen() {
  return (
    <View style={profileStyles.safe}>
      <ProfileAuthGate>
        <AddressesContent />
      </ProfileAuthGate>
    </View>
  );
}
