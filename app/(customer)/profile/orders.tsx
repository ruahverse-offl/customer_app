import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Modal,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import FontAwesome from '@expo/vector-icons/FontAwesome';

import { ProfileAuthGate } from '@/components/ProfileAuthGate';
import { Fonts, Theme } from '@/constants/theme';
import { profileStyles } from '@/constants/profileScreenStyles';
import { useAuth } from '@/context/AuthContext';
import { formatOrderStatusLabel, normalizeOrderStatus } from '@/lib/orderLifecycle';
import { getOrderDetail, getOrders, type OrderItemRow, type OrderDetailResponse, type OrderRow } from '@/services/orders';

function formatOrderDate(iso: string | null | undefined): string | null {
  if (!iso) return null;
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return null;
  return d.toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' });
}

function statusPillColors(normalized: string): { bg: string; text: string; border: string } {
  if (['DELIVERED', 'COMPLETED'].includes(normalized)) {
    return { bg: Theme.secondaryLight, text: Theme.secondaryDark, border: 'rgba(40, 167, 69, 0.35)' };
  }
  if (
    new Set([
      'CANCELLED_BY_STAFF',
      'CANCELLED',
      'PAYMENT_CANCELLED',
      'REFUNDED',
      'REFUND_INITIATED',
      'DELIVERY_RETURNED',
    ]).has(normalized)
  ) {
    return { bg: '#fef2f2', text: '#b91c1c', border: '#fecaca' };
  }
  if (normalized === 'PENDING' || normalized.startsWith('PAYMENT')) {
    return { bg: '#fffbeb', text: '#b45309', border: '#fde68a' };
  }
  return { bg: Theme.primaryLight, text: Theme.primary, border: 'rgba(0, 86, 179, 0.2)' };
}

function OrderDetailField({ label, value }: { label: string; value: string }) {
  return (
    <View style={s.detailField}>
      <Text style={s.detailLabel}>{label}</Text>
      <Text style={s.detailValue}>{value}</Text>
    </View>
  );
}

function lineItemTitle(item: OrderItemRow): string {
  const med = (item.medicine_name || '').trim();
  const brand = (item.brand_name || '').trim();
  if (med && brand) return `${med} — ${brand}`;
  return med || brand || 'Medicine';
}

