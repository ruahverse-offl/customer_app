import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

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
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF003D80), AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(56, 0, 16, 44),
                    child: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Inter')),
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
                    child: Text('Last Updated: January 2026',
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
        heading: '1. Information We Collect',
        paragraphs: ['We collect information you provide when you:'],
        bullets: [
          'Create an account or register',
          'Place an order for medicines or services',
          'Upload prescriptions or medical documents',
          'Contact us via phone, email, or WhatsApp',
        ],
      ),
      _Section(
        heading: '2. How We Use Your Information',
        bullets: [
          'Process and fulfill your medicine orders',
          'Verify prescriptions and ensure compliance',
          'Communicate about your orders and account',
          'Improve our services and user experience',
          'Detect and prevent fraud and security threats',
          'Comply with legal and regulatory requirements',
        ],
      ),
      _Section(
        heading: '3. Information Sharing',
        paragraphs: ['We do not sell your personal information. We may share it only with:'],
        bullets: [
          'Service providers assisting in operating our services',
          'Licensed pharmacists and doctors for prescription verification',
          'Legal authorities when required by law',
        ],
      ),
      _Section(
        heading: '4. Data Security',
        paragraphs: ['We implement industry-standard security measures including:'],
        bullets: [
          'SSL/TLS encryption during data transmission',
          'Secure storage on protected servers',
          'Access controls and authentication',
          'Regular security audits',
        ],
      ),
      _Section(
        heading: '5. Your Rights',
        bullets: [
          'Access: Request the information we hold about you',
          'Correction: Request correction of inaccurate data',
          'Deletion: Request deletion (subject to legal requirements)',
          'Opt-Out: Unsubscribe from marketing at any time',
        ],
      ),
      _Section(
        heading: '6. Data Retention',
        paragraphs: [
          'We retain your information as long as necessary to fulfill orders, comply with legal obligations, and resolve disputes. Prescription records may be kept longer as required by healthcare regulations.',
        ],
      ),
      _Section(
        heading: '7. Contact Us',
        bullets: [
          'Email: newbalanmedicals@gmail.com',
          'Phone: +91 9894880598',
          'Address: 120/a Poobalarayapuram 2nd Street, Thoothukudi, Tamil Nadu 628001',
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
