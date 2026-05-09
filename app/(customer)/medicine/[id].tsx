import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Image,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, router } from 'expo-router';

import { Theme } from '@/constants/theme';
import { useCart } from '@/context/CartContext';
import { useToast } from '@/context/ToastContext';
import { getStorageFileUrl } from '@/lib/storageUrl';
import { brandPackDescription, isBrandPurchasable, type MedicineBrand } from '@/lib/pharmacyUtils';
import { getMedicineById, type MedicineRow } from '@/services/medicines';
import { getMedicineCategoryById } from '@/services/categories';

export default function MedicineDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string | string[] }>();
  const medicineId = Array.isArray(id) ? id[0] : id;
  const { addToCart } = useCart();
  const toast = useToast();
  const [med, setMed] = useState<MedicineRow | null>(null);
  const [categoryName, setCategoryName] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!medicineId) return;
    setLoading(true);
    setError(null);
    try {
      const m = await getMedicineById(medicineId, true);
      setMed(m);
      const catId = m.medicine_category_id;
      if (catId) {
        try {
          const c = await getMedicineCategoryById(catId);
          setCategoryName(c.name);
        } catch {
          setCategoryName(m.medicine_category_name || null);
        }
      } else {
        setCategoryName(m.medicine_category_name || null);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load');
      setMed(null);
    } finally {
      setLoading(false);
    }
  }, [medicineId]);

  useEffect(() => {
    load();
  }, [load]);

  const buyable = (med?.brands || []).filter((b) => isBrandPurchasable(b) && b.id);

  const addBrand = (brand: MedicineBrand) => {
    if (!med?.id || !brand.id) return;
    const price = parseFloat(String(brand.mrp ?? 0)) || 0;
    const bname = brand.brand_name || brand.name || 'Brand';
    const pack = brandPackDescription(brand);
    addToCart({
      medicineId: med.id,
      brandId: brand.id,
      name: pack ? `${med.name} · ${bname} — ${pack}` : `${med.name} · ${bname}`,
      price,
      requiresPrescription: Boolean(med.is_prescription_required),
      quantity: 1,
    });
    toast.success(`${med.name} added to cart`);
  };

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={Theme.primary} />
      </View>
    );
  }

  if (error || !med) {
    return (
      <SafeAreaView style={styles.safe} edges={['top']}>
        <Text style={styles.err}>{error || 'Not found'}</Text>
        <Pressable style={styles.back} onPress={() => router.back()}>
          <Text style={styles.backText}>Back</Text>
        </Pressable>
      </SafeAreaView>
    );
  }

  const img = getStorageFileUrl(med.image_path);

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Pressable onPress={() => router.back()} hitSlop={12} style={styles.backRow}>
          <Text style={styles.backLink}>‹ Back to pharmacy</Text>
        </Pressable>

        {img ? (
          <Image source={{ uri: img }} style={styles.heroImg} />
        ) : (
          <LinearGradient colors={[Theme.primaryLight, Theme.white]} style={styles.heroImg}>
            <Text style={styles.heroPlaceholder}>No image</Text>
          </LinearGradient>
        )}

        <Text style={styles.title}>{med.name}</Text>
        <Text style={styles.meta}>{categoryName || med.medicine_category_name || 'Medicine'}</Text>
        {med.is_prescription_required ? (
          <View style={styles.rx}>
            <Text style={styles.rxText}>Prescription required for purchase</Text>
          </View>
        ) : null}
        {med.description ? <Text style={styles.desc}>{med.description}</Text> : null}

        <Text style={styles.section}>Available packs</Text>
        {buyable.length === 0 ? (
          <Text style={styles.none}>No packs in stock right now.</Text>
        ) : (
          buyable.map((b) => {
            const mrp = parseFloat(String(b.mrp ?? 0)) || 0;
            const pack = brandPackDescription(b);
            return (
              <View key={b.id} style={styles.row}>
                <View style={{ flex: 1, minWidth: 0 }}>
                  <Text style={styles.brandName}>{b.brand_name || b.name || 'Brand'}</Text>
                  {pack ? <Text style={styles.brandPack}>{pack}</Text> : null}
                  <Text style={styles.mrp}>₹{mrp.toFixed(0)}</Text>
                </View>
                <Pressable style={styles.addBtn} onPress={() => addBrand(b)}>
                  <Text style={styles.addBtnText}>Add</Text>
                </Pressable>
              </View>
            );
          })
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Theme.gray50 },
  center: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  scroll: { padding: 16, paddingBottom: 40 },
  backRow: { marginBottom: 12 },
  backLink: { color: Theme.primary, fontWeight: '700' },
  heroImg: { width: '100%', height: 200, borderRadius: 14, marginBottom: 16, alignItems: 'center', justifyContent: 'center' },
  heroPlaceholder: { color: Theme.gray500, fontWeight: '600' },
  title: { fontSize: 24, fontWeight: '800', color: Theme.gray900 },
  meta: { marginTop: 6, color: Theme.gray600, fontSize: 15 },
  rx: {
    marginTop: 10,
    backgroundColor: 'rgba(40,167,69,0.12)',
    padding: 10,
    borderRadius: 10,
  },
  rxText: { color: Theme.secondaryDark, fontWeight: '700', fontSize: 13 },
  desc: { marginTop: 14, fontSize: 15, lineHeight: 22, color: Theme.gray800 },
  section: { marginTop: 22, fontSize: 16, fontWeight: '800', color: Theme.gray900 },
  none: { marginTop: 8, color: Theme.gray500 },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 10,
    padding: 14,
    backgroundColor: Theme.white,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: Theme.gray200,
  },
  brandName: { fontWeight: '700', color: Theme.gray900, fontSize: 16 },
  brandPack: { marginTop: 4, fontSize: 13, lineHeight: 18, color: Theme.gray600, fontWeight: '500' },
  mrp: { marginTop: 4, fontSize: 18, fontWeight: '800', color: Theme.primary },
  addBtn: { backgroundColor: Theme.accentBlue, paddingVertical: 10, paddingHorizontal: 18, borderRadius: 10 },
  addBtnText: { color: Theme.white, fontWeight: '800' },
  err: { textAlign: 'center', marginTop: 40, color: Theme.gray600 },
  back: { marginTop: 16, alignSelf: 'center' },
  backText: { color: Theme.primary, fontWeight: '700' },
});
