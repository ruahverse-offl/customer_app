import { apiGet } from '@/lib/api';

export type DeliverySettings = {
  is_enabled?: boolean;
  show_marquee?: boolean;
  delivery_fee?: number | string;
  free_delivery_min_amount?: number | string | null;
  free_delivery_max_amount?: number | string | null;
  delivery_slot_times?: { slot_time?: string; is_active?: boolean }[];
};

const defaults: DeliverySettings = {
  is_enabled: true,
  show_marquee: true,
  delivery_fee: 40,
  free_delivery_min_amount: 500,
  free_delivery_max_amount: null,
  delivery_slot_times: [],
};

export async function getDeliverySettings(): Promise<DeliverySettings> {
  try {
    return await apiGet<DeliverySettings>('delivery-settings/');
  } catch (e) {
    const msg = e instanceof Error ? e.message : '';
    if (msg.toLowerCase().includes('not found')) {
      return defaults;
    }
    throw e;
  }
}

export function computeDeliveryFee(subtotal: number, settings: DeliverySettings | null): number {
  if (!settings || settings.is_enabled === false) return 0;
  const fee = Number(settings.delivery_fee ?? 40);
  const minRaw = settings.free_delivery_min_amount ?? 500;
  const min = minRaw != null && minRaw !== '' ? Number(minRaw) : 500;
  const maxRaw = settings.free_delivery_max_amount;
  const max =
    maxRaw != null && maxRaw !== '' && !Number.isNaN(Number(maxRaw)) ? Number(maxRaw) : null;
  if (subtotal < min) return fee;
  if (max != null && max > 0 && subtotal > max) return fee;
  return 0;
}

