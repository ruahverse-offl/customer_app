import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  FlatList,
  Image,
  ListRenderItem,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import Animated, { FadeInDown, FadeIn } from 'react-native-reanimated';
import FontAwesome from '@expo/vector-icons/FontAwesome';
import { router } from 'expo-router';

import { Fonts, Theme } from '@/constants/theme';
import { useAuth } from '@/context/AuthContext';
import { HREF_AUTH_LOGIN } from '@/lib/navigation';
import { SHOP_CITY } from '@/lib/shopLocation';
import type { Href } from 'expo-router';
import { getStorageFileUrl } from '@/lib/storageUrl';
import { brandPackDescription, isBrandPurchasable, MedicineBrand } from '@/lib/pharmacyUtils';
import { getMedicines, MedicineRow } from '@/services/medicines';
import { getMedicineCategories } from '@/services/categories';
import { useCart } from '@/context/CartContext';

type DisplayProduct = {
  id: string;
  name: string;
  category: string;
  price: number;
  image: string;
  requiresPrescription: boolean;
  brands: MedicineBrand[];
};

function buildProducts(rows: MedicineRow[]): DisplayProduct[] {
  const priceMap: Record<string, number> = {};
  const bMap: Record<string, MedicineBrand[]> = {};
  rows.forEach((med) => {
    const mid = med.id;
    (med.brands || []).forEach((brand) => {
      if (!isBrandPurchasable(brand)) return;
      const mrp = parseFloat(String(brand.mrp ?? 0)) || 0;
      if (!priceMap[mid] || mrp < priceMap[mid]) priceMap[mid] = mrp;
      if (!bMap[mid]) bMap[mid] = [];
      bMap[mid].push(brand);
    });
  });
  Object.values(bMap).forEach((arr) =>
    arr.sort((a, b) => (parseFloat(String(a.mrp)) || 0) - (parseFloat(String(b.mrp)) || 0)),
  );

  return rows
    .map((med) => {
      const brands = bMap[med.id] || [];
      const purchasable = brands.filter(isBrandPurchasable).length;
      if (purchasable === 0) return null;
      return {
        id: med.id,
        name: med.name,
        category: med.medicine_category_name || '',
        price: priceMap[med.id] || 0,
        image: getStorageFileUrl(med.image_path),
        requiresPrescription: Boolean(med.is_prescription_required),
        brands,
      } as DisplayProduct;
    })
    .filter(Boolean) as DisplayProduct[];
}