function OrdersContent() {
  const { token } = useAuth();
  const [orders, setOrders] = useState<OrderRow[]>([]);
  const [selectedOrder, setSelectedOrder] = useState<OrderRow | null>(null);
  const [orderDetail, setOrderDetail] = useState<OrderDetailResponse | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailError, setDetailError] = useState<string | null>(null);
  const [ordersLoading, setOrdersLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);

  const closeOrderModal = useCallback(() => {
    setSelectedOrder(null);
    setOrderDetail(null);
    setDetailError(null);
    setDetailLoading(false);
  }, []);

  useEffect(() => {
    if (!selectedOrder?.id) {
      setOrderDetail(null);
      setDetailError(null);
      return;
    }
    setOrderDetail(null);
    let cancelled = false;
    setDetailLoading(true);
    setDetailError(null);
    getOrderDetail(selectedOrder.id)
      .then((d) => {
        if (!cancelled) {
          setOrderDetail(d);
        }
      })
      .catch((e) => {
        if (!cancelled) {
          setOrderDetail(null);
          setDetailError(e instanceof Error ? e.message : 'Could not load order items');
        }
      })
      .finally(() => {
        if (!cancelled) setDetailLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [selectedOrder?.id]);

  const loadOrders = useCallback(async () => {
    if (!token) return;
    setOrdersLoading(true);
    setLoadError(null);
    try {
      const res = await getOrders({ limit: 30 });
      setOrders(res.items || []);
    } catch (e) {
      setOrders([]);
      setLoadError(e instanceof Error ? e.message : 'Could not load orders');
    } finally {
      setOrdersLoading(false);
    }
  }, [token]);

  const onRefresh = useCallback(async () => {
    if (!token) return;
    setRefreshing(true);
    setLoadError(null);
    try {
      const res = await getOrders({ limit: 30 });
      setOrders(res.items || []);
    } catch (e) {
      setLoadError(e instanceof Error ? e.message : 'Could not load orders');
    } finally {
      setRefreshing(false);
    }
  }, [token]);

  useEffect(() => {
    loadOrders();
  }, [loadOrders]);

  return (
    <>
      <ScrollView
        contentContainerStyle={[profileStyles.scroll, s.scrollPad]}
        keyboardShouldPersistTaps="handled"
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} colors={[Theme.primary]} tintColor={Theme.primary} />
        }>
        <View style={s.listHeader}>
          <Text style={s.listHeaderTitle}>Your orders</Text>
          <Text style={s.listHeaderSub}>
            {orders.length > 0
              ? 'Tap a row for full details.'
              : ordersLoading
                ? 'Loading…'
                : 'Placed orders appear here after checkout.'}
          </Text>
        </View>

        {loadError && !ordersLoading ? (
          <View style={s.errorBox}>
            <Text style={s.errorText}>{loadError}</Text>
            <Pressable style={s.retryBtn} onPress={loadOrders}>
              <Text style={s.retryText}>Try again</Text>
            </Pressable>
          </View>
        ) : null}

        {ordersLoading && orders.length === 0 ? (
          <View style={s.loadingBlock}>
            <ActivityIndicator size="large" color={Theme.primary} />
            <Text style={s.loadingHint}>Loading your orders…</Text>
          </View>
        ) : null}

        {!ordersLoading && !loadError && orders.length === 0 ? (
          <View style={s.emptyBlock}>
            <View style={s.emptyIconWrap}>
              <FontAwesome name="inbox" size={36} color={Theme.gray400} />
            </View>
            <Text style={s.emptyTitle}>No orders yet</Text>
            <Text style={s.emptySub}>When you place an order from Pharmacy, it will show up here.</Text>
          </View>
        ) : null}

        {orders.map((o) => {
          const normalized = normalizeOrderStatus(o.order_status);
          const pill = statusPillColors(normalized);
          const refText = o.order_reference || o.id.slice(0, 8);
          const dateLabel = formatOrderDate(o.created_at ?? null);
          return (
            <Pressable
              key={o.id}
              style={({ pressed }) => [s.orderRow, pressed && s.orderRowPressed]}
              onPress={() => setSelectedOrder(o)}
              accessibilityRole="button"
              accessibilityLabel={`Order ${refText}, ${formatOrderStatusLabel(normalized)}`}>
              <View style={s.orderRowTop}>
                <View style={s.orderRefBlock}>
                  <Text style={s.orderRef} numberOfLines={1}>
                    {refText}
                  </Text>
                  {dateLabel ? <Text style={s.orderDate}>{dateLabel}</Text> : null}
                </View>
                <Text style={s.orderAmt}>₹{Number(o.final_amount).toFixed(2)}</Text>
              </View>
              <View style={s.orderRowBottom}>
                <View style={[s.statusPill, { backgroundColor: pill.bg, borderColor: pill.border }]}>
                  <Text style={[s.statusPillText, { color: pill.text }]} numberOfLines={1}>
                    {formatOrderStatusLabel(normalized)}
                  </Text>
                </View>
                <Text style={s.viewLink}>View</Text>
                <FontAwesome name="angle-right" size={16} color={Theme.gray400} style={s.chev} />
              </View>
            </Pressable>
          );
        })}
      </ScrollView>

      <Modal
        visible={!!selectedOrder}
        animationType="slide"
        transparent
        onRequestClose={closeOrderModal}>
        <View style={s.modalRoot}>
          <Pressable style={s.modalBackdrop} onPress={closeOrderModal} accessibilityLabel="Dismiss" />
          <View style={s.modalCard}>
            <View style={s.modalHandle} />
            {selectedOrder ? (
              <>
                <Text style={s.modalTitle}>Order details</Text>
                <Text style={s.modalRef}>{selectedOrder.order_reference || selectedOrder.id}</Text>
                {(() => {
                  const n = normalizeOrderStatus(selectedOrder.order_status);
                  const p = statusPillColors(n);
                  return (
                    <View style={[s.modalStatusPill, { backgroundColor: p.bg, borderColor: p.border }]}>
                      <Text style={[s.modalStatusText, { color: p.text }]}>{formatOrderStatusLabel(n)}</Text>
                    </View>
                  );
                })()}
                <ScrollView style={s.modalScroll} showsVerticalScrollIndicator={false} keyboardShouldPersistTaps="handled">
                  <View style={s.modalBody}>
                    <Text style={s.itemsSectionLabel}>Medicines in this order</Text>
                    {detailLoading ? (
                      <View style={s.itemsLoading}>
                        <ActivityIndicator color={Theme.primary} />
                        <Text style={s.itemsLoadingText}>Loading items…</Text>
                      </View>
                    ) : null}
                    {detailError && !detailLoading ? <Text style={s.itemsErrorText}>{detailError}</Text> : null}
                    {!detailLoading && !detailError && (orderDetail?.items?.length ?? 0) === 0 ? (
                      <Text style={s.itemsEmpty}>No line items returned for this order.</Text>
                    ) : null}
                    {(orderDetail?.items || []).map((it) => (
                      <View key={it.id} style={s.itemLine}>
                        <View style={s.itemLineTop}>
                          <Text style={s.itemName} numberOfLines={2}>
                            {lineItemTitle(it)}
                          </Text>
                          <Text style={s.itemLineAmt}>₹{Number(it.total_price).toFixed(2)}</Text>
                        </View>
                        <View style={s.itemLineMeta}>
                          <Text style={s.itemUnitQty}>
                            ₹{Number(it.unit_price).toFixed(2)} × {it.quantity}
                          </Text>
                          {it.requires_prescription ? (
                            <View style={s.rxBadge}>
                              <Text style={s.rxBadgeText}>Rx</Text>
                            </View>
                          ) : null}
                        </View>
                      </View>
                    ))}

                    <View style={s.modalDivider} />
                    <OrderDetailField label="Total" value={`₹${Number(selectedOrder.final_amount).toFixed(2)}`} />
                    {(() => {
                      const placed = formatOrderDate(
                        selectedOrder.created_at ?? orderDetail?.order?.created_at ?? null,
                      );
                      return placed ? <OrderDetailField label="Placed" value={placed} /> : null;
                    })()}
                    {(orderDetail?.order?.customer_name || selectedOrder.customer_name)?.toString().trim() ? (
                      <OrderDetailField
                        label="Name"
                        value={String(
                          orderDetail?.order?.customer_name?.trim() || selectedOrder.customer_name,
                        )}
                      />
                    ) : null}
                    <OrderDetailField
                      label="Phone"
                      value={String(orderDetail?.order?.customer_phone || selectedOrder.customer_phone)}
                    />
                    <View style={s.addressBox}>
                      <Text style={s.detailLabel}>Delivery address</Text>
                      <Text style={s.addressText}>
                        {String(orderDetail?.order?.delivery_address || selectedOrder.delivery_address)}
                      </Text>
                    </View>
                  </View>
                </ScrollView>
                <Pressable style={s.modalClose} onPress={closeOrderModal}>
                  <Text style={s.modalCloseText}>Close</Text>
                </Pressable>
              </>
            ) : null}
          </View>
        </View>
      </Modal>
    </>
  );
}

