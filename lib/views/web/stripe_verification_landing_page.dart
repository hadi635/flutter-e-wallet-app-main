import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/utils/web_meta/web_meta.dart';
import 'package:flutter/material.dart';

class StripeVerificationLandingPage extends StatefulWidget {
  const StripeVerificationLandingPage({super.key});

  @override
  State<StripeVerificationLandingPage> createState() =>
      _StripeVerificationLandingPageState();
}

class _StripeVerificationLandingPageState
    extends State<StripeVerificationLandingPage> {
  static const String _title = 'Stripe Verification | Infinity E-wallet';
  static const String _description =
      'Business verification page for Infinity E-wallet by Toub Zone Ltd with legal entity, trading name, services, privacy policy, terms, payment, and security details.';

  @override
  void initState() {
    super.initState();
    // Web metadata for Stripe and search crawlers on /home.
    setWebPageMeta(title: _title, description: _description);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 980;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const GlassContainer(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stripe Verification Landing',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'This URL is dedicated to business and payment verification for infinity-sharing.money (Infinity E-wallet), a SaaS product powered by Toub Zone Ltd.',
                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.6,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 18),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Tag(label: 'Environment: Production'),
                              _Tag(label: 'Platform: Flutter Web'),
                              _Tag(label: 'Payments: Stripe'),
                              _Tag(label: 'Type: Business Verification'),
                              _Tag(label: 'Route: /home'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    isWide
                        ? const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _MetadataCard()),
                              SizedBox(width: 12),
                              Expanded(child: _DescriptionCard()),
                            ],
                          )
                        : const Column(
                            children: [
                              _MetadataCard(),
                              SizedBox(height: 12),
                              _DescriptionCard(),
                            ],
                          ),
                    const SizedBox(height: 12),
                    const _VerificationSection(
                      title: 'Business Identity',
                      points: [
                        'Legal Entity: Toub Zone Ltd',
                        'Trading Name: infinity-sharing.money (Infinity E-wallet)',
                        'Registered Address: High Street North East Ham, Office 13028, London, E6 2JA, United Kingdom',
                        'Support Email: support@toubzone.com',
                        'Support Phone: +44 000 000 0000',
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _VerificationSection(
                      title: 'Services Summary',
                      points: [
                        'Custom Software Development',
                        'Web Development',
                        'Mobile App Development',
                        'AI & Automation Solutions',
                        'SaaS Platform Development',
                        'UI/UX Design',
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _VerificationSection(
                      title: 'Payments and Billing',
                      points: [
                        'Online payments are processed securely through Stripe.',
                        'Card entry and payment authorization are handled by Stripe-hosted flows.',
                        'Payment status and wallet credit are verified by backend systems.',
                        'All delivered products/services are digital.',
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _VerificationSection(
                      title: 'Privacy Policy Summary',
                      points: [
                        'We collect basic customer information such as name, email, and billing details to provide our services.',
                        'We do not sell or share personal data with third parties.',
                        'Customer data is used for service delivery, transaction records, communication, and account security.',
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _VerificationSection(
                      title: 'Security Statement',
                      points: [
                        'Stripe keys never go in app code except publishable key.',
                        'Payment and balance credit are verified by backend.',
                        'Platform operations are managed with account and transaction security controls.',
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _VerificationSection(
                      title: 'Terms and Refunds Summary',
                      points: [
                        'Toub Zone Ltd provides digital services including software development, SaaS platforms, and AI solutions.',
                        'All services are delivered digitally.',
                        'Refunds depend on project agreements or subscription terms.',
                        'By using services on this platform, customers agree to the applicable terms.',
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _VerificationSection(
                      title: 'Policy References',
                      points: [
                        'Privacy Policy route: /privacy',
                        'Terms of Service route: /terms',
                        'Services route: /services',
                        'This verification page route: /home',
                      ],
                    ),
                    const SizedBox(height: 12),
                    const GlassContainer(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'No app navigation, login flow, or wallet controls are rendered here. This page is intentionally URL-accessed for verification and compliance review.',
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.65,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard();

  @override
  Widget build(BuildContext context) {
    return const GlassContainer(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metadata',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          _MetaRow(label: 'Business Name', value: 'Toub Zone Ltd'),
          _MetaRow(
            label: 'Address',
            value:
                'High Street North East Ham, Office 13028, London, E6 2JA, United Kingdom',
          ),
          _MetaRow(label: 'Support Email', value: 'support@toubzone.com'),
          _MetaRow(label: 'Support Phone', value: '+44 000 000 0000'),
          _MetaRow(
            label: 'Trading Name',
            value: 'infinity-sharing.money (Infinity E-wallet)',
          ),
          _MetaRow(label: 'Payment Provider', value: 'Stripe'),
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard();

  @override
  Widget build(BuildContext context) {
    return const GlassContainer(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Infinity E-wallet is a SaaS product powered by Toub Zone Ltd. This public page is provided to support Stripe verification workflows and establish transparent business identity data for payment operations.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.6,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'This page includes dedicated business, legal, privacy, security, and terms sections required during verification review.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.6,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationSection extends StatelessWidget {
  const _VerificationSection({
    required this.title,
    required this.points,
  });

  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 7,
                      color: Appcolor.accent,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.55,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Appcolor.glassBorder),
        color: Appcolor.glass,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
