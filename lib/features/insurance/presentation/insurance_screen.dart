import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/widgets/gradient_button.dart';
import '../data/insurance_repository.dart';

const _gold = Color(0xFFD97706);

class InsuranceScreen extends ConsumerStatefulWidget {
  const InsuranceScreen({super.key});
  @override
  ConsumerState<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends ConsumerState<InsuranceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _familyCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _planType = '';
  bool _submitting = false;
  bool _submitted = false;
  String? _submitError;

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _ageCtrl.dispose();
    _familyCtrl.dispose(); _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _submitError = null; });
    try {
      await ref.read(insuranceRepositoryProvider).submitEnquiry(
        customerName: _nameCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        customerAge: _ageCtrl.text.trim().isNotEmpty ? int.tryParse(_ageCtrl.text.trim()) : null,
        familySize: _familyCtrl.text.trim().isNotEmpty ? int.tryParse(_familyCtrl.text.trim()) : null,
        planType: _planType.isNotEmpty ? _planType : null,
        message: _msgCtrl.text.trim().isNotEmpty ? _msgCtrl.text.trim() : null,
      );
      if (mounted) {
        setState(() { _submitted = true; _submitting = false; });
        _nameCtrl.clear(); _phoneCtrl.clear(); _ageCtrl.clear();
        _familyCtrl.clear(); _msgCtrl.clear();
        _planType = '';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitError = 'Something went wrong. Please try again or call us directly.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: const Text('Star Health Insurance',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Outfit', fontWeight: FontWeight.w700)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFB45309)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 36),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.health_and_safety_outlined, color: Colors.white70, size: 44),
                      SizedBox(height: 6),
                      Text("Securing your family's future",
                          style: TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Inter')),
                    ]),
                  ),
                ),
              ),
            ),
            backgroundColor: _gold,
            foregroundColor: Colors.white,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Consult Manikandan card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _gold.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.person_outline, color: _gold, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Consult with Manikandan', style: AppTextStyles.labelLarge),
                              Row(children: [
                                const Icon(Icons.workspace_premium_outlined, size: 14, color: _gold),
                                const SizedBox(width: 4),
                                Text('Zonal Manager Club Achiever',
                                    style: AppTextStyles.caption.copyWith(color: _gold, fontWeight: FontWeight.w600)),
                              ]),
                            ])),
                          ]),
                          const SizedBox(height: 14),
                          _TimingRow(icon: Icons.location_on_outlined, label: 'In-Person:', value: '1:00 PM – 2:00 PM (Daily)'),
                          const SizedBox(height: 6),
                          _TimingRow(icon: Icons.phone_outlined, label: 'Phone / WhatsApp:', value: 'Anytime'),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: OutlinedButton.icon(
                              onPressed: () => _launch(AppConstants.storeWhatsApp),
                              icon: const Icon(Icons.chat_outlined, size: 16),
                              label: const Text('WhatsApp'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF25D366),
                                side: const BorderSide(color: Color(0xFF25D366)),
                                minimumSize: const Size(0, 44),
                              ),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: ElevatedButton.icon(
                              onPressed: () => _launch('tel:${AppConstants.storePhone}'),
                              icon: const Icon(Icons.phone_outlined, size: 16),
                              label: const Text('Call Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 44),
                              ),
                            )),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // About & What It Does
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _InfoCard(
                      icon: Icons.health_and_safety_outlined,
                      title: 'About Star Health',
                      bullets: const [
                        "India's first standalone health insurer",
                        'Established in 2006',
                        'Head office in Chennai',
                        'Trusted by lakhs across India',
                      ],
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _InfoCard(
                      icon: Icons.monitor_heart_outlined,
                      title: 'What It Does',
                      bullets: const [
                        'Pays hospital bills',
                        'Covers sickness & accidents',
                        'Financial protection for family',
                        'Cashless treatment option',
                      ],
                    )),
                  ]),
                  const SizedBox(height: 20),

                  // Key Benefits
                  Text('Key Benefits', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  _BenefitsList(benefits: const [
                    'Cashless hospitalization in 14,000+ network hospitals.',
                    'No pre-acceptance medical screening up to 50 years.',
                    'Coverage for pre-existing diseases after 48 months.',
                    'Direct in-house claim settlement (No TPA).',
                    'Lifetime renewal facility.',
                    'Tax benefits under Section 80D.',
                  ]),
                  const SizedBox(height: 20),

                  // Plans
                  Text('Insurance Plans', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: const [
                      _PlanCard(icon: Icons.person_outline, title: 'Individual Plan',
                          subtitle: 'Coverage for one person', color: AppColors.primary),
                      _PlanCard(icon: Icons.people_outline, title: 'Family Plan',
                          subtitle: 'Coverage for entire family', color: AppColors.secondary),
                      _PlanCard(icon: Icons.elderly_outlined, title: 'Senior Citizen',
                          subtitle: 'Special plans for elders', color: Color(0xFF7C3AED)),
                      _PlanCard(icon: Icons.warning_amber_outlined, title: 'Critical Illness',
                          subtitle: 'Covers serious diseases', color: AppColors.danger),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Why Choose / How We Help
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _ChecklistCard(
                      title: 'Why Choose Star Health',
                      items: const [
                        'Network of 14,000+ hospitals',
                        'Flexible plans for all ages',
                        'Fast cashless claim processing',
                        'No medical test under 50 years',
                      ],
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _ChecklistCard(
                      title: 'How We Help You',
                      items: const [
                        'Choose the right plan',
                        'Understand insurance terms',
                        'Assistance during claims',
                      ],
                    )),
                  ]),
                  const SizedBox(height: 24),

                  // Enquiry Form
                  Text('Submit an Enquiry', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Text('Our expert Manikandan will get back to you.', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),

                  if (_submitted)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle, color: AppColors.secondary),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          'Enquiry submitted! Our expert will get back to you shortly.',
                          style: AppTextStyles.body,
                        )),
                      ]),
                    )
                  else
                    _EnquiryForm(
                      formKey: _formKey,
                      nameCtrl: _nameCtrl,
                      phoneCtrl: _phoneCtrl,
                      ageCtrl: _ageCtrl,
                      familyCtrl: _familyCtrl,
                      msgCtrl: _msgCtrl,
                      planType: _planType,
                      submitting: _submitting,
                      submitError: _submitError,
                      onPlanChanged: (v) => setState(() => _planType = v ?? ''),
                      onSubmit: _submit,
                    ),

                  const SizedBox(height: 24),

                  // FAQ
                  Text('FAQs', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  const _Faq(
                    q: 'What is the waiting period for pre-existing diseases?',
                    a: 'Typically 48 months of continuous coverage is required for PED coverage in most plans.',
                  ),
                  const SizedBox(height: 10),
                  const _Faq(
                    q: 'How do I file a cashless claim?',
                    a: 'Present your Star Health ID card at any network hospital. Our team can assist with the paperwork.',
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Extracted form widget to avoid nested if/else inside list ──

class _EnquiryForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, phoneCtrl, ageCtrl, familyCtrl, msgCtrl;
  final String planType;
  final bool submitting;
  final String? submitError;
  final ValueChanged<String?> onPlanChanged;
  final VoidCallback onSubmit;

  const _EnquiryForm({
    required this.formKey,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.ageCtrl,
    required this.familyCtrl,
    required this.msgCtrl,
    required this.planType,
    required this.submitting,
    required this.submitError,
    required this.onPlanChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(children: [
        if (submitError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(submitError!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger))),
              ]),
            ),
          ),
        Row(children: [
          Expanded(child: TextFormField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Full Name *'),
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
          )),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: 'Phone *',
              prefixText: '+91 ',
              counterText: '',
            ),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return 'Required';
              if (t.length != 10 || int.tryParse(t) == null) return 'Enter a valid 10-digit number';
              return null;
            },
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(
            controller: ageCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Age'),
          )),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(
            controller: familyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Family Size'),
          )),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: planType.isEmpty ? null : planType,
          decoration: const InputDecoration(labelText: 'Preferred Plan (optional)'),
          items: const [
            DropdownMenuItem(value: 'Individual Plan', child: Text('Individual Plan')),
            DropdownMenuItem(value: 'Family Plan', child: Text('Family Plan')),
            DropdownMenuItem(value: 'Senior Citizen', child: Text('Senior Citizen Plan')),
            DropdownMenuItem(value: 'Critical Illness', child: Text('Critical Illness Plan')),
          ],
          onChanged: onPlanChanged,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: msgCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Message (optional)'),
        ),
        const SizedBox(height: 20),
        GradientButton(
          onPressed: submitting ? null : onSubmit,
          label: submitting ? 'Submitting…' : 'Submit Enquiry',
          icon: Icons.send_rounded,
          loading: submitting,
          gradient: const LinearGradient(
            colors: [Color(0xFFD97706), Color(0xFFB45309)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          glow: [
            BoxShadow(
              color: _gold.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
      ]),
    );
  }
}

