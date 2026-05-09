/**
 * Mobile app allows only storefront customers and delivery agents.
 * Role codes come from GET /auth/me/permissions (same as web).
 */

const STOREFRONT = new Set(['CUSTOMER', 'PUBLIC']);

export function normalizeRoleCode(role: string | null | undefined): string {
  return String(role || '').toUpperCase();
}

export function isStorefrontCustomerRole(role: string | null | undefined): boolean {
  return STOREFRONT.has(normalizeRoleCode(role));
}

export function isDeliveryAgentRole(role: string | null | undefined): boolean {
  return normalizeRoleCode(role) === 'DELIVERY_AGENT';
}

/**
 * Validates role after login/register for the given UX intent.
 * @throws Error with user-facing message if role is not allowed for this app.
 */
export function assertRoleAllowedForIntent(
  roleCode: string | null | undefined,
  intent: 'customer' | 'delivery',
): string {
  const r = normalizeRoleCode(roleCode);
  if (intent === 'delivery') {
    if (r !== 'DELIVERY_AGENT') {
      throw new Error('This sign-in is for delivery partners only. Customer accounts cannot open the delivery console.');
    }
    return r;
  }
  if (isStorefrontCustomerRole(r)) {
    return r;
  }
  if (r === 'DELIVERY_AGENT') {
    throw new Error('Delivery partner accounts cannot use the shopping checkout here. Use Delivery partner sign-in from the pharmacy screen.');
  }
  throw new Error('This app is only for customers and delivery partners. Please use the staff website for other roles.');
}
