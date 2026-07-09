// lib/features/bookings/presentation/packages_screen.dart
//
// MOD-25 — Studio Package Management.
//
// Full CRUD screen for managing reusable booking packages. Displays
// packages as styled cards with a spec grid, line items, and inline
// edit/delete actions. Add/edit opens as a bottom sheet with live
// net-price calculation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/currency.dart';
import '../../../core/role/capability.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../shared/widgets/motion.dart';
import '../../../shared/widgets/web_shell.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';


import '../application/booking_providers.dart';
import '../domain/package.dart';
import 'web_packages.dart';
import 'widgets/lens_form_fields.dart';

const _printSizeOptions = [
  '8×10',
  '10×12',
  '12×18',
  '16×24',
  '20×30',
  '24×36',
  'Custom',
];

const _deliveryOptions = ['Pendrive', 'Google Drive', 'Both'];

List<Color> get _cardColors => [
  AppColors.teal,
  AppColors.gold,
  AppColors.purple,
  AppColors.green,
  AppColors.coral,
];

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  @override
  Widget build(BuildContext context) {
    final policy = ref.watch(bookingsPolicyProvider);
    final canManage = policy.can(Capability.editStudioBranding);

    // On wide web the WebNavShell owns the chrome; render the dedicated desktop
    // package grid instead of the mobile body. Mobile + narrow web unchanged.
    final webWide = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    if (webWide) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: WebPackages(
          canManage: canManage,
          onEdit: (pkg) => _openEditSheet(context, ref, pkg),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Packages',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: AppText.brandFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'New Package',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () => _openEditSheet(context, ref, null),
            )
          : null,
      body: SafeArea(child: _PackageList(canManage: canManage)),
    );
  }

  void _openEditSheet(BuildContext context, WidgetRef ref, Package? existing) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.voidElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PackageEditSheet(package: existing),
    );
  }
}

// ---------------------------------------------------------------------------
// List
// ---------------------------------------------------------------------------

class _PackageList extends ConsumerWidget {
  const _PackageList({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(packagesProvider);

    return async.when(
      loading: () => const Center(
        child: Padding(padding: EdgeInsets.only(top: 120), child: LensLoader()),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 120),
          child: ErrorState(
            message: 'Could not load packages.',
            onRetry: () => ref.invalidate(packagesProvider),
          ),
        ),
      ),
      data: (packages) {
        if (packages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 120),
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                message:
                    'No packages yet.\nCreate one to speed up booking edits.',
                actionLabel: canManage ? 'Create Package' : null,
                onAction: canManage
                    ? () => _openEditSheet(context, ref, null)
                    : null,
              ),
            ),
          );
        }
        return WebFormWidth(
          maxWidth: 620,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: packages.length,
            itemBuilder: (context, index) => StaggeredList.item(
              index,
              _PackageCard(
                package: packages[index],
                accentColor: _cardColors[index % _cardColors.length],
                canManage: canManage,
              ),
            ),
          ),
        );
      },
    );
  }

  void _openEditSheet(BuildContext context, WidgetRef ref, Package? existing) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.voidElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PackageEditSheet(package: existing),
    );
  }
}

// ---------------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------------

class _PackageCard extends ConsumerWidget {
  const _PackageCard({
    required this.package,
    required this.accentColor,
    required this.canManage,
  });

