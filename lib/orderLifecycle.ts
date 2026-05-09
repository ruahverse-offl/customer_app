/** Subset of `new_balan_fe` `orderLifecycle.js` for delivery agent actions */

const DELIVERY_NEXT: Record<string, string[]> = {
  DELIVERY_ASSIGNED: ['PARCEL_TAKEN'],
  PARCEL_TAKEN: ['OUT_FOR_DELIVERY'],
  OUT_FOR_DELIVERY: ['DELIVERED', 'DELIVERY_RETURNED'],
};

const TERMINAL = new Set([
  'PAYMENT_CANCELLED',
  'DELIVERED',
  'CANCELLED_BY_STAFF',
  'DELIVERY_RETURNED',
  'REFUND_INITIATED',
  'REFUNDED',
  'CANCELLED',
  'COMPLETED',
]);

export function normalizeOrderStatus(raw: string | null | undefined): string {
  if (raw == null || raw === '') return 'PENDING';
  const r = String(raw).trim().toUpperCase();
  if (r === 'CONFIRMED') return 'ORDER_RECEIVED';
  if (r === 'CANCELLED') return 'CANCELLED_BY_STAFF';
  if (r === 'COMPLETED') return 'DELIVERED';
  if (r === 'SHIPPED') return 'OUT_FOR_DELIVERY';
  if (r === 'PROCESSING') return 'ORDER_PROCESSING';
  return r;
}

export function isTerminalOrderStatus(raw: string | null | undefined): boolean {
  const n = normalizeOrderStatus(raw);
  return TERMINAL.has(n) || TERMINAL.has(String(raw || '').toUpperCase());
}

export const ORDER_STATUS_LABELS: Record<string, string> = {
  PENDING: 'Payment pending',
  PAYMENT_CANCELLED: 'Payment cancelled',
  ORDER_RECEIVED: 'Order received',
  ORDER_TAKEN: 'Order taken',
  ORDER_PROCESSING: 'Processing',
  DELIVERY_ASSIGNED: 'Delivery assigned',
  PARCEL_TAKEN: 'Parcel picked up',
  OUT_FOR_DELIVERY: 'Out for delivery',
  DELIVERED: 'Delivered',
  DELIVERY_RETURNED: 'Returned',
};

export function deliveryNextActions(currentRaw: string | null | undefined): string[] {
  const current = normalizeOrderStatus(currentRaw);
  return DELIVERY_NEXT[current] ?? [];
}

export function formatOrderStatusLabel(code: string | null | undefined): string {
  if (!code) return '—';
  const u = String(code).toUpperCase();
  return ORDER_STATUS_LABELS[u] ?? code;
}
