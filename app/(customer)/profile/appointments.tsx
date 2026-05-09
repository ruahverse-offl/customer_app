import React, { useCallback, useEffect, useState } from 'react';
import { ActivityIndicator, ScrollView, Text, View } from 'react-native';

import { ProfileAuthGate } from '@/components/ProfileAuthGate';
import { Theme } from '@/constants/theme';
import { profileStyles } from '@/constants/profileScreenStyles';
import { useAuth } from '@/context/AuthContext';
import { getAppointments, type AppointmentRow } from '@/services/appointments';

function AppointmentsContent() {
  const { token } = useAuth();
  const [appointments, setAppointments] = useState<AppointmentRow[]>([]);
  const [appointmentsLoading, setAppointmentsLoading] = useState(false);

  const load = useCallback(async () => {
    if (!token) return;
    setAppointmentsLoading(true);
    try {
      const res = await getAppointments({ limit: 20 });
      setAppointments(res.items || []);
    } catch {
      setAppointments([]);
    } finally {
      setAppointmentsLoading(false);
    }
  }, [token]);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <ScrollView contentContainerStyle={profileStyles.scroll} keyboardShouldPersistTaps="handled">
      {appointmentsLoading ? (
        <ActivityIndicator color={Theme.primary} style={{ marginVertical: 16 }} />
      ) : appointments.length === 0 ? (
        <Text style={profileStyles.empty}>No appointments available.</Text>
      ) : (
        appointments.map((a) => (
          <View key={a.id} style={profileStyles.orderCard}>
            <Text style={profileStyles.orderRef}>{a.doctor_name || 'Appointment'}</Text>
            <Text style={profileStyles.hint}>{a.specialization || 'General consultation'}</Text>
            <Text style={profileStyles.orderStatus}>{String(a.status || 'scheduled')}</Text>
          </View>
        ))
      )}
    </ScrollView>
  );
}

export default function AppointmentsScreen() {
  return (
    <View style={profileStyles.safe}>
      <ProfileAuthGate>
        <AppointmentsContent />
      </ProfileAuthGate>
    </View>
  );
}
