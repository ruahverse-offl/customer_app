import React, { createContext, useContext, useState, useCallback, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Animated,
  TouchableOpacity,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Theme } from '@/constants/theme';

interface Toast {
  id: number;
  message: string;
  type: 'success' | 'error' | 'warning' | 'info';
  duration: number;
}

interface ToastContextValue {
  success: (msg: string, duration?: number) => void;
  error: (msg: string, duration?: number) => void;
  warning: (msg: string, duration?: number) => void;
  info: (msg: string, duration?: number) => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

let toastIdCounter = 0;

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const addToast = useCallback(
    (message: string, type: Toast['type'] = 'success', duration = 3500) => {
      const id = ++toastIdCounter;
      setToasts((prev) => [...prev, { id, message, type, duration }]);
      return id;
    },
    []
  );

  const removeToast = useCallback((id: number) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const toastApi: ToastContextValue = {
    success: (msg, dur) => addToast(msg, 'success', dur),
    error: (msg, dur) => addToast(msg, 'error', dur || 5000),
    warning: (msg, dur) => addToast(msg, 'warning', dur),
    info: (msg, dur) => addToast(msg, 'info', dur),
  };

  return (
    <ToastContext.Provider value={toastApi}>
      {children}
      <View style={styles.toastContainer} pointerEvents="box-none">
        {toasts.map((toast) => (
          <ToastItem key={toast.id} toast={toast} onRemove={removeToast} />
        ))}
      </View>
    </ToastContext.Provider>
  );
}

const ICONS = {
  success: 'checkmark-circle' as const,
  error: 'close-circle' as const,
  warning: 'alert-circle' as const,
  info: 'information-circle' as const,
};

const COLORS = {
  success: {
    bg: Theme.secondaryLight,
    border: Theme.secondary,
    text: Theme.secondaryDark,
  },
  error: {
    bg: '#fee',
    border: '#dc3545',
    text: '#721c24',
  },
  warning: {
    bg: '#fff3cd',
    border: '#ffc107',
    text: '#856404',
  },
  info: {
    bg: Theme.primaryLight,
    border: Theme.primary,
    text: Theme.primaryDark,
  },
};

function ToastItem({
  toast,
  onRemove,
}: {
  toast: Toast;
  onRemove: (id: number) => void;
}) {
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const slideAnim = useRef(new Animated.Value(-100)).current;

  React.useEffect(() => {
    // Enter animation
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 300,
        useNativeDriver: true,
      }),
      Animated.spring(slideAnim, {
        toValue: 0,
        useNativeDriver: true,
        friction: 8,
      }),
    ]).start();

    // Auto dismiss
    const timer = setTimeout(() => {
      handleDismiss();
    }, toast.duration);

    return () => clearTimeout(timer);
  }, []);

  const handleDismiss = () => {
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 0,
        duration: 300,
        useNativeDriver: true,
      }),
      Animated.timing(slideAnim, {
        toValue: -100,
        duration: 300,
        useNativeDriver: true,
      }),
    ]).start(() => {
      onRemove(toast.id);
    });
  };

  const colors = COLORS[toast.type];

  return (
    <Animated.View
      style={[
        styles.toastItem,
        {
          backgroundColor: colors.bg,
          borderColor: colors.border,
          opacity: fadeAnim,
          transform: [{ translateY: slideAnim }],
        },
      ]}
    >
      <Ionicons name={ICONS[toast.type]} size={22} color={colors.border} />
      <Text style={[styles.toastMessage, { color: colors.text }]} numberOfLines={3}>
        {toast.message}
      </Text>
      <TouchableOpacity onPress={handleDismiss} style={styles.closeButton}>
        <Ionicons name="close" size={18} color={colors.text} />
      </TouchableOpacity>
    </Animated.View>
  );
}

export function useToast(): ToastContextValue {
  const ctx = useContext(ToastContext);
  if (!ctx) {
    // Fallback for components outside provider
    return {
      success: () => {},
      error: () => {},
      warning: () => {},
      info: () => {},
    };
  }
  return ctx;
}

const styles = StyleSheet.create({
  toastContainer: {
    position: 'absolute',
    top: Platform.select({ ios: 50, android: 10, default: 10 }),
    left: 16,
    right: 16,
    zIndex: 9999,
    gap: 10,
    pointerEvents: 'box-none',
  },
  toastItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingVertical: 14,
    paddingHorizontal: 16,
    borderRadius: Theme.radiusMd,
    borderWidth: 1,
    ...Theme.shadowCard,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 5,
  },
  toastMessage: {
    flex: 1,
    fontSize: 14,
    fontWeight: '600',
    lineHeight: 20,
  },
  closeButton: {
    padding: 4,
  },
});
