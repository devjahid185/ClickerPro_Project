enum WhatsAppTemplateType {
  bookingConfirmation,
  paymentReminder,
  invoice,
  followUp,
  birthdayWish,
  anniversaryWish,
}

class WhatsAppTemplate {
  const WhatsAppTemplate({
    required this.type,
    required this.label,
    required this.body,
  });

  final WhatsAppTemplateType type;
  final String label;
  final String body;

  String render(Map<String, String> variables) {
    var result = body;
    for (final entry in variables.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  static const bookingConfirmation = WhatsAppTemplate(
    type: WhatsAppTemplateType.bookingConfirmation,
    label: 'Booking Confirmation',
    body:
        'Dear {name}, your {event} on {date} at {time} is confirmed. '
        'Venue: {venue}. Looking forward to capturing your special moments!',
  );

  static const paymentReminder = WhatsAppTemplate(
    type: WhatsAppTemplateType.paymentReminder,
    label: 'Payment Reminder',
    body:
        'Dear {name}, this is a friendly reminder for the due payment of '
        '{amount} for your {event} on {date}. Please let us know if you '
        'have any questions.',
  );

  static const invoiceTemplate = WhatsAppTemplate(
    type: WhatsAppTemplateType.invoice,
    label: 'Invoice',
    body:
        'Dear {name}, here is the invoice for your {event}.\n\n'
        'Package: {package}\n'
        'Total: {total}\n'
        'Advance: {advance}\n'
        'Due: {due}\n\n'
        'Please review and let us know if you have any questions.',
  );

  static const followUp = WhatsAppTemplate(
    type: WhatsAppTemplateType.followUp,
    label: 'Follow-up',
    body:
        'Dear {name}, your album from the {event} on {date} is ready! '
        'We hope you love the memories we captured together.',
  );

  static const birthdayWish = WhatsAppTemplate(
    type: WhatsAppTemplateType.birthdayWish,
    label: 'Birthday Wish',
    body:
        'Dear {name}, wishing you a very Happy Birthday! '
        'May this year bring you endless joy and beautiful moments.',
  );

  static const anniversaryWish = WhatsAppTemplate(
    type: WhatsAppTemplateType.anniversaryWish,
    label: 'Anniversary Wish',
    body:
        'Dear {name}, Happy Anniversary! '
        'Wishing you both a lifetime of love and cherished memories.',
  );

  static const List<WhatsAppTemplate> all = [
    bookingConfirmation,
    paymentReminder,
    invoiceTemplate,
    followUp,
    birthdayWish,
    anniversaryWish,
  ];
}
