import { apiGet } from '@/lib/api';

export type AppointmentRow = {
  id: string;
  appointment_date?: string | null;
  status?: string | null;
  doctor_name?: string | null;
  specialization?: string | null;
};

export async function getAppointments(params?: { limit?: number; offset?: number }) {
  return apiGet<{ items: AppointmentRow[] }>('appointments/', {
    limit: params?.limit ?? 20,
    offset: params?.offset ?? 0,
    sort_by: 'created_at',
    sort_order: 'desc',
  });
}
