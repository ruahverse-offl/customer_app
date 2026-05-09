import { apiGet } from '@/lib/api';

export async function getMedicineCategories(params?: { limit?: number; is_active?: boolean }) {
  return apiGet<{ items: { id: string; name: string; is_active?: boolean }[] }>('medicine-categories/', {
    limit: params?.limit ?? 100,
    offset: 0,
    sort_by: 'name',
    sort_order: 'asc',
    is_active: params?.is_active ?? true,
  });
}

export async function getMedicineCategoryById(categoryId: string) {
  return apiGet<{ id: string; name: string }>(`medicine-categories/${categoryId}`);
}
