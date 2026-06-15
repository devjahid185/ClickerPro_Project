import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../domain/whatsapp_template.dart';
import '../data/whatsapp_service.dart';

class WhatsAppShareSheet extends StatefulWidget {
  const WhatsAppShareSheet({
    super.key,
    this.clientName = '',
    this.clientPhone = '',
    this.eventName = '',
    this.eventDate = '',
    this.eventTime = '',
    this.venue = '',
    this.amount = '',
    this.total = '',
    this.advance = '',
    this.due = '',
    this.packageName = '',
  });

  final String clientName;
  final String clientPhone;
  final String eventName;
  final String eventDate;
  final String eventTime;
  final String venue;
  final String amount;
  final String total;
  final String advance;
  final String due;
  final String packageName;

  @override
  State<WhatsAppShareSheet> createState() => _WhatsAppShareSheetState();
}

class _WhatsAppShareSheetState extends State<WhatsAppShareSheet> {
  late TextEditingController _phoneController;
  late TextEditingController _messageController;
  WhatsAppTemplateType _selectedType = WhatsAppTemplateType.bookingConfirmation;
  late Map<String, String> _variables;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.clientPhone);
    _messageController = TextEditingController();
    _variables = {
      'name': widget.clientName,
      'event': widget.eventName,
      'date': widget.eventDate,
      'time': widget.eventTime,
      'venue': widget.venue,
      'amount': widget.amount,
      'total': widget.total,
      'advance': widget.advance,
      'due': widget.due,
      'package': widget.packageName,
    };
    _updateMessage();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _updateMessage() {
    final template = WhatsAppTemplate.all.firstWhere(
      (t) => t.type == _selectedType,
    );
    _messageController.text = WhatsAppService.renderTemplate(
      template,
      _variables,
    );
  }

  Future<void> _send() async {
    final phone = _phoneController.text.trim();
    final message = _messageController.text.trim();
    if (phone.isEmpty || message.isEmpty) return;

    final success = await WhatsAppService.openChat(
      phone: phone,
      message: message,
    );

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open WhatsApp. SMS fallback also unavailable.',
          ),
          backgroundColor: AppColors.red,
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: AppColors.voidLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.glassBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            color: AppColors.green,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'WhatsApp Message',
                          style: TextStyle(
                            color: AppColors.film,
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTemplateSelector(),
                    const SizedBox(height: 16),
                    _buildPhoneField(),
                    const SizedBox(height: 16),
                    _buildMessageField(),
                    const SizedBox(height: 20),
                    _buildSendButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: AppColors.glassCardDecoration(),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: WhatsAppTemplate.all.map((template) {
          final isSelected = template.type == _selectedType;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = template.type;
                _updateMessage();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.teal.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.teal.withValues(alpha: 0.4)
                      : AppColors.glassBorder,
                ),
              ),
              child: Text(
                template.label,
                style: TextStyle(
                  color: isSelected ? AppColors.teal : AppColors.filmDim,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PHONE',
          style: TextStyle(
            color: AppColors.teal,
            fontFamily: 'Montserrat',
            fontSize: 10,
            letterSpacing: 1.95,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: AppColors.film, fontSize: 14),
          decoration: InputDecoration(
            hintText: '+8801XXXXXXXXX',
            hintStyle: TextStyle(color: AppColors.filmMuted),
            prefixIcon: const Icon(
              Icons.phone_outlined,
              color: AppColors.teal,
              size: 18,
            ),
            filled: true,
            fillColor: AppColors.glass,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.teal),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MESSAGE',
              style: TextStyle(
                color: AppColors.teal,
                fontFamily: 'Montserrat',
                fontSize: 10,
                letterSpacing: 1.95,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.copy_outlined,
                color: AppColors.filmDim,
                size: 16,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _messageController.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied to clipboard')),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 6,
          style: TextStyle(color: AppColors.film, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.glass,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.teal),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _send,
        icon: const Icon(Icons.send_outlined, size: 18),
        label: const Text(
          'Send via WhatsApp',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.voidBlack,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
