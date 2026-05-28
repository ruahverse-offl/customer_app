import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

/// Bumped whenever any legal screen's content materially changes.
/// Keep in sync with the website's PrivacyPolicy.jsx footer.
const _legalLastUpdated = 'May 2026';

// ── shared widget ─────────────────────────────────────────────────────────────

class _LegalPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_Section> sections;
  const _LegalPage({required this.title, required this.subtitle, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
              title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Outfit')),
              background: DecoratedBox(
                decoration: const BoxDecoration(gradient: AppGradients.primary),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 44),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Inter'),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  if (i < sections.length) return _SectionWidget(sections[i]);
                  // Footer
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    child: Text('Last Updated: $_legalLastUpdated',
                        style: AppTextStyles.caption, textAlign: TextAlign.center),
                  );
                },
                childCount: sections.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section {
  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;
  const _Section({required this.heading, this.paragraphs = const [], this.bullets = const []});
}

class _SectionWidget extends StatelessWidget {
  final _Section s;
  const _SectionWidget(this.s);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.heading, style: AppTextStyles.h3.copyWith(fontSize: 16, color: AppColors.primary)),
        const SizedBox(height: 8),
        ...s.paragraphs.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(p, style: AppTextStyles.body),
        )),
        ...s.bullets.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 14)),
            Expanded(child: Text(b, style: AppTextStyles.body)),
          ]),
        )),
      ]),
    );
  }
}

// ── Terms & Conditions ────────────────────────────────────────────────────────

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => _LegalPage(
    title: 'Terms & Conditions',
    subtitle: 'Please read these terms carefully before using our services.',
    sections: const [
      _Section(
        heading: '1. Acceptance of Terms',
        paragraphs: [
          'By accessing and using NEW BALAN Medical & Clinic services, you accept and agree to be bound by these Terms and Conditions. If you do not agree, please do not use our services.',
          'We reserve the right to modify these terms at any time. Your continued use after modifications constitutes acceptance of the updated terms.',
        ],
      ),
      _Section(
        heading: '2. Use of Services',
        paragraphs: ['Our services are provided for lawful purposes only. You agree to:'],
        bullets: [
          'Use our services only for legitimate medical and healthcare needs',
          'Provide accurate and truthful information when placing orders',
          'Comply with all applicable laws and regulations',
          'Not misuse our services for any illegal or unauthorized purpose',
        ],
      ),
      _Section(
        heading: '3. Prescription Requirements',
        paragraphs: ['For prescription medicines, you must:'],
        bullets: [
          'Provide a valid prescription from a licensed medical practitioner',
          'Upload clear, legible images or PDFs of your prescription',
          'Ensure the prescription is current and not expired',
        ],
      ),
      _Section(
        heading: '4. Order Placement and Processing',
        paragraphs: [
          'Order Confirmation: When you place an order you will receive a confirmation. This does not guarantee acceptance — we reserve the right to reject any order at our discretion.',
          'Order Cancellation: You may cancel before processing. Once dispatched, cancellation may not be possible.',
        ],
      ),
      _Section(
        heading: '5. Pricing and Payment',
        paragraphs: [
          'All prices are in Indian Rupees (₹) and subject to change. We accept Credit/Debit cards, UPI, and Net Banking via Razorpay.',
          'Refunds, when approved, are processed to the original payment method within 7–14 business days.',
        ],
      ),
      _Section(
        heading: '6. Delivery Terms',
        paragraphs: [
          'We provide delivery in specified areas. Estimated delivery times are for guidance only.',
          'Delivery charges apply as shown at checkout. Free delivery may be available above a minimum order value.',
        ],
      ),
      _Section(
        heading: '7. Medical Disclaimer',
        paragraphs: [
          'Our services provide access to medicines and healthcare products. We are not a substitute for professional medical advice, diagnosis, or treatment.',
        ],
        bullets: [
          'Consult qualified healthcare professionals for medical advice',
          'Do not use our services for emergency medical situations',
          'Follow prescribed dosages and usage instructions',
        ],
      ),
      _Section(
        heading: '8. Governing Law',
        paragraphs: [
          'These Terms are governed by the laws of India. Disputes shall be subject to the jurisdiction of the courts in Thoothukudi, Tamil Nadu, India.',
        ],
      ),
      _Section(
        heading: '9. Contact Information',
        bullets: [
          'Email: newbalanmedicals@gmail.com',
          'Phone: +91 9894880598',
          'Address: 120/a Poobalarayapuram 2nd Street, Thoothukudi, Tamil Nadu 628001',
        ],
      ),
    ],
  );
}