export default function PharmacyScreen() {
  const insets = useSafeAreaInsets();
  const { addToCart } = useCart();
  const { user, token } = useAuth();
  const isAuthenticated = Boolean(user && token);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [products, setProducts] = useState<DisplayProduct[]>([]);
  const [categories, setCategories] = useState<{ id: string; name: string }[]>([]);
  const [search, setSearch] = useState('');
  const [debounced, setDebounced] = useState('');
  const [selectedCategories, setSelectedCategories] = useState<string[]>([]);
  const [tempSelectedCategories, setTempSelectedCategories] = useState<string[]>([]);
  const [categoryQuery, setCategoryQuery] = useState('');
  const [showCategoryFilter, setShowCategoryFilter] = useState(false);
  const [pickerProduct, setPickerProduct] = useState<DisplayProduct | null>(null);
  const [selectedBrandId, setSelectedBrandId] = useState<string | null>(null);
  const [pickerQty, setPickerQty] = useState(1);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => setDebounced(search.trim()), 350);
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [search]);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [medRes, catRes] = await Promise.all([
        getMedicines({ limit: 400, is_available: true, include_brands: true, search: debounced || undefined }),
        getMedicineCategories({ limit: 100, is_active: true }).catch(() => ({ items: [] })),
      ]);
      setProducts(buildProducts(medRes.items || []));
      setCategories((catRes.items || []).map((c) => ({ id: c.id, name: c.name })));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load medicines');
      setProducts([]);
    } finally {
      setLoading(false);
    }
  }, [debounced]);

  useEffect(() => {
    load();
  }, [load]);

  const filtered = useMemo(() => {
    if (selectedCategories.length === 0) return products;
    return products.filter((p) => selectedCategories.includes(p.category));
  }, [products, selectedCategories]);

  const filteredCategoryOptions = useMemo(() => {
    const q = categoryQuery.trim().toLowerCase();
    if (!q) return categories;
    return categories.filter((c) => c.name.toLowerCase().includes(q));
  }, [categories, categoryQuery]);

  const openPicker = (p: DisplayProduct) => {
    setPickerProduct(p);
    const first = p.brands.find((b) => isBrandPurchasable(b) && b.id);
    setSelectedBrandId(first?.id ?? null);
    setPickerQty(1);
  };

  const confirmAdd = () => {
    if (!isAuthenticated) {
      Alert.alert('Sign in required', 'Please sign in to add medicines to cart.', [
        { text: 'Not now', style: 'cancel' },
        {
          text: 'Sign in',
          onPress: () => router.push({ pathname: HREF_AUTH_LOGIN, params: { intent: 'customer' } } as Href),
        },
      ]);
      return;
    }
    if (!pickerProduct) {
      Alert.alert('Selection required', 'Please select a medicine first.');
      return;
    }
    if (!selectedBrandId) {
      Alert.alert('Select a pack', 'Please choose a pack/brand before adding to bag.');
      return;
    }
    const brand = pickerProduct.brands.find((b) => b.id === selectedBrandId);
    if (!brand?.id) {
      Alert.alert('Unavailable', 'Selected pack is currently unavailable.');
      return;
    }
    const price = parseFloat(String(brand.mrp ?? 0)) || 0;
    const bname = brand.brand_name || brand.name || 'Brand';
    const pack = brandPackDescription(brand);
    addToCart({
      medicineId: pickerProduct.id,
      brandId: brand.id,
      name: pack ? `${pickerProduct.name} · ${bname} — ${pack}` : `${pickerProduct.name} · ${bname}`,
      price,
      requiresPrescription: pickerProduct.requiresPrescription,
      quantity: pickerQty,
    });
    setPickerProduct(null);
  };

  const selectableBrands = useMemo(
    () => (pickerProduct?.brands || []).filter((b) => isBrandPurchasable(b) && b.id),
    [pickerProduct],
  );
  const canAddToBag = Boolean(
    pickerProduct && selectedBrandId && selectableBrands.some((b) => b.id === selectedBrandId),
  );

  /** Pinned: logo, delivery note, search, category filter — does not scroll with the grid */
  const stickyTop = (
    <View style={styles.stickyTop}>
      <Animated.View entering={FadeIn.duration(500)}>
        <LinearGradient colors={[...Theme.gradientHero]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.hero}>
          <View style={styles.heroTopRow}>
            <Image source={require('@/assets/images/new_balan_logo.png')} style={styles.brandLogo} resizeMode="contain" />
            <View style={styles.heroTitleBlock}>
              <Text style={styles.heroTitle}>Pharmacy</Text>
              <Text style={styles.heroTagline} numberOfLines={1}>
                New Balan — search, pick a pack, checkout
              </Text>
            </View>
          </View>
          <View style={styles.searchRow}>
            <FontAwesome name="search" size={14} color={Theme.gray500} style={styles.searchIcon} />
            <TextInput
              placeholder="Search medicines..."
              placeholderTextColor={Theme.gray400}
              value={search}
              onChangeText={setSearch}
              style={styles.searchInput}
            />
          </View>
          <View style={styles.deliveryNotice}>
            <Text style={styles.deliveryNoticeText} numberOfLines={2}>
              Delivery only available in {SHOP_CITY}.
            </Text>
          </View>
        </LinearGradient>
      </Animated.View>

      <View style={styles.filterRow}>
        <Pressable
          style={styles.filterBtn}
          onPress={() => {
            setTempSelectedCategories(selectedCategories);
            setCategoryQuery('');
            setShowCategoryFilter(true);
          }}>
          <FontAwesome name="sliders" size={15} color={Theme.primary} />
          <Text style={styles.filterBtnText}>
            {selectedCategories.length === 0
              ? 'Categories: All'
              : `Categories: ${selectedCategories.length} selected`}
          </Text>
          <FontAwesome name="chevron-down" size={12} color={Theme.gray600} />
        </Pressable>
        {selectedCategories.length > 0 ? (
          <Pressable
            style={styles.clearFilterBtn}
            onPress={() => {
              setSelectedCategories([]);
            }}>
            <Text style={styles.clearFilterBtnText}>Clear</Text>
          </Pressable>
        ) : null}
      </View>
    </View>
  );

  const listStateHeader = loading ? (
    <View style={styles.listStateBox}>
      <ActivityIndicator size="large" color={Theme.primary} />
    </View>
  ) : error ? (
    <View style={styles.listStateBox}>
      <Text style={styles.errorText}>{error}</Text>
      <Pressable style={styles.retryBtn} onPress={load}>
        <Text style={styles.retryText}>Retry</Text>
      </Pressable>
    </View>
  ) : null;

  const renderItem: ListRenderItem<DisplayProduct> = ({ item, index }) => (
    <Animated.View entering={FadeInDown.delay(Math.min(index, 12) * 40).springify()} style={styles.cardWrap}>
      <Pressable style={styles.card} onPress={() => openPicker(item)}>
        <View style={styles.cardImageWrap}>
          {item.image ? (
            <Image source={{ uri: item.image }} style={styles.cardImage} />
          ) : (
            <LinearGradient colors={[Theme.primaryLight, Theme.white]} style={styles.cardImage} />
          )}
          {item.requiresPrescription ? (
            <View style={styles.rxBadge}>
              <Text style={styles.rxBadgeText}>Rx</Text>
            </View>
          ) : null}
        </View>
        <Text style={styles.cardTitle} numberOfLines={2}>
          {item.name}
        </Text>
        <Text style={styles.cardMeta} numberOfLines={1}>
          {item.category || 'Medicine'}
        </Text>
        <View style={styles.cardFooter}>
          <Text style={styles.price}>₹{item.price.toFixed(0)}</Text>
          <View style={styles.addHint}>
            <FontAwesome name="plus-circle" size={22} color={Theme.accentBlue} />
            <Text style={styles.addHintText}>Add</Text>
          </View>
        </View>
      </Pressable>
    </Animated.View>
  );

  return (
    <SafeAreaView style={styles.safe} edges={['bottom', 'left', 'right']}>
      {stickyTop}
      <FlatList
        data={loading || error ? [] : filtered}
        keyExtractor={(i) => i.id}
        numColumns={2}
        columnWrapperStyle={styles.column}
        ListHeaderComponent={listStateHeader}
        renderItem={renderItem}
        keyboardShouldPersistTaps="handled"
        contentContainerStyle={[styles.listContent, { paddingBottom: 100 + insets.bottom }]}
        ListEmptyComponent={
          !loading && !error ? <Text style={styles.empty}>No medicines match your filters.</Text> : null
        }
        style={styles.listFlex}
      />

      <Modal visible={!!pickerProduct} animationType="slide" transparent>
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>Choose pack</Text>
            <Text style={styles.modalSub} numberOfLines={2}>
              {pickerProduct?.name}
            </Text>
            <ScrollView style={styles.brandList}>
              {selectableBrands.map((b) => {
                const active = b.id === selectedBrandId;
                const mrp = parseFloat(String(b.mrp ?? 0)) || 0;
                const pack = brandPackDescription(b);
                return (
                  <Pressable
                    key={b.id}
                    onPress={() => setSelectedBrandId(b.id!)}
                    style={[styles.brandRow, active && styles.brandRowActive]}>
                    <View style={styles.brandRowText}>
                      <Text style={styles.brandName}>{b.brand_name || b.name || 'Brand'}</Text>
                      {pack ? <Text style={styles.brandPackMeta}>{pack}</Text> : null}
                    </View>
                    <Text style={styles.brandPrice}>₹{mrp.toFixed(0)}</Text>
                  </Pressable>
                );
              })}
              {selectableBrands.length === 0 ? (
                <Text style={styles.modalSub}>No purchasable packs available right now.</Text>
              ) : null}
            </ScrollView>
            <View style={styles.qtyRow}>
              <View style={styles.qtyLabelCol}>
                <Text style={styles.qtyLabel}>Qty</Text>
                <Text style={styles.qtyHint}>Number of packs to add</Text>
              </View>
              <Pressable onPress={() => setPickerQty((q) => Math.max(1, q - 1))} style={styles.qtyBtn}>
                <Text style={styles.qtyBtnText}>−</Text>
              </Pressable>
              <Text style={styles.qtyVal}>{pickerQty}</Text>
              <Pressable onPress={() => setPickerQty((q) => q + 1)} style={styles.qtyBtn}>
                <Text style={styles.qtyBtnText}>+</Text>
              </Pressable>
            </View>
            <View style={styles.modalActions}>
              <Pressable style={styles.btnGhost} onPress={() => setPickerProduct(null)}>
                <Text style={styles.btnGhostText}>Cancel</Text>
              </Pressable>
              <Pressable style={[styles.btnPrimary, !canAddToBag && styles.btnDisabled]} onPress={confirmAdd} disabled={!canAddToBag}>
                <Text style={styles.btnPrimaryText}>Add to bag</Text>
              </Pressable>
            </View>
          </View>
        </View>
      </Modal>

      <Modal visible={showCategoryFilter} animationType="fade" transparent onRequestClose={() => setShowCategoryFilter(false)}>
        <Pressable style={styles.dropdownBackdrop} onPress={() => setShowCategoryFilter(false)}>
          <Pressable style={styles.dropdownCard} onPress={() => null}>
            <Text style={styles.dropdownTitle}>Select categories</Text>
            <View style={styles.dropdownSearchRow}>
              <FontAwesome name="search" size={15} color={Theme.gray500} />
              <TextInput
                value={categoryQuery}
                onChangeText={setCategoryQuery}
                placeholder="Search categories..."
                placeholderTextColor={Theme.gray400}
                style={styles.dropdownSearchInput}
              />
            </View>
            <ScrollView style={styles.dropdownList}>
              <Pressable
                onPress={() => setTempSelectedCategories([])}
                style={[styles.filterOption, tempSelectedCategories.length === 0 && styles.filterOptionActive]}>
                <Text style={[styles.filterOptionText, tempSelectedCategories.length === 0 && styles.filterOptionTextActive]}>
                  {tempSelectedCategories.length === 0 ? '✓ ' : ''}All categories
                </Text>
              </Pressable>
              {filteredCategoryOptions.map((c) => {
                const category = c.name;
                const active = tempSelectedCategories.includes(category);
                return (
                  <Pressable
                    key={category}
                    onPress={() =>
                      setTempSelectedCategories((prev) =>
                        prev.includes(category) ? prev.filter((x) => x !== category) : [...prev, category],
                      )
                    }
                    style={[styles.filterOption, active && styles.filterOptionActive]}>
                    <Text style={[styles.filterOptionText, active && styles.filterOptionTextActive]}>
                      {active ? '✓ ' : ''}
                      {category}
                    </Text>
                  </Pressable>
                );
              })}
              {filteredCategoryOptions.length === 0 ? (
                <Text style={styles.dropdownEmpty}>No categories found</Text>
              ) : null}
            </ScrollView>
            <View style={styles.dropdownActions}>
              <Pressable style={styles.btnGhost} onPress={() => setShowCategoryFilter(false)}>
                <Text style={styles.btnGhostText}>Cancel</Text>
              </Pressable>
              <Pressable
                style={styles.btnPrimary}
                onPress={() => {
                  setSelectedCategories(tempSelectedCategories);
                  setShowCategoryFilter(false);
                }}>
                <Text style={styles.btnPrimaryText}>Apply</Text>
              </Pressable>
            </View>
          </Pressable>
        </Pressable>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Theme.gray50 },
  listFlex: { flex: 1 },
  listContent: { paddingBottom: 100, paddingTop: 4 },
  listStateBox: { paddingVertical: 20, paddingHorizontal: 16, alignItems: 'center' },
  /** Sticky header: search + filters stay on screen */
  stickyTop: {
    backgroundColor: Theme.gray50,
    zIndex: 10,
    elevation: 6,
    shadowColor: '#0f172a',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 6,
  },
  hero: {
    marginHorizontal: 16,
    marginTop: 0,
    borderRadius: Theme.radiusLg,
    paddingHorizontal: 10,
    paddingTop: 6,
    paddingBottom: 6,
    overflow: 'hidden',
    ...Theme.shadowCard,
  },
  heroTopRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 6 },
  heroTitleBlock: { flex: 1, minWidth: 0 },
  brandLogo: { width: 32, height: 32, borderRadius: 8, backgroundColor: Theme.white },
  heroTitle: {
    fontFamily: Fonts.display,
    fontSize: 18,
    color: Theme.white,
    letterSpacing: -0.3,
    fontWeight: '800',
  },
  heroTagline: {
    fontFamily: Fonts.body,
    color: 'rgba(255,255,255,0.82)',
    fontSize: 12,
    marginTop: 2,
    lineHeight: 16,
  },
  deliveryNotice: {
    backgroundColor: 'rgba(255, 235, 235, 0.95)',
    borderLeftWidth: 3,
    borderLeftColor: '#dc2626',
    borderRadius: 8,
    paddingVertical: 4,
    paddingHorizontal: 8,
    marginTop: 6,
  },
  deliveryNoticeText: {
    fontFamily: Fonts.body,
    fontSize: 12,
    lineHeight: 16,
    fontWeight: '700',
    color: '#b91c1c',
  },
  searchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Theme.white,
    borderRadius: 10,
    marginTop: 0,
    paddingHorizontal: 10,
    minHeight: 36,
  },
  searchIcon: { marginRight: 6 },
  searchInput: { flex: 1, minHeight: 36, paddingVertical: 6, fontSize: 15, color: Theme.gray800, fontFamily: Fonts.body },
  filterRow: {
    marginTop: 4,
    marginBottom: 4,
    paddingHorizontal: 16,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  filterBtn: {
    flex: 1,
    backgroundColor: Theme.white,
    borderWidth: 1,
    borderColor: Theme.gray200,
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 10,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  filterBtnText: { flex: 1, color: Theme.gray800, fontFamily: Fonts.bodySemi, fontSize: 13 },
  clearFilterBtn: {
    backgroundColor: Theme.primaryLight,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  clearFilterBtnText: { color: Theme.primary, fontWeight: '700', fontSize: 12 },
  dropdownBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(15,23,42,0.3)',
    justifyContent: 'center',
    paddingHorizontal: 16,
  },
  dropdownCard: {
    backgroundColor: Theme.white,
    borderRadius: 14,
    padding: 16,
    borderWidth: 1,
    borderColor: Theme.gray200,
    maxHeight: '70%',
    ...Theme.shadowCard,
  },
  dropdownTitle: { fontSize: 17, fontWeight: '800', color: Theme.gray900, marginBottom: 10 },
  dropdownSearchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: Theme.gray50,
    borderWidth: 1,
    borderColor: Theme.gray200,
    borderRadius: 10,
    paddingHorizontal: 10,
    marginBottom: 10,
  },
  dropdownSearchInput: { flex: 1, height: 40, color: Theme.gray800, fontFamily: Fonts.body, fontSize: 14 },
  dropdownList: { maxHeight: 320 },
  dropdownActions: { flexDirection: 'row', justifyContent: 'flex-end', gap: 10, marginTop: 14 },
  filterOption: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: Theme.radiusFull,
    borderWidth: 1,
    borderColor: Theme.gray200,
    backgroundColor: Theme.gray50,
  },
  filterOptionActive: { backgroundColor: Theme.primary, borderColor: Theme.primary },
  filterOptionText: { fontFamily: Fonts.bodySemi, color: Theme.gray700, fontSize: 13 },
  filterOptionTextActive: { color: Theme.white },
  dropdownEmpty: { textAlign: 'center', color: Theme.gray500, paddingVertical: 16, fontSize: 13 },
  column: { justifyContent: 'space-between', paddingHorizontal: 12, marginBottom: 12 },
  cardWrap: { flex: 1, maxWidth: '50%', paddingHorizontal: 6 },
  card: {
    backgroundColor: Theme.white,
    borderRadius: Theme.radiusLg,
    padding: 12,
    borderWidth: 1,
    borderColor: Theme.gray200,
    ...Theme.shadowCard,
  },
  cardImageWrap: { position: 'relative', borderRadius: 10, overflow: 'hidden' },
  cardImage: { width: '100%', height: 110, backgroundColor: Theme.gray100 },
  rxBadge: {
    position: 'absolute',
    top: 6,
    right: 6,
    backgroundColor: Theme.secondary,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 6,
  },
  rxBadgeText: { color: Theme.white, fontSize: 10, fontWeight: '800' },
  cardTitle: { marginTop: 8, fontWeight: '700', color: Theme.gray900, fontSize: 14, minHeight: 38 },
  cardMeta: { color: Theme.gray500, fontSize: 12, marginTop: 2 },
  cardFooter: {
    marginTop: 8,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  price: { fontSize: 17, fontWeight: '800', color: Theme.primary },
  addHint: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 999,
    backgroundColor: Theme.primaryLight,
  },
  addHintText: { color: Theme.accentBlue, fontWeight: '800', fontSize: 15 },
  errorText: { color: Theme.gray600, textAlign: 'center' },
  retryBtn: { marginTop: 12, backgroundColor: Theme.primary, paddingHorizontal: 20, paddingVertical: 10, borderRadius: 10 },
  retryText: { color: Theme.white, fontWeight: '700' },
  empty: { textAlign: 'center', color: Theme.gray500, padding: 24 },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(15,23,42,0.45)',
    justifyContent: 'flex-end',
  },
  modalCard: {
    backgroundColor: Theme.white,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    padding: 20,
    maxHeight: '72%',
  },
  modalTitle: { fontSize: 20, fontWeight: '800', color: Theme.gray900 },
  modalSub: { color: Theme.gray600, marginTop: 4 },
  brandList: { maxHeight: 220, marginTop: 12 },
  brandRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: Theme.gray200,
    marginBottom: 8,
    gap: 10,
  },
  brandRowActive: { borderColor: Theme.primary, backgroundColor: Theme.primaryLight },
  brandRowText: { flex: 1, minWidth: 0 },
  brandName: { fontWeight: '600', color: Theme.gray800 },
  brandPackMeta: { marginTop: 3, fontSize: 12, lineHeight: 16, color: Theme.gray600, fontWeight: '500' },
  brandPrice: { fontWeight: '800', color: Theme.primary, fontSize: 16 },
  qtyRow: { flexDirection: 'row', alignItems: 'center', marginTop: 12, gap: 12 },
  qtyLabelCol: { flex: 1, minWidth: 0 },
  qtyLabel: { fontWeight: '600', color: Theme.gray700 },
  qtyHint: { marginTop: 2, fontSize: 11, lineHeight: 14, color: Theme.gray500 },
  qtyBtn: {
    width: 40,
    height: 40,
    borderRadius: 10,
    backgroundColor: Theme.gray100,
    alignItems: 'center',
    justifyContent: 'center',
  },
  qtyBtnText: { fontSize: 20, fontWeight: '700', color: Theme.gray800 },
  qtyVal: { fontSize: 18, fontWeight: '800', minWidth: 28, textAlign: 'center' },
  modalActions: { flexDirection: 'row', gap: 12, marginTop: 18 },
  btnGhost: {
    flex: 1,
    paddingVertical: 14,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: Theme.gray300,
    alignItems: 'center',
  },
  btnGhostText: { fontWeight: '700', color: Theme.gray700 },
  btnPrimary: {
    flex: 1,
    paddingVertical: 14,
    borderRadius: 12,
    backgroundColor: Theme.accentBlue,
    alignItems: 'center',
  },
  btnDisabled: { opacity: 0.5 },
  btnPrimaryText: { fontWeight: '800', color: Theme.white },
});
