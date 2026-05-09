import { apiPost } from '@/lib/api';

export type InitiatePaymentBody = {
  customer_name: string;
  customer_phone: string;
  customer_email?: string;
  delivery_address: string;
  pincode?: string;
  city?: string;
  items: {
    medicine_brand_id: string | null;
    name: string;
    quantity: number;
    price: number;
    requires_prescription: boolean;
  }[];
  subtotal: number;
  delivery_fee: number;
  discount_amount: number;
  final_amount: number;
  coupon_code?: string | null;
  applied_coupons?: { code: string; discount_amount: number }[] | null;
  prescription_path?: string;
};

export type InitiatePaymentResult = {
  order_id: string;
  razorpay_order_id: string;
  key_id: string;
  amount: number;
  order_reference?: string;
  razorpay_mode?: string;
};

export async function initiatePayment(body: InitiatePaymentBody) {
  return apiPost<InitiatePaymentResult>('razorpay/initiate', body);
}

export async function verifyPayment(data: {
  razorpay_payment_id: string;
  razorpay_order_id: string;
  razorpay_signature: string;
}) {
  return apiPost<{
    order_id: string;
    payment_status: string;
    amount: number;
    transaction_id?: string;
    order_status?: string;
  }>('razorpay/verify', data);
}