// ── Privacy Policy ────────────────────────────────────────────────────────────

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => _LegalPage(
    title: 'Privacy Policy',
    subtitle: 'How we collect, use, and protect your information.',
    sections: const [
      _Section(
        heading: '1. Who We Are',
        paragraphs: [
          'NEW BALAN Medical & Clinic ("we", "us", "New Balan") operates a licensed retail pharmacy, polyclinic services, and the New Balan Medical mobile app. This policy explains what personal information we collect through the app and our services, how we use it, who we share it with, and the rights you have over it.',
          'This policy is governed by the Digital Personal Data Protection Act, 2023 (India) and applicable consumer-protection and pharmacy regulations.',
        ],
      ),
      _Section(
        heading: '2. Information We Collect',
        paragraphs: ['We collect the following categories of information:'],
        bullets: [
          'Account info: full name, email address, mobile number, hashed password.',
          'Health data: prescription images or PDFs you upload, the medicines on those prescriptions, and information needed to fulfil your order.',
          'Order info: items purchased, quantities, prices, delivery address, order notes, special instructions.',
          'Payment info: handled by Razorpay (see §4). We do NOT store your card or UPI credentials on our servers.',
          'Device info: a Firebase Cloud Messaging (FCM) token used to send order-status push notifications, plus app version and device type to diagnose problems.',
          'Diagnostic info: crash reports and basic app activity (which screens are visited, when the app last opened) for troubleshooting.',
        ],
      ),
      _Section(
        heading: '3. How We Use Your Information',
        bullets: [
          'Fulfil your medicine orders and dispatch deliveries to your address.',
          'Verify prescriptions and comply with the rules of the Drugs and Cosmetics Act.',
          'Send push notifications and emails about your order status, delivery updates, and refund confirmations.',
          'Provide customer support over phone, WhatsApp, and email.',
          'Detect and prevent fraud, account abuse, and security incidents.',
          'Meet legal obligations including GST tax records, pharmacy licensing audits, and consumer-protection law.',
        ],
        paragraphs: [
          'We do NOT use your health, prescription, or order data to serve advertising. We do not sell your personal information to anyone.',
        ],
      ),
      _Section(
        heading: '4. Who We Share With',
        paragraphs: [
          'We share the minimum information required, only with these processors:',
        ],
        bullets: [
          'Razorpay Software Pvt. Ltd. — payment processing. Receives your name, mobile number, order ID, and amount to complete the transaction. Razorpay\'s own privacy policy governs their handling of card and UPI data.',
          'Google Firebase (Cloud Messaging) — delivers our push notifications. Receives an opaque FCM token tied to your device.',
          'Licensed pharmacists at New Balan — see prescriptions to dispense medicines, as required by law.',
          'Government and regulatory authorities — only when compelled by a valid legal order or required by drug-control / tax / consumer-protection law.',
        ],
      ),
      _Section(
        heading: '5. How We Protect Your Data',
        bullets: [
          'Passwords are stored as one-way bcrypt hashes — we cannot read your password even if asked.',
          'All API traffic is encrypted in transit using HTTPS / TLS 1.2+.',
          'Authentication tokens on your device are stored in Android EncryptedSharedPreferences / iOS Keychain.',
          'Access to production data is restricted to a small number of authorised staff and logged.',
        ],
      ),
      _Section(
        heading: '6. Data Retention',
        paragraphs: [
          'Active accounts: we retain your profile and address details for as long as you have an account with us.',
          'Order and invoice records: retained for at least 8 years from the order date to satisfy GST and the Drugs and Cosmetics Act recordkeeping requirements. After your account is deleted, these records remain but are no longer linked to your name, email, or phone number.',
          'Prescriptions: retained for at least 2 years as required by pharmacy regulations.',
          'Push notification tokens: cleared as soon as you log out or delete your account.',
          'Diagnostic and crash data: retained for 90 days, then aggregated.',
        ],
      ),
      _Section(
        heading: '7. Your Rights',
        paragraphs: [
          'Under the DPDP Act 2023 you have the following rights, exercisable free of charge:',
        ],
        bullets: [
          'Access: request a copy of the personal information we hold about you.',
          'Correction: update your name, email, mobile, or address from the Profile screen — or email us to correct anything else.',
          'Deletion: delete your account at any time using Account → Delete Account inside the app. This permanently removes your identifying information and anonymises any retained order history. See §8 for what stays and why.',
          'Withdraw consent: revoke push notifications from Settings → Notifications, or revoke storage access from your device settings.',
          'Grievance: contact our grievance officer (details in §11) if you believe your rights have been infringed.',
        ],
      ),
      _Section(
        heading: '8. Account Deletion',
        paragraphs: [
          'You can delete your account directly from the app: Account → Delete Account. You will be asked to re-enter your password to prevent accidental deletion.',
          'When you delete your account we immediately do all of the following:',
        ],
        bullets: [
          'Mark the account as deleted and disable login.',
          'Anonymise your name, email, and mobile number on past order records so they cannot be linked back to you.',
          'Invalidate your authentication tokens and push notification tokens.',
          'Clear saved delivery addresses, cart contents, and notification preferences.',
        ],
        // continued in paragraphs2 — represented as bullets work-around not needed; we add a closing paragraph below.
      ),
      _Section(
        heading: '8a. What Remains After Deletion',
        paragraphs: [
          'Anonymised order and invoice records remain in our systems for the retention windows in §6 because GST and consumer-protection law require pharmacies to keep transaction records. After anonymisation these rows cannot be re-associated with you.',
          'If you cannot access the app to delete your account (for example, you lost your device), email or WhatsApp us using the contact details in §11 and we will action your request within 30 days after verifying your identity.',
        ],
      ),
      _Section(
        heading: '9. Children\'s Privacy',
        paragraphs: [
          'New Balan Medical is intended for adults aged 18 and over. We do not knowingly create accounts for or collect personal information from children under 13. If you believe a child has registered, contact us and we will delete the account.',
          'Parents and guardians may order medicines for children using their own adult account. In those cases, the prescription is treated like any other medical document under this policy.',
        ],
      ),
      _Section(
        heading: '10. Cross-Border Transfers',
        paragraphs: [
          'Our servers are located in India. The third parties listed in §4 (Razorpay, Google Firebase) may process data on infrastructure outside India. By using the app you consent to these transfers, which are subject to the contractual safeguards those providers offer.',
        ],
      ),
      _Section(
        heading: '11. Contact and Grievance Officer',
        paragraphs: [
          'For any privacy-related question, request, or complaint, contact our Grievance Officer:',
        ],
        bullets: [
          'Name: Manikandan (Founder & Director)',
          'Email: newbalanmedicals@gmail.com',
          'Phone / WhatsApp: +91 9894880598',
          'Address: 120/a Poobalarayapuram 2nd Street, Thoothukudi, Tamil Nadu 628001',
        ],
        // We acknowledge requests within 7 days and complete within 30.
      ),
      _Section(
        heading: '12. Changes to This Policy',
        paragraphs: [
          'We may update this policy when laws change or when we add new features. Material changes will be announced in-app before they take effect. The "Last Updated" date below tells you when this version was published.',
        ],
      ),
    ],
  );
}

