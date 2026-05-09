import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

export type CartLine = {
  medicineId: string;
  brandId: string;
  name: string;
  price: number;
  quantity: number;
  requiresPrescription: boolean;
  brandName?: string;
  maxStock?: number;
};

type CartContextValue = {
  cart: CartLine[];
  addToCart: (line: Omit<CartLine, 'quantity'> & { quantity?: number }) => void;
  updateQuantity: (brandId: string, quantity: number) => void;
  removeFromCart: (brandId: string) => void;
  clearCart: () => void;
  subtotal: number;
  isLoading: boolean;
};

const CartContext = createContext<CartContextValue | null>(null);

const CART_STORAGE_KEY = 'nb_cart';

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [cart, setCart] = useState<CartLine[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Load cart from AsyncStorage on mount
  useEffect(() => {
    loadCart();
  }, []);

  // Save cart to AsyncStorage whenever it changes
  useEffect(() => {
    if (!isLoading) {
      saveCart();
    }
  }, [cart, isLoading]);

  const loadCart = async () => {
    try {
      const stored = await AsyncStorage.getItem(CART_STORAGE_KEY);
      if (stored) {
        setCart(JSON.parse(stored));
      }
    } catch (error) {
      console.error('Failed to load cart from storage:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const saveCart = async () => {
    try {
      await AsyncStorage.setItem(CART_STORAGE_KEY, JSON.stringify(cart));
    } catch (error) {
      console.error('Failed to save cart to storage:', error);
    }
  };

  const addToCart = useCallback((line: Omit<CartLine, 'quantity'> & { quantity?: number }) => {
    const qty = line.quantity ?? 1;
    setCart((prev) => {
      const i = prev.findIndex((p) => p.brandId === line.brandId);
      if (i >= 0) {
        const next = [...prev];
        next[i] = { ...next[i], quantity: next[i].quantity + qty };
        return next;
      }
      return [...prev, { ...line, quantity: qty }];
    });
  }, []);

  const updateQuantity = useCallback((brandId: string, quantity: number) => {
    if (quantity < 1) {
      setCart((prev) => prev.filter((p) => p.brandId !== brandId));
      return;
    }
    setCart((prev) => prev.map((p) => (p.brandId === brandId ? { ...p, quantity } : p)));
  }, []);

  const removeFromCart = useCallback((brandId: string) => {
    setCart((prev) => prev.filter((p) => p.brandId !== brandId));
  }, []);

  const clearCart = useCallback(() => setCart([]), []);

  const subtotal = useMemo(
    () => cart.reduce((s, l) => s + l.price * l.quantity, 0),
    [cart],
  );

  const value = useMemo(
    () => ({ cart, addToCart, updateQuantity, removeFromCart, clearCart, subtotal, isLoading }),
    [cart, addToCart, updateQuantity, removeFromCart, clearCart, subtotal, isLoading],
  );

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart() {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error('useCart must be used within CartProvider');
  return ctx;
}
