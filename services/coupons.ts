import { apiGet, apiPost } from '@/lib/api';

export type CouponRow = {
  id: string;
  code: string;
  discount_percentage?: number | string | null;
  first_order_only?: boolean;
};

export async function getActiveCoupons() {
  const res = await apiGet<{ items?: CouponRow[] }>('coupons/', {
    is_active: true,
    limit: 20,
    offset: 0,
    sort_by: 'created_at',
    sort_order: 'desc',
  });
  return res.items ?? [];
}

export async function validateCoupon(code: string, orderAmount: number, customerId?: string | null) {
  return apiPost<{ valid: boolean; discount_amount?: string | number | null; message: string }>(
    'coupons/validate',
    {
      code: code.toUpperCase().trim(),
      order_amount: orderAmount,
      customer_id: customerId ?? undefined,
    },
  );
}
