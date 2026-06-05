import 'package:url_launcher/url_launcher.dart';

import '../domain/whatsapp_template.dart';

class WhatsAppService {
  const WhatsAppService._();

  static String buildWhatsAppUrl(String phone, String message) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final encoded = Uri.encodeComponent(message);
    return 'https://wa.me/$cleaned?text=$encoded';
  }

  static String buildSmsUrl(String phone, String message) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final encoded = Uri.encodeComponent(message);
    return 'sms:$cleaned?body=$encoded';
  }

  static Future<bool> openChat({
    required String phone,
    required String message,
  }) async {
    final whatsappUrl = Uri.parse(buildWhatsAppUrl(phone, message));

    if (await canLaunchUrl(whatsappUrl)) {
      return launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }

    final smsUrl = Uri.parse(buildSmsUrl(phone, message));
    if (await canLaunchUrl(smsUrl)) {
      return launchUrl(smsUrl, mode: LaunchMode.externalApplication);
    }

    return false;
  }

  static String renderTemplate(
    WhatsAppTemplate template,
    Map<String, String> variables,
  ) {
    return template.render(variables);
  }
}