// ── Helpers ──

class _TimingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _TimingRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: AppColors.textSecondary),
    const SizedBox(width: 6),
    Text(label, style: AppTextStyles.label.copyWith(fontSize: 13)),
    const SizedBox(width: 6),
    Flexible(child: Text(value, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis)),
  ]);
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> bullets;
  const _InfoCard({required this.icon, required this.title, required this.bullets});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppColors.primary, size: 26),
        const SizedBox(height: 8),
        Text(title, style: AppTextStyles.label),
        const SizedBox(height: 8),
        ...bullets.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_circle, size: 14, color: AppColors.secondary),
            const SizedBox(width: 6),
            Expanded(child: Text(b, style: AppTextStyles.caption)),
          ]),
        )),
      ]),
    ),
  );
}

class _BenefitsList extends StatelessWidget {
  final List<String> benefits;
  const _BenefitsList({required this.benefits});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        ...benefits.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_circle, size: 18, color: AppColors.secondary),
            const SizedBox(width: 10),
            Expanded(child: Text(b, style: AppTextStyles.body)),
          ]),
        )),
      ]),
    ),
  );
}

class _ChecklistCard extends StatelessWidget {
  final String title;
  final List<String> items;
  const _ChecklistCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.label),
        const SizedBox(height: 10),
        ...items.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_circle, size: 15, color: AppColors.secondary),
            const SizedBox(width: 6),
            Expanded(child: Text(s, style: AppTextStyles.bodySmall)),
          ]),
        )),
      ]),
    ),
  );
}

class _PlanCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _PlanCard({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 6),
      Text(title, style: AppTextStyles.label.copyWith(fontSize: 13)),
      const SizedBox(height: 2),
      Text(subtitle, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _Faq extends StatelessWidget {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(q, style: AppTextStyles.label),
        const SizedBox(height: 6),
        Text(a, style: AppTextStyles.bodySmall),
      ]),
    ),
  );
}
