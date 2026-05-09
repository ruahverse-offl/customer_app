import { apiDelete, apiGet, apiPatch, apiPost } from '@/lib/api';

export type AddressRow = {
  id: string;
  label?: string | null;
  street: string;
  city: string;
  state: string;
  pincode: string;
  country?: string;
  is_default?: boolean;
};

export type AddressUpsertBody = {
  label?: string;
  street: string;
  city: string;
  state: string;
  pincode: string;
  country?: string;
  is_default?: boolean;
};

export async function getMyAddresses() {
  return apiGet<AddressRow[]>('addresses/my-addresses');
}

export async function createAddress(data: AddressUpsertBody) {
  return apiPost<AddressRow>('addresses', data);
}

export async function updateAddress(addressId: string, data: Partial<AddressUpsertBody>) {
  return apiPatch<AddressRow>(`addresses/${addressId}`, data);
}

export async function deleteAddress(addressId: string) {
  return apiDelete<Record<string, unknown>>(`addresses/${addressId}`);
}

export async function setDefaultAddress(addressId: string) {
  return apiPatch<AddressRow>(`addresses/${addressId}/default`, {});
}
