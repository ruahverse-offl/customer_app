import { apiGet, apiPatch } from '@/lib/api';

export type OrderRow = {
  id: string;
  order_reference?: string | null;
  customer_name?: string | null;
  customer_phone: string;
  delivery_address: string;
  order_status: string;
  final_amount: string | number;
  created_at?: string | null;
  delivery_assigned_user_id?: string | null;
  payment_completed_at?: string | null;
};

/** Line item from GET /orders/{id}/detail (matches backend OrderItemResponse). */
export type OrderItemRow = {
  id: string;
  medicine_name?: string | null;
  brand_name?: string | null;
  quantity: number;
  unit_price: string | number;
  total_price: string | number;
  requires_prescription: boolean;
};

export type OrderDetailResponse = {
  order: OrderRow;
  items: OrderItemRow[];
  payment?: { payment_status?: string | null; amount?: string | number | null } | null;
};

export async function getOrders(params?: { limit?: number; offset?: number }) {
  return apiGet<{ items: OrderRow[] }>('orders/', {
    limit: params?.limit ?? 50,
    offset: params?.offset ?? 0,
    sort_by: 'created_at',
    sort_order: 'desc',
  });
}

/**
 * Full order with line items (medicines) for the customer “view order” screen.
 * API: GET /api/v1/orders/{order_id}/detail
 */
export async function getOrderDetail(orderId: string) {
  return apiGet<OrderDetailResponse>(`orders/${orderId}/detail`);
}

export async function updateOrder(orderId: string, body: { order_status?: string; return_reason?: string }) {
  return apiPatch<OrderRow>(`orders/${orderId}`, body);
}
