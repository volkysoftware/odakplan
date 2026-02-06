import 'package:flutter/material.dart';

/// Privacy Policy screen displaying OdakPlan's privacy policy
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik Politikası'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'OdakPlan Gizlilik Politikası',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              
              // Last updated date
              Text(
                'Son güncelleme: 19.01.2026',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),

              // Section 1
              _buildSection(
                context,
                '1) Toplanan Veriler',
                'OdakPlan, kullanıcıdan hesap bilgisi istemez ve uygulama içinde doğrudan kimlik belirleyici kişisel veri toplamaz.',
              ),
              const SizedBox(height: 24),

              // Section 2
              _buildSection(
                context,
                '2) Yerel Depolama',
                'Uygulama, odak süreleri ve kullanıcı tercihlerini (tema, hatırlatıcı saat/günleri vb.) cihazınızda yerel olarak saklar. Bu veriler cihazınızdan dışarı gönderilmez.',
              ),
              const SizedBox(height: 24),

              // Section 3
              _buildSection(
                context,
                '3) Bildirimler',
                'Uygulama, seçtiğiniz saat ve günlerde hatırlatma bildirimleri gönderebilir. Bildirimler için işletim sistemi izinleri kullanılabilir.',
              ),
              const SizedBox(height: 24),

              // Section 4
              _buildSection(
                context,
                '4) Üçüncü Taraflarla Paylaşım',
                'OdakPlan, verilerinizi üçüncü taraflarla satmaz veya paylaşmaz.',
              ),
              const SizedBox(height: 24),

              // Section 5
              _buildSection(
                context,
                '5) Güvenlik',
                'Veriler cihazınızda saklanır. Cihaz güvenliği (ekran kilidi vb.) kullanmanız önerilir.',
              ),
              const SizedBox(height: 24),

              // Section 6
              _buildSection(
                context,
                '6) Çocukların Gizliliği',
                'Uygulama, özel olarak çocuklara yönelik kişisel veri toplamaz.',
              ),
              const SizedBox(height: 24),

              // Section 7
              _buildSection(
                context,
                '7) İletişim',
                'Gizlilik ile ilgili sorularınız için: volkysoftware@gmail.com',
              ),
              const SizedBox(height: 32),

              // Footer note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Bu metin bilgilendirme amaçlıdır ve uygulamanın mevcut işleyişine göre hazırlanmıştır.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: theme.colorScheme.onSurface.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}