const s = StyleSheet.create({
  scrollPad: { paddingBottom: 32 },
  listHeader: { marginBottom: 14 },
  listHeaderTitle: { fontFamily: Fonts.display, fontSize: 22, fontWeight: '800', color: Theme.gray900, letterSpacing: -0.3 },
  listHeaderSub: { marginTop: 4, fontSize: 13, color: Theme.gray500, lineHeight: 18 },
  loadingBlock: { alignItems: 'center', paddingVertical: 40, gap: 12 },
  loadingHint: { fontSize: 14, color: Theme.gray500 },
  errorBox: {
    backgroundColor: '#fff7ed',
    borderWidth: 1,
    borderColor: '#fed7aa',
    borderRadius: 12,
    padding: 12,
    marginBottom: 12,
  },
  errorText: { color: '#9a3412', fontSize: 14, marginBottom: 10 },
  retryBtn: { alignSelf: 'flex-start', backgroundColor: Theme.primary, paddingHorizontal: 16, paddingVertical: 8, borderRadius: 10 },
  retryText: { color: Theme.white, fontWeight: '800', fontSize: 14 },
  emptyBlock: { alignItems: 'center', paddingVertical: 32, paddingHorizontal: 8 },
  emptyIconWrap: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: Theme.gray100,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 14,
  },
  emptyTitle: { fontSize: 17, fontWeight: '800', color: Theme.gray800, marginBottom: 6 },
  emptySub: { fontSize: 14, color: Theme.gray500, textAlign: 'center', lineHeight: 20, maxWidth: 280 },
  orderRow: {
    backgroundColor: Theme.white,
    borderRadius: Theme.radiusLg,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: Theme.gray200,
    ...Theme.shadowCard,
  },
  orderRowPressed: { opacity: 0.92 },
  orderRowTop: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 },
  orderRefBlock: { flex: 1, minWidth: 0 },
  orderRef: { fontSize: 16, fontWeight: '800', color: Theme.gray900 },
  orderDate: { marginTop: 2, fontSize: 12, color: Theme.gray500, fontWeight: '600' },
  orderAmt: { fontSize: 16, fontWeight: '800', color: Theme.gray900, fontFamily: Fonts.bodySemi },
  orderRowBottom: { marginTop: 10, flexDirection: 'row', alignItems: 'center', gap: 8 },
  statusPill: { flex: 1, minWidth: 0, paddingVertical: 5, paddingHorizontal: 10, borderRadius: 8, borderWidth: 1 },
  statusPillText: { fontSize: 12, fontWeight: '800' },
  viewLink: { fontSize: 12, fontWeight: '800', color: Theme.primary, marginLeft: 'auto' },
  chev: { marginLeft: 2 },
  modalRoot: { flex: 1, justifyContent: 'flex-end' },
  modalBackdrop: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(15, 23, 42, 0.45)' },
  modalCard: {
    backgroundColor: Theme.white,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    paddingHorizontal: 18,
    paddingTop: 8,
    paddingBottom: 24,
    maxHeight: '88%',
  },
  modalHandle: { alignSelf: 'center', width: 40, height: 4, borderRadius: 2, backgroundColor: Theme.gray200, marginBottom: 10 },
  modalTitle: { fontSize: 11, fontWeight: '800', color: Theme.gray500, textTransform: 'uppercase', letterSpacing: 0.6, marginBottom: 4 },
  modalRef: { fontSize: 20, fontWeight: '800', color: Theme.gray900, fontFamily: Fonts.display, marginBottom: 10 },
  modalStatusPill: { alignSelf: 'flex-start', paddingVertical: 5, paddingHorizontal: 10, borderRadius: 8, borderWidth: 1, marginBottom: 14 },
  modalStatusText: { fontSize: 12, fontWeight: '800' },
  itemsSectionLabel: {
    fontSize: 12,
    fontWeight: '800',
    color: Theme.gray500,
    textTransform: 'uppercase',
    letterSpacing: 0.4,
    marginBottom: 10,
  },
  itemsLoading: { flexDirection: 'row', alignItems: 'center', gap: 10, marginBottom: 12 },
  itemsLoadingText: { fontSize: 14, color: Theme.gray500 },
  itemsErrorText: { color: '#b91c1c', fontSize: 13, marginBottom: 10 },
  itemsEmpty: { color: Theme.gray500, fontSize: 14, marginBottom: 12 },
  itemLine: {
    backgroundColor: Theme.gray100,
    borderRadius: 12,
    padding: 12,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: Theme.gray200,
  },
  itemLineTop: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', gap: 8 },
  itemName: { flex: 1, fontSize: 14, fontWeight: '700', color: Theme.gray900, lineHeight: 20 },
  itemLineAmt: { fontSize: 14, fontWeight: '800', color: Theme.gray900, fontFamily: Fonts.bodySemi },
  itemLineMeta: { marginTop: 6, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 8 },
  itemUnitQty: { fontSize: 12, color: Theme.gray500, fontWeight: '600' },
  rxBadge: { backgroundColor: '#fee2e2', paddingHorizontal: 6, paddingVertical: 2, borderRadius: 4 },
  rxBadgeText: { fontSize: 10, fontWeight: '800', color: '#b91c1c' },
  modalDivider: { height: 1, backgroundColor: Theme.gray200, marginVertical: 14 },
  modalScroll: { maxHeight: 400 },
  modalBody: { paddingBottom: 8 },
  detailField: { marginBottom: 12, paddingBottom: 12, borderBottomWidth: 1, borderBottomColor: Theme.gray100 },
  detailLabel: { fontSize: 11, fontWeight: '800', color: Theme.gray500, marginBottom: 4, textTransform: 'uppercase', letterSpacing: 0.4 },
  detailValue: { fontSize: 15, color: Theme.gray800, fontWeight: '600', lineHeight: 22 },
  addressBox: { marginTop: 2 },
  addressText: { fontSize: 14, color: Theme.gray800, lineHeight: 20, fontWeight: '500' },
  modalClose: { marginTop: 10, backgroundColor: Theme.accentBlue, paddingVertical: 14, borderRadius: 12, alignItems: 'center' },
  modalCloseText: { color: Theme.white, fontWeight: '800', fontSize: 16 },
});

export default function ProfileOrdersScreen() {
  return (
    <View style={profileStyles.safe}>
      <ProfileAuthGate>
        <OrdersContent />
      </ProfileAuthGate>
    </View>
  );
}