  final Package package;
  final Color accentColor;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          // Design (.dc.html "Packages"): the accent is a 3px top rule; the
          // other three edges are the usual hairline.
          top: BorderSide(color: accentColor, width: 3),
          left: BorderSide(color: AppColors.glassBorder),
          right: BorderSide(color: AppColors.glassBorder),
          bottom: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    package.name,
                    style: TextStyle(
                      color: AppColors.film,
                      fontFamily: AppText.brandFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (canManage) ...[
                  _ActionChip(
                    icon: Icons.edit_rounded,
                    onTap: () => _edit(context, ref),
                  ),
                  const SizedBox(width: 6),
                  _ActionChip(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.red,
                    onTap: () => _delete(context, ref),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _PriceRow(package: package, accentColor: accentColor),
            const SizedBox(height: 10),
            _SpecGrid(package: package, accentColor: accentColor),
            if (package.items != null && package.items!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ItemsList(items: package.items!),
            ],
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.voidElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PackageEditSheet(package: package),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        title: Text(
          'Delete Package',
          style: TextStyle(color: AppColors.film),
        ),
        content: Text(
          'Delete "${package.name}"? This cannot be undone.',
          style: TextStyle(color: AppColors.filmDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.filmDim),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final policy = ref.read(bookingsPolicyProvider);
    try {
      await ref
          .read(packageRepositoryProvider)
          .remove(package.id, policy: policy);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Package deleted.'),
              backgroundColor: AppColors.voidElevated,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Delete failed: $e'),
              backgroundColor: AppColors.voidElevated,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Price row
// ---------------------------------------------------------------------------

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.package, required this.accentColor});

  final Package package;
  final Color accentColor;

  // Active-currency symbol with thousands grouping — package cards read
  // "৳85,000" for BDT, "$85,000" for USD, etc.
  static final NumberFormat _money = NumberFormat.decimalPattern('en');
  static String _fmt(num v) => ActiveCurrency.value.wrap(_money.format(v.round()));

  @override
  Widget build(BuildContext context) {
    final hasDiscount = package.discount > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _fmt(package.netPrice),
          style: TextStyle(
            color: accentColor,
            fontFamily: AppText.brandFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 6),
          Text(
            _fmt(package.basePrice),
            style: TextStyle(
              color: AppColors.filmMuted,
              fontSize: 14,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.filmMuted,
            ),
          ),
        ],
        if (hasDiscount) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '-${package.discount.toStringAsFixed(0)}',
              style: TextStyle(
                color: AppColors.red,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Spec grid
// ---------------------------------------------------------------------------

class _SpecGrid extends StatelessWidget {
  const _SpecGrid({required this.package, required this.accentColor});

  final Package package;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final specs = <_SpecItem>[];

    if (package.printQuantity != null && (package.printQuantity ?? 0) > 0) {
      final size = package.printSize ?? '—';
      specs.add(
        _SpecItem(label: 'PRINTS', value: '${package.printQuantity} × $size'),
      );
    }
    if (package.albumText != null && package.albumText!.isNotEmpty) {
      specs.add(_SpecItem(label: 'ALBUM', value: package.albumText!));
    }
    if (package.trailersPerEvent != null &&
        (package.trailersPerEvent ?? 0) > 0) {
      specs.add(
        _SpecItem(label: 'TRAILERS', value: '${package.trailersPerEvent}'),
      );
    }
    if (package.fullVideosPerEvent != null &&
        (package.fullVideosPerEvent ?? 0) > 0) {
      specs.add(
        _SpecItem(label: 'VIDEOS', value: '${package.fullVideosPerEvent}'),
      );
    }
    if (package.deliveryMethod != null && package.deliveryMethod!.isNotEmpty) {
      specs.add(_SpecItem(label: 'DELIVERY', value: package.deliveryMethod!));
    }

    if (specs.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: specs.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.label,
                style: TextStyle(
                  fontFamily: AppText.monoFontFamily,
                  fontSize: 9,
                  letterSpacing: 1,
                  color: accentColor.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                s.value,
                style: TextStyle(
                  color: AppColors.film,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SpecItem {
  const _SpecItem({required this.label, required this.value});
  final String label;
  final String value;
}

// ---------------------------------------------------------------------------
// Items list
// ---------------------------------------------------------------------------

class _ItemsList extends StatelessWidget {
  const _ItemsList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ITEMS',
          style: TextStyle(
            fontFamily: AppText.monoFontFamily,
            fontSize: 9,
            letterSpacing: 1,
            color: AppColors.filmMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: AppColors.teal.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: AppColors.filmDim.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Action chip (icon-only button)
// ---------------------------------------------------------------------------

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.filmDim;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 16, color: c),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit / Create bottom sheet
// ---------------------------------------------------------------------------

class _PackageEditSheet extends ConsumerStatefulWidget {
  const _PackageEditSheet({this.package});

  final Package? package;

  @override
  ConsumerState<_PackageEditSheet> createState() => _PackageEditSheetState();
}

class _PackageEditSheetState extends ConsumerState<_PackageEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _printQtyCtrl;
  late final TextEditingController _albumCtrl;
  late final TextEditingController _trailersCtrl;
  late final TextEditingController _videosCtrl;
  late final TextEditingController _customSizeCtrl;
  late final TextEditingController _photographersCtrl;
  late final TextEditingController _cinematographersCtrl;

  String? _printSize;
  String? _delivery;
  bool _includesChief = false;
  late List<String> _items;
  bool _saving = false;

  bool get _isEditing => widget.package != null;

  @override
  void initState() {
    super.initState();
    final p = widget.package;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(
      text: p?.basePrice.toStringAsFixed(0) ?? '',
    );
    _discountCtrl = TextEditingController(
      text: p?.discount.toStringAsFixed(0) ?? '',
    );
    _printQtyCtrl = TextEditingController(
      text: p?.printQuantity?.toString() ?? '',
    );
    _albumCtrl = TextEditingController(text: p?.albumText ?? '');
    _trailersCtrl = TextEditingController(
      text: p?.trailersPerEvent?.toString() ?? '',
    );
    _videosCtrl = TextEditingController(
      text: p?.fullVideosPerEvent?.toString() ?? '',
    );
    _customSizeCtrl = TextEditingController(text: p?.printSize ?? '');
    _photographersCtrl = TextEditingController(
      text: p?.photographerCount?.toString() ?? '',
    );
    _cinematographersCtrl = TextEditingController(
      text: p?.cinematographerCount?.toString() ?? '',
    );
    _printSize = p?.printSize;
    _delivery = p?.deliveryMethod;
    _includesChief = p?.includesChief ?? false;
    _items = List<String>.from(p?.items ?? const []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _printQtyCtrl.dispose();
    _albumCtrl.dispose();
    _trailersCtrl.dispose();
    _videosCtrl.dispose();
    _customSizeCtrl.dispose();
    _photographersCtrl.dispose();
    _cinematographersCtrl.dispose();
    super.dispose();
  }

  double get _netPrice {
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final disc = double.tryParse(_discountCtrl.text) ?? 0;
    return price - disc;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return StatefulBuilder(
      builder: (context, setSheetState) {
        void refresh() => setSheetState(() {});

        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: AppColors.filmMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isEditing ? 'Edit Package' : 'New Package',
                          style: TextStyle(
                            color: AppColors.film,
                            fontFamily: AppText.brandFontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_isEditing)
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _deleteFromSheet();
                          },
                          child: Text(
                            'Delete',
                            style: TextStyle(color: AppColors.red),
                          ),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      LensTextField(
                        label: 'Name',
                        controller: _nameCtrl,
                        maxLength: 80,
                        hint: 'Premium Wedding Package',
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: LensTextField(
                              label: 'Price',
                              controller: _priceCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => refresh(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: LensTextField(
                              label: 'Discount',
                              controller: _discountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => refresh(),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'NET PRICE',
                              style: TextStyle(
                                fontFamily: AppText.bodyFontFamily,
                                fontSize: 10,
                                letterSpacing: 1.4,
                                color: AppColors.teal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _netPrice.toStringAsFixed(0),
                              style: TextStyle(
                                color: AppColors.teal,
                                fontFamily: AppText.brandFontFamily,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: LensTextField(
                              label: 'Print Qty',
                              controller: _printQtyCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: _buildPrintSizeSelector(refresh)),
                        ],
                      ),
                      if (_printSize == 'Custom')
                        LensTextField(
                          label: 'Custom Size',
                          controller: _customSizeCtrl,
                          hint: 'e.g. 30×40',
                        ),
                      LensTextField(
                        label: 'Album',
                        controller: _albumCtrl,
                        hint: 'e.g. 1 Premium Album',
                      ),
                      _buildDeliverySelector(refresh),
                      Row(
                        children: [
                          Expanded(
                            child: LensTextField(
                              label: 'Trailers / Event',
                              controller: _trailersCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: LensTextField(
                              label: 'Full Videos / Event',
                              controller: _videosCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      // Team composition — auto-fills the booking form's
                      // photographer / cinematographer slots on select.
                      Row(
                        children: [
                          Expanded(
                            child: LensTextField(
                              label: 'Photographers',
                              controller: _photographersCtrl,
                              keyboardType: TextInputType.number,
                              hint: 'e.g. 2',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: LensTextField(
                              label: 'Cinematographers',
                              controller: _cinematographersCtrl,
                              keyboardType: TextInputType.number,
                              hint: 'e.g. 1',
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Includes Chief Photographer',
                          style: TextStyle(
                            color: AppColors.film,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: _includesChief,
                        activeThumbColor: AppColors.gold,
                        onChanged: (v) {
                          setState(() => _includesChief = v);
                          refresh();
                        },
                      ),
                      const SizedBox(height: 6),
                      _buildItemsEditor(refresh),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _saving ? null : () => _onSave(refresh),
                          child: _saving
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.film,
                                  ),
                                )
                              : Text(
                                  _isEditing
                                      ? 'Save Changes'
                                      : 'Create Package',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrintSizeSelector(VoidCallback refresh) {
    final displayValue = _printSize == null
        ? null
        : (_printSize == 'Custom' ? 'Custom' : _printSize);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRINT SIZE',
            style: TextStyle(
              fontFamily: AppText.bodyFontFamily,
              fontSize: 10,
              letterSpacing: 1.4,
              color: AppColors.gold.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.line(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line(0.08)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: displayValue,
                isExpanded: true,
                isDense: true,
                dropdownColor: AppColors.voidElevated,
                iconEnabledColor: AppColors.filmDim,
                style: TextStyle(color: AppColors.film, fontSize: 13.5),
                hint: Text(
                  'Select size',
                  style: TextStyle(
                    color: AppColors.filmMuted.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                onChanged: (v) {
                  _printSize = v;
                  refresh();
                },
                items: _printSizeOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySelector(VoidCallback refresh) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DELIVERY',
            style: TextStyle(
              fontFamily: AppText.bodyFontFamily,
              fontSize: 10,
              letterSpacing: 1.4,
              color: AppColors.gold.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.line(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line(0.08)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _delivery,
                isExpanded: true,
                isDense: true,
                dropdownColor: AppColors.voidElevated,
                iconEnabledColor: AppColors.filmDim,
                style: TextStyle(color: AppColors.film, fontSize: 13.5),
                hint: Text(
                  'Select delivery method',
                  style: TextStyle(
                    color: AppColors.filmMuted.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                onChanged: (v) {
                  _delivery = v;
                  refresh();
                },
                items: _deliveryOptions
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsEditor(VoidCallback refresh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ITEMS',
              style: TextStyle(
                fontFamily: AppText.bodyFontFamily,
                fontSize: 10,
                letterSpacing: 1.4,
                color: AppColors.gold.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _addItem(refresh),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: AppColors.teal),
                    SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: AppColors.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No items added yet.',
              style: TextStyle(
                color: AppColors.filmMuted.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          )
        else
          ...List.generate(_items.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: _items[i]),
                      style: TextStyle(color: AppColors.film, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.line(0.04),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.line(0.08),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.line(0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.teal),
                        ),
                      ),
                      onChanged: (v) => _items[i] = v,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      _items.removeAt(i);
                      refresh();
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.red,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _addItem(VoidCallback refresh) {
    _items.add('');
    refresh();
  }

  Future<void> _onSave(VoidCallback refresh) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Package name is required.'),
            backgroundColor: AppColors.voidElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final disc = double.tryParse(_discountCtrl.text) ?? 0;
    final printQty = int.tryParse(_printQtyCtrl.text.trim());
    final trailers = int.tryParse(_trailersCtrl.text.trim());
    final videos = int.tryParse(_videosCtrl.text.trim());
    final photographers = int.tryParse(_photographersCtrl.text.trim());
    final cinematographers = int.tryParse(_cinematographersCtrl.text.trim());

    String? resolvedPrintSize = _printSize;
    if (resolvedPrintSize == 'Custom') {
      final custom = _customSizeCtrl.text.trim();
      resolvedPrintSize = custom.isEmpty ? null : custom;
    }

    final cleanedItems = _items
        .where((i) => i.trim().isNotEmpty)
        .map((i) => i.trim())
        .toList();

    final now = DateTime.now();
    final existing = widget.package;

    final pkg = Package(
      id: existing?.id ?? 'p-${now.microsecondsSinceEpoch}',
      remoteId: existing?.remoteId,
      studioId: existing?.studioId ?? '',
      name: name,
      basePrice: price,
      discount: disc,
      coverageHours: existing?.coverageHours,
      extraHourRate: existing?.extraHourRate,
      printSize: resolvedPrintSize,
      printQuantity: printQty,
      albumText: _albumCtrl.text.trim().isEmpty ? null : _albumCtrl.text.trim(),
      deliveryMethod: _delivery,
      trailersPerEvent: trailers,
      fullVideosPerEvent: videos,
      photographerCount: photographers,
      cinematographerCount: cinematographers,
      includesChief: _includesChief,
      items: cleanedItems.isEmpty ? null : cleanedItems,
      inclusions: existing?.inclusions,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      pending: existing?.pending ?? false,
    );

    setState(() => _saving = true);

    try {
      final policy = ref.read(bookingsPolicyProvider);
      await ref.read(packageRepositoryProvider).save(pkg, policy: policy);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                _isEditing ? 'Package updated.' : 'Package created.',
              ),
              backgroundColor: AppColors.voidElevated,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Save failed: $e'),
              backgroundColor: AppColors.voidElevated,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }

  Future<void> _deleteFromSheet() async {
    final pkg = widget.package;
    if (pkg == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.voidElevated,
        title: Text(
          'Delete Package',
          style: TextStyle(color: AppColors.film),
        ),
        content: Text(
          'Delete "${pkg.name}"? This cannot be undone.',
          style: TextStyle(color: AppColors.filmDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.filmDim),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final policy = ref.read(bookingsPolicyProvider);
    try {
      await ref.read(packageRepositoryProvider).remove(pkg.id, policy: policy);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Package deleted.'),
              backgroundColor: AppColors.voidElevated,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Delete failed: $e'),
              backgroundColor: AppColors.voidElevated,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }
}
