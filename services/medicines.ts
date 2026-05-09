import { apiGet } from '@/lib/api';

export type MedicineRow = {
  id: string;
  name: string;
  description?: string | null;
  is_active?: boolean;
  is_prescription_required?: boolean;
  medicine_category_id?: string | null;
  medicine_category_name?: string | null;
  image_path?: string | null;
  brands?: Array<{
    id: string;
    brand_name?: string;
    name?: string | null;
    mrp?: string | number | null;
    stock_quantity?: number | string | null;
    is_active?: boolean;
    is_available?: boolean;
    description?: string | null;
    manufacturer?: string | null;
  }>;
};

export async function getMedicines(params: {
  limit?: number;
  offset?: number;
  search?: string;
  is_available?: boolean;
  include_brands?: boolean;
}) {
  return apiGet<{ items: MedicineRow[]; pagination?: unknown }>('medicines/', {
    limit: params.limit ?? 200,
    offset: params.offset ?? 0,
    search: params.search,
    sort_by: 'created_at',
    sort_order: 'desc',
    is_available: params.is_available === undefined ? true : params.is_available,
    include_brands: params.include_brands ?? true,
  });
}

export async function getMedicineById(medicineId: string, include_brands = true) {
  return apiGet<MedicineRow>(`medicines/${medicineId}`, {
    include_brands: include_brands,
  });
}
