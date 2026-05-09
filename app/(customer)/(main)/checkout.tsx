import React, { useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { SafeAreaView } from 'react-native-safe-area-context';
import * as DocumentPicker from 'expo-document-picker';
import RazorpayCheckout from 'react-native-razorpay';
import { router } from 'expo-router';

import { Fonts, Theme } from '@/constants/theme';
import { HREF_AUTH_LOGIN, HREF_PROFILE } from '@/lib/navigation';
import { SHOP_CITY, SHOP_PINCODE, SHOP_STATE } from '@/lib/shopLocation';
import type { Href } from 'expo-router';
import { useAuth } from '@/context/AuthContext';
import { useCart } from '@/context/CartContext';
import { computeDeliveryFee, getDeliverySettings, type DeliverySettings } from '@/services/delivery';
import { initiatePayment, verifyPayment } from '@/services/razorpay';
import { getMyAddresses, createAddress, type AddressRow } from '@/services/addresses';
import { getActiveCoupons, validateCoupon, type CouponRow } from '@/services/coupons';
import { uploadPrescriptionFromPicker } from '@/services/upload';

function openCustomerAuth(returnTo: string, mode?: string) {
  router.push({
    pathname: HREF_AUTH_LOGIN,
    params: { intent: 'customer', returnTo, ...(mode ? { mode } : {}) },
  } as Href);
}

export default function CheckoutScreen() {
  const { user } = useAuth();
  const { cart, subtotal, updateQuantity, removeFromCart, clearCart } = useCart();
  const [settings, setSettings] = useState<DeliverySettings | null>(null);
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [street, setStreet] = useState('');
  const [savedAddresses, setSavedAddresses] = useState<AddressRow[]>([]);
  const [loadingAddresses, setLoadingAddresses] = useState(false);
  const [selectedAddressId, setSelectedAddressId] = useState<string | null>(null);
  const [saveAddress, setSaveAddress] = useState(false);
  const [addressLabel, setAddressLabel] = useState('');
  const [availableCoupons, setAvailableCoupons] = useState<CouponRow[]>([]);
  const [couponCode, setCouponCode] = useState('');
  const [discountAmount, setDiscountAmount] = useState(0);
  const [couponMsg, setCouponMsg] = useState('');
  const [prescription, setPrescription] = useState<{ stored_as?: string; url?: string } | null>(null);
  const [uploadingRx, setUploadingRx] = useState(false);
  const [paying, setPaying] = useState(false);
  useEffect(() => {
    getDeliverySettings().then(setSettings).catch(() => setSettings({ is_enabled: true }));
  }, []);

  useEffect(() => {
    if (user) {
      setName(user.name || '');
      setEmail(user.email || '');
      const digits = String(user.mobile_number || '').replace(/\D/g, '');
      if (digits.length >= 10) {
        setPhone(digits.slice(-10));
      }
    }
  }, [user]);

  useEffect(() => {
    if (!user) return;
    setLoadingAddresses(true);
    getMyAddresses()
      .then((rows) => {
        setSavedAddresses(rows ?? []);
        const d = (rows ?? []).find((r) => r.is_default);
        if (!d) return;
        setSelectedAddressId(d.id);
        setStreet(d.street || '');
      })
      .catch(() => setSavedAddresses([]))
      .finally(() => setLoadingAddresses(false));
  }, [user]);

  useEffect(() => {
    getActiveCoupons().then(setAvailableCoupons).catch(() => setAvailableCoupons([]));
  }, []);

  const deliveryFee = useMemo(() => computeDeliveryFee(subtotal, settings), [subtotal, settings]);
  const finalTotal = Math.max(0, subtotal - discountAmount + deliveryFee);
  const cartNeedsRx = cart.some((c) => c.requiresPrescription);
  const rxOk = !cartNeedsRx || Boolean(prescription?.stored_as || prescription?.url);

  const applyCoupon = async () => {
    setCouponMsg('');
    if (!couponCode.trim()) return;
    try {
      const res = await validateCoupon(couponCode, subtotal, user?.id ?? null);
      if (res.valid && res.discount_amount != null) {
        const d = Number(res.discount_amount);
        setDiscountAmount(Number.isFinite(d) ? d : 0);
        setCouponMsg(res.message || 'Coupon applied');
      } else {
        setDiscountAmount(0);
        setCouponMsg(res.message || 'Invalid coupon');
      }
    } catch (e) {
      setDiscountAmount(0);
      setCouponMsg(e instanceof Error ? e.message : 'Coupon failed');
    }
  };

  const pickPrescription = async () => {
    if (!user) {
      Alert.alert('Sign in required', 'Please sign in to upload a prescription.', [
        { text: 'Not now', style: 'cancel' },
        { text: 'Sign in', onPress: () => openCustomerAuth('/checkout') },
      ]);
      return;
    }
    setUploadingRx(true);
    try {
      const pick = await DocumentPicker.getDocumentAsync({
        type: ['image/*', 'application/pdf'],
        copyToCacheDirectory: true,
      });
      const up = await uploadPrescriptionFromPicker(pick);
      setPrescription({ stored_as: up.stored_as, url: up.url });
    } catch (e) {
      Alert.alert('Upload', e instanceof Error ? e.message : 'Could not upload');
    } finally {
      setUploadingRx(false);
    }
  };

  const itemNeedsRx = (item: (typeof cart)[0]) => item.requiresPrescription;
  const isRazorpayAvailable = typeof (RazorpayCheckout as { open?: unknown } | null)?.open === 'function';

  const pay = async () => {
    if (!user) {
      Alert.alert('Sign in required', 'Please sign in to pay and place your order.', [
        { text: 'Not now', style: 'cancel' },
        { text: 'Sign in', onPress: () => openCustomerAuth('/checkout') },
      ]);
      return;
    }
    if (!settings || settings.is_enabled === false) {
      Alert.alert('Delivery', 'Delivery is currently unavailable.');
      return;
    }
    if (!name.trim() || !phone.trim() || !street.trim()) {
      Alert.alert('Address', 'Please fill your name, phone, and street / flat.');
      return;
    }
    if (cartNeedsRx && !rxOk) {
      Alert.alert('Prescription', 'This order includes prescription items. Upload a prescription or remove those items.');
      return;
    }

    setPaying(true);
    try {
      if (user && saveAddress && !selectedAddressId) {
        await createAddress({
          label: addressLabel.trim() || undefined,
          street: street.trim(),
          city: SHOP_CITY,
          state: SHOP_STATE,
          pincode: SHOP_PINCODE,
          country: 'India',
          is_default: savedAddresses.length === 0,
        }).catch(() => null);
      }

      const orderData = {
        customer_name: name.trim(),
        customer_phone: phone.trim(),
        customer_email: email.trim() || undefined,
        delivery_address: `${street.trim()}, ${SHOP_CITY}, ${SHOP_STATE} - ${SHOP_PINCODE}, India`,
        pincode: SHOP_PINCODE,
        city: SHOP_CITY,
        items: cart.map((item) => ({
          medicine_brand_id: item.brandId,
          name: item.name,
          quantity: item.quantity,
          price: item.price,
          requires_prescription: itemNeedsRx(item),
        })),
        subtotal,
        delivery_fee: deliveryFee,
        discount_amount: discountAmount,
        final_amount: finalTotal,
        coupon_code: discountAmount > 0 ? couponCode.toUpperCase().trim() : null,
        applied_coupons:
          discountAmount > 0
            ? [{ code: couponCode.toUpperCase().trim(), discount_amount: discountAmount }]
            : null,
        prescription_path: prescription?.stored_as || prescription?.url || undefined,
      };

      const result = await initiatePayment(orderData);
      if (!result?.order_id || !result?.razorpay_order_id || result.key_id == null) {
        throw new Error('Could not start payment');
      }

      const amountPaise = Math.round(Number(result.amount));
      if (!Number.isFinite(amountPaise) || amountPaise < 1) {
        throw new Error('Invalid amount from server');
      }

      const phoneDigits = phone.replace(/\D/g, '');
      const contactPrefill = phoneDigits.length >= 10 ? `+91${phoneDigits.slice(-10)}` : undefined;

      if (!isRazorpayAvailable) {
        Alert.alert(
          'Payment unavailable',
          'Razorpay is not available in this build. Use a development client / release build with native modules enabled.',
        );
        return;
      }

      const payRes = await RazorpayCheckout.open({
        key: result.key_id,
        amount: String(amountPaise),
        currency: 'INR',
        order_id: result.razorpay_order_id,
        name: 'New Balan Pharmacy',
        description: `Order ${result.order_reference || result.order_id}`,
        prefill: {
          name: name.trim(),
          ...(email.trim() ? { email: email.trim() } : {}),
          ...(contactPrefill ? { contact: contactPrefill } : {}),
        },
        theme: { color: Theme.accentBlue },
        notes: { internal_order_id: result.order_id },
      });

      await verifyPayment({
        razorpay_payment_id: payRes.razorpay_payment_id,
        razorpay_order_id: payRes.razorpay_order_id,
        razorpay_signature: payRes.razorpay_signature,
      });

      clearCart();
      setPrescription(null);
      setDiscountAmount(0);
      setCouponCode('');
      Alert.alert('Thank you', 'Payment successful. Your order is placed.');
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      if (msg.includes('cancel') || msg.includes('back')) {
        /* user closed checkout */
      } else {
        Alert.alert('Payment', msg || 'Something went wrong');
      }
    } finally {
      setPaying(false);
    }
  };

  if (cart.length === 0) {
    return (
      <SafeAreaView style={styles.safe} edges={['bottom', 'left', 'right']}>
        <LinearGradient colors={[...Theme.gradientHero]} style={styles.emptyHero}>
          <Text style={styles.emptyTitle}>Your bag is empty</Text>
          <Text style={styles.emptySub}>Add medicines from the Pharmacy tab.</Text>
        </LinearGradient>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safe} edges={['bottom', 'left', 'right']}>
      <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
        <Text style={styles.screenTitle}>Checkout</Text>

        {!user ? (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Sign in</Text>
            <Text style={styles.hint}>Sign in to upload prescriptions, apply some coupons, and pay securely.</Text>
            <Pressable style={styles.secondaryBtn} onPress={() => openCustomerAuth('/checkout')}>
              <Text style={styles.secondaryBtnText}>Sign in or create account</Text>
            </Pressable>
          </View>
        ) : null}

        <View style={[styles.card, styles.contactCard]}>
          <View style={styles.contactTitleRow}>
            <Text style={styles.contactHeading}>Contact</Text>
            {user ? (
              <Pressable
                onPress={() => router.push(HREF_PROFILE as Href)}
                hitSlop={8}
                accessibilityRole="button"
                accessibilityLabel="Open profile to edit contact details">
                <Text style={styles.profileLinkTextSmall}>Edit in profile</Text>
              </Pressable>
            ) : null}
          </View>
          {user ? (
            <View>
              <View style={styles.contactField}>
                <Text style={styles.fieldLabelTight}>Name</Text>
                <Text style={styles.contactValue} numberOfLines={1}>
                  {name || '—'}
                </Text>
              </View>
              <View style={styles.contactField}>
                <Text style={styles.fieldLabelTight}>Phone</Text>
                <Text style={styles.contactValue} numberOfLines={1}>
                  {phone || '—'}
                </Text>
              </View>
              <View style={styles.contactFieldLast}>
                <Text style={styles.fieldLabelTight}>Email</Text>
                <Text style={[styles.contactValue, !email && styles.contactValueEmpty]} numberOfLines={1}>
                  {email || 'Not set'}
                </Text>
              </View>
            </View>
          ) : (
            <>
              <Text style={styles.contactHint}>After sign-in, contact is managed in profile.</Text>
              <TextInput style={styles.input} placeholder="Full name" value={name} onChangeText={setName} />
              <TextInput style={styles.input} placeholder="Phone" value={phone} onChangeText={setPhone} keyboardType="phone-pad" />
              <TextInput style={styles.input} placeholder="Email (optional)" value={email} onChangeText={setEmail} autoCapitalize="none" />
            </>
          )}
        </View>

        <View style={[styles.card, styles.addressCard]}>
          <Text style={styles.cardTitle}>Delivery address</Text>
          {user && savedAddresses.length > 0 ? (
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.addressRow}>
              {savedAddresses.map((addr) => (
                <Pressable
                  key={addr.id}
                  style={[styles.addressChip, selectedAddressId === addr.id && styles.addressChipActive]}
                  onPress={() => {
                    setSelectedAddressId(addr.id);
                    setStreet(addr.street || '');
                  }}>
                  <Text style={styles.addressChipTitle}>{addr.label || 'Address'}</Text>
                  <Text style={styles.addressChipSub} numberOfLines={2}>
                    {addr.street}, {addr.city}
                  </Text>
                </Pressable>
              ))}
            </ScrollView>
          ) : null}
          {loadingAddresses ? <Text style={styles.addressMeta}>Loading saved addresses...</Text> : null}
          <Text style={styles.addressMeta}>Service area is fixed for this shop.</Text>
          <TextInput style={styles.input} placeholder="Street / flat" value={street} onChangeText={setStreet} />
          <View style={styles.serviceAreaBox}>
            <Text style={styles.serviceAreaText}>
              {SHOP_CITY}, {SHOP_STATE} - {SHOP_PINCODE}
            </Text>
          </View>
          {user ? (
            <>
              <Pressable style={styles.checkboxRow} onPress={() => setSaveAddress((v) => !v)}>
                <Text style={styles.checkbox}>{saveAddress ? '☑' : '☐'}</Text>
                <Text style={styles.checkboxText}>Save this address for future orders</Text>
              </Pressable>
              {saveAddress ? (
                <TextInput
                  style={styles.input}
                  placeholder="Address label (Home/Office)"
                  value={addressLabel}
                  onChangeText={setAddressLabel}
                />
              ) : null}
            </>
          ) : null}
        </View>

        {cartNeedsRx ? (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Prescription</Text>
            <Text style={styles.hint}>Order includes Rx items — upload a clear photo or PDF.</Text>
            <Pressable style={styles.outlineBtn} onPress={pickPrescription} disabled={uploadingRx}>
              <Text style={styles.outlineBtnText}>{uploadingRx ? 'Uploading…' : prescription ? 'Replace file' : 'Upload prescription'}</Text>
            </Pressable>
            {prescription ? <Text style={styles.ok}>File attached ✓</Text> : null}
          </View>
        ) : null}

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Coupon</Text>
          {availableCoupons.length > 0 ? (
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.addressRow}>
              {availableCoupons.map((cp) => (
                <Pressable key={cp.id} style={styles.slotChip} onPress={() => setCouponCode(cp.code)}>
                  <Text style={styles.slotChipText}>{cp.code}</Text>
                </Pressable>
              ))}
            </ScrollView>
          ) : null}
          <View style={styles.couponRow}>
            <TextInput style={[styles.input, styles.couponInput]} placeholder="Code" value={couponCode} onChangeText={setCouponCode} autoCapitalize="characters" />
            <Pressable style={styles.smallBtn} onPress={applyCoupon}>
              <Text style={styles.smallBtnText}>Apply</Text>
            </Pressable>
          </View>
          {couponMsg ? <Text style={styles.couponMsg}>{couponMsg}</Text> : null}
        </View>

        <View style={[styles.card, styles.summaryCard]}>
          <View style={styles.summaryTopBar}>
            <Text style={styles.summaryTitle}>Order summary</Text>
            <Text style={styles.summaryCount}>
              {cart.length} {cart.length === 1 ? 'item' : 'items'}
            </Text>
          </View>
          {cart.map((line, index) => {
            const lineTotal = line.price * line.quantity;
            return (
              <View
                key={line.brandId}
                style={[styles.orderItem, index < cart.length - 1 && styles.orderItemDivider]}>
                <View style={styles.orderItemHead}>
                  <Text style={styles.orderItemName} numberOfLines={2}>
                    {line.name}
                  </Text>
                  <Text style={styles.orderItemLineTotal}>₹{lineTotal.toFixed(2)}</Text>
                </View>
                <View style={styles.orderItemFoot}>
                  <Text style={styles.orderItemMeta} numberOfLines={1}>
                    ₹{Number(line.price).toFixed(2)} each × {line.quantity}
                  </Text>
                  <View style={styles.orderItemActions}>
                    <View style={styles.qtyPill}>
                      <Pressable
                        onPress={() => updateQuantity(line.brandId, line.quantity - 1)}
                        style={styles.qtyPillHit}
                        hitSlop={6}
                        accessibilityLabel="Decrease quantity">
                        <Text style={styles.qtyPillSymbol}>−</Text>
                      </Pressable>
                      <Text style={styles.qtyPillValue}>{line.quantity}</Text>
                      <Pressable
                        onPress={() => updateQuantity(line.brandId, line.quantity + 1)}
                        style={styles.qtyPillHit}
                        hitSlop={6}
                        accessibilityLabel="Increase quantity">
                        <Text style={styles.qtyPillSymbol}>+</Text>
                      </Pressable>
                    </View>
                    <Pressable
                      onPress={() => removeFromCart(line.brandId)}
                      hitSlop={8}
                      style={styles.removePill}
                      accessibilityLabel="Remove from bag">
                      <Text style={styles.removePillText}>Remove</Text>
                    </Pressable>
                  </View>
                </View>
              </View>
            );
          })}

          <View style={styles.billBlock}>
            <View style={styles.billLine}>
              <Text style={styles.billLineLabel}>Subtotal</Text>
              <Text style={styles.billLineValue}>₹{subtotal.toFixed(2)}</Text>
            </View>
            <View style={styles.billLine}>
              <Text style={styles.billLineLabel}>Delivery</Text>
              <Text style={styles.billLineValue}>₹{deliveryFee.toFixed(2)}</Text>
            </View>
            {discountAmount > 0 ? (
              <View style={styles.billLine}>
                <Text style={styles.billLineLabelDiscount}>Discount</Text>
                <Text style={styles.billLineValueDiscount}>−₹{discountAmount.toFixed(2)}</Text>
              </View>
            ) : null}
            {cartNeedsRx ? (
              <View style={styles.rxNote}>
                <Text style={styles.rxNoteText}>
                  Prescription: {rxOk ? '✓ Attached' : 'Required before pay'}
                </Text>
              </View>
            ) : null}
            <View style={styles.billTotalBar}>
              <Text style={styles.billTotalLabel}>Amount to pay</Text>
              <Text style={styles.billTotalValue}>₹{finalTotal.toFixed(2)}</Text>
            </View>
          </View>
        </View>

        <Pressable style={[styles.payBtn, paying && styles.payDisabled]} onPress={pay} disabled={paying}>
          {paying ? (
            <ActivityIndicator color={Theme.white} />
          ) : (
            <Text style={styles.payText}>Pay with Razorpay</Text>
          )}
        </Pressable>
        <Text style={styles.footNote}>Secure payment powered by Razorpay.</Text>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Theme.gray50 },
  scroll: { paddingTop: 6, paddingHorizontal: 12, paddingBottom: 12 },
  screenTitle: {
    fontFamily: Fonts.display,
    fontSize: 20,
    fontWeight: '800',
    color: Theme.gray900,
    marginBottom: 8,
    letterSpacing: -0.3,
  },
  card: {
    backgroundColor: Theme.white,
    borderRadius: Theme.radiusXl,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: Theme.gray200,
    ...Theme.shadowCard,
  },
  contactCard: { padding: 12 },
  addressCard: { padding: 12 },
  contactTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 8,
    marginBottom: 2,
  },
  contactHeading: { fontSize: 16, fontWeight: '800', color: Theme.gray900 },
  cardTitle: { fontSize: 17, fontWeight: '800', color: Theme.gray900, marginBottom: 8 },
  contactHint: { color: Theme.gray600, marginBottom: 8, fontSize: 12, lineHeight: 16 },
  contactField: { flexDirection: 'row', alignItems: 'center', paddingVertical: 6, borderBottomWidth: 1, borderBottomColor: Theme.gray100 },
  contactFieldLast: { flexDirection: 'row', alignItems: 'center', paddingVertical: 6 },
  fieldLabelTight: { width: 56, fontSize: 12, fontWeight: '800', color: Theme.gray500 },
  contactValue: { flex: 1, fontSize: 14, fontWeight: '600', color: Theme.gray800, paddingLeft: 4 },
  contactValueEmpty: { color: Theme.gray500, fontWeight: '500' },
  profileLinkTextSmall: { color: Theme.primary, fontSize: 13, fontWeight: '800' },
  hint: { color: Theme.gray600, marginBottom: 10, fontSize: 13 },
  input: {
    borderWidth: 1,
    borderColor: Theme.gray200,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    marginBottom: 10,
    fontSize: 16,
    color: Theme.gray800,
  },
  addressMeta: { color: Theme.gray600, marginBottom: 8, fontSize: 12, lineHeight: 16 },
  serviceAreaBox: {
    borderWidth: 1,
    borderColor: Theme.gray200,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 9,
    marginBottom: 10,
    backgroundColor: Theme.gray100,
  },
  serviceAreaText: { fontSize: 14, color: Theme.gray700, fontWeight: '700' },
  secondaryBtn: {
    backgroundColor: Theme.primary,
    paddingVertical: 12,
    borderRadius: 12,
    alignItems: 'center',
  },
  secondaryBtnText: { color: Theme.white, fontWeight: '800' },
  checkboxRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 8 },
  checkbox: { fontSize: 18, color: Theme.gray700 },
  checkboxText: { color: Theme.gray600, fontSize: 12 },
  outlineBtn: {
    borderWidth: 1,
    borderColor: Theme.primary,
    paddingVertical: 12,
    borderRadius: 12,
    alignItems: 'center',
  },
  outlineBtnText: { color: Theme.primary, fontWeight: '700' },
  ok: { marginTop: 8, color: Theme.secondaryDark, fontWeight: '600' },
  couponRow: { flexDirection: 'row', gap: 8, alignItems: 'center' },
  addressRow: { gap: 8, paddingBottom: 6 },
  addressChip: {
    width: 156,
    borderWidth: 1,
    borderColor: Theme.gray200,
    borderRadius: 10,
    padding: 8,
    backgroundColor: Theme.white,
  },
  addressChipActive: { borderColor: Theme.primary, backgroundColor: Theme.primaryLight },
  addressChipTitle: { fontWeight: '700', color: Theme.gray800, marginBottom: 1, fontSize: 12 },
  addressChipSub: { fontSize: 12, color: Theme.gray600 },
  slotChip: {
    borderWidth: 1,
    borderColor: Theme.gray300,
    borderRadius: 999,
    paddingVertical: 7,
    paddingHorizontal: 12,
    backgroundColor: Theme.white,
  },
  slotChipText: { color: Theme.gray700, fontWeight: '600' },
  couponInput: { flex: 1, marginBottom: 0 },
  smallBtn: { backgroundColor: Theme.gray800, paddingHorizontal: 16, paddingVertical: 12, borderRadius: 10 },
  smallBtnText: { color: Theme.white, fontWeight: '700' },
  couponMsg: { marginTop: 8, color: Theme.gray600, fontSize: 13 },
  /** Order summary: line items + bill breakdown */
  summaryCard: { padding: 0, overflow: 'hidden' },
  summaryTopBar: {
    flexDirection: 'row',
    alignItems: 'baseline',
    justifyContent: 'space-between',
    paddingHorizontal: 14,
    paddingTop: 14,
    paddingBottom: 10,
  },
  summaryTitle: { fontSize: 17, fontWeight: '800', color: Theme.gray900, marginBottom: 0 },
  summaryCount: { fontSize: 12, fontWeight: '700', color: Theme.gray500, textTransform: 'uppercase', letterSpacing: 0.4 },
  orderItem: { paddingHorizontal: 14, paddingVertical: 10 },
  orderItemDivider: { borderBottomWidth: 1, borderBottomColor: Theme.gray100 },
  orderItemHead: { flexDirection: 'row', alignItems: 'flex-start', gap: 10, marginBottom: 8 },
  orderItemName: { flex: 1, fontSize: 14, fontWeight: '700', color: Theme.gray800, lineHeight: 20 },
  orderItemLineTotal: { fontSize: 15, fontWeight: '800', color: Theme.gray900, fontFamily: Fonts.bodySemi },
  orderItemFoot: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 8 },
  orderItemMeta: { flex: 1, minWidth: 0, fontSize: 12, color: Theme.gray500, fontWeight: '600' },
  orderItemActions: { flexDirection: 'row', alignItems: 'center', flexShrink: 0, gap: 6 },
  qtyPill: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Theme.gray100,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: Theme.gray200,
    overflow: 'hidden',
  },
  qtyPillHit: { paddingHorizontal: 10, paddingVertical: 4, minWidth: 32, alignItems: 'center' },
  qtyPillSymbol: { fontSize: 18, fontWeight: '700', color: Theme.primary, lineHeight: 22 },
  qtyPillValue: { fontSize: 14, fontWeight: '800', color: Theme.gray800, minWidth: 24, textAlign: 'center', paddingVertical: 4 },
  removePill: { paddingVertical: 4, paddingHorizontal: 6 },
  removePillText: { color: '#b91c1c', fontWeight: '700', fontSize: 12 },
  billBlock: {
    marginTop: 4,
    marginHorizontal: 10,
    marginBottom: 10,
    padding: 12,
    borderRadius: 14,
    backgroundColor: Theme.gray100,
    borderWidth: 1,
    borderColor: Theme.gray200,
  },
  billLine: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 },
  billLineLabel: { fontSize: 14, color: Theme.gray600, fontWeight: '600' },
  billLineValue: { fontSize: 14, color: Theme.gray800, fontWeight: '700', fontFamily: Fonts.bodySemi },
  billLineLabelDiscount: { fontSize: 14, color: Theme.secondaryDark, fontWeight: '600' },
  billLineValueDiscount: { fontSize: 14, color: Theme.secondaryDark, fontWeight: '800', fontFamily: Fonts.bodySemi },
  rxNote: { marginBottom: 8, paddingTop: 2 },
  rxNoteText: { fontSize: 12, color: Theme.gray600, fontWeight: '600' },
  billTotalBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 6,
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: Theme.gray200,
  },
  billTotalLabel: { fontSize: 15, fontWeight: '800', color: Theme.gray800 },
  billTotalValue: { fontSize: 22, fontWeight: '800', color: Theme.accentBlue, fontFamily: Fonts.display },
  payBtn: {
    backgroundColor: Theme.accentBlue,
    paddingVertical: 16,
    borderRadius: 14,
    alignItems: 'center',
    marginTop: 6,
    shadowColor: Theme.accentBlue,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.35,
    shadowRadius: 12,
    elevation: 4,
  },
  payDisabled: { opacity: 0.55 },
  payText: { color: Theme.white, fontWeight: '800', fontSize: 17 },
  footNote: { marginTop: 6, marginBottom: 0, fontSize: 11, color: Theme.gray500, textAlign: 'center' },
  emptyHero: { margin: 16, borderRadius: Theme.radiusXl, padding: 32, ...Theme.shadowCard },
  emptyTitle: { fontSize: 22, fontWeight: '800', color: Theme.white },
  emptySub: { color: 'rgba(255,255,255,0.9)', marginTop: 8 },
});
