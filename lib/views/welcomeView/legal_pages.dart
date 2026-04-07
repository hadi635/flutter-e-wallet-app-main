import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/main.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const String _companyName = 'Toub Zone Ltd';
const String _address1 = 'High Street North East Ham, Office 13028';
const String _address2 = 'London, E6 2JA';
const String _country = 'United Kingdom';
const String _email = 'support@toubzone.com';
const String _phone = '+44 000 000 0000';
const String _tradingNameNote =
    'infinity-sharing.money (Infinity E-wallet) is a trading name and SaaS product powered by Toub Zone Ltd.';

const List<_RouteLink> _legalLinks = [
  _RouteLink('Home', AppRoutes.welcome),
  _RouteLink('About', AppRoutes.about),
  _RouteLink('Services', AppRoutes.services),
  _RouteLink('Contact', AppRoutes.contact),
  _RouteLink('Privacy Policy', AppRoutes.privacy),
  _RouteLink('Terms', AppRoutes.terms),
];

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPageScaffold(
      currentRoute: AppRoutes.about,
      title: 'About',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Toub Zone Ltd is a software development company focused on building dependable digital products for modern businesses. Our engineering teams deliver web and mobile software with clean architecture, strong performance, and long-term maintainability.',
            style: _bodyStyle,
          ),
          SizedBox(height: 14),
          Text(
            'We also provide AI solutions that help organizations automate repetitive workflows, improve decision-making, and reduce operational overhead. From AI integration strategy to production implementation, we prioritize measurable business outcomes.',
            style: _bodyStyle,
          ),
          SizedBox(height: 14),
          Text(
            'Our SaaS platform development services cover product planning, multi-tenant architecture, cloud infrastructure, billing integration, and lifecycle support. We help clients launch scalable subscription products and continuously improve them as customer demand grows.',
            style: _bodyStyle,
          ),
          SizedBox(height: 14),
          Text(
            'Toub Zone Ltd supports international clients across multiple industries with a full range of digital services, including discovery, design, development, deployment, and ongoing technical support.',
            style: _bodyStyle,
          ),
          SizedBox(height: 14),
          Text(_tradingNameNote, style: _bodyStyle),
        ],
      ),
    );
  }
}

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1200
        ? 3
        : width >= 820
            ? 2
            : 1;
    const services = [
      _ServiceItem(
        title: 'Custom Software Development',
        description:
            'Tailored software systems designed around your operations, goals, and growth plans.',
      ),
      _ServiceItem(
        title: 'Web Development',
        description:
            'Responsive, high-performance web applications with modern architecture and optimized user experience.',
      ),
      _ServiceItem(
        title: 'Mobile App Development',
        description:
            'Cross-platform and native mobile apps with reliable performance, secure APIs, and maintainable codebases.',
      ),
      _ServiceItem(
        title: 'AI & Automation Solutions',
        description:
            'Practical AI workflows and automation tools to streamline repetitive business processes.',
      ),
      _ServiceItem(
        title: 'SaaS Platform Development',
        description:
            'End-to-end SaaS product engineering from architecture and development to deployment.',
      ),
      _ServiceItem(
        title: 'UI/UX Design',
        description:
            'User-centered product design focused on clarity, conversion, accessibility, and consistent brand experience.',
      ),
    ];

    return _LegalPageScaffold(
      currentRoute: AppRoutes.services,
      title: 'Services',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: crossAxisCount == 1 ? 1.95 : 1.35,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final item = services[index];
          return GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: _cardTitleStyle),
                const SizedBox(height: 10),
                Text(item.description, style: _bodyStyle),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message sent. We will contact you soon.')),
    );
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 980;
    return _LegalPageScaffold(
      currentRoute: AppRoutes.contact,
      title: 'Contact',
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: _ContactInfoCard()),
                const SizedBox(width: 12),
                Expanded(
                  child: _ContactFormCard(
                    formKey: _formKey,
                    onSend: _sendMessage,
                    nameController: _nameController,
                    emailController: _emailController,
                    messageController: _messageController,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ContactInfoCard(),
                const SizedBox(height: 12),
                _ContactFormCard(
                  formKey: _formKey,
                  onSend: _sendMessage,
                  nameController: _nameController,
                  emailController: _emailController,
                  messageController: _messageController,
                ),
              ],
            ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPageScaffold(
      currentRoute: AppRoutes.privacy,
      title: 'Privacy Policy',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We collect basic customer information such as name, email, and billing details to provide our services. We do not sell or share personal data with third parties. All payments are processed securely via Stripe. Customer data is used only for service delivery and communication.',
            style: _bodyStyle,
          ),
          SizedBox(height: 14),
          Text(
            'Your data is used only for wallet operations, transaction history, and account security.',
            style: _bodyStyle,
          ),
          SizedBox(height: 14),
          Text(
            'Security note: Stripe keys never go in app code except publishable key. Payment and balance credit are verified by backend.',
            style: _bodyStyle,
          ),
        ],
      ),
    );
  }
}

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPageScaffold(
      currentRoute: AppRoutes.terms,
      title: 'Terms of Service',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Toub Zone Ltd provides digital services including software development, SaaS platforms, and AI solutions. All services are delivered digitally. Refunds depend on project agreements or subscription terms. By using our services, you agree to these terms.',
            style: _bodyStyle,
          ),
          SizedBox(height: 14),
          Text(
            'For wallet and SaaS operations, customer data is handled only for service delivery, transaction records, communication, and account security.',
            style: _bodyStyle,
          ),
          SizedBox(height: 14),
          Text(
            'Payments are processed securely through Stripe and payment confirmation or wallet credit is verified by backend systems.',
            style: _bodyStyle,
          ),
        ],
      ),
    );
  }
}