// ── Refund & Cancellation Policy ─────────────────────────────────────────────

class RefundScreen extends StatelessWidget {
  const RefundScreen({super.key});

  @override
  Widget build(BuildContext context) => _LegalPage(
    title: 'Refund & Cancellation',
    subtitle: 'How we handle cancellations, failed payments, and refunds.',
    sections: const [
      _Section(
        heading: '1. Scope',
        paragraphs: [
          'This policy applies to orders placed through NEW BALAN Medical & Clinic for pharmacy products and online payments processed via Razorpay.',
        ],
      ),
      _Section(
        heading: '2. Order Cancellation (Before Dispatch)',
        paragraphs: [
          'You may request cancellation before an order is verified and dispatched. If accepted, any successful online payment will be refunded as described below.',
          'Once dispatched, cancellation may not be possible. Contact us immediately and we will advise based on the situation.',
        ],
      ),
      _Section(
        heading: '3. Prescription Holds',
        paragraphs: [
          'Orders with prescription-only medicines require a valid prescription. If missing or unclear, we may delay or cancel the order. If payment was already captured, a refund will be initiated where applicable.',
        ],
      ),
      _Section(
        heading: '4. Failed or Duplicate Payments',
        paragraphs: [
          'If a payment fails, no charge should appear. If money was debited but our system did not confirm success, the bank usually reverses the amount automatically within a few business days.',
          'If you believe you were charged twice, contact us with your order reference and payment details.',
        ],
      ),
      _Section(
        heading: '5. Refund Method and Timeline',
        paragraphs: [
          'Approved refunds are credited to the original payment method (card / UPI / net banking). Many refunds complete within 7–14 business days depending on your bank.',
          'We do not guarantee instant refunds; we will provide reference IDs when available.',
        ],
      ),
      _Section(
        heading: '6. Non-Returnable Items',
        paragraphs: [
          'Opened medicines, temperature-sensitive items, or products that cannot be resold may not be eligible for return or refund except where required by law or for genuine errors on our part.',
        ],
      ),
      _Section(
        heading: '7. Contact for Refund Queries',
        bullets: [
          'Email: newbalanmedicals@gmail.com',
          'Phone: +91 9894880598',
          'Address: 120/a Poobalarayapuram 2nd Street, Thoothukudi, Tamil Nadu 628001',
        ],
      ),
    ],
  );
}
