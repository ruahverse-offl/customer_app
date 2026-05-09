export type MedicineBrand = {
  id?: string;
  is_active?: boolean;
  is_available?: boolean;
  stock_quantity?: number | string | null;
  mrp?: number | string | null;
  brand_name?: string;
  name?: string | null;
  /** Pack/strip size or offering note from backend, e.g. "Strip of 10", "Pack of 2" */
  description?: string | null;
  manufacturer?: string | null;
};

/** Non-empty pack / offering line for UI (API `description` on medicine–brand offering). */
export function brandPackDescription(brand: MedicineBrand | null | undefined): string | null {
  if (!brand) return null;
  const s = (brand.description ?? '').trim();
  return s.length > 0 ? s : null;
}

export function brandStockQuantity(brand: MedicineBrand | null | undefined): number {
  if (!brand || brand.stock_quantity == null) return 0;
  const n = Number(brand.stock_quantity);
  return Number.isFinite(n) ? Math.max(0, Math.floor(n)) : 0;
}

export function isBrandPurchasable(brand: MedicineBrand | null | undefined): boolean {
  if (!brand) return false;
  if (brand.is_active === false || brand.is_available === false) return false;
  return brandStockQuantity(brand) > 0;
}