class _LegalPageScaffold extends StatelessWidget {
  const _LegalPageScaffold({
    required this.currentRoute,
    required this.title,
    required this.child,
  });

  final String currentRoute;
  final String title;
  final Widget child;

  void _go(String route) {
    if (Get.currentRoute == route) return;
    Get.offNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopNav = MediaQuery.sizeOf(context).width >= 980;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          _companyName,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!isDesktopNav)
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onSelected: _go,
              itemBuilder: (context) => _legalLinks
                  .map(
                    (e) => PopupMenuItem<String>(
                      value: e.route,
                      child: Text(e.label),
                    ),
                  )
                  .toList(),
            )
          else
            Row(
              children: _legalLinks
                  .map(
                    (link) => TextButton(
                      onPressed: () => _go(link.route),
                      child: Text(
                        link.label,
                        style: TextStyle(
                          color: currentRoute == link.route
                              ? Appcolor.accent
                              : Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassContainer(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: _pageTitleStyle),
                          const SizedBox(height: 14),
                          child,
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _LegalFooter(),
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

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  void _go(String route) {
    if (Get.currentRoute == route) return;
    Get.offNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(_companyName, style: _footerTitleStyle),
          const SizedBox(height: 8),
          const Text(
            '$_address1\n$_address2\n$_country',
            textAlign: TextAlign.center,
            style: _footerBodyStyle,
          ),
          const SizedBox(height: 8),
          const Text(
            '$_email\n$_phone',
            textAlign: TextAlign.center,
            style: _footerBodyStyle,
          ),
          const SizedBox(height: 8),
          const Text(
            _tradingNameNote,
            textAlign: TextAlign.center,
            style: _footerBodyStyle,
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: _legalLinks
                .map(
                  (link) => _RoutePill(
                    label: link.label,
                    onTap: () => _go(link.route),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard();

  @override
  Widget build(BuildContext context) {
    return const GlassContainer(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_companyName, style: _sectionTitleStyle),
          SizedBox(height: 10),
          Text('$_address1\n$_address2\n$_country', style: _bodyStyle),
          SizedBox(height: 10),
          Text(_email, style: _bodyStyle),
          SizedBox(height: 6),
          Text(_phone, style: _bodyStyle),
          SizedBox(height: 10),
          Text(_tradingNameNote, style: _bodyStyle),
        ],
      ),
    );
  }
}

class _ContactFormCard extends StatelessWidget {
  const _ContactFormCard({
    required this.formKey,
    required this.onSend,
    required this.nameController,
    required this.emailController,
    required this.messageController,
  });

  final GlobalKey<FormState> formKey;
  final VoidCallback onSend;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController messageController;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send a Message', style: _sectionTitleStyle),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Name'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter your name'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Email'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter your email'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: messageController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Message'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter your message'
                  : null,
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolor.accent,
                foregroundColor: Colors.black87,
              ),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePill extends StatelessWidget {
  const _RoutePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
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
      ),
    );
  }
}

class _RouteLink {
  final String label;
  final String route;

  const _RouteLink(this.label, this.route);
}

class _ServiceItem {
  final String title;
  final String description;

  const _ServiceItem({required this.title, required this.description});
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Colors.black.withValues(alpha: 0.20),
    enabledBorder: OutlineInputBorder(
      borderSide:
          BorderSide(color: Appcolor.glassBorder.withValues(alpha: 0.85)),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Appcolor.accent),
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.redAccent),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.redAccent),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

const TextStyle _pageTitleStyle = TextStyle(
  color: Colors.white,
  fontSize: 28,
  fontWeight: FontWeight.w800,
);

const TextStyle _sectionTitleStyle = TextStyle(
  color: Colors.white,
  fontSize: 20,
  fontWeight: FontWeight.w700,
);

const TextStyle _cardTitleStyle = TextStyle(
  color: Colors.white,
  fontSize: 18,
  fontWeight: FontWeight.w700,
);

const TextStyle _bodyStyle = TextStyle(
  color: Colors.white70,
  fontSize: 15,
  height: 1.65,
);

const TextStyle _footerTitleStyle = TextStyle(
  color: Colors.white,
  fontSize: 18,
  fontWeight: FontWeight.w700,
);

const TextStyle _footerBodyStyle = TextStyle(
  color: Colors.white70,
  height: 1.5,
);
