// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTableTable extends UsersTable
    with TableInfo<$UsersTableTable, UserRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
    'bio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _specializationMeta = const VerificationMeta(
    'specialization',
  );
  @override
  late final GeneratedColumn<String> specialization = GeneratedColumn<String>(
    'specialization',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vatBinMeta = const VerificationMeta('vatBin');
  @override
  late final GeneratedColumn<String> vatBin = GeneratedColumn<String>(
    'vat_bin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _studioAddressMeta = const VerificationMeta(
    'studioAddress',
  );
  @override
  late final GeneratedColumn<String> studioAddress = GeneratedColumn<String>(
    'studio_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _whatsappMeta = const VerificationMeta(
    'whatsapp',
  );
  @override
  late final GeneratedColumn<String> whatsapp = GeneratedColumn<String>(
    'whatsapp',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bkashMeta = const VerificationMeta('bkash');
  @override
  late final GeneratedColumn<String> bkash = GeneratedColumn<String>(
    'bkash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bankDetailsMeta = const VerificationMeta(
    'bankDetails',
  );
  @override
  late final GeneratedColumn<String> bankDetails = GeneratedColumn<String>(
    'bank_details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _signatureUrlMeta = const VerificationMeta(
    'signatureUrl',
  );
  @override
  late final GeneratedColumn<String> signatureUrl = GeneratedColumn<String>(
    'signature_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoUrlMeta = const VerificationMeta(
    'logoUrl',
  );
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companyNameMeta = const VerificationMeta(
    'companyName',
  );
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
    'company_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalEventsMeta = const VerificationMeta(
    'totalEvents',
  );
  @override
  late final GeneratedColumn<int> totalEvents = GeneratedColumn<int>(
    'total_events',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalRevenueMinorMeta = const VerificationMeta(
    'totalRevenueMinor',
  );
  @override
  late final GeneratedColumn<int> totalRevenueMinor = GeneratedColumn<int>(
    'total_revenue_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalClientsMeta = const VerificationMeta(
    'totalClients',
  );
  @override
  late final GeneratedColumn<int> totalClients = GeneratedColumn<int>(
    'total_clients',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statsRefreshedAtMeta = const VerificationMeta(
    'statsRefreshedAt',
  );
  @override
  late final GeneratedColumn<DateTime> statsRefreshedAt =
      GeneratedColumn<DateTime>(
        'stats_refreshed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCurrentMeta = const VerificationMeta(
    'isCurrent',
  );
  @override
  late final GeneratedColumn<bool> isCurrent = GeneratedColumn<bool>(
    'is_current',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_current" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    name,
    email,
    phone,
    role,
    ownerId,
    avatarUrl,
    bio,
    specialization,
    vatBin,
    studioAddress,
    whatsapp,
    bkash,
    bankDetails,
    signatureUrl,
    logoUrl,
    companyName,
    totalEvents,
    totalRevenueMinor,
    totalClients,
    statsRefreshedAt,
    createdAt,
    updatedAt,
    pending,
    deletedAt,
    isCurrent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('bio')) {
      context.handle(
        _bioMeta,
        bio.isAcceptableOrUnknown(data['bio']!, _bioMeta),
      );
    }
    if (data.containsKey('specialization')) {
      context.handle(
        _specializationMeta,
        specialization.isAcceptableOrUnknown(
          data['specialization']!,
          _specializationMeta,
        ),
      );
    }
    if (data.containsKey('vat_bin')) {
      context.handle(
        _vatBinMeta,
        vatBin.isAcceptableOrUnknown(data['vat_bin']!, _vatBinMeta),
      );
    }
    if (data.containsKey('studio_address')) {
      context.handle(
        _studioAddressMeta,
        studioAddress.isAcceptableOrUnknown(
          data['studio_address']!,
          _studioAddressMeta,
        ),
      );
    }
    if (data.containsKey('whatsapp')) {
      context.handle(
        _whatsappMeta,
        whatsapp.isAcceptableOrUnknown(data['whatsapp']!, _whatsappMeta),
      );
    }
    if (data.containsKey('bkash')) {
      context.handle(
        _bkashMeta,
        bkash.isAcceptableOrUnknown(data['bkash']!, _bkashMeta),
      );
    }
    if (data.containsKey('bank_details')) {
      context.handle(
        _bankDetailsMeta,
        bankDetails.isAcceptableOrUnknown(
          data['bank_details']!,
          _bankDetailsMeta,
        ),
      );
    }
    if (data.containsKey('signature_url')) {
      context.handle(
        _signatureUrlMeta,
        signatureUrl.isAcceptableOrUnknown(
          data['signature_url']!,
          _signatureUrlMeta,
        ),
      );
    }
    if (data.containsKey('logo_url')) {
      context.handle(
        _logoUrlMeta,
        logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta),
      );
    }
    if (data.containsKey('company_name')) {
      context.handle(
        _companyNameMeta,
        companyName.isAcceptableOrUnknown(
          data['company_name']!,
          _companyNameMeta,
        ),
      );
    }
    if (data.containsKey('total_events')) {
      context.handle(
        _totalEventsMeta,
        totalEvents.isAcceptableOrUnknown(
          data['total_events']!,
          _totalEventsMeta,
        ),
      );
    }
    if (data.containsKey('total_revenue_minor')) {
      context.handle(
        _totalRevenueMinorMeta,
        totalRevenueMinor.isAcceptableOrUnknown(
          data['total_revenue_minor']!,
          _totalRevenueMinorMeta,
        ),
      );
    }
    if (data.containsKey('total_clients')) {
      context.handle(
        _totalClientsMeta,
        totalClients.isAcceptableOrUnknown(
          data['total_clients']!,
          _totalClientsMeta,
        ),
      );
    }
    if (data.containsKey('stats_refreshed_at')) {
      context.handle(
        _statsRefreshedAtMeta,
        statsRefreshedAt.isAcceptableOrUnknown(
          data['stats_refreshed_at']!,
          _statsRefreshedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('is_current')) {
      context.handle(
        _isCurrentMeta,
        isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      bio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bio'],
      ),
      specialization: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}specialization'],
      ),
      vatBin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vat_bin'],
      ),
      studioAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}studio_address'],
      ),
      whatsapp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}whatsapp'],
      ),
      bkash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bkash'],
      ),
      bankDetails: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_details'],
      ),
      signatureUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature_url'],
      ),
      logoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_url'],
      ),
      companyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_name'],
      ),
      totalEvents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_events'],
      )!,
      totalRevenueMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_revenue_minor'],
      )!,
      totalClients: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_clients'],
      )!,
      statsRefreshedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}stats_refreshed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      isCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_current'],
      )!,
    );
  }

  @override
  $UsersTableTable createAlias(String alias) {
    return $UsersTableTable(attachedDatabase, alias);
  }
}

class UserRow extends DataClass implements Insertable<UserRow> {
  final String id;
  final String? remoteId;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? ownerId;
  final String? avatarUrl;
  final String? bio;
  final String? specialization;
  final String? vatBin;
  final String? studioAddress;
  final String? whatsapp;
  final String? bkash;
  final String? bankDetails;
  final String? signatureUrl;
  final String? logoUrl;
  final String? companyName;
  final int totalEvents;
  final int totalRevenueMinor;
  final int totalClients;
  final DateTime? statsRefreshedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pending;
  final DateTime? deletedAt;
  final bool isCurrent;
  const UserRow({
    required this.id,
    this.remoteId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.ownerId,
    this.avatarUrl,
    this.bio,
    this.specialization,
    this.vatBin,
    this.studioAddress,
    this.whatsapp,
    this.bkash,
    this.bankDetails,
    this.signatureUrl,
    this.logoUrl,
    this.companyName,
    required this.totalEvents,
    required this.totalRevenueMinor,
    required this.totalClients,
    this.statsRefreshedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.pending,
    this.deletedAt,
    required this.isCurrent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    if (!nullToAbsent || specialization != null) {
      map['specialization'] = Variable<String>(specialization);
    }
    if (!nullToAbsent || vatBin != null) {
      map['vat_bin'] = Variable<String>(vatBin);
    }
    if (!nullToAbsent || studioAddress != null) {
      map['studio_address'] = Variable<String>(studioAddress);
    }
    if (!nullToAbsent || whatsapp != null) {
      map['whatsapp'] = Variable<String>(whatsapp);
    }
    if (!nullToAbsent || bkash != null) {
      map['bkash'] = Variable<String>(bkash);
    }
    if (!nullToAbsent || bankDetails != null) {
      map['bank_details'] = Variable<String>(bankDetails);
    }
    if (!nullToAbsent || signatureUrl != null) {
      map['signature_url'] = Variable<String>(signatureUrl);
    }
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    if (!nullToAbsent || companyName != null) {
      map['company_name'] = Variable<String>(companyName);
    }
    map['total_events'] = Variable<int>(totalEvents);
    map['total_revenue_minor'] = Variable<int>(totalRevenueMinor);
    map['total_clients'] = Variable<int>(totalClients);
    if (!nullToAbsent || statsRefreshedAt != null) {
      map['stats_refreshed_at'] = Variable<DateTime>(statsRefreshedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending'] = Variable<bool>(pending);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['is_current'] = Variable<bool>(isCurrent);
    return map;
  }

  UsersTableCompanion toCompanion(bool nullToAbsent) {
    return UsersTableCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      name: Value(name),
      email: Value(email),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      role: Value(role),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      specialization: specialization == null && nullToAbsent
          ? const Value.absent()
          : Value(specialization),
      vatBin: vatBin == null && nullToAbsent
          ? const Value.absent()
          : Value(vatBin),
      studioAddress: studioAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(studioAddress),
      whatsapp: whatsapp == null && nullToAbsent
          ? const Value.absent()
          : Value(whatsapp),
      bkash: bkash == null && nullToAbsent
          ? const Value.absent()
          : Value(bkash),
      bankDetails: bankDetails == null && nullToAbsent
          ? const Value.absent()
          : Value(bankDetails),
      signatureUrl: signatureUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(signatureUrl),
      logoUrl: logoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(logoUrl),
      companyName: companyName == null && nullToAbsent
          ? const Value.absent()
          : Value(companyName),
      totalEvents: Value(totalEvents),
      totalRevenueMinor: Value(totalRevenueMinor),
      totalClients: Value(totalClients),
      statsRefreshedAt: statsRefreshedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(statsRefreshedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      pending: Value(pending),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      isCurrent: Value(isCurrent),
    );
  }

  factory UserRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRow(
      id: serializer.fromJson<String>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      phone: serializer.fromJson<String?>(json['phone']),
      role: serializer.fromJson<String>(json['role']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      bio: serializer.fromJson<String?>(json['bio']),
      specialization: serializer.fromJson<String?>(json['specialization']),
      vatBin: serializer.fromJson<String?>(json['vatBin']),
      studioAddress: serializer.fromJson<String?>(json['studioAddress']),
      whatsapp: serializer.fromJson<String?>(json['whatsapp']),
      bkash: serializer.fromJson<String?>(json['bkash']),
      bankDetails: serializer.fromJson<String?>(json['bankDetails']),
      signatureUrl: serializer.fromJson<String?>(json['signatureUrl']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
      companyName: serializer.fromJson<String?>(json['companyName']),
      totalEvents: serializer.fromJson<int>(json['totalEvents']),
      totalRevenueMinor: serializer.fromJson<int>(json['totalRevenueMinor']),
      totalClients: serializer.fromJson<int>(json['totalClients']),
      statsRefreshedAt: serializer.fromJson<DateTime?>(
        json['statsRefreshedAt'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pending: serializer.fromJson<bool>(json['pending']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      isCurrent: serializer.fromJson<bool>(json['isCurrent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'phone': serializer.toJson<String?>(phone),
      'role': serializer.toJson<String>(role),
      'ownerId': serializer.toJson<String?>(ownerId),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'bio': serializer.toJson<String?>(bio),
      'specialization': serializer.toJson<String?>(specialization),
      'vatBin': serializer.toJson<String?>(vatBin),
      'studioAddress': serializer.toJson<String?>(studioAddress),
      'whatsapp': serializer.toJson<String?>(whatsapp),
      'bkash': serializer.toJson<String?>(bkash),
      'bankDetails': serializer.toJson<String?>(bankDetails),
      'signatureUrl': serializer.toJson<String?>(signatureUrl),
      'logoUrl': serializer.toJson<String?>(logoUrl),
      'companyName': serializer.toJson<String?>(companyName),
      'totalEvents': serializer.toJson<int>(totalEvents),
      'totalRevenueMinor': serializer.toJson<int>(totalRevenueMinor),
      'totalClients': serializer.toJson<int>(totalClients),
      'statsRefreshedAt': serializer.toJson<DateTime?>(statsRefreshedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pending': serializer.toJson<bool>(pending),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'isCurrent': serializer.toJson<bool>(isCurrent),
    };
  }

  UserRow copyWith({
    String? id,
    Value<String?> remoteId = const Value.absent(),
    String? name,
    String? email,
    Value<String?> phone = const Value.absent(),
    String? role,
    Value<String?> ownerId = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    Value<String?> bio = const Value.absent(),
    Value<String?> specialization = const Value.absent(),
    Value<String?> vatBin = const Value.absent(),
    Value<String?> studioAddress = const Value.absent(),
    Value<String?> whatsapp = const Value.absent(),
    Value<String?> bkash = const Value.absent(),
    Value<String?> bankDetails = const Value.absent(),
    Value<String?> signatureUrl = const Value.absent(),
    Value<String?> logoUrl = const Value.absent(),
    Value<String?> companyName = const Value.absent(),
    int? totalEvents,
    int? totalRevenueMinor,
    int? totalClients,
    Value<DateTime?> statsRefreshedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pending,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? isCurrent,
  }) => UserRow(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone.present ? phone.value : this.phone,
    role: role ?? this.role,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    bio: bio.present ? bio.value : this.bio,
    specialization: specialization.present
        ? specialization.value
        : this.specialization,
    vatBin: vatBin.present ? vatBin.value : this.vatBin,
    studioAddress: studioAddress.present
        ? studioAddress.value
        : this.studioAddress,
    whatsapp: whatsapp.present ? whatsapp.value : this.whatsapp,
    bkash: bkash.present ? bkash.value : this.bkash,
    bankDetails: bankDetails.present ? bankDetails.value : this.bankDetails,
    signatureUrl: signatureUrl.present ? signatureUrl.value : this.signatureUrl,
    logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
    companyName: companyName.present ? companyName.value : this.companyName,
    totalEvents: totalEvents ?? this.totalEvents,
    totalRevenueMinor: totalRevenueMinor ?? this.totalRevenueMinor,
    totalClients: totalClients ?? this.totalClients,
    statsRefreshedAt: statsRefreshedAt.present
        ? statsRefreshedAt.value
        : this.statsRefreshedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pending: pending ?? this.pending,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    isCurrent: isCurrent ?? this.isCurrent,
  );
  UserRow copyWithCompanion(UsersTableCompanion data) {
    return UserRow(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      role: data.role.present ? data.role.value : this.role,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      bio: data.bio.present ? data.bio.value : this.bio,
      specialization: data.specialization.present
          ? data.specialization.value
          : this.specialization,
      vatBin: data.vatBin.present ? data.vatBin.value : this.vatBin,
      studioAddress: data.studioAddress.present
          ? data.studioAddress.value
          : this.studioAddress,
      whatsapp: data.whatsapp.present ? data.whatsapp.value : this.whatsapp,
      bkash: data.bkash.present ? data.bkash.value : this.bkash,
      bankDetails: data.bankDetails.present
          ? data.bankDetails.value
          : this.bankDetails,
      signatureUrl: data.signatureUrl.present
          ? data.signatureUrl.value
          : this.signatureUrl,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      companyName: data.companyName.present
          ? data.companyName.value
          : this.companyName,
      totalEvents: data.totalEvents.present
          ? data.totalEvents.value
          : this.totalEvents,
      totalRevenueMinor: data.totalRevenueMinor.present
          ? data.totalRevenueMinor.value
          : this.totalRevenueMinor,
      totalClients: data.totalClients.present
          ? data.totalClients.value
          : this.totalClients,
      statsRefreshedAt: data.statsRefreshedAt.present
          ? data.statsRefreshedAt.value
          : this.statsRefreshedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pending: data.pending.present ? data.pending.value : this.pending,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRow(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('role: $role, ')
          ..write('ownerId: $ownerId, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('bio: $bio, ')
          ..write('specialization: $specialization, ')
          ..write('vatBin: $vatBin, ')
          ..write('studioAddress: $studioAddress, ')
          ..write('whatsapp: $whatsapp, ')
          ..write('bkash: $bkash, ')
          ..write('bankDetails: $bankDetails, ')
          ..write('signatureUrl: $signatureUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('companyName: $companyName, ')
          ..write('totalEvents: $totalEvents, ')
          ..write('totalRevenueMinor: $totalRevenueMinor, ')
          ..write('totalClients: $totalClients, ')
          ..write('statsRefreshedAt: $statsRefreshedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isCurrent: $isCurrent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    remoteId,
    name,
    email,
    phone,
    role,
    ownerId,
    avatarUrl,
    bio,
    specialization,
    vatBin,
    studioAddress,
    whatsapp,
    bkash,
    bankDetails,
    signatureUrl,
    logoUrl,
    companyName,
    totalEvents,
    totalRevenueMinor,
    totalClients,
    statsRefreshedAt,
    createdAt,
    updatedAt,
    pending,
    deletedAt,
    isCurrent,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.role == this.role &&
          other.ownerId == this.ownerId &&
          other.avatarUrl == this.avatarUrl &&
          other.bio == this.bio &&
          other.specialization == this.specialization &&
          other.vatBin == this.vatBin &&
          other.studioAddress == this.studioAddress &&
          other.whatsapp == this.whatsapp &&
          other.bkash == this.bkash &&
          other.bankDetails == this.bankDetails &&
          other.signatureUrl == this.signatureUrl &&
          other.logoUrl == this.logoUrl &&
          other.companyName == this.companyName &&
          other.totalEvents == this.totalEvents &&
          other.totalRevenueMinor == this.totalRevenueMinor &&
          other.totalClients == this.totalClients &&
          other.statsRefreshedAt == this.statsRefreshedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.pending == this.pending &&
          other.deletedAt == this.deletedAt &&
          other.isCurrent == this.isCurrent);
}

class UsersTableCompanion extends UpdateCompanion<UserRow> {
  final Value<String> id;
  final Value<String?> remoteId;
  final Value<String> name;
  final Value<String> email;
  final Value<String?> phone;
  final Value<String> role;
  final Value<String?> ownerId;
  final Value<String?> avatarUrl;
  final Value<String?> bio;
  final Value<String?> specialization;
  final Value<String?> vatBin;
  final Value<String?> studioAddress;
  final Value<String?> whatsapp;
  final Value<String?> bkash;
  final Value<String?> bankDetails;
  final Value<String?> signatureUrl;
  final Value<String?> logoUrl;
  final Value<String?> companyName;
  final Value<int> totalEvents;
  final Value<int> totalRevenueMinor;
  final Value<int> totalClients;
  final Value<DateTime?> statsRefreshedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pending;
  final Value<DateTime?> deletedAt;
  final Value<bool> isCurrent;
  final Value<int> rowid;
  const UsersTableCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.role = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.bio = const Value.absent(),
    this.specialization = const Value.absent(),
    this.vatBin = const Value.absent(),
    this.studioAddress = const Value.absent(),
    this.whatsapp = const Value.absent(),
    this.bkash = const Value.absent(),
    this.bankDetails = const Value.absent(),
    this.signatureUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.companyName = const Value.absent(),
    this.totalEvents = const Value.absent(),
    this.totalRevenueMinor = const Value.absent(),
    this.totalClients = const Value.absent(),
    this.statsRefreshedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersTableCompanion.insert({
    required String id,
    this.remoteId = const Value.absent(),
    required String name,
    required String email,
    this.phone = const Value.absent(),
    required String role,
    this.ownerId = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.bio = const Value.absent(),
    this.specialization = const Value.absent(),
    this.vatBin = const Value.absent(),
    this.studioAddress = const Value.absent(),
    this.whatsapp = const Value.absent(),
    this.bkash = const Value.absent(),
    this.bankDetails = const Value.absent(),
    this.signatureUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.companyName = const Value.absent(),
    this.totalEvents = const Value.absent(),
    this.totalRevenueMinor = const Value.absent(),
    this.totalClients = const Value.absent(),
    this.statsRefreshedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       email = Value(email),
       role = Value(role);
  static Insertable<UserRow> custom({
    Expression<String>? id,
    Expression<String>? remoteId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? role,
    Expression<String>? ownerId,
    Expression<String>? avatarUrl,
    Expression<String>? bio,
    Expression<String>? specialization,
    Expression<String>? vatBin,
    Expression<String>? studioAddress,
    Expression<String>? whatsapp,
    Expression<String>? bkash,
    Expression<String>? bankDetails,
    Expression<String>? signatureUrl,
    Expression<String>? logoUrl,
    Expression<String>? companyName,
    Expression<int>? totalEvents,
    Expression<int>? totalRevenueMinor,
    Expression<int>? totalClients,
    Expression<DateTime>? statsRefreshedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pending,
    Expression<DateTime>? deletedAt,
    Expression<bool>? isCurrent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role,
      if (ownerId != null) 'owner_id': ownerId,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (bio != null) 'bio': bio,
      if (specialization != null) 'specialization': specialization,
      if (vatBin != null) 'vat_bin': vatBin,
      if (studioAddress != null) 'studio_address': studioAddress,
      if (whatsapp != null) 'whatsapp': whatsapp,
      if (bkash != null) 'bkash': bkash,
      if (bankDetails != null) 'bank_details': bankDetails,
      if (signatureUrl != null) 'signature_url': signatureUrl,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (companyName != null) 'company_name': companyName,
      if (totalEvents != null) 'total_events': totalEvents,
      if (totalRevenueMinor != null) 'total_revenue_minor': totalRevenueMinor,
      if (totalClients != null) 'total_clients': totalClients,
      if (statsRefreshedAt != null) 'stats_refreshed_at': statsRefreshedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pending != null) 'pending': pending,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (isCurrent != null) 'is_current': isCurrent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? remoteId,
    Value<String>? name,
    Value<String>? email,
    Value<String?>? phone,
    Value<String>? role,
    Value<String?>? ownerId,
    Value<String?>? avatarUrl,
    Value<String?>? bio,
    Value<String?>? specialization,
    Value<String?>? vatBin,
    Value<String?>? studioAddress,
    Value<String?>? whatsapp,
    Value<String?>? bkash,
    Value<String?>? bankDetails,
    Value<String?>? signatureUrl,
    Value<String?>? logoUrl,
    Value<String?>? companyName,
    Value<int>? totalEvents,
    Value<int>? totalRevenueMinor,
    Value<int>? totalClients,
    Value<DateTime?>? statsRefreshedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pending,
    Value<DateTime?>? deletedAt,
    Value<bool>? isCurrent,
    Value<int>? rowid,
  }) {
    return UsersTableCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      ownerId: ownerId ?? this.ownerId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      specialization: specialization ?? this.specialization,
      vatBin: vatBin ?? this.vatBin,
      studioAddress: studioAddress ?? this.studioAddress,
      whatsapp: whatsapp ?? this.whatsapp,
      bkash: bkash ?? this.bkash,
      bankDetails: bankDetails ?? this.bankDetails,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      companyName: companyName ?? this.companyName,
      totalEvents: totalEvents ?? this.totalEvents,
      totalRevenueMinor: totalRevenueMinor ?? this.totalRevenueMinor,
      totalClients: totalClients ?? this.totalClients,
      statsRefreshedAt: statsRefreshedAt ?? this.statsRefreshedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
      deletedAt: deletedAt ?? this.deletedAt,
      isCurrent: isCurrent ?? this.isCurrent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (specialization.present) {
      map['specialization'] = Variable<String>(specialization.value);
    }
    if (vatBin.present) {
      map['vat_bin'] = Variable<String>(vatBin.value);
    }
    if (studioAddress.present) {
      map['studio_address'] = Variable<String>(studioAddress.value);
    }
    if (whatsapp.present) {
      map['whatsapp'] = Variable<String>(whatsapp.value);
    }
    if (bkash.present) {
      map['bkash'] = Variable<String>(bkash.value);
    }
    if (bankDetails.present) {
      map['bank_details'] = Variable<String>(bankDetails.value);
    }
    if (signatureUrl.present) {
      map['signature_url'] = Variable<String>(signatureUrl.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (totalEvents.present) {
      map['total_events'] = Variable<int>(totalEvents.value);
    }
    if (totalRevenueMinor.present) {
      map['total_revenue_minor'] = Variable<int>(totalRevenueMinor.value);
    }
    if (totalClients.present) {
      map['total_clients'] = Variable<int>(totalClients.value);
    }
    if (statsRefreshedAt.present) {
      map['stats_refreshed_at'] = Variable<DateTime>(statsRefreshedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<bool>(isCurrent.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersTableCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('role: $role, ')
          ..write('ownerId: $ownerId, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('bio: $bio, ')
          ..write('specialization: $specialization, ')
          ..write('vatBin: $vatBin, ')
          ..write('studioAddress: $studioAddress, ')
          ..write('whatsapp: $whatsapp, ')
          ..write('bkash: $bkash, ')
          ..write('bankDetails: $bankDetails, ')
          ..write('signatureUrl: $signatureUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('companyName: $companyName, ')
          ..write('totalEvents: $totalEvents, ')
          ..write('totalRevenueMinor: $totalRevenueMinor, ')
          ..write('totalClients: $totalClients, ')
          ..write('statsRefreshedAt: $statsRefreshedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserPreferencesTableTable extends UserPreferencesTable
    with TableInfo<$UserPreferencesTableTable, UserPreferencesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPreferencesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en'),
  );
  static const VerificationMeta _distributionEnabledMeta =
      const VerificationMeta('distributionEnabled');
  @override
  late final GeneratedColumn<bool> distributionEnabled = GeneratedColumn<bool>(
    'distribution_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("distribution_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _vatEnabledMeta = const VerificationMeta(
    'vatEnabled',
  );
  @override
  late final GeneratedColumn<bool> vatEnabled = GeneratedColumn<bool>(
    'vat_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("vat_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bengaliNumeralsMeta = const VerificationMeta(
    'bengaliNumerals',
  );
  @override
  late final GeneratedColumn<bool> bengaliNumerals = GeneratedColumn<bool>(
    'bengali_numerals',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("bengali_numerals" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    language,
    distributionEnabled,
    vatEnabled,
    bengaliNumerals,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_preferences_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPreferencesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('distribution_enabled')) {
      context.handle(
        _distributionEnabledMeta,
        distributionEnabled.isAcceptableOrUnknown(
          data['distribution_enabled']!,
          _distributionEnabledMeta,
        ),
      );
    }
    if (data.containsKey('vat_enabled')) {
      context.handle(
        _vatEnabledMeta,
        vatEnabled.isAcceptableOrUnknown(data['vat_enabled']!, _vatEnabledMeta),
      );
    }
    if (data.containsKey('bengali_numerals')) {
      context.handle(
        _bengaliNumeralsMeta,
        bengaliNumerals.isAcceptableOrUnknown(
          data['bengali_numerals']!,
          _bengaliNumeralsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  UserPreferencesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPreferencesRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      distributionEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}distribution_enabled'],
      )!,
      vatEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}vat_enabled'],
      )!,
      bengaliNumerals: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}bengali_numerals'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserPreferencesTableTable createAlias(String alias) {
    return $UserPreferencesTableTable(attachedDatabase, alias);
  }
}

class UserPreferencesRow extends DataClass
    implements Insertable<UserPreferencesRow> {
  final String userId;
  final String language;
  final bool distributionEnabled;
  final bool vatEnabled;
  final bool bengaliNumerals;
  final DateTime updatedAt;
  const UserPreferencesRow({
    required this.userId,
    required this.language,
    required this.distributionEnabled,
    required this.vatEnabled,
    required this.bengaliNumerals,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['language'] = Variable<String>(language);
    map['distribution_enabled'] = Variable<bool>(distributionEnabled);
    map['vat_enabled'] = Variable<bool>(vatEnabled);
    map['bengali_numerals'] = Variable<bool>(bengaliNumerals);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserPreferencesTableCompanion toCompanion(bool nullToAbsent) {
    return UserPreferencesTableCompanion(
      userId: Value(userId),
      language: Value(language),
      distributionEnabled: Value(distributionEnabled),
      vatEnabled: Value(vatEnabled),
      bengaliNumerals: Value(bengaliNumerals),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserPreferencesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPreferencesRow(
      userId: serializer.fromJson<String>(json['userId']),
      language: serializer.fromJson<String>(json['language']),
      distributionEnabled: serializer.fromJson<bool>(
        json['distributionEnabled'],
      ),
      vatEnabled: serializer.fromJson<bool>(json['vatEnabled']),
      bengaliNumerals: serializer.fromJson<bool>(json['bengaliNumerals']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'language': serializer.toJson<String>(language),
      'distributionEnabled': serializer.toJson<bool>(distributionEnabled),
      'vatEnabled': serializer.toJson<bool>(vatEnabled),
      'bengaliNumerals': serializer.toJson<bool>(bengaliNumerals),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserPreferencesRow copyWith({
    String? userId,
    String? language,
    bool? distributionEnabled,
    bool? vatEnabled,
    bool? bengaliNumerals,
    DateTime? updatedAt,
  }) => UserPreferencesRow(
    userId: userId ?? this.userId,
    language: language ?? this.language,
    distributionEnabled: distributionEnabled ?? this.distributionEnabled,
    vatEnabled: vatEnabled ?? this.vatEnabled,
    bengaliNumerals: bengaliNumerals ?? this.bengaliNumerals,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserPreferencesRow copyWithCompanion(UserPreferencesTableCompanion data) {
    return UserPreferencesRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      language: data.language.present ? data.language.value : this.language,
      distributionEnabled: data.distributionEnabled.present
          ? data.distributionEnabled.value
          : this.distributionEnabled,
      vatEnabled: data.vatEnabled.present
          ? data.vatEnabled.value
          : this.vatEnabled,
      bengaliNumerals: data.bengaliNumerals.present
          ? data.bengaliNumerals.value
          : this.bengaliNumerals,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesRow(')
          ..write('userId: $userId, ')
          ..write('language: $language, ')
          ..write('distributionEnabled: $distributionEnabled, ')
          ..write('vatEnabled: $vatEnabled, ')
          ..write('bengaliNumerals: $bengaliNumerals, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    language,
    distributionEnabled,
    vatEnabled,
    bengaliNumerals,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreferencesRow &&
          other.userId == this.userId &&
          other.language == this.language &&
          other.distributionEnabled == this.distributionEnabled &&
          other.vatEnabled == this.vatEnabled &&
          other.bengaliNumerals == this.bengaliNumerals &&
          other.updatedAt == this.updatedAt);
}

class UserPreferencesTableCompanion
    extends UpdateCompanion<UserPreferencesRow> {
  final Value<String> userId;
  final Value<String> language;
  final Value<bool> distributionEnabled;
  final Value<bool> vatEnabled;
  final Value<bool> bengaliNumerals;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserPreferencesTableCompanion({
    this.userId = const Value.absent(),
    this.language = const Value.absent(),
    this.distributionEnabled = const Value.absent(),
    this.vatEnabled = const Value.absent(),
    this.bengaliNumerals = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserPreferencesTableCompanion.insert({
    required String userId,
    this.language = const Value.absent(),
    this.distributionEnabled = const Value.absent(),
    this.vatEnabled = const Value.absent(),
    this.bengaliNumerals = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<UserPreferencesRow> custom({
    Expression<String>? userId,
    Expression<String>? language,
    Expression<bool>? distributionEnabled,
    Expression<bool>? vatEnabled,
    Expression<bool>? bengaliNumerals,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (language != null) 'language': language,
      if (distributionEnabled != null)
        'distribution_enabled': distributionEnabled,
      if (vatEnabled != null) 'vat_enabled': vatEnabled,
      if (bengaliNumerals != null) 'bengali_numerals': bengaliNumerals,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserPreferencesTableCompanion copyWith({
    Value<String>? userId,
    Value<String>? language,
    Value<bool>? distributionEnabled,
    Value<bool>? vatEnabled,
    Value<bool>? bengaliNumerals,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserPreferencesTableCompanion(
      userId: userId ?? this.userId,
      language: language ?? this.language,
      distributionEnabled: distributionEnabled ?? this.distributionEnabled,
      vatEnabled: vatEnabled ?? this.vatEnabled,
      bengaliNumerals: bengaliNumerals ?? this.bengaliNumerals,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (distributionEnabled.present) {
      map['distribution_enabled'] = Variable<bool>(distributionEnabled.value);
    }
    if (vatEnabled.present) {
      map['vat_enabled'] = Variable<bool>(vatEnabled.value);
    }
    if (bengaliNumerals.present) {
      map['bengali_numerals'] = Variable<bool>(bengaliNumerals.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesTableCompanion(')
          ..write('userId: $userId, ')
          ..write('language: $language, ')
          ..write('distributionEnabled: $distributionEnabled, ')
          ..write('vatEnabled: $vatEnabled, ')
          ..write('bengaliNumerals: $bengaliNumerals, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationPreferencesTableTable extends NotificationPreferencesTable
    with
        TableInfo<
          $NotificationPreferencesTableTable,
          NotificationPreferencesRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationPreferencesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventRemindersMeta = const VerificationMeta(
    'eventReminders',
  );
  @override
  late final GeneratedColumn<bool> eventReminders = GeneratedColumn<bool>(
    'event_reminders',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("event_reminders" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _paymentDueMeta = const VerificationMeta(
    'paymentDue',
  );
  @override
  late final GeneratedColumn<bool> paymentDue = GeneratedColumn<bool>(
    'payment_due',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("payment_due" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _teamMessagesMeta = const VerificationMeta(
    'teamMessages',
  );
  @override
  late final GeneratedColumn<bool> teamMessages = GeneratedColumn<bool>(
    'team_messages',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("team_messages" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _announcementsMeta = const VerificationMeta(
    'announcements',
  );
  @override
  late final GeneratedColumn<bool> announcements = GeneratedColumn<bool>(
    'announcements',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("announcements" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _marketingMeta = const VerificationMeta(
    'marketing',
  );
  @override
  late final GeneratedColumn<bool> marketing = GeneratedColumn<bool>(
    'marketing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("marketing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    eventReminders,
    paymentDue,
    teamMessages,
    announcements,
    marketing,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_preferences_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationPreferencesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('event_reminders')) {
      context.handle(
        _eventRemindersMeta,
        eventReminders.isAcceptableOrUnknown(
          data['event_reminders']!,
          _eventRemindersMeta,
        ),
      );
    }
    if (data.containsKey('payment_due')) {
      context.handle(
        _paymentDueMeta,
        paymentDue.isAcceptableOrUnknown(data['payment_due']!, _paymentDueMeta),
      );
    }
    if (data.containsKey('team_messages')) {
      context.handle(
        _teamMessagesMeta,
        teamMessages.isAcceptableOrUnknown(
          data['team_messages']!,
          _teamMessagesMeta,
        ),
      );
    }
    if (data.containsKey('announcements')) {
      context.handle(
        _announcementsMeta,
        announcements.isAcceptableOrUnknown(
          data['announcements']!,
          _announcementsMeta,
        ),
      );
    }
    if (data.containsKey('marketing')) {
      context.handle(
        _marketingMeta,
        marketing.isAcceptableOrUnknown(data['marketing']!, _marketingMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  NotificationPreferencesRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationPreferencesRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      eventReminders: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}event_reminders'],
      )!,
      paymentDue: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}payment_due'],
      )!,
      teamMessages: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}team_messages'],
      )!,
      announcements: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}announcements'],
      )!,
      marketing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}marketing'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NotificationPreferencesTableTable createAlias(String alias) {
    return $NotificationPreferencesTableTable(attachedDatabase, alias);
  }
}

class NotificationPreferencesRow extends DataClass
    implements Insertable<NotificationPreferencesRow> {
  final String userId;
  final bool eventReminders;
  final bool paymentDue;
  final bool teamMessages;
  final bool announcements;
  final bool marketing;
  final DateTime updatedAt;
  const NotificationPreferencesRow({
    required this.userId,
    required this.eventReminders,
    required this.paymentDue,
    required this.teamMessages,
    required this.announcements,
    required this.marketing,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['event_reminders'] = Variable<bool>(eventReminders);
    map['payment_due'] = Variable<bool>(paymentDue);
    map['team_messages'] = Variable<bool>(teamMessages);
    map['announcements'] = Variable<bool>(announcements);
    map['marketing'] = Variable<bool>(marketing);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NotificationPreferencesTableCompanion toCompanion(bool nullToAbsent) {
    return NotificationPreferencesTableCompanion(
      userId: Value(userId),
      eventReminders: Value(eventReminders),
      paymentDue: Value(paymentDue),
      teamMessages: Value(teamMessages),
      announcements: Value(announcements),
      marketing: Value(marketing),
      updatedAt: Value(updatedAt),
    );
  }

  factory NotificationPreferencesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationPreferencesRow(
      userId: serializer.fromJson<String>(json['userId']),
      eventReminders: serializer.fromJson<bool>(json['eventReminders']),
      paymentDue: serializer.fromJson<bool>(json['paymentDue']),
      teamMessages: serializer.fromJson<bool>(json['teamMessages']),
      announcements: serializer.fromJson<bool>(json['announcements']),
      marketing: serializer.fromJson<bool>(json['marketing']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'eventReminders': serializer.toJson<bool>(eventReminders),
      'paymentDue': serializer.toJson<bool>(paymentDue),
      'teamMessages': serializer.toJson<bool>(teamMessages),
      'announcements': serializer.toJson<bool>(announcements),
      'marketing': serializer.toJson<bool>(marketing),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  NotificationPreferencesRow copyWith({
    String? userId,
    bool? eventReminders,
    bool? paymentDue,
    bool? teamMessages,
    bool? announcements,
    bool? marketing,
    DateTime? updatedAt,
  }) => NotificationPreferencesRow(
    userId: userId ?? this.userId,
    eventReminders: eventReminders ?? this.eventReminders,
    paymentDue: paymentDue ?? this.paymentDue,
    teamMessages: teamMessages ?? this.teamMessages,
    announcements: announcements ?? this.announcements,
    marketing: marketing ?? this.marketing,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NotificationPreferencesRow copyWithCompanion(
    NotificationPreferencesTableCompanion data,
  ) {
    return NotificationPreferencesRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      eventReminders: data.eventReminders.present
          ? data.eventReminders.value
          : this.eventReminders,
      paymentDue: data.paymentDue.present
          ? data.paymentDue.value
          : this.paymentDue,
      teamMessages: data.teamMessages.present
          ? data.teamMessages.value
          : this.teamMessages,
      announcements: data.announcements.present
          ? data.announcements.value
          : this.announcements,
      marketing: data.marketing.present ? data.marketing.value : this.marketing,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationPreferencesRow(')
          ..write('userId: $userId, ')
          ..write('eventReminders: $eventReminders, ')
          ..write('paymentDue: $paymentDue, ')
          ..write('teamMessages: $teamMessages, ')
          ..write('announcements: $announcements, ')
          ..write('marketing: $marketing, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    eventReminders,
    paymentDue,
    teamMessages,
    announcements,
    marketing,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationPreferencesRow &&
          other.userId == this.userId &&
          other.eventReminders == this.eventReminders &&
          other.paymentDue == this.paymentDue &&
          other.teamMessages == this.teamMessages &&
          other.announcements == this.announcements &&
          other.marketing == this.marketing &&
          other.updatedAt == this.updatedAt);
}

class NotificationPreferencesTableCompanion
    extends UpdateCompanion<NotificationPreferencesRow> {
  final Value<String> userId;
  final Value<bool> eventReminders;
  final Value<bool> paymentDue;
  final Value<bool> teamMessages;
  final Value<bool> announcements;
  final Value<bool> marketing;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const NotificationPreferencesTableCompanion({
    this.userId = const Value.absent(),
    this.eventReminders = const Value.absent(),
    this.paymentDue = const Value.absent(),
    this.teamMessages = const Value.absent(),
    this.announcements = const Value.absent(),
    this.marketing = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationPreferencesTableCompanion.insert({
    required String userId,
    this.eventReminders = const Value.absent(),
    this.paymentDue = const Value.absent(),
    this.teamMessages = const Value.absent(),
    this.announcements = const Value.absent(),
    this.marketing = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<NotificationPreferencesRow> custom({
    Expression<String>? userId,
    Expression<bool>? eventReminders,
    Expression<bool>? paymentDue,
    Expression<bool>? teamMessages,
    Expression<bool>? announcements,
    Expression<bool>? marketing,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (eventReminders != null) 'event_reminders': eventReminders,
      if (paymentDue != null) 'payment_due': paymentDue,
      if (teamMessages != null) 'team_messages': teamMessages,
      if (announcements != null) 'announcements': announcements,
      if (marketing != null) 'marketing': marketing,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationPreferencesTableCompanion copyWith({
    Value<String>? userId,
    Value<bool>? eventReminders,
    Value<bool>? paymentDue,
    Value<bool>? teamMessages,
    Value<bool>? announcements,
    Value<bool>? marketing,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return NotificationPreferencesTableCompanion(
      userId: userId ?? this.userId,
      eventReminders: eventReminders ?? this.eventReminders,
      paymentDue: paymentDue ?? this.paymentDue,
      teamMessages: teamMessages ?? this.teamMessages,
      announcements: announcements ?? this.announcements,
      marketing: marketing ?? this.marketing,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (eventReminders.present) {
      map['event_reminders'] = Variable<bool>(eventReminders.value);
    }
    if (paymentDue.present) {
      map['payment_due'] = Variable<bool>(paymentDue.value);
    }
    if (teamMessages.present) {
      map['team_messages'] = Variable<bool>(teamMessages.value);
    }
    if (announcements.present) {
      map['announcements'] = Variable<bool>(announcements.value);
    }
    if (marketing.present) {
      map['marketing'] = Variable<bool>(marketing.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationPreferencesTableCompanion(')
          ..write('userId: $userId, ')
          ..write('eventReminders: $eventReminders, ')
          ..write('paymentDue: $paymentDue, ')
          ..write('teamMessages: $teamMessages, ')
          ..write('announcements: $announcements, ')
          ..write('marketing: $marketing, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GearItemsTableTable extends GearItemsTable
    with TableInfo<$GearItemsTableTable, GearItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GearItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    userId,
    name,
    brand,
    addedAt,
    pending,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gear_items_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<GearItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GearItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GearItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $GearItemsTableTable createAlias(String alias) {
    return $GearItemsTableTable(attachedDatabase, alias);
  }
}

class GearItemRow extends DataClass implements Insertable<GearItemRow> {
  final String id;
  final String? remoteId;
  final String userId;
  final String name;
  final String? brand;
  final DateTime addedAt;
  final bool pending;
  final bool deleted;
  const GearItemRow({
    required this.id,
    this.remoteId,
    required this.userId,
    required this.name,
    this.brand,
    required this.addedAt,
    required this.pending,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    map['pending'] = Variable<bool>(pending);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  GearItemsTableCompanion toCompanion(bool nullToAbsent) {
    return GearItemsTableCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      userId: Value(userId),
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      addedAt: Value(addedAt),
      pending: Value(pending),
      deleted: Value(deleted),
    );
  }

  factory GearItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GearItemRow(
      id: serializer.fromJson<String>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      pending: serializer.fromJson<bool>(json['pending']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'pending': serializer.toJson<bool>(pending),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  GearItemRow copyWith({
    String? id,
    Value<String?> remoteId = const Value.absent(),
    String? userId,
    String? name,
    Value<String?> brand = const Value.absent(),
    DateTime? addedAt,
    bool? pending,
    bool? deleted,
  }) => GearItemRow(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
    addedAt: addedAt ?? this.addedAt,
    pending: pending ?? this.pending,
    deleted: deleted ?? this.deleted,
  );
  GearItemRow copyWithCompanion(GearItemsTableCompanion data) {
    return GearItemRow(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      pending: data.pending.present ? data.pending.value : this.pending,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GearItemRow(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('addedAt: $addedAt, ')
          ..write('pending: $pending, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, remoteId, userId, name, brand, addedAt, pending, deleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GearItemRow &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.addedAt == this.addedAt &&
          other.pending == this.pending &&
          other.deleted == this.deleted);
}

class GearItemsTableCompanion extends UpdateCompanion<GearItemRow> {
  final Value<String> id;
  final Value<String?> remoteId;
  final Value<String> userId;
  final Value<String> name;
  final Value<String?> brand;
  final Value<DateTime> addedAt;
  final Value<bool> pending;
  final Value<bool> deleted;
  final Value<int> rowid;
  const GearItemsTableCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GearItemsTableCompanion.insert({
    required String id,
    this.remoteId = const Value.absent(),
    required String userId,
    required String name,
    this.brand = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name);
  static Insertable<GearItemRow> custom({
    Expression<String>? id,
    Expression<String>? remoteId,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<DateTime>? addedAt,
    Expression<bool>? pending,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (addedAt != null) 'added_at': addedAt,
      if (pending != null) 'pending': pending,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GearItemsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? remoteId,
    Value<String>? userId,
    Value<String>? name,
    Value<String?>? brand,
    Value<DateTime>? addedAt,
    Value<bool>? pending,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return GearItemsTableCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      addedAt: addedAt ?? this.addedAt,
      pending: pending ?? this.pending,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GearItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('addedAt: $addedAt, ')
          ..write('pending: $pending, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamInvitesTableTable extends TeamInvitesTable
    with TableInfo<$TeamInvitesTableTable, TeamInviteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamInvitesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consumedAtMeta = const VerificationMeta(
    'consumedAt',
  );
  @override
  late final GeneratedColumn<DateTime> consumedAt = GeneratedColumn<DateTime>(
    'consumed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    code,
    ownerId,
    role,
    createdAt,
    expiresAt,
    consumedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'team_invites_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeamInviteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('consumed_at')) {
      context.handle(
        _consumedAtMeta,
        consumedAt.isAcceptableOrUnknown(data['consumed_at']!, _consumedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  TeamInviteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeamInviteRow(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      consumedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}consumed_at'],
      ),
    );
  }

  @override
  $TeamInvitesTableTable createAlias(String alias) {
    return $TeamInvitesTableTable(attachedDatabase, alias);
  }
}

class TeamInviteRow extends DataClass implements Insertable<TeamInviteRow> {
  final String code;
  final String ownerId;
  final String role;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? consumedAt;
  const TeamInviteRow({
    required this.code,
    required this.ownerId,
    required this.role,
    required this.createdAt,
    required this.expiresAt,
    this.consumedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['owner_id'] = Variable<String>(ownerId);
    map['role'] = Variable<String>(role);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    if (!nullToAbsent || consumedAt != null) {
      map['consumed_at'] = Variable<DateTime>(consumedAt);
    }
    return map;
  }

  TeamInvitesTableCompanion toCompanion(bool nullToAbsent) {
    return TeamInvitesTableCompanion(
      code: Value(code),
      ownerId: Value(ownerId),
      role: Value(role),
      createdAt: Value(createdAt),
      expiresAt: Value(expiresAt),
      consumedAt: consumedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(consumedAt),
    );
  }

  factory TeamInviteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeamInviteRow(
      code: serializer.fromJson<String>(json['code']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      role: serializer.fromJson<String>(json['role']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      consumedAt: serializer.fromJson<DateTime?>(json['consumedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'ownerId': serializer.toJson<String>(ownerId),
      'role': serializer.toJson<String>(role),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'consumedAt': serializer.toJson<DateTime?>(consumedAt),
    };
  }

  TeamInviteRow copyWith({
    String? code,
    String? ownerId,
    String? role,
    DateTime? createdAt,
    DateTime? expiresAt,
    Value<DateTime?> consumedAt = const Value.absent(),
  }) => TeamInviteRow(
    code: code ?? this.code,
    ownerId: ownerId ?? this.ownerId,
    role: role ?? this.role,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    consumedAt: consumedAt.present ? consumedAt.value : this.consumedAt,
  );
  TeamInviteRow copyWithCompanion(TeamInvitesTableCompanion data) {
    return TeamInviteRow(
      code: data.code.present ? data.code.value : this.code,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      role: data.role.present ? data.role.value : this.role,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      consumedAt: data.consumedAt.present
          ? data.consumedAt.value
          : this.consumedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeamInviteRow(')
          ..write('code: $code, ')
          ..write('ownerId: $ownerId, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('consumedAt: $consumedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(code, ownerId, role, createdAt, expiresAt, consumedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeamInviteRow &&
          other.code == this.code &&
          other.ownerId == this.ownerId &&
          other.role == this.role &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt &&
          other.consumedAt == this.consumedAt);
}

class TeamInvitesTableCompanion extends UpdateCompanion<TeamInviteRow> {
  final Value<String> code;
  final Value<String> ownerId;
  final Value<String> role;
  final Value<DateTime> createdAt;
  final Value<DateTime> expiresAt;
  final Value<DateTime?> consumedAt;
  final Value<int> rowid;
  const TeamInvitesTableCompanion({
    this.code = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.role = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.consumedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamInvitesTableCompanion.insert({
    required String code,
    required String ownerId,
    required String role,
    required DateTime createdAt,
    required DateTime expiresAt,
    this.consumedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       ownerId = Value(ownerId),
       role = Value(role),
       createdAt = Value(createdAt),
       expiresAt = Value(expiresAt);
  static Insertable<TeamInviteRow> custom({
    Expression<String>? code,
    Expression<String>? ownerId,
    Expression<String>? role,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? consumedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (ownerId != null) 'owner_id': ownerId,
      if (role != null) 'role': role,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (consumedAt != null) 'consumed_at': consumedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamInvitesTableCompanion copyWith({
    Value<String>? code,
    Value<String>? ownerId,
    Value<String>? role,
    Value<DateTime>? createdAt,
    Value<DateTime>? expiresAt,
    Value<DateTime?>? consumedAt,
    Value<int>? rowid,
  }) {
    return TeamInvitesTableCompanion(
      code: code ?? this.code,
      ownerId: ownerId ?? this.ownerId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      consumedAt: consumedAt ?? this.consumedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (consumedAt.present) {
      map['consumed_at'] = Variable<DateTime>(consumedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamInvitesTableCompanion(')
          ..write('code: $code, ')
          ..write('ownerId: $ownerId, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTableTable extends OutboxTable
    with TableInfo<$OutboxTableTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    op,
    payloadJson,
    createdAt,
    attempts,
    nextAttemptAt,
    status,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $OutboxTableTable createAlias(String alias) {
    return $OutboxTableTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int id;
  final String entityType;
  final String entityId;
  final String op;
  final String payloadJson;
  final DateTime createdAt;
  final int attempts;
  final DateTime? nextAttemptAt;
  final String status;
  final String? lastError;
  const OutboxRow({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.op,
    required this.payloadJson,
    required this.createdAt,
    required this.attempts,
    this.nextAttemptAt,
    required this.status,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['op'] = Variable<String>(op);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OutboxTableCompanion toCompanion(bool nullToAbsent) {
    return OutboxTableCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      op: Value(op),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      status: Value(status),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      op: serializer.fromJson<String>(json['op']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      status: serializer.fromJson<String>(json['status']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'op': serializer.toJson<String>(op),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'status': serializer.toJson<String>(status),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OutboxRow copyWith({
    int? id,
    String? entityType,
    String? entityId,
    String? op,
    String? payloadJson,
    DateTime? createdAt,
    int? attempts,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    String? status,
    Value<String?> lastError = const Value.absent(),
  }) => OutboxRow(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    op: op ?? this.op,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    status: status ?? this.status,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  OutboxRow copyWithCompanion(OutboxTableCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      op: data.op.present ? data.op.value : this.op,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      status: data.status.present ? data.status.value : this.status,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    op,
    payloadJson,
    createdAt,
    attempts,
    nextAttemptAt,
    status,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.op == this.op &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.status == this.status &&
          other.lastError == this.lastError);
}

class OutboxTableCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> op;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<DateTime?> nextAttemptAt;
  final Value<String> status;
  final Value<String?> lastError;
  const OutboxTableCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.op = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  OutboxTableCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required String op,
    required String payloadJson,
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       op = Value(op),
       payloadJson = Value(payloadJson);
  static Insertable<OutboxRow> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? op,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? status,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (op != null) 'op': op,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (status != null) 'status': status,
      if (lastError != null) 'last_error': lastError,
    });
  }

  OutboxTableCompanion copyWith({
    Value<int>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? op,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
    Value<DateTime?>? nextAttemptAt,
    Value<String>? status,
    Value<String?>? lastError,
  }) {
    return OutboxTableCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxTableCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTableTable extends ExpensesTable
    with TableInfo<$ExpensesTableTable, ExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptUrlMeta = const VerificationMeta(
    'receiptUrl',
  );
  @override
  late final GeneratedColumn<String> receiptUrl = GeneratedColumn<String>(
    'receipt_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _incurredAtMeta = const VerificationMeta(
    'incurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> incurredAt = GeneratedColumn<DateTime>(
    'incurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    ownerId,
    category,
    amount,
    eventId,
    note,
    receiptUrl,
    incurredAt,
    createdAt,
    pending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('receipt_url')) {
      context.handle(
        _receiptUrlMeta,
        receiptUrl.isAcceptableOrUnknown(data['receipt_url']!, _receiptUrlMeta),
      );
    }
    if (data.containsKey('incurred_at')) {
      context.handle(
        _incurredAtMeta,
        incurredAt.isAcceptableOrUnknown(data['incurred_at']!, _incurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_incurredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      receiptUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_url'],
      ),
      incurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}incurred_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
    );
  }

  @override
  $ExpensesTableTable createAlias(String alias) {
    return $ExpensesTableTable(attachedDatabase, alias);
  }
}

class ExpenseRow extends DataClass implements Insertable<ExpenseRow> {
  final String id;
  final String? remoteId;
  final String? ownerId;
  final String category;
  final double amount;
  final String? eventId;
  final String? note;
  final String? receiptUrl;
  final DateTime incurredAt;
  final DateTime? createdAt;
  final bool pending;
  const ExpenseRow({
    required this.id,
    this.remoteId,
    this.ownerId,
    required this.category,
    required this.amount,
    this.eventId,
    this.note,
    this.receiptUrl,
    required this.incurredAt,
    this.createdAt,
    required this.pending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    map['category'] = Variable<String>(category);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<String>(eventId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || receiptUrl != null) {
      map['receipt_url'] = Variable<String>(receiptUrl);
    }
    map['incurred_at'] = Variable<DateTime>(incurredAt);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    map['pending'] = Variable<bool>(pending);
    return map;
  }

  ExpensesTableCompanion toCompanion(bool nullToAbsent) {
    return ExpensesTableCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      category: Value(category),
      amount: Value(amount),
      eventId: eventId == null && nullToAbsent
          ? const Value.absent()
          : Value(eventId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      receiptUrl: receiptUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptUrl),
      incurredAt: Value(incurredAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      pending: Value(pending),
    );
  }

  factory ExpenseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRow(
      id: serializer.fromJson<String>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      category: serializer.fromJson<String>(json['category']),
      amount: serializer.fromJson<double>(json['amount']),
      eventId: serializer.fromJson<String?>(json['eventId']),
      note: serializer.fromJson<String?>(json['note']),
      receiptUrl: serializer.fromJson<String?>(json['receiptUrl']),
      incurredAt: serializer.fromJson<DateTime>(json['incurredAt']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      pending: serializer.fromJson<bool>(json['pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'ownerId': serializer.toJson<String?>(ownerId),
      'category': serializer.toJson<String>(category),
      'amount': serializer.toJson<double>(amount),
      'eventId': serializer.toJson<String?>(eventId),
      'note': serializer.toJson<String?>(note),
      'receiptUrl': serializer.toJson<String?>(receiptUrl),
      'incurredAt': serializer.toJson<DateTime>(incurredAt),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'pending': serializer.toJson<bool>(pending),
    };
  }

  ExpenseRow copyWith({
    String? id,
    Value<String?> remoteId = const Value.absent(),
    Value<String?> ownerId = const Value.absent(),
    String? category,
    double? amount,
    Value<String?> eventId = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> receiptUrl = const Value.absent(),
    DateTime? incurredAt,
    Value<DateTime?> createdAt = const Value.absent(),
    bool? pending,
  }) => ExpenseRow(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    eventId: eventId.present ? eventId.value : this.eventId,
    note: note.present ? note.value : this.note,
    receiptUrl: receiptUrl.present ? receiptUrl.value : this.receiptUrl,
    incurredAt: incurredAt ?? this.incurredAt,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    pending: pending ?? this.pending,
  );
  ExpenseRow copyWithCompanion(ExpensesTableCompanion data) {
    return ExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      category: data.category.present ? data.category.value : this.category,
      amount: data.amount.present ? data.amount.value : this.amount,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      note: data.note.present ? data.note.value : this.note,
      receiptUrl: data.receiptUrl.present
          ? data.receiptUrl.value
          : this.receiptUrl,
      incurredAt: data.incurredAt.present
          ? data.incurredAt.value
          : this.incurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      pending: data.pending.present ? data.pending.value : this.pending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRow(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('ownerId: $ownerId, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('eventId: $eventId, ')
          ..write('note: $note, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('incurredAt: $incurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('pending: $pending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    ownerId,
    category,
    amount,
    eventId,
    note,
    receiptUrl,
    incurredAt,
    createdAt,
    pending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRow &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.ownerId == this.ownerId &&
          other.category == this.category &&
          other.amount == this.amount &&
          other.eventId == this.eventId &&
          other.note == this.note &&
          other.receiptUrl == this.receiptUrl &&
          other.incurredAt == this.incurredAt &&
          other.createdAt == this.createdAt &&
          other.pending == this.pending);
}

class ExpensesTableCompanion extends UpdateCompanion<ExpenseRow> {
  final Value<String> id;
  final Value<String?> remoteId;
  final Value<String?> ownerId;
  final Value<String> category;
  final Value<double> amount;
  final Value<String?> eventId;
  final Value<String?> note;
  final Value<String?> receiptUrl;
  final Value<DateTime> incurredAt;
  final Value<DateTime?> createdAt;
  final Value<bool> pending;
  final Value<int> rowid;
  const ExpensesTableCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.category = const Value.absent(),
    this.amount = const Value.absent(),
    this.eventId = const Value.absent(),
    this.note = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.incurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesTableCompanion.insert({
    required String id,
    this.remoteId = const Value.absent(),
    this.ownerId = const Value.absent(),
    required String category,
    required double amount,
    this.eventId = const Value.absent(),
    this.note = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    required DateTime incurredAt,
    this.createdAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       amount = Value(amount),
       incurredAt = Value(incurredAt);
  static Insertable<ExpenseRow> custom({
    Expression<String>? id,
    Expression<String>? remoteId,
    Expression<String>? ownerId,
    Expression<String>? category,
    Expression<double>? amount,
    Expression<String>? eventId,
    Expression<String>? note,
    Expression<String>? receiptUrl,
    Expression<DateTime>? incurredAt,
    Expression<DateTime>? createdAt,
    Expression<bool>? pending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (ownerId != null) 'owner_id': ownerId,
      if (category != null) 'category': category,
      if (amount != null) 'amount': amount,
      if (eventId != null) 'event_id': eventId,
      if (note != null) 'note': note,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      if (incurredAt != null) 'incurred_at': incurredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (pending != null) 'pending': pending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? remoteId,
    Value<String?>? ownerId,
    Value<String>? category,
    Value<double>? amount,
    Value<String?>? eventId,
    Value<String?>? note,
    Value<String?>? receiptUrl,
    Value<DateTime>? incurredAt,
    Value<DateTime?>? createdAt,
    Value<bool>? pending,
    Value<int>? rowid,
  }) {
    return ExpensesTableCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      ownerId: ownerId ?? this.ownerId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      eventId: eventId ?? this.eventId,
      note: note ?? this.note,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      incurredAt: incurredAt ?? this.incurredAt,
      createdAt: createdAt ?? this.createdAt,
      pending: pending ?? this.pending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (receiptUrl.present) {
      map['receipt_url'] = Variable<String>(receiptUrl.value);
    }
    if (incurredAt.present) {
      map['incurred_at'] = Variable<DateTime>(incurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesTableCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('ownerId: $ownerId, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('eventId: $eventId, ')
          ..write('note: $note, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('incurredAt: $incurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('pending: $pending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookingsTableTable extends BookingsTable
    with TableInfo<$BookingsTableTable, BookingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _studioIdMeta = const VerificationMeta(
    'studioId',
  );
  @override
  late final GeneratedColumn<String> studioId = GeneratedColumn<String>(
    'studio_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByUserIdMeta = const VerificationMeta(
    'createdByUserId',
  );
  @override
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
    'created_by_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftMeta = const VerificationMeta('shift');
  @override
  late final GeneratedColumn<String> shift = GeneratedColumn<String>(
    'shift',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientNameMeta = const VerificationMeta(
    'clientName',
  );
  @override
  late final GeneratedColumn<String> clientName = GeneratedColumn<String>(
    'client_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientPhoneMeta = const VerificationMeta(
    'clientPhone',
  );
  @override
  late final GeneratedColumn<String> clientPhone = GeneratedColumn<String>(
    'client_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _venueMeta = const VerificationMeta('venue');
  @override
  late final GeneratedColumn<String> venue = GeneratedColumn<String>(
    'venue',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outdoorMeta = const VerificationMeta(
    'outdoor',
  );
  @override
  late final GeneratedColumn<bool> outdoor = GeneratedColumn<bool>(
    'outdoor',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("outdoor" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _brideNameMeta = const VerificationMeta(
    'brideName',
  );
  @override
  late final GeneratedColumn<String> brideName = GeneratedColumn<String>(
    'bride_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groomNameMeta = const VerificationMeta(
    'groomName',
  );
  @override
  late final GeneratedColumn<String> groomName = GeneratedColumn<String>(
    'groom_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _packageIdMeta = const VerificationMeta(
    'packageId',
  );
  @override
  late final GeneratedColumn<String> packageId = GeneratedColumn<String>(
    'package_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customPriceMeta = const VerificationMeta(
    'customPrice',
  );
  @override
  late final GeneratedColumn<double> customPrice = GeneratedColumn<double>(
    'custom_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverageHoursMeta = const VerificationMeta(
    'coverageHours',
  );
  @override
  late final GeneratedColumn<double> coverageHours = GeneratedColumn<double>(
    'coverage_hours',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extraHourRateMeta = const VerificationMeta(
    'extraHourRate',
  );
  @override
  late final GeneratedColumn<double> extraHourRate = GeneratedColumn<double>(
    'extra_hour_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _driveLinkMeta = const VerificationMeta(
    'driveLink',
  );
  @override
  late final GeneratedColumn<String> driveLink = GeneratedColumn<String>(
    'drive_link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientRequirementsJsonMeta =
      const VerificationMeta('clientRequirementsJson');
  @override
  late final GeneratedColumn<String> clientRequirementsJson =
      GeneratedColumn<String>(
        'client_requirements_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chiefPhotographerUserIdMeta =
      const VerificationMeta('chiefPhotographerUserId');
  @override
  late final GeneratedColumn<String> chiefPhotographerUserId =
      GeneratedColumn<String>(
        'chief_photographer_user_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _chiefHoursMeta = const VerificationMeta(
    'chiefHours',
  );
  @override
  late final GeneratedColumn<double> chiefHours = GeneratedColumn<double>(
    'chief_hours',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hidePaymentFromTeamMeta =
      const VerificationMeta('hidePaymentFromTeam');
  @override
  late final GeneratedColumn<bool> hidePaymentFromTeam = GeneratedColumn<bool>(
    'hide_payment_from_team',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hide_payment_from_team" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    studioId,
    createdByUserId,
    title,
    eventType,
    date,
    startTime,
    endTime,
    shift,
    clientName,
    clientPhone,
    venue,
    outdoor,
    brideName,
    groomName,
    clientId,
    packageId,
    customPrice,
    coverageHours,
    extraHourRate,
    driveLink,
    clientRequirementsJson,
    notes,
    chiefPhotographerUserId,
    chiefHours,
    hidePaymentFromTeam,
    status,
    createdAt,
    updatedAt,
    pending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('studio_id')) {
      context.handle(
        _studioIdMeta,
        studioId.isAcceptableOrUnknown(data['studio_id']!, _studioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studioIdMeta);
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
        _createdByUserIdMeta,
        createdByUserId.isAcceptableOrUnknown(
          data['created_by_user_id']!,
          _createdByUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('shift')) {
      context.handle(
        _shiftMeta,
        shift.isAcceptableOrUnknown(data['shift']!, _shiftMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftMeta);
    }
    if (data.containsKey('client_name')) {
      context.handle(
        _clientNameMeta,
        clientName.isAcceptableOrUnknown(data['client_name']!, _clientNameMeta),
      );
    }
    if (data.containsKey('client_phone')) {
      context.handle(
        _clientPhoneMeta,
        clientPhone.isAcceptableOrUnknown(
          data['client_phone']!,
          _clientPhoneMeta,
        ),
      );
    }
    if (data.containsKey('venue')) {
      context.handle(
        _venueMeta,
        venue.isAcceptableOrUnknown(data['venue']!, _venueMeta),
      );
    }
    if (data.containsKey('outdoor')) {
      context.handle(
        _outdoorMeta,
        outdoor.isAcceptableOrUnknown(data['outdoor']!, _outdoorMeta),
      );
    }
    if (data.containsKey('bride_name')) {
      context.handle(
        _brideNameMeta,
        brideName.isAcceptableOrUnknown(data['bride_name']!, _brideNameMeta),
      );
    }
    if (data.containsKey('groom_name')) {
      context.handle(
        _groomNameMeta,
        groomName.isAcceptableOrUnknown(data['groom_name']!, _groomNameMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('package_id')) {
      context.handle(
        _packageIdMeta,
        packageId.isAcceptableOrUnknown(data['package_id']!, _packageIdMeta),
      );
    }
    if (data.containsKey('custom_price')) {
      context.handle(
        _customPriceMeta,
        customPrice.isAcceptableOrUnknown(
          data['custom_price']!,
          _customPriceMeta,
        ),
      );
    }
    if (data.containsKey('coverage_hours')) {
      context.handle(
        _coverageHoursMeta,
        coverageHours.isAcceptableOrUnknown(
          data['coverage_hours']!,
          _coverageHoursMeta,
        ),
      );
    }
    if (data.containsKey('extra_hour_rate')) {
      context.handle(
        _extraHourRateMeta,
        extraHourRate.isAcceptableOrUnknown(
          data['extra_hour_rate']!,
          _extraHourRateMeta,
        ),
      );
    }
    if (data.containsKey('drive_link')) {
      context.handle(
        _driveLinkMeta,
        driveLink.isAcceptableOrUnknown(data['drive_link']!, _driveLinkMeta),
      );
    }
    if (data.containsKey('client_requirements_json')) {
      context.handle(
        _clientRequirementsJsonMeta,
        clientRequirementsJson.isAcceptableOrUnknown(
          data['client_requirements_json']!,
          _clientRequirementsJsonMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('chief_photographer_user_id')) {
      context.handle(
        _chiefPhotographerUserIdMeta,
        chiefPhotographerUserId.isAcceptableOrUnknown(
          data['chief_photographer_user_id']!,
          _chiefPhotographerUserIdMeta,
        ),
      );
    }
    if (data.containsKey('chief_hours')) {
      context.handle(
        _chiefHoursMeta,
        chiefHours.isAcceptableOrUnknown(data['chief_hours']!, _chiefHoursMeta),
      );
    }
    if (data.containsKey('hide_payment_from_team')) {
      context.handle(
        _hidePaymentFromTeamMeta,
        hidePaymentFromTeam.isAcceptableOrUnknown(
          data['hide_payment_from_team']!,
          _hidePaymentFromTeamMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      studioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}studio_id'],
      )!,
      createdByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      )!,
      shift: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift'],
      )!,
      clientName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_name'],
      ),
      clientPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_phone'],
      ),
      venue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}venue'],
      ),
      outdoor: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}outdoor'],
      )!,
      brideName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bride_name'],
      ),
      groomName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}groom_name'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      packageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_id'],
      ),
      customPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}custom_price'],
      ),
      coverageHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}coverage_hours'],
      ),
      extraHourRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}extra_hour_rate'],
      ),
      driveLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}drive_link'],
      ),
      clientRequirementsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_requirements_json'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      chiefPhotographerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chief_photographer_user_id'],
      ),
      chiefHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}chief_hours'],
      ),
      hidePaymentFromTeam: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hide_payment_from_team'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
    );
  }

  @override
  $BookingsTableTable createAlias(String alias) {
    return $BookingsTableTable(attachedDatabase, alias);
  }
}

class BookingRow extends DataClass implements Insertable<BookingRow> {
  final String id;
  final String? remoteId;
  final String studioId;
  final String createdByUserId;
  final String title;
  final String eventType;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String shift;
  final String? clientName;
  final String? clientPhone;
  final String? venue;
  final bool outdoor;
  final String? brideName;
  final String? groomName;
  final String? clientId;
  final String? packageId;
  final double? customPrice;
  final double? coverageHours;
  final double? extraHourRate;
  final String? driveLink;
  final String? clientRequirementsJson;
  final String? notes;
  final String? chiefPhotographerUserId;
  final double? chiefHours;
  final bool hidePaymentFromTeam;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pending;
  const BookingRow({
    required this.id,
    this.remoteId,
    required this.studioId,
    required this.createdByUserId,
    required this.title,
    required this.eventType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.shift,
    this.clientName,
    this.clientPhone,
    this.venue,
    required this.outdoor,
    this.brideName,
    this.groomName,
    this.clientId,
    this.packageId,
    this.customPrice,
    this.coverageHours,
    this.extraHourRate,
    this.driveLink,
    this.clientRequirementsJson,
    this.notes,
    this.chiefPhotographerUserId,
    this.chiefHours,
    required this.hidePaymentFromTeam,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.pending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['studio_id'] = Variable<String>(studioId);
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    map['title'] = Variable<String>(title);
    map['event_type'] = Variable<String>(eventType);
    map['date'] = Variable<DateTime>(date);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    map['shift'] = Variable<String>(shift);
    if (!nullToAbsent || clientName != null) {
      map['client_name'] = Variable<String>(clientName);
    }
    if (!nullToAbsent || clientPhone != null) {
      map['client_phone'] = Variable<String>(clientPhone);
    }
    if (!nullToAbsent || venue != null) {
      map['venue'] = Variable<String>(venue);
    }
    map['outdoor'] = Variable<bool>(outdoor);
    if (!nullToAbsent || brideName != null) {
      map['bride_name'] = Variable<String>(brideName);
    }
    if (!nullToAbsent || groomName != null) {
      map['groom_name'] = Variable<String>(groomName);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    if (!nullToAbsent || packageId != null) {
      map['package_id'] = Variable<String>(packageId);
    }
    if (!nullToAbsent || customPrice != null) {
      map['custom_price'] = Variable<double>(customPrice);
    }
    if (!nullToAbsent || coverageHours != null) {
      map['coverage_hours'] = Variable<double>(coverageHours);
    }
    if (!nullToAbsent || extraHourRate != null) {
      map['extra_hour_rate'] = Variable<double>(extraHourRate);
    }
    if (!nullToAbsent || driveLink != null) {
      map['drive_link'] = Variable<String>(driveLink);
    }
    if (!nullToAbsent || clientRequirementsJson != null) {
      map['client_requirements_json'] = Variable<String>(
        clientRequirementsJson,
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || chiefPhotographerUserId != null) {
      map['chief_photographer_user_id'] = Variable<String>(
        chiefPhotographerUserId,
      );
    }
    if (!nullToAbsent || chiefHours != null) {
      map['chief_hours'] = Variable<double>(chiefHours);
    }
    map['hide_payment_from_team'] = Variable<bool>(hidePaymentFromTeam);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending'] = Variable<bool>(pending);
    return map;
  }

  BookingsTableCompanion toCompanion(bool nullToAbsent) {
    return BookingsTableCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      studioId: Value(studioId),
      createdByUserId: Value(createdByUserId),
      title: Value(title),
      eventType: Value(eventType),
      date: Value(date),
      startTime: Value(startTime),
      endTime: Value(endTime),
      shift: Value(shift),
      clientName: clientName == null && nullToAbsent
          ? const Value.absent()
          : Value(clientName),
      clientPhone: clientPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(clientPhone),
      venue: venue == null && nullToAbsent
          ? const Value.absent()
          : Value(venue),
      outdoor: Value(outdoor),
      brideName: brideName == null && nullToAbsent
          ? const Value.absent()
          : Value(brideName),
      groomName: groomName == null && nullToAbsent
          ? const Value.absent()
          : Value(groomName),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      packageId: packageId == null && nullToAbsent
          ? const Value.absent()
          : Value(packageId),
      customPrice: customPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(customPrice),
      coverageHours: coverageHours == null && nullToAbsent
          ? const Value.absent()
          : Value(coverageHours),
      extraHourRate: extraHourRate == null && nullToAbsent
          ? const Value.absent()
          : Value(extraHourRate),
      driveLink: driveLink == null && nullToAbsent
          ? const Value.absent()
          : Value(driveLink),
      clientRequirementsJson: clientRequirementsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(clientRequirementsJson),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      chiefPhotographerUserId: chiefPhotographerUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(chiefPhotographerUserId),
      chiefHours: chiefHours == null && nullToAbsent
          ? const Value.absent()
          : Value(chiefHours),
      hidePaymentFromTeam: Value(hidePaymentFromTeam),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      pending: Value(pending),
    );
  }

  factory BookingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookingRow(
      id: serializer.fromJson<String>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      studioId: serializer.fromJson<String>(json['studioId']),
      createdByUserId: serializer.fromJson<String>(json['createdByUserId']),
      title: serializer.fromJson<String>(json['title']),
      eventType: serializer.fromJson<String>(json['eventType']),
      date: serializer.fromJson<DateTime>(json['date']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      shift: serializer.fromJson<String>(json['shift']),
      clientName: serializer.fromJson<String?>(json['clientName']),
      clientPhone: serializer.fromJson<String?>(json['clientPhone']),
      venue: serializer.fromJson<String?>(json['venue']),
      outdoor: serializer.fromJson<bool>(json['outdoor']),
      brideName: serializer.fromJson<String?>(json['brideName']),
      groomName: serializer.fromJson<String?>(json['groomName']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      packageId: serializer.fromJson<String?>(json['packageId']),
      customPrice: serializer.fromJson<double?>(json['customPrice']),
      coverageHours: serializer.fromJson<double?>(json['coverageHours']),
      extraHourRate: serializer.fromJson<double?>(json['extraHourRate']),
      driveLink: serializer.fromJson<String?>(json['driveLink']),
      clientRequirementsJson: serializer.fromJson<String?>(
        json['clientRequirementsJson'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      chiefPhotographerUserId: serializer.fromJson<String?>(
        json['chiefPhotographerUserId'],
      ),
      chiefHours: serializer.fromJson<double?>(json['chiefHours']),
      hidePaymentFromTeam: serializer.fromJson<bool>(
        json['hidePaymentFromTeam'],
      ),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pending: serializer.fromJson<bool>(json['pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'studioId': serializer.toJson<String>(studioId),
      'createdByUserId': serializer.toJson<String>(createdByUserId),
      'title': serializer.toJson<String>(title),
      'eventType': serializer.toJson<String>(eventType),
      'date': serializer.toJson<DateTime>(date),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'shift': serializer.toJson<String>(shift),
      'clientName': serializer.toJson<String?>(clientName),
      'clientPhone': serializer.toJson<String?>(clientPhone),
      'venue': serializer.toJson<String?>(venue),
      'outdoor': serializer.toJson<bool>(outdoor),
      'brideName': serializer.toJson<String?>(brideName),
      'groomName': serializer.toJson<String?>(groomName),
      'clientId': serializer.toJson<String?>(clientId),
      'packageId': serializer.toJson<String?>(packageId),
      'customPrice': serializer.toJson<double?>(customPrice),
      'coverageHours': serializer.toJson<double?>(coverageHours),
      'extraHourRate': serializer.toJson<double?>(extraHourRate),
      'driveLink': serializer.toJson<String?>(driveLink),
      'clientRequirementsJson': serializer.toJson<String?>(
        clientRequirementsJson,
      ),
      'notes': serializer.toJson<String?>(notes),
      'chiefPhotographerUserId': serializer.toJson<String?>(
        chiefPhotographerUserId,
      ),
      'chiefHours': serializer.toJson<double?>(chiefHours),
      'hidePaymentFromTeam': serializer.toJson<bool>(hidePaymentFromTeam),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pending': serializer.toJson<bool>(pending),
    };
  }

  BookingRow copyWith({
    String? id,
    Value<String?> remoteId = const Value.absent(),
    String? studioId,
    String? createdByUserId,
    String? title,
    String? eventType,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? shift,
    Value<String?> clientName = const Value.absent(),
    Value<String?> clientPhone = const Value.absent(),
    Value<String?> venue = const Value.absent(),
    bool? outdoor,
    Value<String?> brideName = const Value.absent(),
    Value<String?> groomName = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    Value<String?> packageId = const Value.absent(),
    Value<double?> customPrice = const Value.absent(),
    Value<double?> coverageHours = const Value.absent(),
    Value<double?> extraHourRate = const Value.absent(),
    Value<String?> driveLink = const Value.absent(),
    Value<String?> clientRequirementsJson = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> chiefPhotographerUserId = const Value.absent(),
    Value<double?> chiefHours = const Value.absent(),
    bool? hidePaymentFromTeam,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pending,
  }) => BookingRow(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    studioId: studioId ?? this.studioId,
    createdByUserId: createdByUserId ?? this.createdByUserId,
    title: title ?? this.title,
    eventType: eventType ?? this.eventType,
    date: date ?? this.date,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    shift: shift ?? this.shift,
    clientName: clientName.present ? clientName.value : this.clientName,
    clientPhone: clientPhone.present ? clientPhone.value : this.clientPhone,
    venue: venue.present ? venue.value : this.venue,
    outdoor: outdoor ?? this.outdoor,
    brideName: brideName.present ? brideName.value : this.brideName,
    groomName: groomName.present ? groomName.value : this.groomName,
    clientId: clientId.present ? clientId.value : this.clientId,
    packageId: packageId.present ? packageId.value : this.packageId,
    customPrice: customPrice.present ? customPrice.value : this.customPrice,
    coverageHours: coverageHours.present
        ? coverageHours.value
        : this.coverageHours,
    extraHourRate: extraHourRate.present
        ? extraHourRate.value
        : this.extraHourRate,
    driveLink: driveLink.present ? driveLink.value : this.driveLink,
    clientRequirementsJson: clientRequirementsJson.present
        ? clientRequirementsJson.value
        : this.clientRequirementsJson,
    notes: notes.present ? notes.value : this.notes,
    chiefPhotographerUserId: chiefPhotographerUserId.present
        ? chiefPhotographerUserId.value
        : this.chiefPhotographerUserId,
    chiefHours: chiefHours.present ? chiefHours.value : this.chiefHours,
    hidePaymentFromTeam: hidePaymentFromTeam ?? this.hidePaymentFromTeam,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pending: pending ?? this.pending,
  );
  BookingRow copyWithCompanion(BookingsTableCompanion data) {
    return BookingRow(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      studioId: data.studioId.present ? data.studioId.value : this.studioId,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      title: data.title.present ? data.title.value : this.title,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      date: data.date.present ? data.date.value : this.date,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      shift: data.shift.present ? data.shift.value : this.shift,
      clientName: data.clientName.present
          ? data.clientName.value
          : this.clientName,
      clientPhone: data.clientPhone.present
          ? data.clientPhone.value
          : this.clientPhone,
      venue: data.venue.present ? data.venue.value : this.venue,
      outdoor: data.outdoor.present ? data.outdoor.value : this.outdoor,
      brideName: data.brideName.present ? data.brideName.value : this.brideName,
      groomName: data.groomName.present ? data.groomName.value : this.groomName,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      packageId: data.packageId.present ? data.packageId.value : this.packageId,
      customPrice: data.customPrice.present
          ? data.customPrice.value
          : this.customPrice,
      coverageHours: data.coverageHours.present
          ? data.coverageHours.value
          : this.coverageHours,
      extraHourRate: data.extraHourRate.present
          ? data.extraHourRate.value
          : this.extraHourRate,
      driveLink: data.driveLink.present ? data.driveLink.value : this.driveLink,
      clientRequirementsJson: data.clientRequirementsJson.present
          ? data.clientRequirementsJson.value
          : this.clientRequirementsJson,
      notes: data.notes.present ? data.notes.value : this.notes,
      chiefPhotographerUserId: data.chiefPhotographerUserId.present
          ? data.chiefPhotographerUserId.value
          : this.chiefPhotographerUserId,
      chiefHours: data.chiefHours.present
          ? data.chiefHours.value
          : this.chiefHours,
      hidePaymentFromTeam: data.hidePaymentFromTeam.present
          ? data.hidePaymentFromTeam.value
          : this.hidePaymentFromTeam,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pending: data.pending.present ? data.pending.value : this.pending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookingRow(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('studioId: $studioId, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('title: $title, ')
          ..write('eventType: $eventType, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('shift: $shift, ')
          ..write('clientName: $clientName, ')
          ..write('clientPhone: $clientPhone, ')
          ..write('venue: $venue, ')
          ..write('outdoor: $outdoor, ')
          ..write('brideName: $brideName, ')
          ..write('groomName: $groomName, ')
          ..write('clientId: $clientId, ')
          ..write('packageId: $packageId, ')
          ..write('customPrice: $customPrice, ')
          ..write('coverageHours: $coverageHours, ')
          ..write('extraHourRate: $extraHourRate, ')
          ..write('driveLink: $driveLink, ')
          ..write('clientRequirementsJson: $clientRequirementsJson, ')
          ..write('notes: $notes, ')
          ..write('chiefPhotographerUserId: $chiefPhotographerUserId, ')
          ..write('chiefHours: $chiefHours, ')
          ..write('hidePaymentFromTeam: $hidePaymentFromTeam, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    remoteId,
    studioId,
    createdByUserId,
    title,
    eventType,
    date,
    startTime,
    endTime,
    shift,
    clientName,
    clientPhone,
    venue,
    outdoor,
    brideName,
    groomName,
    clientId,
    packageId,
    customPrice,
    coverageHours,
    extraHourRate,
    driveLink,
    clientRequirementsJson,
    notes,
    chiefPhotographerUserId,
    chiefHours,
    hidePaymentFromTeam,
    status,
    createdAt,
    updatedAt,
    pending,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookingRow &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.studioId == this.studioId &&
          other.createdByUserId == this.createdByUserId &&
          other.title == this.title &&
          other.eventType == this.eventType &&
          other.date == this.date &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.shift == this.shift &&
          other.clientName == this.clientName &&
          other.clientPhone == this.clientPhone &&
          other.venue == this.venue &&
          other.outdoor == this.outdoor &&
          other.brideName == this.brideName &&
          other.groomName == this.groomName &&
          other.clientId == this.clientId &&
          other.packageId == this.packageId &&
          other.customPrice == this.customPrice &&
          other.coverageHours == this.coverageHours &&
          other.extraHourRate == this.extraHourRate &&
          other.driveLink == this.driveLink &&
          other.clientRequirementsJson == this.clientRequirementsJson &&
          other.notes == this.notes &&
          other.chiefPhotographerUserId == this.chiefPhotographerUserId &&
          other.chiefHours == this.chiefHours &&
          other.hidePaymentFromTeam == this.hidePaymentFromTeam &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.pending == this.pending);
}

class BookingsTableCompanion extends UpdateCompanion<BookingRow> {
  final Value<String> id;
  final Value<String?> remoteId;
  final Value<String> studioId;
  final Value<String> createdByUserId;
  final Value<String> title;
  final Value<String> eventType;
  final Value<DateTime> date;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<String> shift;
  final Value<String?> clientName;
  final Value<String?> clientPhone;
  final Value<String?> venue;
  final Value<bool> outdoor;
  final Value<String?> brideName;
  final Value<String?> groomName;
  final Value<String?> clientId;
  final Value<String?> packageId;
  final Value<double?> customPrice;
  final Value<double?> coverageHours;
  final Value<double?> extraHourRate;
  final Value<String?> driveLink;
  final Value<String?> clientRequirementsJson;
  final Value<String?> notes;
  final Value<String?> chiefPhotographerUserId;
  final Value<double?> chiefHours;
  final Value<bool> hidePaymentFromTeam;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pending;
  final Value<int> rowid;
  const BookingsTableCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.studioId = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.title = const Value.absent(),
    this.eventType = const Value.absent(),
    this.date = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.shift = const Value.absent(),
    this.clientName = const Value.absent(),
    this.clientPhone = const Value.absent(),
    this.venue = const Value.absent(),
    this.outdoor = const Value.absent(),
    this.brideName = const Value.absent(),
    this.groomName = const Value.absent(),
    this.clientId = const Value.absent(),
    this.packageId = const Value.absent(),
    this.customPrice = const Value.absent(),
    this.coverageHours = const Value.absent(),
    this.extraHourRate = const Value.absent(),
    this.driveLink = const Value.absent(),
    this.clientRequirementsJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.chiefPhotographerUserId = const Value.absent(),
    this.chiefHours = const Value.absent(),
    this.hidePaymentFromTeam = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookingsTableCompanion.insert({
    required String id,
    this.remoteId = const Value.absent(),
    required String studioId,
    required String createdByUserId,
    required String title,
    required String eventType,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String shift,
    this.clientName = const Value.absent(),
    this.clientPhone = const Value.absent(),
    this.venue = const Value.absent(),
    this.outdoor = const Value.absent(),
    this.brideName = const Value.absent(),
    this.groomName = const Value.absent(),
    this.clientId = const Value.absent(),
    this.packageId = const Value.absent(),
    this.customPrice = const Value.absent(),
    this.coverageHours = const Value.absent(),
    this.extraHourRate = const Value.absent(),
    this.driveLink = const Value.absent(),
    this.clientRequirementsJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.chiefPhotographerUserId = const Value.absent(),
    this.chiefHours = const Value.absent(),
    this.hidePaymentFromTeam = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       studioId = Value(studioId),
       createdByUserId = Value(createdByUserId),
       title = Value(title),
       eventType = Value(eventType),
       date = Value(date),
       startTime = Value(startTime),
       endTime = Value(endTime),
       shift = Value(shift);
  static Insertable<BookingRow> custom({
    Expression<String>? id,
    Expression<String>? remoteId,
    Expression<String>? studioId,
    Expression<String>? createdByUserId,
    Expression<String>? title,
    Expression<String>? eventType,
    Expression<DateTime>? date,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? shift,
    Expression<String>? clientName,
    Expression<String>? clientPhone,
    Expression<String>? venue,
    Expression<bool>? outdoor,
    Expression<String>? brideName,
    Expression<String>? groomName,
    Expression<String>? clientId,
    Expression<String>? packageId,
    Expression<double>? customPrice,
    Expression<double>? coverageHours,
    Expression<double>? extraHourRate,
    Expression<String>? driveLink,
    Expression<String>? clientRequirementsJson,
    Expression<String>? notes,
    Expression<String>? chiefPhotographerUserId,
    Expression<double>? chiefHours,
    Expression<bool>? hidePaymentFromTeam,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (studioId != null) 'studio_id': studioId,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (title != null) 'title': title,
      if (eventType != null) 'event_type': eventType,
      if (date != null) 'date': date,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (shift != null) 'shift': shift,
      if (clientName != null) 'client_name': clientName,
      if (clientPhone != null) 'client_phone': clientPhone,
      if (venue != null) 'venue': venue,
      if (outdoor != null) 'outdoor': outdoor,
      if (brideName != null) 'bride_name': brideName,
      if (groomName != null) 'groom_name': groomName,
      if (clientId != null) 'client_id': clientId,
      if (packageId != null) 'package_id': packageId,
      if (customPrice != null) 'custom_price': customPrice,
      if (coverageHours != null) 'coverage_hours': coverageHours,
      if (extraHourRate != null) 'extra_hour_rate': extraHourRate,
      if (driveLink != null) 'drive_link': driveLink,
      if (clientRequirementsJson != null)
        'client_requirements_json': clientRequirementsJson,
      if (notes != null) 'notes': notes,
      if (chiefPhotographerUserId != null)
        'chief_photographer_user_id': chiefPhotographerUserId,
      if (chiefHours != null) 'chief_hours': chiefHours,
      if (hidePaymentFromTeam != null)
        'hide_payment_from_team': hidePaymentFromTeam,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pending != null) 'pending': pending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookingsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? remoteId,
    Value<String>? studioId,
    Value<String>? createdByUserId,
    Value<String>? title,
    Value<String>? eventType,
    Value<DateTime>? date,
    Value<String>? startTime,
    Value<String>? endTime,
    Value<String>? shift,
    Value<String?>? clientName,
    Value<String?>? clientPhone,
    Value<String?>? venue,
    Value<bool>? outdoor,
    Value<String?>? brideName,
    Value<String?>? groomName,
    Value<String?>? clientId,
    Value<String?>? packageId,
    Value<double?>? customPrice,
    Value<double?>? coverageHours,
    Value<double?>? extraHourRate,
    Value<String?>? driveLink,
    Value<String?>? clientRequirementsJson,
    Value<String?>? notes,
    Value<String?>? chiefPhotographerUserId,
    Value<double?>? chiefHours,
    Value<bool>? hidePaymentFromTeam,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pending,
    Value<int>? rowid,
  }) {
    return BookingsTableCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      studioId: studioId ?? this.studioId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      title: title ?? this.title,
      eventType: eventType ?? this.eventType,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      shift: shift ?? this.shift,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      venue: venue ?? this.venue,
      outdoor: outdoor ?? this.outdoor,
      brideName: brideName ?? this.brideName,
      groomName: groomName ?? this.groomName,
      clientId: clientId ?? this.clientId,
      packageId: packageId ?? this.packageId,
      customPrice: customPrice ?? this.customPrice,
      coverageHours: coverageHours ?? this.coverageHours,
      extraHourRate: extraHourRate ?? this.extraHourRate,
      driveLink: driveLink ?? this.driveLink,
      clientRequirementsJson:
          clientRequirementsJson ?? this.clientRequirementsJson,
      notes: notes ?? this.notes,
      chiefPhotographerUserId:
          chiefPhotographerUserId ?? this.chiefPhotographerUserId,
      chiefHours: chiefHours ?? this.chiefHours,
      hidePaymentFromTeam: hidePaymentFromTeam ?? this.hidePaymentFromTeam,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (studioId.present) {
      map['studio_id'] = Variable<String>(studioId.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (shift.present) {
      map['shift'] = Variable<String>(shift.value);
    }
    if (clientName.present) {
      map['client_name'] = Variable<String>(clientName.value);
    }
    if (clientPhone.present) {
      map['client_phone'] = Variable<String>(clientPhone.value);
    }
    if (venue.present) {
      map['venue'] = Variable<String>(venue.value);
    }
    if (outdoor.present) {
      map['outdoor'] = Variable<bool>(outdoor.value);
    }
    if (brideName.present) {
      map['bride_name'] = Variable<String>(brideName.value);
    }
    if (groomName.present) {
      map['groom_name'] = Variable<String>(groomName.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (packageId.present) {
      map['package_id'] = Variable<String>(packageId.value);
    }
    if (customPrice.present) {
      map['custom_price'] = Variable<double>(customPrice.value);
    }
    if (coverageHours.present) {
      map['coverage_hours'] = Variable<double>(coverageHours.value);
    }
    if (extraHourRate.present) {
      map['extra_hour_rate'] = Variable<double>(extraHourRate.value);
    }
    if (driveLink.present) {
      map['drive_link'] = Variable<String>(driveLink.value);
    }
    if (clientRequirementsJson.present) {
      map['client_requirements_json'] = Variable<String>(
        clientRequirementsJson.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (chiefPhotographerUserId.present) {
      map['chief_photographer_user_id'] = Variable<String>(
        chiefPhotographerUserId.value,
      );
    }
    if (chiefHours.present) {
      map['chief_hours'] = Variable<double>(chiefHours.value);
    }
    if (hidePaymentFromTeam.present) {
      map['hide_payment_from_team'] = Variable<bool>(hidePaymentFromTeam.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookingsTableCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('studioId: $studioId, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('title: $title, ')
          ..write('eventType: $eventType, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('shift: $shift, ')
          ..write('clientName: $clientName, ')
          ..write('clientPhone: $clientPhone, ')
          ..write('venue: $venue, ')
          ..write('outdoor: $outdoor, ')
          ..write('brideName: $brideName, ')
          ..write('groomName: $groomName, ')
          ..write('clientId: $clientId, ')
          ..write('packageId: $packageId, ')
          ..write('customPrice: $customPrice, ')
          ..write('coverageHours: $coverageHours, ')
          ..write('extraHourRate: $extraHourRate, ')
          ..write('driveLink: $driveLink, ')
          ..write('clientRequirementsJson: $clientRequirementsJson, ')
          ..write('notes: $notes, ')
          ..write('chiefPhotographerUserId: $chiefPhotographerUserId, ')
          ..write('chiefHours: $chiefHours, ')
          ..write('hidePaymentFromTeam: $hidePaymentFromTeam, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClientsTableTable extends ClientsTable
    with TableInfo<$ClientsTableTable, ClientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _studioIdMeta = const VerificationMeta(
    'studioId',
  );
  @override
  late final GeneratedColumn<String> studioId = GeneratedColumn<String>(
    'studio_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dobMeta = const VerificationMeta('dob');
  @override
  late final GeneratedColumn<DateTime> dob = GeneratedColumn<DateTime>(
    'dob',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _anniversaryMeta = const VerificationMeta(
    'anniversary',
  );
  @override
  late final GeneratedColumn<DateTime> anniversary = GeneratedColumn<DateTime>(
    'anniversary',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    studioId,
    name,
    phone,
    email,
    address,
    dob,
    anniversary,
    createdAt,
    updatedAt,
    pending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clients_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClientRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('studio_id')) {
      context.handle(
        _studioIdMeta,
        studioId.isAcceptableOrUnknown(data['studio_id']!, _studioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studioIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('dob')) {
      context.handle(
        _dobMeta,
        dob.isAcceptableOrUnknown(data['dob']!, _dobMeta),
      );
    }
    if (data.containsKey('anniversary')) {
      context.handle(
        _anniversaryMeta,
        anniversary.isAcceptableOrUnknown(
          data['anniversary']!,
          _anniversaryMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {studioId, phone},
  ];
  @override
  ClientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClientRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      studioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}studio_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      dob: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dob'],
      ),
      anniversary: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}anniversary'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
    );
  }

  @override
  $ClientsTableTable createAlias(String alias) {
    return $ClientsTableTable(attachedDatabase, alias);
  }
}

class ClientRow extends DataClass implements Insertable<ClientRow> {
  final String id;
  final String? remoteId;
  final String studioId;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final DateTime? dob;
  final DateTime? anniversary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pending;
  const ClientRow({
    required this.id,
    this.remoteId,
    required this.studioId,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.dob,
    this.anniversary,
    required this.createdAt,
    required this.updatedAt,
    required this.pending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['studio_id'] = Variable<String>(studioId);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || dob != null) {
      map['dob'] = Variable<DateTime>(dob);
    }
    if (!nullToAbsent || anniversary != null) {
      map['anniversary'] = Variable<DateTime>(anniversary);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending'] = Variable<bool>(pending);
    return map;
  }

  ClientsTableCompanion toCompanion(bool nullToAbsent) {
    return ClientsTableCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      studioId: Value(studioId),
      name: Value(name),
      phone: Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      dob: dob == null && nullToAbsent ? const Value.absent() : Value(dob),
      anniversary: anniversary == null && nullToAbsent
          ? const Value.absent()
          : Value(anniversary),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      pending: Value(pending),
    );
  }

  factory ClientRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClientRow(
      id: serializer.fromJson<String>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      studioId: serializer.fromJson<String>(json['studioId']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      address: serializer.fromJson<String?>(json['address']),
      dob: serializer.fromJson<DateTime?>(json['dob']),
      anniversary: serializer.fromJson<DateTime?>(json['anniversary']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pending: serializer.fromJson<bool>(json['pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'studioId': serializer.toJson<String>(studioId),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'email': serializer.toJson<String?>(email),
      'address': serializer.toJson<String?>(address),
      'dob': serializer.toJson<DateTime?>(dob),
      'anniversary': serializer.toJson<DateTime?>(anniversary),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pending': serializer.toJson<bool>(pending),
    };
  }

  ClientRow copyWith({
    String? id,
    Value<String?> remoteId = const Value.absent(),
    String? studioId,
    String? name,
    String? phone,
    Value<String?> email = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<DateTime?> dob = const Value.absent(),
    Value<DateTime?> anniversary = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pending,
  }) => ClientRow(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    studioId: studioId ?? this.studioId,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email.present ? email.value : this.email,
    address: address.present ? address.value : this.address,
    dob: dob.present ? dob.value : this.dob,
    anniversary: anniversary.present ? anniversary.value : this.anniversary,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pending: pending ?? this.pending,
  );
  ClientRow copyWithCompanion(ClientsTableCompanion data) {
    return ClientRow(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      studioId: data.studioId.present ? data.studioId.value : this.studioId,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      dob: data.dob.present ? data.dob.value : this.dob,
      anniversary: data.anniversary.present
          ? data.anniversary.value
          : this.anniversary,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pending: data.pending.present ? data.pending.value : this.pending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClientRow(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('studioId: $studioId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('dob: $dob, ')
          ..write('anniversary: $anniversary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    studioId,
    name,
    phone,
    email,
    address,
    dob,
    anniversary,
    createdAt,
    updatedAt,
    pending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientRow &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.studioId == this.studioId &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.address == this.address &&
          other.dob == this.dob &&
          other.anniversary == this.anniversary &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.pending == this.pending);
}

class ClientsTableCompanion extends UpdateCompanion<ClientRow> {
  final Value<String> id;
  final Value<String?> remoteId;
  final Value<String> studioId;
  final Value<String> name;
  final Value<String> phone;
  final Value<String?> email;
  final Value<String?> address;
  final Value<DateTime?> dob;
  final Value<DateTime?> anniversary;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pending;
  final Value<int> rowid;
  const ClientsTableCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.studioId = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.dob = const Value.absent(),
    this.anniversary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientsTableCompanion.insert({
    required String id,
    this.remoteId = const Value.absent(),
    required String studioId,
    required String name,
    required String phone,
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.dob = const Value.absent(),
    this.anniversary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       studioId = Value(studioId),
       name = Value(name),
       phone = Value(phone);
  static Insertable<ClientRow> custom({
    Expression<String>? id,
    Expression<String>? remoteId,
    Expression<String>? studioId,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? address,
    Expression<DateTime>? dob,
    Expression<DateTime>? anniversary,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (studioId != null) 'studio_id': studioId,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (dob != null) 'dob': dob,
      if (anniversary != null) 'anniversary': anniversary,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pending != null) 'pending': pending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? remoteId,
    Value<String>? studioId,
    Value<String>? name,
    Value<String>? phone,
    Value<String?>? email,
    Value<String?>? address,
    Value<DateTime?>? dob,
    Value<DateTime?>? anniversary,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pending,
    Value<int>? rowid,
  }) {
    return ClientsTableCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      studioId: studioId ?? this.studioId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      dob: dob ?? this.dob,
      anniversary: anniversary ?? this.anniversary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (studioId.present) {
      map['studio_id'] = Variable<String>(studioId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (dob.present) {
      map['dob'] = Variable<DateTime>(dob.value);
    }
    if (anniversary.present) {
      map['anniversary'] = Variable<DateTime>(anniversary.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientsTableCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('studioId: $studioId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('dob: $dob, ')
          ..write('anniversary: $anniversary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssignmentsTableTable extends AssignmentsTable
    with TableInfo<$AssignmentsTableTable, AssignmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssignmentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookingIdMeta = const VerificationMeta(
    'bookingId',
  );
  @override
  late final GeneratedColumn<String> bookingId = GeneratedColumn<String>(
    'booking_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payoutMeta = const VerificationMeta('payout');
  @override
  late final GeneratedColumn<double> payout = GeneratedColumn<double>(
    'payout',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    bookingId,
    userId,
    role,
    payout,
    notes,
    createdAt,
    updatedAt,
    pending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assignments_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssignmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('booking_id')) {
      context.handle(
        _bookingIdMeta,
        bookingId.isAcceptableOrUnknown(data['booking_id']!, _bookingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookingIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('payout')) {
      context.handle(
        _payoutMeta,
        payout.isAcceptableOrUnknown(data['payout']!, _payoutMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssignmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssignmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      bookingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booking_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      payout: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}payout'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
    );
  }

  @override
  $AssignmentsTableTable createAlias(String alias) {
    return $AssignmentsTableTable(attachedDatabase, alias);
  }
}

class AssignmentRow extends DataClass implements Insertable<AssignmentRow> {
  final String id;
  final String? remoteId;
  final String bookingId;
  final String userId;
  final String role;
  final double payout;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pending;
  const AssignmentRow({
    required this.id,
    this.remoteId,
    required this.bookingId,
    required this.userId,
    required this.role,
    required this.payout,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.pending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['booking_id'] = Variable<String>(bookingId);
    map['user_id'] = Variable<String>(userId);
    map['role'] = Variable<String>(role);
    map['payout'] = Variable<double>(payout);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending'] = Variable<bool>(pending);
    return map;
  }

  AssignmentsTableCompanion toCompanion(bool nullToAbsent) {
    return AssignmentsTableCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      bookingId: Value(bookingId),
      userId: Value(userId),
      role: Value(role),
      payout: Value(payout),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      pending: Value(pending),
    );
  }

  factory AssignmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssignmentRow(
      id: serializer.fromJson<String>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      bookingId: serializer.fromJson<String>(json['bookingId']),
      userId: serializer.fromJson<String>(json['userId']),
      role: serializer.fromJson<String>(json['role']),
      payout: serializer.fromJson<double>(json['payout']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pending: serializer.fromJson<bool>(json['pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'bookingId': serializer.toJson<String>(bookingId),
      'userId': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
      'payout': serializer.toJson<double>(payout),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pending': serializer.toJson<bool>(pending),
    };
  }

  AssignmentRow copyWith({
    String? id,
    Value<String?> remoteId = const Value.absent(),
    String? bookingId,
    String? userId,
    String? role,
    double? payout,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pending,
  }) => AssignmentRow(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    bookingId: bookingId ?? this.bookingId,
    userId: userId ?? this.userId,
    role: role ?? this.role,
    payout: payout ?? this.payout,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pending: pending ?? this.pending,
  );
  AssignmentRow copyWithCompanion(AssignmentsTableCompanion data) {
    return AssignmentRow(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      bookingId: data.bookingId.present ? data.bookingId.value : this.bookingId,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      payout: data.payout.present ? data.payout.value : this.payout,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pending: data.pending.present ? data.pending.value : this.pending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssignmentRow(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('bookingId: $bookingId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('payout: $payout, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    bookingId,
    userId,
    role,
    payout,
    notes,
    createdAt,
    updatedAt,
    pending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssignmentRow &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.bookingId == this.bookingId &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.payout == this.payout &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.pending == this.pending);
}

class AssignmentsTableCompanion extends UpdateCompanion<AssignmentRow> {
  final Value<String> id;
  final Value<String?> remoteId;
  final Value<String> bookingId;
  final Value<String> userId;
  final Value<String> role;
  final Value<double> payout;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pending;
  final Value<int> rowid;
  const AssignmentsTableCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.bookingId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.payout = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssignmentsTableCompanion.insert({
    required String id,
    this.remoteId = const Value.absent(),
    required String bookingId,
    required String userId,
    required String role,
    this.payout = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookingId = Value(bookingId),
       userId = Value(userId),
       role = Value(role);
  static Insertable<AssignmentRow> custom({
    Expression<String>? id,
    Expression<String>? remoteId,
    Expression<String>? bookingId,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<double>? payout,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (bookingId != null) 'booking_id': bookingId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (payout != null) 'payout': payout,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pending != null) 'pending': pending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssignmentsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? remoteId,
    Value<String>? bookingId,
    Value<String>? userId,
    Value<String>? role,
    Value<double>? payout,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pending,
    Value<int>? rowid,
  }) {
    return AssignmentsTableCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      payout: payout ?? this.payout,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (bookingId.present) {
      map['booking_id'] = Variable<String>(bookingId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (payout.present) {
      map['payout'] = Variable<double>(payout.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssignmentsTableCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('bookingId: $bookingId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('payout: $payout, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTableTable extends PaymentsTable
    with TableInfo<$PaymentsTableTable, PaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookingIdMeta = const VerificationMeta(
    'bookingId',
  );
  @override
  late final GeneratedColumn<String> bookingId = GeneratedColumn<String>(
    'booking_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
    'paid_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    bookingId,
    kind,
    amount,
    method,
    note,
    paidAt,
    createdAt,
    updatedAt,
    pending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('booking_id')) {
      context.handle(
        _bookingIdMeta,
        bookingId.isAcceptableOrUnknown(data['booking_id']!, _bookingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookingIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('paid_at')) {
      context.handle(
        _paidAtMeta,
        paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      bookingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booking_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      paidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
    );
  }

  @override
  $PaymentsTableTable createAlias(String alias) {
    return $PaymentsTableTable(attachedDatabase, alias);
  }
}

class PaymentRow extends DataClass implements Insertable<PaymentRow> {
  final String id;
  final String? remoteId;
  final String bookingId;
  final String kind;
  final double amount;
  final String? method;
  final String? note;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pending;
  const PaymentRow({
    required this.id,
    this.remoteId,
    required this.bookingId,
    required this.kind,
    required this.amount,
    this.method,
    this.note,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
    required this.pending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['booking_id'] = Variable<String>(bookingId);
    map['kind'] = Variable<String>(kind);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || method != null) {
      map['method'] = Variable<String>(method);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || paidAt != null) {
      map['paid_at'] = Variable<DateTime>(paidAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending'] = Variable<bool>(pending);
    return map;
  }

  PaymentsTableCompanion toCompanion(bool nullToAbsent) {
    return PaymentsTableCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      bookingId: Value(bookingId),
      kind: Value(kind),
      amount: Value(amount),
      method: method == null && nullToAbsent
          ? const Value.absent()
          : Value(method),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      paidAt: paidAt == null && nullToAbsent
          ? const Value.absent()
          : Value(paidAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      pending: Value(pending),
    );
  }

  factory PaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentRow(
      id: serializer.fromJson<String>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      bookingId: serializer.fromJson<String>(json['bookingId']),
      kind: serializer.fromJson<String>(json['kind']),
      amount: serializer.fromJson<double>(json['amount']),
      method: serializer.fromJson<String?>(json['method']),
      note: serializer.fromJson<String?>(json['note']),
      paidAt: serializer.fromJson<DateTime?>(json['paidAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pending: serializer.fromJson<bool>(json['pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'bookingId': serializer.toJson<String>(bookingId),
      'kind': serializer.toJson<String>(kind),
      'amount': serializer.toJson<double>(amount),
      'method': serializer.toJson<String?>(method),
      'note': serializer.toJson<String?>(note),
      'paidAt': serializer.toJson<DateTime?>(paidAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pending': serializer.toJson<bool>(pending),
    };
  }

  PaymentRow copyWith({
    String? id,
    Value<String?> remoteId = const Value.absent(),
    String? bookingId,
    String? kind,
    double? amount,
    Value<String?> method = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<DateTime?> paidAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pending,
  }) => PaymentRow(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    bookingId: bookingId ?? this.bookingId,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    method: method.present ? method.value : this.method,
    note: note.present ? note.value : this.note,
    paidAt: paidAt.present ? paidAt.value : this.paidAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pending: pending ?? this.pending,
  );
  PaymentRow copyWithCompanion(PaymentsTableCompanion data) {
    return PaymentRow(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      bookingId: data.bookingId.present ? data.bookingId.value : this.bookingId,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      method: data.method.present ? data.method.value : this.method,
      note: data.note.present ? data.note.value : this.note,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pending: data.pending.present ? data.pending.value : this.pending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentRow(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('bookingId: $bookingId, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('note: $note, ')
          ..write('paidAt: $paidAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    bookingId,
    kind,
    amount,
    method,
    note,
    paidAt,
    createdAt,
    updatedAt,
    pending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentRow &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.bookingId == this.bookingId &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.method == this.method &&
          other.note == this.note &&
          other.paidAt == this.paidAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.pending == this.pending);
}

class PaymentsTableCompanion extends UpdateCompanion<PaymentRow> {
  final Value<String> id;
  final Value<String?> remoteId;
  final Value<String> bookingId;
  final Value<String> kind;
  final Value<double> amount;
  final Value<String?> method;
  final Value<String?> note;
  final Value<DateTime?> paidAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pending;
  final Value<int> rowid;
  const PaymentsTableCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.bookingId = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.method = const Value.absent(),
    this.note = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentsTableCompanion.insert({
    required String id,
    this.remoteId = const Value.absent(),
    required String bookingId,
    required String kind,
    required double amount,
    this.method = const Value.absent(),
    this.note = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookingId = Value(bookingId),
       kind = Value(kind),
       amount = Value(amount);
  static Insertable<PaymentRow> custom({
    Expression<String>? id,
    Expression<String>? remoteId,
    Expression<String>? bookingId,
    Expression<String>? kind,
    Expression<double>? amount,
    Expression<String>? method,
    Expression<String>? note,
    Expression<DateTime>? paidAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (bookingId != null) 'booking_id': bookingId,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (method != null) 'method': method,
      if (note != null) 'note': note,
      if (paidAt != null) 'paid_at': paidAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pending != null) 'pending': pending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? remoteId,
    Value<String>? bookingId,
    Value<String>? kind,
    Value<double>? amount,
    Value<String?>? method,
    Value<String?>? note,
    Value<DateTime?>? paidAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pending,
    Value<int>? rowid,
  }) {
    return PaymentsTableCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      bookingId: bookingId ?? this.bookingId,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      note: note ?? this.note,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (bookingId.present) {
      map['booking_id'] = Variable<String>(bookingId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsTableCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('bookingId: $bookingId, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('method: $method, ')
          ..write('note: $note, ')
          ..write('paidAt: $paidAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PackagesTableTable extends PackagesTable
    with TableInfo<$PackagesTableTable, PackageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PackagesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _studioIdMeta = const VerificationMeta(
    'studioId',
  );
  @override
  late final GeneratedColumn<String> studioId = GeneratedColumn<String>(
    'studio_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _basePriceMeta = const VerificationMeta(
    'basePrice',
  );
  @override
  late final GeneratedColumn<double> basePrice = GeneratedColumn<double>(
    'base_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountMeta = const VerificationMeta(
    'discount',
  );
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
    'discount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _coverageHoursMeta = const VerificationMeta(
    'coverageHours',
  );
  @override
  late final GeneratedColumn<double> coverageHours = GeneratedColumn<double>(
    'coverage_hours',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extraHourRateMeta = const VerificationMeta(
    'extraHourRate',
  );
  @override
  late final GeneratedColumn<double> extraHourRate = GeneratedColumn<double>(
    'extra_hour_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _printSizeMeta = const VerificationMeta(
    'printSize',
  );
  @override
  late final GeneratedColumn<String> printSize = GeneratedColumn<String>(
    'print_size',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _printQuantityMeta = const VerificationMeta(
    'printQuantity',
  );
  @override
  late final GeneratedColumn<int> printQuantity = GeneratedColumn<int>(
    'print_quantity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumTextMeta = const VerificationMeta(
    'albumText',
  );
  @override
  late final GeneratedColumn<String> albumText = GeneratedColumn<String>(
    'album_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deliveryMethodMeta = const VerificationMeta(
    'deliveryMethod',
  );
  @override
  late final GeneratedColumn<String> deliveryMethod = GeneratedColumn<String>(
    'delivery_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trailersPerEventMeta = const VerificationMeta(
    'trailersPerEvent',
  );
  @override
  late final GeneratedColumn<int> trailersPerEvent = GeneratedColumn<int>(
    'trailers_per_event',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fullVideosPerEventMeta =
      const VerificationMeta('fullVideosPerEvent');
  @override
  late final GeneratedColumn<int> fullVideosPerEvent = GeneratedColumn<int>(
    'full_videos_per_event',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemsJsonMeta = const VerificationMeta(
    'itemsJson',
  );
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
    'items_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inclusionsJsonMeta = const VerificationMeta(
    'inclusionsJson',
  );
  @override
  late final GeneratedColumn<String> inclusionsJson = GeneratedColumn<String>(
    'inclusions_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    studioId,
    name,
    basePrice,
    discount,
    coverageHours,
    extraHourRate,
    printSize,
    printQuantity,
    albumText,
    deliveryMethod,
    trailersPerEvent,
    fullVideosPerEvent,
    itemsJson,
    inclusionsJson,
    createdAt,
    updatedAt,
    pending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'packages_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PackageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('studio_id')) {
      context.handle(
        _studioIdMeta,
        studioId.isAcceptableOrUnknown(data['studio_id']!, _studioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studioIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('base_price')) {
      context.handle(
        _basePriceMeta,
        basePrice.isAcceptableOrUnknown(data['base_price']!, _basePriceMeta),
      );
    } else if (isInserting) {
      context.missing(_basePriceMeta);
    }
    if (data.containsKey('discount')) {
      context.handle(
        _discountMeta,
        discount.isAcceptableOrUnknown(data['discount']!, _discountMeta),
      );
    }
    if (data.containsKey('coverage_hours')) {
      context.handle(
        _coverageHoursMeta,
        coverageHours.isAcceptableOrUnknown(
          data['coverage_hours']!,
          _coverageHoursMeta,
        ),
      );
    }
    if (data.containsKey('extra_hour_rate')) {
      context.handle(
        _extraHourRateMeta,
        extraHourRate.isAcceptableOrUnknown(
          data['extra_hour_rate']!,
          _extraHourRateMeta,
        ),
      );
    }
    if (data.containsKey('print_size')) {
      context.handle(
        _printSizeMeta,
        printSize.isAcceptableOrUnknown(data['print_size']!, _printSizeMeta),
      );
    }
    if (data.containsKey('print_quantity')) {
      context.handle(
        _printQuantityMeta,
        printQuantity.isAcceptableOrUnknown(
          data['print_quantity']!,
          _printQuantityMeta,
        ),
      );
    }
    if (data.containsKey('album_text')) {
      context.handle(
        _albumTextMeta,
        albumText.isAcceptableOrUnknown(data['album_text']!, _albumTextMeta),
      );
    }
    if (data.containsKey('delivery_method')) {
      context.handle(
        _deliveryMethodMeta,
        deliveryMethod.isAcceptableOrUnknown(
          data['delivery_method']!,
          _deliveryMethodMeta,
        ),
      );
    }
    if (data.containsKey('trailers_per_event')) {
      context.handle(
        _trailersPerEventMeta,
        trailersPerEvent.isAcceptableOrUnknown(
          data['trailers_per_event']!,
          _trailersPerEventMeta,
        ),
      );
    }
    if (data.containsKey('full_videos_per_event')) {
      context.handle(
        _fullVideosPerEventMeta,
        fullVideosPerEvent.isAcceptableOrUnknown(
          data['full_videos_per_event']!,
          _fullVideosPerEventMeta,
        ),
      );
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
      );
    }
    if (data.containsKey('inclusions_json')) {
      context.handle(
        _inclusionsJsonMeta,
        inclusionsJson.isAcceptableOrUnknown(
          data['inclusions_json']!,
          _inclusionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PackageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PackageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      studioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}studio_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      basePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_price'],
      )!,
      discount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount'],
      )!,
      coverageHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}coverage_hours'],
      ),
      extraHourRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}extra_hour_rate'],
      ),
      printSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}print_size'],
      ),
      printQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}print_quantity'],
      ),
      albumText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_text'],
      ),
      deliveryMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_method'],
      ),
      trailersPerEvent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trailers_per_event'],
      ),
      fullVideosPerEvent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}full_videos_per_event'],
      ),
      itemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      ),
      inclusionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inclusions_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
    );
  }

  @override
  $PackagesTableTable createAlias(String alias) {
    return $PackagesTableTable(attachedDatabase, alias);
  }
}

class PackageRow extends DataClass implements Insertable<PackageRow> {
  final String id;
  final String? remoteId;
  final String studioId;
  final String name;
  final double basePrice;
  final double discount;
  final double? coverageHours;
  final double? extraHourRate;
  final String? printSize;
  final int? printQuantity;
  final String? albumText;
  final String? deliveryMethod;
  final int? trailersPerEvent;
  final int? fullVideosPerEvent;
  final String? itemsJson;
  final String? inclusionsJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pending;
  const PackageRow({
    required this.id,
    this.remoteId,
    required this.studioId,
    required this.name,
    required this.basePrice,
    required this.discount,
    this.coverageHours,
    this.extraHourRate,
    this.printSize,
    this.printQuantity,
    this.albumText,
    this.deliveryMethod,
    this.trailersPerEvent,
    this.fullVideosPerEvent,
    this.itemsJson,
    this.inclusionsJson,
    required this.createdAt,
    required this.updatedAt,
    required this.pending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['studio_id'] = Variable<String>(studioId);
    map['name'] = Variable<String>(name);
    map['base_price'] = Variable<double>(basePrice);
    map['discount'] = Variable<double>(discount);
    if (!nullToAbsent || coverageHours != null) {
      map['coverage_hours'] = Variable<double>(coverageHours);
    }
    if (!nullToAbsent || extraHourRate != null) {
      map['extra_hour_rate'] = Variable<double>(extraHourRate);
    }
    if (!nullToAbsent || printSize != null) {
      map['print_size'] = Variable<String>(printSize);
    }
    if (!nullToAbsent || printQuantity != null) {
      map['print_quantity'] = Variable<int>(printQuantity);
    }
    if (!nullToAbsent || albumText != null) {
      map['album_text'] = Variable<String>(albumText);
    }
    if (!nullToAbsent || deliveryMethod != null) {
      map['delivery_method'] = Variable<String>(deliveryMethod);
    }
    if (!nullToAbsent || trailersPerEvent != null) {
      map['trailers_per_event'] = Variable<int>(trailersPerEvent);
    }
    if (!nullToAbsent || fullVideosPerEvent != null) {
      map['full_videos_per_event'] = Variable<int>(fullVideosPerEvent);
    }
    if (!nullToAbsent || itemsJson != null) {
      map['items_json'] = Variable<String>(itemsJson);
    }
    if (!nullToAbsent || inclusionsJson != null) {
      map['inclusions_json'] = Variable<String>(inclusionsJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending'] = Variable<bool>(pending);
    return map;
  }

  PackagesTableCompanion toCompanion(bool nullToAbsent) {
    return PackagesTableCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      studioId: Value(studioId),
      name: Value(name),
      basePrice: Value(basePrice),
      discount: Value(discount),
      coverageHours: coverageHours == null && nullToAbsent
          ? const Value.absent()
          : Value(coverageHours),
      extraHourRate: extraHourRate == null && nullToAbsent
          ? const Value.absent()
          : Value(extraHourRate),
      printSize: printSize == null && nullToAbsent
          ? const Value.absent()
          : Value(printSize),
      printQuantity: printQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(printQuantity),
      albumText: albumText == null && nullToAbsent
          ? const Value.absent()
          : Value(albumText),
      deliveryMethod: deliveryMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryMethod),
      trailersPerEvent: trailersPerEvent == null && nullToAbsent
          ? const Value.absent()
          : Value(trailersPerEvent),
      fullVideosPerEvent: fullVideosPerEvent == null && nullToAbsent
          ? const Value.absent()
          : Value(fullVideosPerEvent),
      itemsJson: itemsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(itemsJson),
      inclusionsJson: inclusionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(inclusionsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      pending: Value(pending),
    );
  }

  factory PackageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PackageRow(
      id: serializer.fromJson<String>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      studioId: serializer.fromJson<String>(json['studioId']),
      name: serializer.fromJson<String>(json['name']),
      basePrice: serializer.fromJson<double>(json['basePrice']),
      discount: serializer.fromJson<double>(json['discount']),
      coverageHours: serializer.fromJson<double?>(json['coverageHours']),
      extraHourRate: serializer.fromJson<double?>(json['extraHourRate']),
      printSize: serializer.fromJson<String?>(json['printSize']),
      printQuantity: serializer.fromJson<int?>(json['printQuantity']),
      albumText: serializer.fromJson<String?>(json['albumText']),
      deliveryMethod: serializer.fromJson<String?>(json['deliveryMethod']),
      trailersPerEvent: serializer.fromJson<int?>(json['trailersPerEvent']),
      fullVideosPerEvent: serializer.fromJson<int?>(json['fullVideosPerEvent']),
      itemsJson: serializer.fromJson<String?>(json['itemsJson']),
      inclusionsJson: serializer.fromJson<String?>(json['inclusionsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pending: serializer.fromJson<bool>(json['pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'studioId': serializer.toJson<String>(studioId),
      'name': serializer.toJson<String>(name),
      'basePrice': serializer.toJson<double>(basePrice),
      'discount': serializer.toJson<double>(discount),
      'coverageHours': serializer.toJson<double?>(coverageHours),
      'extraHourRate': serializer.toJson<double?>(extraHourRate),
      'printSize': serializer.toJson<String?>(printSize),
      'printQuantity': serializer.toJson<int?>(printQuantity),
      'albumText': serializer.toJson<String?>(albumText),
      'deliveryMethod': serializer.toJson<String?>(deliveryMethod),
      'trailersPerEvent': serializer.toJson<int?>(trailersPerEvent),
      'fullVideosPerEvent': serializer.toJson<int?>(fullVideosPerEvent),
      'itemsJson': serializer.toJson<String?>(itemsJson),
      'inclusionsJson': serializer.toJson<String?>(inclusionsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pending': serializer.toJson<bool>(pending),
    };
  }

  PackageRow copyWith({
    String? id,
    Value<String?> remoteId = const Value.absent(),
    String? studioId,
    String? name,
    double? basePrice,
    double? discount,
    Value<double?> coverageHours = const Value.absent(),
    Value<double?> extraHourRate = const Value.absent(),
    Value<String?> printSize = const Value.absent(),
    Value<int?> printQuantity = const Value.absent(),
    Value<String?> albumText = const Value.absent(),
    Value<String?> deliveryMethod = const Value.absent(),
    Value<int?> trailersPerEvent = const Value.absent(),
    Value<int?> fullVideosPerEvent = const Value.absent(),
    Value<String?> itemsJson = const Value.absent(),
    Value<String?> inclusionsJson = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pending,
  }) => PackageRow(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    studioId: studioId ?? this.studioId,
    name: name ?? this.name,
    basePrice: basePrice ?? this.basePrice,
    discount: discount ?? this.discount,
    coverageHours: coverageHours.present
        ? coverageHours.value
        : this.coverageHours,
    extraHourRate: extraHourRate.present
        ? extraHourRate.value
        : this.extraHourRate,
    printSize: printSize.present ? printSize.value : this.printSize,
    printQuantity: printQuantity.present
        ? printQuantity.value
        : this.printQuantity,
    albumText: albumText.present ? albumText.value : this.albumText,
    deliveryMethod: deliveryMethod.present
        ? deliveryMethod.value
        : this.deliveryMethod,
    trailersPerEvent: trailersPerEvent.present
        ? trailersPerEvent.value
        : this.trailersPerEvent,
    fullVideosPerEvent: fullVideosPerEvent.present
        ? fullVideosPerEvent.value
        : this.fullVideosPerEvent,
    itemsJson: itemsJson.present ? itemsJson.value : this.itemsJson,
    inclusionsJson: inclusionsJson.present
        ? inclusionsJson.value
        : this.inclusionsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pending: pending ?? this.pending,
  );
  PackageRow copyWithCompanion(PackagesTableCompanion data) {
    return PackageRow(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      studioId: data.studioId.present ? data.studioId.value : this.studioId,
      name: data.name.present ? data.name.value : this.name,
      basePrice: data.basePrice.present ? data.basePrice.value : this.basePrice,
      discount: data.discount.present ? data.discount.value : this.discount,
      coverageHours: data.coverageHours.present
          ? data.coverageHours.value
          : this.coverageHours,
      extraHourRate: data.extraHourRate.present
          ? data.extraHourRate.value
          : this.extraHourRate,
      printSize: data.printSize.present ? data.printSize.value : this.printSize,
      printQuantity: data.printQuantity.present
          ? data.printQuantity.value
          : this.printQuantity,
      albumText: data.albumText.present ? data.albumText.value : this.albumText,
      deliveryMethod: data.deliveryMethod.present
          ? data.deliveryMethod.value
          : this.deliveryMethod,
      trailersPerEvent: data.trailersPerEvent.present
          ? data.trailersPerEvent.value
          : this.trailersPerEvent,
      fullVideosPerEvent: data.fullVideosPerEvent.present
          ? data.fullVideosPerEvent.value
          : this.fullVideosPerEvent,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      inclusionsJson: data.inclusionsJson.present
          ? data.inclusionsJson.value
          : this.inclusionsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pending: data.pending.present ? data.pending.value : this.pending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PackageRow(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('studioId: $studioId, ')
          ..write('name: $name, ')
          ..write('basePrice: $basePrice, ')
          ..write('discount: $discount, ')
          ..write('coverageHours: $coverageHours, ')
          ..write('extraHourRate: $extraHourRate, ')
          ..write('printSize: $printSize, ')
          ..write('printQuantity: $printQuantity, ')
          ..write('albumText: $albumText, ')
          ..write('deliveryMethod: $deliveryMethod, ')
          ..write('trailersPerEvent: $trailersPerEvent, ')
          ..write('fullVideosPerEvent: $fullVideosPerEvent, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('inclusionsJson: $inclusionsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    studioId,
    name,
    basePrice,
    discount,
    coverageHours,
    extraHourRate,
    printSize,
    printQuantity,
    albumText,
    deliveryMethod,
    trailersPerEvent,
    fullVideosPerEvent,
    itemsJson,
    inclusionsJson,
    createdAt,
    updatedAt,
    pending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PackageRow &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.studioId == this.studioId &&
          other.name == this.name &&
          other.basePrice == this.basePrice &&
          other.discount == this.discount &&
          other.coverageHours == this.coverageHours &&
          other.extraHourRate == this.extraHourRate &&
          other.printSize == this.printSize &&
          other.printQuantity == this.printQuantity &&
          other.albumText == this.albumText &&
          other.deliveryMethod == this.deliveryMethod &&
          other.trailersPerEvent == this.trailersPerEvent &&
          other.fullVideosPerEvent == this.fullVideosPerEvent &&
          other.itemsJson == this.itemsJson &&
          other.inclusionsJson == this.inclusionsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.pending == this.pending);
}

class PackagesTableCompanion extends UpdateCompanion<PackageRow> {
  final Value<String> id;
  final Value<String?> remoteId;
  final Value<String> studioId;
  final Value<String> name;
  final Value<double> basePrice;
  final Value<double> discount;
  final Value<double?> coverageHours;
  final Value<double?> extraHourRate;
  final Value<String?> printSize;
  final Value<int?> printQuantity;
  final Value<String?> albumText;
  final Value<String?> deliveryMethod;
  final Value<int?> trailersPerEvent;
  final Value<int?> fullVideosPerEvent;
  final Value<String?> itemsJson;
  final Value<String?> inclusionsJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pending;
  final Value<int> rowid;
  const PackagesTableCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.studioId = const Value.absent(),
    this.name = const Value.absent(),
    this.basePrice = const Value.absent(),
    this.discount = const Value.absent(),
    this.coverageHours = const Value.absent(),
    this.extraHourRate = const Value.absent(),
    this.printSize = const Value.absent(),
    this.printQuantity = const Value.absent(),
    this.albumText = const Value.absent(),
    this.deliveryMethod = const Value.absent(),
    this.trailersPerEvent = const Value.absent(),
    this.fullVideosPerEvent = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.inclusionsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PackagesTableCompanion.insert({
    required String id,
    this.remoteId = const Value.absent(),
    required String studioId,
    required String name,
    required double basePrice,
    this.discount = const Value.absent(),
    this.coverageHours = const Value.absent(),
    this.extraHourRate = const Value.absent(),
    this.printSize = const Value.absent(),
    this.printQuantity = const Value.absent(),
    this.albumText = const Value.absent(),
    this.deliveryMethod = const Value.absent(),
    this.trailersPerEvent = const Value.absent(),
    this.fullVideosPerEvent = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.inclusionsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       studioId = Value(studioId),
       name = Value(name),
       basePrice = Value(basePrice);
  static Insertable<PackageRow> custom({
    Expression<String>? id,
    Expression<String>? remoteId,
    Expression<String>? studioId,
    Expression<String>? name,
    Expression<double>? basePrice,
    Expression<double>? discount,
    Expression<double>? coverageHours,
    Expression<double>? extraHourRate,
    Expression<String>? printSize,
    Expression<int>? printQuantity,
    Expression<String>? albumText,
    Expression<String>? deliveryMethod,
    Expression<int>? trailersPerEvent,
    Expression<int>? fullVideosPerEvent,
    Expression<String>? itemsJson,
    Expression<String>? inclusionsJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (studioId != null) 'studio_id': studioId,
      if (name != null) 'name': name,
      if (basePrice != null) 'base_price': basePrice,
      if (discount != null) 'discount': discount,
      if (coverageHours != null) 'coverage_hours': coverageHours,
      if (extraHourRate != null) 'extra_hour_rate': extraHourRate,
      if (printSize != null) 'print_size': printSize,
      if (printQuantity != null) 'print_quantity': printQuantity,
      if (albumText != null) 'album_text': albumText,
      if (deliveryMethod != null) 'delivery_method': deliveryMethod,
      if (trailersPerEvent != null) 'trailers_per_event': trailersPerEvent,
      if (fullVideosPerEvent != null)
        'full_videos_per_event': fullVideosPerEvent,
      if (itemsJson != null) 'items_json': itemsJson,
      if (inclusionsJson != null) 'inclusions_json': inclusionsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pending != null) 'pending': pending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PackagesTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? remoteId,
    Value<String>? studioId,
    Value<String>? name,
    Value<double>? basePrice,
    Value<double>? discount,
    Value<double?>? coverageHours,
    Value<double?>? extraHourRate,
    Value<String?>? printSize,
    Value<int?>? printQuantity,
    Value<String?>? albumText,
    Value<String?>? deliveryMethod,
    Value<int?>? trailersPerEvent,
    Value<int?>? fullVideosPerEvent,
    Value<String?>? itemsJson,
    Value<String?>? inclusionsJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pending,
    Value<int>? rowid,
  }) {
    return PackagesTableCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      studioId: studioId ?? this.studioId,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      discount: discount ?? this.discount,
      coverageHours: coverageHours ?? this.coverageHours,
      extraHourRate: extraHourRate ?? this.extraHourRate,
      printSize: printSize ?? this.printSize,
      printQuantity: printQuantity ?? this.printQuantity,
      albumText: albumText ?? this.albumText,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      trailersPerEvent: trailersPerEvent ?? this.trailersPerEvent,
      fullVideosPerEvent: fullVideosPerEvent ?? this.fullVideosPerEvent,
      itemsJson: itemsJson ?? this.itemsJson,
      inclusionsJson: inclusionsJson ?? this.inclusionsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (studioId.present) {
      map['studio_id'] = Variable<String>(studioId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (basePrice.present) {
      map['base_price'] = Variable<double>(basePrice.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (coverageHours.present) {
      map['coverage_hours'] = Variable<double>(coverageHours.value);
    }
    if (extraHourRate.present) {
      map['extra_hour_rate'] = Variable<double>(extraHourRate.value);
    }
    if (printSize.present) {
      map['print_size'] = Variable<String>(printSize.value);
    }
    if (printQuantity.present) {
      map['print_quantity'] = Variable<int>(printQuantity.value);
    }
    if (albumText.present) {
      map['album_text'] = Variable<String>(albumText.value);
    }
    if (deliveryMethod.present) {
      map['delivery_method'] = Variable<String>(deliveryMethod.value);
    }
    if (trailersPerEvent.present) {
      map['trailers_per_event'] = Variable<int>(trailersPerEvent.value);
    }
    if (fullVideosPerEvent.present) {
      map['full_videos_per_event'] = Variable<int>(fullVideosPerEvent.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (inclusionsJson.present) {
      map['inclusions_json'] = Variable<String>(inclusionsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PackagesTableCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('studioId: $studioId, ')
          ..write('name: $name, ')
          ..write('basePrice: $basePrice, ')
          ..write('discount: $discount, ')
          ..write('coverageHours: $coverageHours, ')
          ..write('extraHourRate: $extraHourRate, ')
          ..write('printSize: $printSize, ')
          ..write('printQuantity: $printQuantity, ')
          ..write('albumText: $albumText, ')
          ..write('deliveryMethod: $deliveryMethod, ')
          ..write('trailersPerEvent: $trailersPerEvent, ')
          ..write('fullVideosPerEvent: $fullVideosPerEvent, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('inclusionsJson: $inclusionsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StatusHistoryTableTable extends StatusHistoryTable
    with TableInfo<$StatusHistoryTableTable, StatusHistoryEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StatusHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookingIdMeta = const VerificationMeta(
    'bookingId',
  );
  @override
  late final GeneratedColumn<String> bookingId = GeneratedColumn<String>(
    'booking_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromStatusMeta = const VerificationMeta(
    'fromStatus',
  );
  @override
  late final GeneratedColumn<String> fromStatus = GeneratedColumn<String>(
    'from_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toStatusMeta = const VerificationMeta(
    'toStatus',
  );
  @override
  late final GeneratedColumn<String> toStatus = GeneratedColumn<String>(
    'to_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changedByUserIdMeta = const VerificationMeta(
    'changedByUserId',
  );
  @override
  late final GeneratedColumn<String> changedByUserId = GeneratedColumn<String>(
    'changed_by_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    bookingId,
    fromStatus,
    toStatus,
    changedByUserId,
    note,
    at,
    pending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'status_history_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<StatusHistoryEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('booking_id')) {
      context.handle(
        _bookingIdMeta,
        bookingId.isAcceptableOrUnknown(data['booking_id']!, _bookingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookingIdMeta);
    }
    if (data.containsKey('from_status')) {
      context.handle(
        _fromStatusMeta,
        fromStatus.isAcceptableOrUnknown(data['from_status']!, _fromStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_fromStatusMeta);
    }
    if (data.containsKey('to_status')) {
      context.handle(
        _toStatusMeta,
        toStatus.isAcceptableOrUnknown(data['to_status']!, _toStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_toStatusMeta);
    }
    if (data.containsKey('changed_by_user_id')) {
      context.handle(
        _changedByUserIdMeta,
        changedByUserId.isAcceptableOrUnknown(
          data['changed_by_user_id']!,
          _changedByUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changedByUserIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StatusHistoryEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StatusHistoryEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      bookingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booking_id'],
      )!,
      fromStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_status'],
      )!,
      toStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_status'],
      )!,
      changedByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}changed_by_user_id'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
    );
  }

  @override
  $StatusHistoryTableTable createAlias(String alias) {
    return $StatusHistoryTableTable(attachedDatabase, alias);
  }
}

class StatusHistoryEntryRow extends DataClass
    implements Insertable<StatusHistoryEntryRow> {
  final String id;
  final String? remoteId;
  final String bookingId;
  final String fromStatus;
  final String toStatus;
  final String changedByUserId;
  final String? note;
  final DateTime at;
  final bool pending;
  const StatusHistoryEntryRow({
    required this.id,
    this.remoteId,
    required this.bookingId,
    required this.fromStatus,
    required this.toStatus,
    required this.changedByUserId,
    this.note,
    required this.at,
    required this.pending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['booking_id'] = Variable<String>(bookingId);
    map['from_status'] = Variable<String>(fromStatus);
    map['to_status'] = Variable<String>(toStatus);
    map['changed_by_user_id'] = Variable<String>(changedByUserId);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['at'] = Variable<DateTime>(at);
    map['pending'] = Variable<bool>(pending);
    return map;
  }

  StatusHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return StatusHistoryTableCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      bookingId: Value(bookingId),
      fromStatus: Value(fromStatus),
      toStatus: Value(toStatus),
      changedByUserId: Value(changedByUserId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      at: Value(at),
      pending: Value(pending),
    );
  }

  factory StatusHistoryEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StatusHistoryEntryRow(
      id: serializer.fromJson<String>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      bookingId: serializer.fromJson<String>(json['bookingId']),
      fromStatus: serializer.fromJson<String>(json['fromStatus']),
      toStatus: serializer.fromJson<String>(json['toStatus']),
      changedByUserId: serializer.fromJson<String>(json['changedByUserId']),
      note: serializer.fromJson<String?>(json['note']),
      at: serializer.fromJson<DateTime>(json['at']),
      pending: serializer.fromJson<bool>(json['pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'bookingId': serializer.toJson<String>(bookingId),
      'fromStatus': serializer.toJson<String>(fromStatus),
      'toStatus': serializer.toJson<String>(toStatus),
      'changedByUserId': serializer.toJson<String>(changedByUserId),
      'note': serializer.toJson<String?>(note),
      'at': serializer.toJson<DateTime>(at),
      'pending': serializer.toJson<bool>(pending),
    };
  }

  StatusHistoryEntryRow copyWith({
    String? id,
    Value<String?> remoteId = const Value.absent(),
    String? bookingId,
    String? fromStatus,
    String? toStatus,
    String? changedByUserId,
    Value<String?> note = const Value.absent(),
    DateTime? at,
    bool? pending,
  }) => StatusHistoryEntryRow(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    bookingId: bookingId ?? this.bookingId,
    fromStatus: fromStatus ?? this.fromStatus,
    toStatus: toStatus ?? this.toStatus,
    changedByUserId: changedByUserId ?? this.changedByUserId,
    note: note.present ? note.value : this.note,
    at: at ?? this.at,
    pending: pending ?? this.pending,
  );
  StatusHistoryEntryRow copyWithCompanion(StatusHistoryTableCompanion data) {
    return StatusHistoryEntryRow(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      bookingId: data.bookingId.present ? data.bookingId.value : this.bookingId,
      fromStatus: data.fromStatus.present
          ? data.fromStatus.value
          : this.fromStatus,
      toStatus: data.toStatus.present ? data.toStatus.value : this.toStatus,
      changedByUserId: data.changedByUserId.present
          ? data.changedByUserId.value
          : this.changedByUserId,
      note: data.note.present ? data.note.value : this.note,
      at: data.at.present ? data.at.value : this.at,
      pending: data.pending.present ? data.pending.value : this.pending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StatusHistoryEntryRow(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('bookingId: $bookingId, ')
          ..write('fromStatus: $fromStatus, ')
          ..write('toStatus: $toStatus, ')
          ..write('changedByUserId: $changedByUserId, ')
          ..write('note: $note, ')
          ..write('at: $at, ')
          ..write('pending: $pending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    bookingId,
    fromStatus,
    toStatus,
    changedByUserId,
    note,
    at,
    pending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StatusHistoryEntryRow &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.bookingId == this.bookingId &&
          other.fromStatus == this.fromStatus &&
          other.toStatus == this.toStatus &&
          other.changedByUserId == this.changedByUserId &&
          other.note == this.note &&
          other.at == this.at &&
          other.pending == this.pending);
}

class StatusHistoryTableCompanion
    extends UpdateCompanion<StatusHistoryEntryRow> {
  final Value<String> id;
  final Value<String?> remoteId;
  final Value<String> bookingId;
  final Value<String> fromStatus;
  final Value<String> toStatus;
  final Value<String> changedByUserId;
  final Value<String?> note;
  final Value<DateTime> at;
  final Value<bool> pending;
  final Value<int> rowid;
  const StatusHistoryTableCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.bookingId = const Value.absent(),
    this.fromStatus = const Value.absent(),
    this.toStatus = const Value.absent(),
    this.changedByUserId = const Value.absent(),
    this.note = const Value.absent(),
    this.at = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StatusHistoryTableCompanion.insert({
    required String id,
    this.remoteId = const Value.absent(),
    required String bookingId,
    required String fromStatus,
    required String toStatus,
    required String changedByUserId,
    this.note = const Value.absent(),
    required DateTime at,
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookingId = Value(bookingId),
       fromStatus = Value(fromStatus),
       toStatus = Value(toStatus),
       changedByUserId = Value(changedByUserId),
       at = Value(at);
  static Insertable<StatusHistoryEntryRow> custom({
    Expression<String>? id,
    Expression<String>? remoteId,
    Expression<String>? bookingId,
    Expression<String>? fromStatus,
    Expression<String>? toStatus,
    Expression<String>? changedByUserId,
    Expression<String>? note,
    Expression<DateTime>? at,
    Expression<bool>? pending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (bookingId != null) 'booking_id': bookingId,
      if (fromStatus != null) 'from_status': fromStatus,
      if (toStatus != null) 'to_status': toStatus,
      if (changedByUserId != null) 'changed_by_user_id': changedByUserId,
      if (note != null) 'note': note,
      if (at != null) 'at': at,
      if (pending != null) 'pending': pending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StatusHistoryTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? remoteId,
    Value<String>? bookingId,
    Value<String>? fromStatus,
    Value<String>? toStatus,
    Value<String>? changedByUserId,
    Value<String?>? note,
    Value<DateTime>? at,
    Value<bool>? pending,
    Value<int>? rowid,
  }) {
    return StatusHistoryTableCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      bookingId: bookingId ?? this.bookingId,
      fromStatus: fromStatus ?? this.fromStatus,
      toStatus: toStatus ?? this.toStatus,
      changedByUserId: changedByUserId ?? this.changedByUserId,
      note: note ?? this.note,
      at: at ?? this.at,
      pending: pending ?? this.pending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (bookingId.present) {
      map['booking_id'] = Variable<String>(bookingId.value);
    }
    if (fromStatus.present) {
      map['from_status'] = Variable<String>(fromStatus.value);
    }
    if (toStatus.present) {
      map['to_status'] = Variable<String>(toStatus.value);
    }
    if (changedByUserId.present) {
      map['changed_by_user_id'] = Variable<String>(changedByUserId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StatusHistoryTableCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('bookingId: $bookingId, ')
          ..write('fromStatus: $fromStatus, ')
          ..write('toStatus: $toStatus, ')
          ..write('changedByUserId: $changedByUserId, ')
          ..write('note: $note, ')
          ..write('at: $at, ')
          ..write('pending: $pending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReEditRequestsTableTable extends ReEditRequestsTable
    with TableInfo<$ReEditRequestsTableTable, ReEditRequestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReEditRequestsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookingIdMeta = const VerificationMeta(
    'bookingId',
  );
  @override
  late final GeneratedColumn<String> bookingId = GeneratedColumn<String>(
    'booking_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundMeta = const VerificationMeta('round');
  @override
  late final GeneratedColumn<int> round = GeneratedColumn<int>(
    'round',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editorUserIdMeta = const VerificationMeta(
    'editorUserId',
  );
  @override
  late final GeneratedColumn<String> editorUserId = GeneratedColumn<String>(
    'editor_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
    'deadline',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceImageUrlsJsonMeta =
      const VerificationMeta('referenceImageUrlsJson');
  @override
  late final GeneratedColumn<String> referenceImageUrlsJson =
      GeneratedColumn<String>(
        'reference_image_urls_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _requestedByUserIdMeta = const VerificationMeta(
    'requestedByUserId',
  );
  @override
  late final GeneratedColumn<String> requestedByUserId =
      GeneratedColumn<String>(
        'requested_by_user_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _requestedAtMeta = const VerificationMeta(
    'requestedAt',
  );
  @override
  late final GeneratedColumn<DateTime> requestedAt = GeneratedColumn<DateTime>(
    'requested_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    bookingId,
    round,
    editorUserId,
    deadline,
    referenceImageUrlsJson,
    notes,
    status,
    requestedByUserId,
    requestedAt,
    updatedAt,
    pending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 're_edit_requests_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReEditRequestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('booking_id')) {
      context.handle(
        _bookingIdMeta,
        bookingId.isAcceptableOrUnknown(data['booking_id']!, _bookingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookingIdMeta);
    }
    if (data.containsKey('round')) {
      context.handle(
        _roundMeta,
        round.isAcceptableOrUnknown(data['round']!, _roundMeta),
      );
    } else if (isInserting) {
      context.missing(_roundMeta);
    }
    if (data.containsKey('editor_user_id')) {
      context.handle(
        _editorUserIdMeta,
        editorUserId.isAcceptableOrUnknown(
          data['editor_user_id']!,
          _editorUserIdMeta,
        ),
      );
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    } else if (isInserting) {
      context.missing(_deadlineMeta);
    }
    if (data.containsKey('reference_image_urls_json')) {
      context.handle(
        _referenceImageUrlsJsonMeta,
        referenceImageUrlsJson.isAcceptableOrUnknown(
          data['reference_image_urls_json']!,
          _referenceImageUrlsJsonMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('requested_by_user_id')) {
      context.handle(
        _requestedByUserIdMeta,
        requestedByUserId.isAcceptableOrUnknown(
          data['requested_by_user_id']!,
          _requestedByUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestedByUserIdMeta);
    }
    if (data.containsKey('requested_at')) {
      context.handle(
        _requestedAtMeta,
        requestedAt.isAcceptableOrUnknown(
          data['requested_at']!,
          _requestedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {bookingId, round},
  ];
  @override
  ReEditRequestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReEditRequestRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      bookingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booking_id'],
      )!,
      round: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round'],
      )!,
      editorUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}editor_user_id'],
      ),
      deadline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deadline'],
      )!,
      referenceImageUrlsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_image_urls_json'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      requestedByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requested_by_user_id'],
      )!,
      requestedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}requested_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
    );
  }

  @override
  $ReEditRequestsTableTable createAlias(String alias) {
    return $ReEditRequestsTableTable(attachedDatabase, alias);
  }
}

class ReEditRequestRow extends DataClass
    implements Insertable<ReEditRequestRow> {
  final String id;
  final String? remoteId;
  final String bookingId;
  final int round;
  final String? editorUserId;
  final DateTime deadline;
  final String? referenceImageUrlsJson;
  final String? notes;
  final String status;
  final String requestedByUserId;
  final DateTime requestedAt;
  final DateTime updatedAt;
  final bool pending;
  const ReEditRequestRow({
    required this.id,
    this.remoteId,
    required this.bookingId,
    required this.round,
    this.editorUserId,
    required this.deadline,
    this.referenceImageUrlsJson,
    this.notes,
    required this.status,
    required this.requestedByUserId,
    required this.requestedAt,
    required this.updatedAt,
    required this.pending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['booking_id'] = Variable<String>(bookingId);
    map['round'] = Variable<int>(round);
    if (!nullToAbsent || editorUserId != null) {
      map['editor_user_id'] = Variable<String>(editorUserId);
    }
    map['deadline'] = Variable<DateTime>(deadline);
    if (!nullToAbsent || referenceImageUrlsJson != null) {
      map['reference_image_urls_json'] = Variable<String>(
        referenceImageUrlsJson,
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['status'] = Variable<String>(status);
    map['requested_by_user_id'] = Variable<String>(requestedByUserId);
    map['requested_at'] = Variable<DateTime>(requestedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending'] = Variable<bool>(pending);
    return map;
  }

  ReEditRequestsTableCompanion toCompanion(bool nullToAbsent) {
    return ReEditRequestsTableCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      bookingId: Value(bookingId),
      round: Value(round),
      editorUserId: editorUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(editorUserId),
      deadline: Value(deadline),
      referenceImageUrlsJson: referenceImageUrlsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceImageUrlsJson),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
      requestedByUserId: Value(requestedByUserId),
      requestedAt: Value(requestedAt),
      updatedAt: Value(updatedAt),
      pending: Value(pending),
    );
  }

  factory ReEditRequestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReEditRequestRow(
      id: serializer.fromJson<String>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      bookingId: serializer.fromJson<String>(json['bookingId']),
      round: serializer.fromJson<int>(json['round']),
      editorUserId: serializer.fromJson<String?>(json['editorUserId']),
      deadline: serializer.fromJson<DateTime>(json['deadline']),
      referenceImageUrlsJson: serializer.fromJson<String?>(
        json['referenceImageUrlsJson'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      status: serializer.fromJson<String>(json['status']),
      requestedByUserId: serializer.fromJson<String>(json['requestedByUserId']),
      requestedAt: serializer.fromJson<DateTime>(json['requestedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pending: serializer.fromJson<bool>(json['pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'bookingId': serializer.toJson<String>(bookingId),
      'round': serializer.toJson<int>(round),
      'editorUserId': serializer.toJson<String?>(editorUserId),
      'deadline': serializer.toJson<DateTime>(deadline),
      'referenceImageUrlsJson': serializer.toJson<String?>(
        referenceImageUrlsJson,
      ),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<String>(status),
      'requestedByUserId': serializer.toJson<String>(requestedByUserId),
      'requestedAt': serializer.toJson<DateTime>(requestedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pending': serializer.toJson<bool>(pending),
    };
  }

  ReEditRequestRow copyWith({
    String? id,
    Value<String?> remoteId = const Value.absent(),
    String? bookingId,
    int? round,
    Value<String?> editorUserId = const Value.absent(),
    DateTime? deadline,
    Value<String?> referenceImageUrlsJson = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? status,
    String? requestedByUserId,
    DateTime? requestedAt,
    DateTime? updatedAt,
    bool? pending,
  }) => ReEditRequestRow(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    bookingId: bookingId ?? this.bookingId,
    round: round ?? this.round,
    editorUserId: editorUserId.present ? editorUserId.value : this.editorUserId,
    deadline: deadline ?? this.deadline,
    referenceImageUrlsJson: referenceImageUrlsJson.present
        ? referenceImageUrlsJson.value
        : this.referenceImageUrlsJson,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
    requestedByUserId: requestedByUserId ?? this.requestedByUserId,
    requestedAt: requestedAt ?? this.requestedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pending: pending ?? this.pending,
  );
  ReEditRequestRow copyWithCompanion(ReEditRequestsTableCompanion data) {
    return ReEditRequestRow(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      bookingId: data.bookingId.present ? data.bookingId.value : this.bookingId,
      round: data.round.present ? data.round.value : this.round,
      editorUserId: data.editorUserId.present
          ? data.editorUserId.value
          : this.editorUserId,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      referenceImageUrlsJson: data.referenceImageUrlsJson.present
          ? data.referenceImageUrlsJson.value
          : this.referenceImageUrlsJson,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      requestedByUserId: data.requestedByUserId.present
          ? data.requestedByUserId.value
          : this.requestedByUserId,
      requestedAt: data.requestedAt.present
          ? data.requestedAt.value
          : this.requestedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pending: data.pending.present ? data.pending.value : this.pending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReEditRequestRow(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('bookingId: $bookingId, ')
          ..write('round: $round, ')
          ..write('editorUserId: $editorUserId, ')
          ..write('deadline: $deadline, ')
          ..write('referenceImageUrlsJson: $referenceImageUrlsJson, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('requestedByUserId: $requestedByUserId, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    bookingId,
    round,
    editorUserId,
    deadline,
    referenceImageUrlsJson,
    notes,
    status,
    requestedByUserId,
    requestedAt,
    updatedAt,
    pending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReEditRequestRow &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.bookingId == this.bookingId &&
          other.round == this.round &&
          other.editorUserId == this.editorUserId &&
          other.deadline == this.deadline &&
          other.referenceImageUrlsJson == this.referenceImageUrlsJson &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.requestedByUserId == this.requestedByUserId &&
          other.requestedAt == this.requestedAt &&
          other.updatedAt == this.updatedAt &&
          other.pending == this.pending);
}

class ReEditRequestsTableCompanion extends UpdateCompanion<ReEditRequestRow> {
  final Value<String> id;
  final Value<String?> remoteId;
  final Value<String> bookingId;
  final Value<int> round;
  final Value<String?> editorUserId;
  final Value<DateTime> deadline;
  final Value<String?> referenceImageUrlsJson;
  final Value<String?> notes;
  final Value<String> status;
  final Value<String> requestedByUserId;
  final Value<DateTime> requestedAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pending;
  final Value<int> rowid;
  const ReEditRequestsTableCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.bookingId = const Value.absent(),
    this.round = const Value.absent(),
    this.editorUserId = const Value.absent(),
    this.deadline = const Value.absent(),
    this.referenceImageUrlsJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.requestedByUserId = const Value.absent(),
    this.requestedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReEditRequestsTableCompanion.insert({
    required String id,
    this.remoteId = const Value.absent(),
    required String bookingId,
    required int round,
    this.editorUserId = const Value.absent(),
    required DateTime deadline,
    this.referenceImageUrlsJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    required String requestedByUserId,
    this.requestedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookingId = Value(bookingId),
       round = Value(round),
       deadline = Value(deadline),
       requestedByUserId = Value(requestedByUserId);
  static Insertable<ReEditRequestRow> custom({
    Expression<String>? id,
    Expression<String>? remoteId,
    Expression<String>? bookingId,
    Expression<int>? round,
    Expression<String>? editorUserId,
    Expression<DateTime>? deadline,
    Expression<String>? referenceImageUrlsJson,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<String>? requestedByUserId,
    Expression<DateTime>? requestedAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (bookingId != null) 'booking_id': bookingId,
      if (round != null) 'round': round,
      if (editorUserId != null) 'editor_user_id': editorUserId,
      if (deadline != null) 'deadline': deadline,
      if (referenceImageUrlsJson != null)
        'reference_image_urls_json': referenceImageUrlsJson,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (requestedByUserId != null) 'requested_by_user_id': requestedByUserId,
      if (requestedAt != null) 'requested_at': requestedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pending != null) 'pending': pending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReEditRequestsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? remoteId,
    Value<String>? bookingId,
    Value<int>? round,
    Value<String?>? editorUserId,
    Value<DateTime>? deadline,
    Value<String?>? referenceImageUrlsJson,
    Value<String?>? notes,
    Value<String>? status,
    Value<String>? requestedByUserId,
    Value<DateTime>? requestedAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pending,
    Value<int>? rowid,
  }) {
    return ReEditRequestsTableCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      bookingId: bookingId ?? this.bookingId,
      round: round ?? this.round,
      editorUserId: editorUserId ?? this.editorUserId,
      deadline: deadline ?? this.deadline,
      referenceImageUrlsJson:
          referenceImageUrlsJson ?? this.referenceImageUrlsJson,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      requestedByUserId: requestedByUserId ?? this.requestedByUserId,
      requestedAt: requestedAt ?? this.requestedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (bookingId.present) {
      map['booking_id'] = Variable<String>(bookingId.value);
    }
    if (round.present) {
      map['round'] = Variable<int>(round.value);
    }
    if (editorUserId.present) {
      map['editor_user_id'] = Variable<String>(editorUserId.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (referenceImageUrlsJson.present) {
      map['reference_image_urls_json'] = Variable<String>(
        referenceImageUrlsJson.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (requestedByUserId.present) {
      map['requested_by_user_id'] = Variable<String>(requestedByUserId.value);
    }
    if (requestedAt.present) {
      map['requested_at'] = Variable<DateTime>(requestedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReEditRequestsTableCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('bookingId: $bookingId, ')
          ..write('round: $round, ')
          ..write('editorUserId: $editorUserId, ')
          ..write('deadline: $deadline, ')
          ..write('referenceImageUrlsJson: $referenceImageUrlsJson, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('requestedByUserId: $requestedByUserId, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskProgressTableTable extends TaskProgressTable
    with TableInfo<$TaskProgressTableTable, TaskProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskProgressTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookingIdMeta = const VerificationMeta(
    'bookingId',
  );
  @override
  late final GeneratedColumn<String> bookingId = GeneratedColumn<String>(
    'booking_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _percentageMeta = const VerificationMeta(
    'percentage',
  );
  @override
  late final GeneratedColumn<int> percentage = GeneratedColumn<int>(
    'percentage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookingId,
    userId,
    percentage,
    note,
    updatedAt,
    pending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_progress_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('booking_id')) {
      context.handle(
        _bookingIdMeta,
        bookingId.isAcceptableOrUnknown(data['booking_id']!, _bookingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookingIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('percentage')) {
      context.handle(
        _percentageMeta,
        percentage.isAcceptableOrUnknown(data['percentage']!, _percentageMeta),
      );
    } else if (isInserting) {
      context.missing(_percentageMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookingId, userId};
  @override
  TaskProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskProgressRow(
      bookingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booking_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      percentage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}percentage'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
    );
  }

  @override
  $TaskProgressTableTable createAlias(String alias) {
    return $TaskProgressTableTable(attachedDatabase, alias);
  }
}

class TaskProgressRow extends DataClass implements Insertable<TaskProgressRow> {
  final String bookingId;
  final String userId;
  final int percentage;
  final String? note;
  final DateTime updatedAt;
  final bool pending;
  const TaskProgressRow({
    required this.bookingId,
    required this.userId,
    required this.percentage,
    this.note,
    required this.updatedAt,
    required this.pending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['booking_id'] = Variable<String>(bookingId);
    map['user_id'] = Variable<String>(userId);
    map['percentage'] = Variable<int>(percentage);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending'] = Variable<bool>(pending);
    return map;
  }

  TaskProgressTableCompanion toCompanion(bool nullToAbsent) {
    return TaskProgressTableCompanion(
      bookingId: Value(bookingId),
      userId: Value(userId),
      percentage: Value(percentage),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      updatedAt: Value(updatedAt),
      pending: Value(pending),
    );
  }

  factory TaskProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskProgressRow(
      bookingId: serializer.fromJson<String>(json['bookingId']),
      userId: serializer.fromJson<String>(json['userId']),
      percentage: serializer.fromJson<int>(json['percentage']),
      note: serializer.fromJson<String?>(json['note']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pending: serializer.fromJson<bool>(json['pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookingId': serializer.toJson<String>(bookingId),
      'userId': serializer.toJson<String>(userId),
      'percentage': serializer.toJson<int>(percentage),
      'note': serializer.toJson<String?>(note),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pending': serializer.toJson<bool>(pending),
    };
  }

  TaskProgressRow copyWith({
    String? bookingId,
    String? userId,
    int? percentage,
    Value<String?> note = const Value.absent(),
    DateTime? updatedAt,
    bool? pending,
  }) => TaskProgressRow(
    bookingId: bookingId ?? this.bookingId,
    userId: userId ?? this.userId,
    percentage: percentage ?? this.percentage,
    note: note.present ? note.value : this.note,
    updatedAt: updatedAt ?? this.updatedAt,
    pending: pending ?? this.pending,
  );
  TaskProgressRow copyWithCompanion(TaskProgressTableCompanion data) {
    return TaskProgressRow(
      bookingId: data.bookingId.present ? data.bookingId.value : this.bookingId,
      userId: data.userId.present ? data.userId.value : this.userId,
      percentage: data.percentage.present
          ? data.percentage.value
          : this.percentage,
      note: data.note.present ? data.note.value : this.note,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pending: data.pending.present ? data.pending.value : this.pending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskProgressRow(')
          ..write('bookingId: $bookingId, ')
          ..write('userId: $userId, ')
          ..write('percentage: $percentage, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(bookingId, userId, percentage, note, updatedAt, pending);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskProgressRow &&
          other.bookingId == this.bookingId &&
          other.userId == this.userId &&
          other.percentage == this.percentage &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt &&
          other.pending == this.pending);
}

class TaskProgressTableCompanion extends UpdateCompanion<TaskProgressRow> {
  final Value<String> bookingId;
  final Value<String> userId;
  final Value<int> percentage;
  final Value<String?> note;
  final Value<DateTime> updatedAt;
  final Value<bool> pending;
  final Value<int> rowid;
  const TaskProgressTableCompanion({
    this.bookingId = const Value.absent(),
    this.userId = const Value.absent(),
    this.percentage = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskProgressTableCompanion.insert({
    required String bookingId,
    required String userId,
    required int percentage,
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bookingId = Value(bookingId),
       userId = Value(userId),
       percentage = Value(percentage);
  static Insertable<TaskProgressRow> custom({
    Expression<String>? bookingId,
    Expression<String>? userId,
    Expression<int>? percentage,
    Expression<String>? note,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookingId != null) 'booking_id': bookingId,
      if (userId != null) 'user_id': userId,
      if (percentage != null) 'percentage': percentage,
      if (note != null) 'note': note,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pending != null) 'pending': pending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskProgressTableCompanion copyWith({
    Value<String>? bookingId,
    Value<String>? userId,
    Value<int>? percentage,
    Value<String?>? note,
    Value<DateTime>? updatedAt,
    Value<bool>? pending,
    Value<int>? rowid,
  }) {
    return TaskProgressTableCompanion(
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      percentage: percentage ?? this.percentage,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookingId.present) {
      map['booking_id'] = Variable<String>(bookingId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (percentage.present) {
      map['percentage'] = Variable<int>(percentage.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskProgressTableCompanion(')
          ..write('bookingId: $bookingId, ')
          ..write('userId: $userId, ')
          ..write('percentage: $percentage, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pending: $pending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PublicBookingRequestsTableTable extends PublicBookingRequestsTable
    with TableInfo<$PublicBookingRequestsTableTable, PublicBookingRequestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PublicBookingRequestsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studioIdMeta = const VerificationMeta(
    'studioId',
  );
  @override
  late final GeneratedColumn<String> studioId = GeneratedColumn<String>(
    'studio_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftMeta = const VerificationMeta('shift');
  @override
  late final GeneratedColumn<String> shift = GeneratedColumn<String>(
    'shift',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _venueMeta = const VerificationMeta('venue');
  @override
  late final GeneratedColumn<String> venue = GeneratedColumn<String>(
    'venue',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brideNameMeta = const VerificationMeta(
    'brideName',
  );
  @override
  late final GeneratedColumn<String> brideName = GeneratedColumn<String>(
    'bride_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groomNameMeta = const VerificationMeta(
    'groomName',
  );
  @override
  late final GeneratedColumn<String> groomName = GeneratedColumn<String>(
    'groom_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientNameMeta = const VerificationMeta(
    'clientName',
  );
  @override
  late final GeneratedColumn<String> clientName = GeneratedColumn<String>(
    'client_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientPhoneMeta = const VerificationMeta(
    'clientPhone',
  );
  @override
  late final GeneratedColumn<String> clientPhone = GeneratedColumn<String>(
    'client_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientEmailMeta = const VerificationMeta(
    'clientEmail',
  );
  @override
  late final GeneratedColumn<String> clientEmail = GeneratedColumn<String>(
    'client_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _submittedAtMeta = const VerificationMeta(
    'submittedAt',
  );
  @override
  late final GeneratedColumn<DateTime> submittedAt = GeneratedColumn<DateTime>(
    'submitted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studioId,
    title,
    eventType,
    date,
    startTime,
    endTime,
    shift,
    venue,
    brideName,
    groomName,
    clientName,
    clientPhone,
    clientEmail,
    notes,
    status,
    submittedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'public_booking_requests_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PublicBookingRequestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('studio_id')) {
      context.handle(
        _studioIdMeta,
        studioId.isAcceptableOrUnknown(data['studio_id']!, _studioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studioIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('shift')) {
      context.handle(
        _shiftMeta,
        shift.isAcceptableOrUnknown(data['shift']!, _shiftMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftMeta);
    }
    if (data.containsKey('venue')) {
      context.handle(
        _venueMeta,
        venue.isAcceptableOrUnknown(data['venue']!, _venueMeta),
      );
    }
    if (data.containsKey('bride_name')) {
      context.handle(
        _brideNameMeta,
        brideName.isAcceptableOrUnknown(data['bride_name']!, _brideNameMeta),
      );
    }
    if (data.containsKey('groom_name')) {
      context.handle(
        _groomNameMeta,
        groomName.isAcceptableOrUnknown(data['groom_name']!, _groomNameMeta),
      );
    }
    if (data.containsKey('client_name')) {
      context.handle(
        _clientNameMeta,
        clientName.isAcceptableOrUnknown(data['client_name']!, _clientNameMeta),
      );
    } else if (isInserting) {
      context.missing(_clientNameMeta);
    }
    if (data.containsKey('client_phone')) {
      context.handle(
        _clientPhoneMeta,
        clientPhone.isAcceptableOrUnknown(
          data['client_phone']!,
          _clientPhoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientPhoneMeta);
    }
    if (data.containsKey('client_email')) {
      context.handle(
        _clientEmailMeta,
        clientEmail.isAcceptableOrUnknown(
          data['client_email']!,
          _clientEmailMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('submitted_at')) {
      context.handle(
        _submittedAtMeta,
        submittedAt.isAcceptableOrUnknown(
          data['submitted_at']!,
          _submittedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_submittedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PublicBookingRequestRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PublicBookingRequestRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      studioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}studio_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      )!,
      shift: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift'],
      )!,
      venue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}venue'],
      ),
      brideName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bride_name'],
      ),
      groomName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}groom_name'],
      ),
      clientName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_name'],
      )!,
      clientPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_phone'],
      )!,
      clientEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_email'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      submittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}submitted_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PublicBookingRequestsTableTable createAlias(String alias) {
    return $PublicBookingRequestsTableTable(attachedDatabase, alias);
  }
}

class PublicBookingRequestRow extends DataClass
    implements Insertable<PublicBookingRequestRow> {
  final String id;
  final String studioId;
  final String title;
  final String eventType;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String shift;
  final String? venue;
  final String? brideName;
  final String? groomName;
  final String clientName;
  final String clientPhone;
  final String? clientEmail;
  final String? notes;
  final String status;
  final DateTime submittedAt;
  final DateTime updatedAt;
  const PublicBookingRequestRow({
    required this.id,
    required this.studioId,
    required this.title,
    required this.eventType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.shift,
    this.venue,
    this.brideName,
    this.groomName,
    required this.clientName,
    required this.clientPhone,
    this.clientEmail,
    this.notes,
    required this.status,
    required this.submittedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['studio_id'] = Variable<String>(studioId);
    map['title'] = Variable<String>(title);
    map['event_type'] = Variable<String>(eventType);
    map['date'] = Variable<DateTime>(date);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    map['shift'] = Variable<String>(shift);
    if (!nullToAbsent || venue != null) {
      map['venue'] = Variable<String>(venue);
    }
    if (!nullToAbsent || brideName != null) {
      map['bride_name'] = Variable<String>(brideName);
    }
    if (!nullToAbsent || groomName != null) {
      map['groom_name'] = Variable<String>(groomName);
    }
    map['client_name'] = Variable<String>(clientName);
    map['client_phone'] = Variable<String>(clientPhone);
    if (!nullToAbsent || clientEmail != null) {
      map['client_email'] = Variable<String>(clientEmail);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['status'] = Variable<String>(status);
    map['submitted_at'] = Variable<DateTime>(submittedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PublicBookingRequestsTableCompanion toCompanion(bool nullToAbsent) {
    return PublicBookingRequestsTableCompanion(
      id: Value(id),
      studioId: Value(studioId),
      title: Value(title),
      eventType: Value(eventType),
      date: Value(date),
      startTime: Value(startTime),
      endTime: Value(endTime),
      shift: Value(shift),
      venue: venue == null && nullToAbsent
          ? const Value.absent()
          : Value(venue),
      brideName: brideName == null && nullToAbsent
          ? const Value.absent()
          : Value(brideName),
      groomName: groomName == null && nullToAbsent
          ? const Value.absent()
          : Value(groomName),
      clientName: Value(clientName),
      clientPhone: Value(clientPhone),
      clientEmail: clientEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(clientEmail),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
      submittedAt: Value(submittedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PublicBookingRequestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PublicBookingRequestRow(
      id: serializer.fromJson<String>(json['id']),
      studioId: serializer.fromJson<String>(json['studioId']),
      title: serializer.fromJson<String>(json['title']),
      eventType: serializer.fromJson<String>(json['eventType']),
      date: serializer.fromJson<DateTime>(json['date']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      shift: serializer.fromJson<String>(json['shift']),
      venue: serializer.fromJson<String?>(json['venue']),
      brideName: serializer.fromJson<String?>(json['brideName']),
      groomName: serializer.fromJson<String?>(json['groomName']),
      clientName: serializer.fromJson<String>(json['clientName']),
      clientPhone: serializer.fromJson<String>(json['clientPhone']),
      clientEmail: serializer.fromJson<String?>(json['clientEmail']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: serializer.fromJson<String>(json['status']),
      submittedAt: serializer.fromJson<DateTime>(json['submittedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'studioId': serializer.toJson<String>(studioId),
      'title': serializer.toJson<String>(title),
      'eventType': serializer.toJson<String>(eventType),
      'date': serializer.toJson<DateTime>(date),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'shift': serializer.toJson<String>(shift),
      'venue': serializer.toJson<String?>(venue),
      'brideName': serializer.toJson<String?>(brideName),
      'groomName': serializer.toJson<String?>(groomName),
      'clientName': serializer.toJson<String>(clientName),
      'clientPhone': serializer.toJson<String>(clientPhone),
      'clientEmail': serializer.toJson<String?>(clientEmail),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<String>(status),
      'submittedAt': serializer.toJson<DateTime>(submittedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PublicBookingRequestRow copyWith({
    String? id,
    String? studioId,
    String? title,
    String? eventType,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? shift,
    Value<String?> venue = const Value.absent(),
    Value<String?> brideName = const Value.absent(),
    Value<String?> groomName = const Value.absent(),
    String? clientName,
    String? clientPhone,
    Value<String?> clientEmail = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? status,
    DateTime? submittedAt,
    DateTime? updatedAt,
  }) => PublicBookingRequestRow(
    id: id ?? this.id,
    studioId: studioId ?? this.studioId,
    title: title ?? this.title,
    eventType: eventType ?? this.eventType,
    date: date ?? this.date,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    shift: shift ?? this.shift,
    venue: venue.present ? venue.value : this.venue,
    brideName: brideName.present ? brideName.value : this.brideName,
    groomName: groomName.present ? groomName.value : this.groomName,
    clientName: clientName ?? this.clientName,
    clientPhone: clientPhone ?? this.clientPhone,
    clientEmail: clientEmail.present ? clientEmail.value : this.clientEmail,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
    submittedAt: submittedAt ?? this.submittedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PublicBookingRequestRow copyWithCompanion(
    PublicBookingRequestsTableCompanion data,
  ) {
    return PublicBookingRequestRow(
      id: data.id.present ? data.id.value : this.id,
      studioId: data.studioId.present ? data.studioId.value : this.studioId,
      title: data.title.present ? data.title.value : this.title,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      date: data.date.present ? data.date.value : this.date,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      shift: data.shift.present ? data.shift.value : this.shift,
      venue: data.venue.present ? data.venue.value : this.venue,
      brideName: data.brideName.present ? data.brideName.value : this.brideName,
      groomName: data.groomName.present ? data.groomName.value : this.groomName,
      clientName: data.clientName.present
          ? data.clientName.value
          : this.clientName,
      clientPhone: data.clientPhone.present
          ? data.clientPhone.value
          : this.clientPhone,
      clientEmail: data.clientEmail.present
          ? data.clientEmail.value
          : this.clientEmail,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PublicBookingRequestRow(')
          ..write('id: $id, ')
          ..write('studioId: $studioId, ')
          ..write('title: $title, ')
          ..write('eventType: $eventType, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('shift: $shift, ')
          ..write('venue: $venue, ')
          ..write('brideName: $brideName, ')
          ..write('groomName: $groomName, ')
          ..write('clientName: $clientName, ')
          ..write('clientPhone: $clientPhone, ')
          ..write('clientEmail: $clientEmail, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    studioId,
    title,
    eventType,
    date,
    startTime,
    endTime,
    shift,
    venue,
    brideName,
    groomName,
    clientName,
    clientPhone,
    clientEmail,
    notes,
    status,
    submittedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PublicBookingRequestRow &&
          other.id == this.id &&
          other.studioId == this.studioId &&
          other.title == this.title &&
          other.eventType == this.eventType &&
          other.date == this.date &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.shift == this.shift &&
          other.venue == this.venue &&
          other.brideName == this.brideName &&
          other.groomName == this.groomName &&
          other.clientName == this.clientName &&
          other.clientPhone == this.clientPhone &&
          other.clientEmail == this.clientEmail &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.submittedAt == this.submittedAt &&
          other.updatedAt == this.updatedAt);
}

class PublicBookingRequestsTableCompanion
    extends UpdateCompanion<PublicBookingRequestRow> {
  final Value<String> id;
  final Value<String> studioId;
  final Value<String> title;
  final Value<String> eventType;
  final Value<DateTime> date;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<String> shift;
  final Value<String?> venue;
  final Value<String?> brideName;
  final Value<String?> groomName;
  final Value<String> clientName;
  final Value<String> clientPhone;
  final Value<String?> clientEmail;
  final Value<String?> notes;
  final Value<String> status;
  final Value<DateTime> submittedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PublicBookingRequestsTableCompanion({
    this.id = const Value.absent(),
    this.studioId = const Value.absent(),
    this.title = const Value.absent(),
    this.eventType = const Value.absent(),
    this.date = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.shift = const Value.absent(),
    this.venue = const Value.absent(),
    this.brideName = const Value.absent(),
    this.groomName = const Value.absent(),
    this.clientName = const Value.absent(),
    this.clientPhone = const Value.absent(),
    this.clientEmail = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PublicBookingRequestsTableCompanion.insert({
    required String id,
    required String studioId,
    required String title,
    required String eventType,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String shift,
    this.venue = const Value.absent(),
    this.brideName = const Value.absent(),
    this.groomName = const Value.absent(),
    required String clientName,
    required String clientPhone,
    this.clientEmail = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime submittedAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       studioId = Value(studioId),
       title = Value(title),
       eventType = Value(eventType),
       date = Value(date),
       startTime = Value(startTime),
       endTime = Value(endTime),
       shift = Value(shift),
       clientName = Value(clientName),
       clientPhone = Value(clientPhone),
       submittedAt = Value(submittedAt);
  static Insertable<PublicBookingRequestRow> custom({
    Expression<String>? id,
    Expression<String>? studioId,
    Expression<String>? title,
    Expression<String>? eventType,
    Expression<DateTime>? date,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? shift,
    Expression<String>? venue,
    Expression<String>? brideName,
    Expression<String>? groomName,
    Expression<String>? clientName,
    Expression<String>? clientPhone,
    Expression<String>? clientEmail,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<DateTime>? submittedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studioId != null) 'studio_id': studioId,
      if (title != null) 'title': title,
      if (eventType != null) 'event_type': eventType,
      if (date != null) 'date': date,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (shift != null) 'shift': shift,
      if (venue != null) 'venue': venue,
      if (brideName != null) 'bride_name': brideName,
      if (groomName != null) 'groom_name': groomName,
      if (clientName != null) 'client_name': clientName,
      if (clientPhone != null) 'client_phone': clientPhone,
      if (clientEmail != null) 'client_email': clientEmail,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (submittedAt != null) 'submitted_at': submittedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PublicBookingRequestsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? studioId,
    Value<String>? title,
    Value<String>? eventType,
    Value<DateTime>? date,
    Value<String>? startTime,
    Value<String>? endTime,
    Value<String>? shift,
    Value<String?>? venue,
    Value<String?>? brideName,
    Value<String?>? groomName,
    Value<String>? clientName,
    Value<String>? clientPhone,
    Value<String?>? clientEmail,
    Value<String?>? notes,
    Value<String>? status,
    Value<DateTime>? submittedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PublicBookingRequestsTableCompanion(
      id: id ?? this.id,
      studioId: studioId ?? this.studioId,
      title: title ?? this.title,
      eventType: eventType ?? this.eventType,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      shift: shift ?? this.shift,
      venue: venue ?? this.venue,
      brideName: brideName ?? this.brideName,
      groomName: groomName ?? this.groomName,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (studioId.present) {
      map['studio_id'] = Variable<String>(studioId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (shift.present) {
      map['shift'] = Variable<String>(shift.value);
    }
    if (venue.present) {
      map['venue'] = Variable<String>(venue.value);
    }
    if (brideName.present) {
      map['bride_name'] = Variable<String>(brideName.value);
    }
    if (groomName.present) {
      map['groom_name'] = Variable<String>(groomName.value);
    }
    if (clientName.present) {
      map['client_name'] = Variable<String>(clientName.value);
    }
    if (clientPhone.present) {
      map['client_phone'] = Variable<String>(clientPhone.value);
    }
    if (clientEmail.present) {
      map['client_email'] = Variable<String>(clientEmail.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<DateTime>(submittedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PublicBookingRequestsTableCompanion(')
          ..write('id: $id, ')
          ..write('studioId: $studioId, ')
          ..write('title: $title, ')
          ..write('eventType: $eventType, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('shift: $shift, ')
          ..write('venue: $venue, ')
          ..write('brideName: $brideName, ')
          ..write('groomName: $groomName, ')
          ..write('clientName: $clientName, ')
          ..write('clientPhone: $clientPhone, ')
          ..write('clientEmail: $clientEmail, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTableTable usersTable = $UsersTableTable(this);
  late final $UserPreferencesTableTable userPreferencesTable =
      $UserPreferencesTableTable(this);
  late final $NotificationPreferencesTableTable notificationPreferencesTable =
      $NotificationPreferencesTableTable(this);
  late final $GearItemsTableTable gearItemsTable = $GearItemsTableTable(this);
  late final $TeamInvitesTableTable teamInvitesTable = $TeamInvitesTableTable(
    this,
  );
  late final $OutboxTableTable outboxTable = $OutboxTableTable(this);
  late final $ExpensesTableTable expensesTable = $ExpensesTableTable(this);
  late final $BookingsTableTable bookingsTable = $BookingsTableTable(this);
  late final $ClientsTableTable clientsTable = $ClientsTableTable(this);
  late final $AssignmentsTableTable assignmentsTable = $AssignmentsTableTable(
    this,
  );
  late final $PaymentsTableTable paymentsTable = $PaymentsTableTable(this);
  late final $PackagesTableTable packagesTable = $PackagesTableTable(this);
  late final $StatusHistoryTableTable statusHistoryTable =
      $StatusHistoryTableTable(this);
  late final $ReEditRequestsTableTable reEditRequestsTable =
      $ReEditRequestsTableTable(this);
  late final $TaskProgressTableTable taskProgressTable =
      $TaskProgressTableTable(this);
  late final $PublicBookingRequestsTableTable publicBookingRequestsTable =
      $PublicBookingRequestsTableTable(this);
  late final UsersDao usersDao = UsersDao(this as AppDatabase);
  late final PreferencesDao preferencesDao = PreferencesDao(
    this as AppDatabase,
  );
  late final GearDao gearDao = GearDao(this as AppDatabase);
  late final OutboxDao outboxDao = OutboxDao(this as AppDatabase);
  late final ExpensesDao expensesDao = ExpensesDao(this as AppDatabase);
  late final BookingsDao bookingsDao = BookingsDao(this as AppDatabase);
  late final ClientsDao clientsDao = ClientsDao(this as AppDatabase);
  late final AssignmentsDao assignmentsDao = AssignmentsDao(
    this as AppDatabase,
  );
  late final PaymentsDao paymentsDao = PaymentsDao(this as AppDatabase);
  late final PackagesDao packagesDao = PackagesDao(this as AppDatabase);
  late final StatusHistoryDao statusHistoryDao = StatusHistoryDao(
    this as AppDatabase,
  );
  late final ReEditRequestsDao reEditRequestsDao = ReEditRequestsDao(
    this as AppDatabase,
  );
  late final TaskProgressDao taskProgressDao = TaskProgressDao(
    this as AppDatabase,
  );
  late final PublicBookingRequestsDao publicBookingRequestsDao =
      PublicBookingRequestsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    usersTable,
    userPreferencesTable,
    notificationPreferencesTable,
    gearItemsTable,
    teamInvitesTable,
    outboxTable,
    expensesTable,
    bookingsTable,
    clientsTable,
    assignmentsTable,
    paymentsTable,
    packagesTable,
    statusHistoryTable,
    reEditRequestsTable,
    taskProgressTable,
    publicBookingRequestsTable,
  ];
}

typedef $$UsersTableTableCreateCompanionBuilder =
    UsersTableCompanion Function({
      required String id,
      Value<String?> remoteId,
      required String name,
      required String email,
      Value<String?> phone,
      required String role,
      Value<String?> ownerId,
      Value<String?> avatarUrl,
      Value<String?> bio,
      Value<String?> specialization,
      Value<String?> vatBin,
      Value<String?> studioAddress,
      Value<String?> whatsapp,
      Value<String?> bkash,
      Value<String?> bankDetails,
      Value<String?> signatureUrl,
      Value<String?> logoUrl,
      Value<String?> companyName,
      Value<int> totalEvents,
      Value<int> totalRevenueMinor,
      Value<int> totalClients,
      Value<DateTime?> statsRefreshedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<DateTime?> deletedAt,
      Value<bool> isCurrent,
      Value<int> rowid,
    });
typedef $$UsersTableTableUpdateCompanionBuilder =
    UsersTableCompanion Function({
      Value<String> id,
      Value<String?> remoteId,
      Value<String> name,
      Value<String> email,
      Value<String?> phone,
      Value<String> role,
      Value<String?> ownerId,
      Value<String?> avatarUrl,
      Value<String?> bio,
      Value<String?> specialization,
      Value<String?> vatBin,
      Value<String?> studioAddress,
      Value<String?> whatsapp,
      Value<String?> bkash,
      Value<String?> bankDetails,
      Value<String?> signatureUrl,
      Value<String?> logoUrl,
      Value<String?> companyName,
      Value<int> totalEvents,
      Value<int> totalRevenueMinor,
      Value<int> totalClients,
      Value<DateTime?> statsRefreshedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<DateTime?> deletedAt,
      Value<bool> isCurrent,
      Value<int> rowid,
    });

class $$UsersTableTableFilterComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specialization => $composableBuilder(
    column: $table.specialization,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vatBin => $composableBuilder(
    column: $table.vatBin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studioAddress => $composableBuilder(
    column: $table.studioAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whatsapp => $composableBuilder(
    column: $table.whatsapp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bkash => $composableBuilder(
    column: $table.bkash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankDetails => $composableBuilder(
    column: $table.bankDetails,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signatureUrl => $composableBuilder(
    column: $table.signatureUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalEvents => $composableBuilder(
    column: $table.totalEvents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalRevenueMinor => $composableBuilder(
    column: $table.totalRevenueMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalClients => $composableBuilder(
    column: $table.totalClients,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get statsRefreshedAt => $composableBuilder(
    column: $table.statsRefreshedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specialization => $composableBuilder(
    column: $table.specialization,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vatBin => $composableBuilder(
    column: $table.vatBin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studioAddress => $composableBuilder(
    column: $table.studioAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whatsapp => $composableBuilder(
    column: $table.whatsapp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bkash => $composableBuilder(
    column: $table.bkash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankDetails => $composableBuilder(
    column: $table.bankDetails,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signatureUrl => $composableBuilder(
    column: $table.signatureUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalEvents => $composableBuilder(
    column: $table.totalEvents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalRevenueMinor => $composableBuilder(
    column: $table.totalRevenueMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalClients => $composableBuilder(
    column: $table.totalClients,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get statsRefreshedAt => $composableBuilder(
    column: $table.statsRefreshedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<String> get specialization => $composableBuilder(
    column: $table.specialization,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vatBin =>
      $composableBuilder(column: $table.vatBin, builder: (column) => column);

  GeneratedColumn<String> get studioAddress => $composableBuilder(
    column: $table.studioAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get whatsapp =>
      $composableBuilder(column: $table.whatsapp, builder: (column) => column);

  GeneratedColumn<String> get bkash =>
      $composableBuilder(column: $table.bkash, builder: (column) => column);

  GeneratedColumn<String> get bankDetails => $composableBuilder(
    column: $table.bankDetails,
    builder: (column) => column,
  );

  GeneratedColumn<String> get signatureUrl => $composableBuilder(
    column: $table.signatureUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalEvents => $composableBuilder(
    column: $table.totalEvents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalRevenueMinor => $composableBuilder(
    column: $table.totalRevenueMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalClients => $composableBuilder(
    column: $table.totalClients,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get statsRefreshedAt => $composableBuilder(
    column: $table.statsRefreshedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pending =>
      $composableBuilder(column: $table.pending, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get isCurrent =>
      $composableBuilder(column: $table.isCurrent, builder: (column) => column);
}

class $$UsersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTableTable,
          UserRow,
          $$UsersTableTableFilterComposer,
          $$UsersTableTableOrderingComposer,
          $$UsersTableTableAnnotationComposer,
          $$UsersTableTableCreateCompanionBuilder,
          $$UsersTableTableUpdateCompanionBuilder,
          (UserRow, BaseReferences<_$AppDatabase, $UsersTableTable, UserRow>),
          UserRow,
          PrefetchHooks Function()
        > {
  $$UsersTableTableTableManager(_$AppDatabase db, $UsersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> specialization = const Value.absent(),
                Value<String?> vatBin = const Value.absent(),
                Value<String?> studioAddress = const Value.absent(),
                Value<String?> whatsapp = const Value.absent(),
                Value<String?> bkash = const Value.absent(),
                Value<String?> bankDetails = const Value.absent(),
                Value<String?> signatureUrl = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
                Value<int> totalEvents = const Value.absent(),
                Value<int> totalRevenueMinor = const Value.absent(),
                Value<int> totalClients = const Value.absent(),
                Value<DateTime?> statsRefreshedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isCurrent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersTableCompanion(
                id: id,
                remoteId: remoteId,
                name: name,
                email: email,
                phone: phone,
                role: role,
                ownerId: ownerId,
                avatarUrl: avatarUrl,
                bio: bio,
                specialization: specialization,
                vatBin: vatBin,
                studioAddress: studioAddress,
                whatsapp: whatsapp,
                bkash: bkash,
                bankDetails: bankDetails,
                signatureUrl: signatureUrl,
                logoUrl: logoUrl,
                companyName: companyName,
                totalEvents: totalEvents,
                totalRevenueMinor: totalRevenueMinor,
                totalClients: totalClients,
                statsRefreshedAt: statsRefreshedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pending: pending,
                deletedAt: deletedAt,
                isCurrent: isCurrent,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> remoteId = const Value.absent(),
                required String name,
                required String email,
                Value<String?> phone = const Value.absent(),
                required String role,
                Value<String?> ownerId = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> specialization = const Value.absent(),
                Value<String?> vatBin = const Value.absent(),
                Value<String?> studioAddress = const Value.absent(),
                Value<String?> whatsapp = const Value.absent(),
                Value<String?> bkash = const Value.absent(),
                Value<String?> bankDetails = const Value.absent(),
                Value<String?> signatureUrl = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
                Value<int> totalEvents = const Value.absent(),
                Value<int> totalRevenueMinor = const Value.absent(),
                Value<int> totalClients = const Value.absent(),
                Value<DateTime?> statsRefreshedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isCurrent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersTableCompanion.insert(
                id: id,
                remoteId: remoteId,
                name: name,
                email: email,
                phone: phone,
                role: role,
                ownerId: ownerId,
                avatarUrl: avatarUrl,
                bio: bio,
                specialization: specialization,
                vatBin: vatBin,
                studioAddress: studioAddress,
                whatsapp: whatsapp,
                bkash: bkash,
                bankDetails: bankDetails,
                signatureUrl: signatureUrl,
                logoUrl: logoUrl,
                companyName: companyName,
                totalEvents: totalEvents,
                totalRevenueMinor: totalRevenueMinor,
                totalClients: totalClients,
                statsRefreshedAt: statsRefreshedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pending: pending,
                deletedAt: deletedAt,
                isCurrent: isCurrent,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTableTable,
      UserRow,
      $$UsersTableTableFilterComposer,
      $$UsersTableTableOrderingComposer,
      $$UsersTableTableAnnotationComposer,
      $$UsersTableTableCreateCompanionBuilder,
      $$UsersTableTableUpdateCompanionBuilder,
      (UserRow, BaseReferences<_$AppDatabase, $UsersTableTable, UserRow>),
      UserRow,
      PrefetchHooks Function()
    >;
typedef $$UserPreferencesTableTableCreateCompanionBuilder =
    UserPreferencesTableCompanion Function({
      required String userId,
      Value<String> language,
      Value<bool> distributionEnabled,
      Value<bool> vatEnabled,
      Value<bool> bengaliNumerals,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UserPreferencesTableTableUpdateCompanionBuilder =
    UserPreferencesTableCompanion Function({
      Value<String> userId,
      Value<String> language,
      Value<bool> distributionEnabled,
      Value<bool> vatEnabled,
      Value<bool> bengaliNumerals,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserPreferencesTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get distributionEnabled => $composableBuilder(
    column: $table.distributionEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get vatEnabled => $composableBuilder(
    column: $table.vatEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bengaliNumerals => $composableBuilder(
    column: $table.bengaliNumerals,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserPreferencesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get distributionEnabled => $composableBuilder(
    column: $table.distributionEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get vatEnabled => $composableBuilder(
    column: $table.vatEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bengaliNumerals => $composableBuilder(
    column: $table.bengaliNumerals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserPreferencesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<bool> get distributionEnabled => $composableBuilder(
    column: $table.distributionEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get vatEnabled => $composableBuilder(
    column: $table.vatEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get bengaliNumerals => $composableBuilder(
    column: $table.bengaliNumerals,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserPreferencesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserPreferencesTableTable,
          UserPreferencesRow,
          $$UserPreferencesTableTableFilterComposer,
          $$UserPreferencesTableTableOrderingComposer,
          $$UserPreferencesTableTableAnnotationComposer,
          $$UserPreferencesTableTableCreateCompanionBuilder,
          $$UserPreferencesTableTableUpdateCompanionBuilder,
          (
            UserPreferencesRow,
            BaseReferences<
              _$AppDatabase,
              $UserPreferencesTableTable,
              UserPreferencesRow
            >,
          ),
          UserPreferencesRow,
          PrefetchHooks Function()
        > {
  $$UserPreferencesTableTableTableManager(
    _$AppDatabase db,
    $UserPreferencesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPreferencesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPreferencesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserPreferencesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<bool> distributionEnabled = const Value.absent(),
                Value<bool> vatEnabled = const Value.absent(),
                Value<bool> bengaliNumerals = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesTableCompanion(
                userId: userId,
                language: language,
                distributionEnabled: distributionEnabled,
                vatEnabled: vatEnabled,
                bengaliNumerals: bengaliNumerals,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String> language = const Value.absent(),
                Value<bool> distributionEnabled = const Value.absent(),
                Value<bool> vatEnabled = const Value.absent(),
                Value<bool> bengaliNumerals = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesTableCompanion.insert(
                userId: userId,
                language: language,
                distributionEnabled: distributionEnabled,
                vatEnabled: vatEnabled,
                bengaliNumerals: bengaliNumerals,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserPreferencesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserPreferencesTableTable,
      UserPreferencesRow,
      $$UserPreferencesTableTableFilterComposer,
      $$UserPreferencesTableTableOrderingComposer,
      $$UserPreferencesTableTableAnnotationComposer,
      $$UserPreferencesTableTableCreateCompanionBuilder,
      $$UserPreferencesTableTableUpdateCompanionBuilder,
      (
        UserPreferencesRow,
        BaseReferences<
          _$AppDatabase,
          $UserPreferencesTableTable,
          UserPreferencesRow
        >,
      ),
      UserPreferencesRow,
      PrefetchHooks Function()
    >;
typedef $$NotificationPreferencesTableTableCreateCompanionBuilder =
    NotificationPreferencesTableCompanion Function({
      required String userId,
      Value<bool> eventReminders,
      Value<bool> paymentDue,
      Value<bool> teamMessages,
      Value<bool> announcements,
      Value<bool> marketing,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$NotificationPreferencesTableTableUpdateCompanionBuilder =
    NotificationPreferencesTableCompanion Function({
      Value<String> userId,
      Value<bool> eventReminders,
      Value<bool> paymentDue,
      Value<bool> teamMessages,
      Value<bool> announcements,
      Value<bool> marketing,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$NotificationPreferencesTableTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationPreferencesTableTable> {
  $$NotificationPreferencesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get eventReminders => $composableBuilder(
    column: $table.eventReminders,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paymentDue => $composableBuilder(
    column: $table.paymentDue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get teamMessages => $composableBuilder(
    column: $table.teamMessages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get announcements => $composableBuilder(
    column: $table.announcements,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get marketing => $composableBuilder(
    column: $table.marketing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationPreferencesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationPreferencesTableTable> {
  $$NotificationPreferencesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get eventReminders => $composableBuilder(
    column: $table.eventReminders,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paymentDue => $composableBuilder(
    column: $table.paymentDue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get teamMessages => $composableBuilder(
    column: $table.teamMessages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get announcements => $composableBuilder(
    column: $table.announcements,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get marketing => $composableBuilder(
    column: $table.marketing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationPreferencesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationPreferencesTableTable> {
  $$NotificationPreferencesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<bool> get eventReminders => $composableBuilder(
    column: $table.eventReminders,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get paymentDue => $composableBuilder(
    column: $table.paymentDue,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get teamMessages => $composableBuilder(
    column: $table.teamMessages,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get announcements => $composableBuilder(
    column: $table.announcements,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get marketing =>
      $composableBuilder(column: $table.marketing, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NotificationPreferencesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationPreferencesTableTable,
          NotificationPreferencesRow,
          $$NotificationPreferencesTableTableFilterComposer,
          $$NotificationPreferencesTableTableOrderingComposer,
          $$NotificationPreferencesTableTableAnnotationComposer,
          $$NotificationPreferencesTableTableCreateCompanionBuilder,
          $$NotificationPreferencesTableTableUpdateCompanionBuilder,
          (
            NotificationPreferencesRow,
            BaseReferences<
              _$AppDatabase,
              $NotificationPreferencesTableTable,
              NotificationPreferencesRow
            >,
          ),
          NotificationPreferencesRow,
          PrefetchHooks Function()
        > {
  $$NotificationPreferencesTableTableTableManager(
    _$AppDatabase db,
    $NotificationPreferencesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationPreferencesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$NotificationPreferencesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$NotificationPreferencesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<bool> eventReminders = const Value.absent(),
                Value<bool> paymentDue = const Value.absent(),
                Value<bool> teamMessages = const Value.absent(),
                Value<bool> announcements = const Value.absent(),
                Value<bool> marketing = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationPreferencesTableCompanion(
                userId: userId,
                eventReminders: eventReminders,
                paymentDue: paymentDue,
                teamMessages: teamMessages,
                announcements: announcements,
                marketing: marketing,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<bool> eventReminders = const Value.absent(),
                Value<bool> paymentDue = const Value.absent(),
                Value<bool> teamMessages = const Value.absent(),
                Value<bool> announcements = const Value.absent(),
                Value<bool> marketing = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationPreferencesTableCompanion.insert(
                userId: userId,
                eventReminders: eventReminders,
                paymentDue: paymentDue,
                teamMessages: teamMessages,
                announcements: announcements,
                marketing: marketing,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationPreferencesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationPreferencesTableTable,
      NotificationPreferencesRow,
      $$NotificationPreferencesTableTableFilterComposer,
      $$NotificationPreferencesTableTableOrderingComposer,
      $$NotificationPreferencesTableTableAnnotationComposer,
      $$NotificationPreferencesTableTableCreateCompanionBuilder,
      $$NotificationPreferencesTableTableUpdateCompanionBuilder,
      (
        NotificationPreferencesRow,
        BaseReferences<
          _$AppDatabase,
          $NotificationPreferencesTableTable,
          NotificationPreferencesRow
        >,
      ),
      NotificationPreferencesRow,
      PrefetchHooks Function()
    >;
typedef $$GearItemsTableTableCreateCompanionBuilder =
    GearItemsTableCompanion Function({
      required String id,
      Value<String?> remoteId,
      required String userId,
      required String name,
      Value<String?> brand,
      Value<DateTime> addedAt,
      Value<bool> pending,
      Value<bool> deleted,
      Value<int> rowid,
    });
typedef $$GearItemsTableTableUpdateCompanionBuilder =
    GearItemsTableCompanion Function({
      Value<String> id,
      Value<String?> remoteId,
      Value<String> userId,
      Value<String> name,
      Value<String?> brand,
      Value<DateTime> addedAt,
      Value<bool> pending,
      Value<bool> deleted,
      Value<int> rowid,
    });

class $$GearItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $GearItemsTableTable> {
  $$GearItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GearItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GearItemsTableTable> {
  $$GearItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GearItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GearItemsTableTable> {
  $$GearItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<bool> get pending =>
      $composableBuilder(column: $table.pending, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$GearItemsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GearItemsTableTable,
          GearItemRow,
          $$GearItemsTableTableFilterComposer,
          $$GearItemsTableTableOrderingComposer,
          $$GearItemsTableTableAnnotationComposer,
          $$GearItemsTableTableCreateCompanionBuilder,
          $$GearItemsTableTableUpdateCompanionBuilder,
          (
            GearItemRow,
            BaseReferences<_$AppDatabase, $GearItemsTableTable, GearItemRow>,
          ),
          GearItemRow,
          PrefetchHooks Function()
        > {
  $$GearItemsTableTableTableManager(
    _$AppDatabase db,
    $GearItemsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GearItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GearItemsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GearItemsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GearItemsTableCompanion(
                id: id,
                remoteId: remoteId,
                userId: userId,
                name: name,
                brand: brand,
                addedAt: addedAt,
                pending: pending,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> remoteId = const Value.absent(),
                required String userId,
                required String name,
                Value<String?> brand = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GearItemsTableCompanion.insert(
                id: id,
                remoteId: remoteId,
                userId: userId,
                name: name,
                brand: brand,
                addedAt: addedAt,
                pending: pending,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GearItemsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GearItemsTableTable,
      GearItemRow,
      $$GearItemsTableTableFilterComposer,
      $$GearItemsTableTableOrderingComposer,
      $$GearItemsTableTableAnnotationComposer,
      $$GearItemsTableTableCreateCompanionBuilder,
      $$GearItemsTableTableUpdateCompanionBuilder,
      (
        GearItemRow,
        BaseReferences<_$AppDatabase, $GearItemsTableTable, GearItemRow>,
      ),
      GearItemRow,
      PrefetchHooks Function()
    >;
typedef $$TeamInvitesTableTableCreateCompanionBuilder =
    TeamInvitesTableCompanion Function({
      required String code,
      required String ownerId,
      required String role,
      required DateTime createdAt,
      required DateTime expiresAt,
      Value<DateTime?> consumedAt,
      Value<int> rowid,
    });
typedef $$TeamInvitesTableTableUpdateCompanionBuilder =
    TeamInvitesTableCompanion Function({
      Value<String> code,
      Value<String> ownerId,
      Value<String> role,
      Value<DateTime> createdAt,
      Value<DateTime> expiresAt,
      Value<DateTime?> consumedAt,
      Value<int> rowid,
    });

class $$TeamInvitesTableTableFilterComposer
    extends Composer<_$AppDatabase, $TeamInvitesTableTable> {
  $$TeamInvitesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TeamInvitesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamInvitesTableTable> {
  $$TeamInvitesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TeamInvitesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamInvitesTableTable> {
  $$TeamInvitesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => column,
  );
}

class $$TeamInvitesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamInvitesTableTable,
          TeamInviteRow,
          $$TeamInvitesTableTableFilterComposer,
          $$TeamInvitesTableTableOrderingComposer,
          $$TeamInvitesTableTableAnnotationComposer,
          $$TeamInvitesTableTableCreateCompanionBuilder,
          $$TeamInvitesTableTableUpdateCompanionBuilder,
          (
            TeamInviteRow,
            BaseReferences<
              _$AppDatabase,
              $TeamInvitesTableTable,
              TeamInviteRow
            >,
          ),
          TeamInviteRow,
          PrefetchHooks Function()
        > {
  $$TeamInvitesTableTableTableManager(
    _$AppDatabase db,
    $TeamInvitesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamInvitesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamInvitesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamInvitesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> code = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime?> consumedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamInvitesTableCompanion(
                code: code,
                ownerId: ownerId,
                role: role,
                createdAt: createdAt,
                expiresAt: expiresAt,
                consumedAt: consumedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String code,
                required String ownerId,
                required String role,
                required DateTime createdAt,
                required DateTime expiresAt,
                Value<DateTime?> consumedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamInvitesTableCompanion.insert(
                code: code,
                ownerId: ownerId,
                role: role,
                createdAt: createdAt,
                expiresAt: expiresAt,
                consumedAt: consumedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TeamInvitesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamInvitesTableTable,
      TeamInviteRow,
      $$TeamInvitesTableTableFilterComposer,
      $$TeamInvitesTableTableOrderingComposer,
      $$TeamInvitesTableTableAnnotationComposer,
      $$TeamInvitesTableTableCreateCompanionBuilder,
      $$TeamInvitesTableTableUpdateCompanionBuilder,
      (
        TeamInviteRow,
        BaseReferences<_$AppDatabase, $TeamInvitesTableTable, TeamInviteRow>,
      ),
      TeamInviteRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableTableCreateCompanionBuilder =
    OutboxTableCompanion Function({
      Value<int> id,
      required String entityType,
      required String entityId,
      required String op,
      required String payloadJson,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String> status,
      Value<String?> lastError,
    });
typedef $$OutboxTableTableUpdateCompanionBuilder =
    OutboxTableCompanion Function({
      Value<int> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> op,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String> status,
      Value<String?> lastError,
    });

class $$OutboxTableTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTableTable> {
  $$OutboxTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTableTable> {
  $$OutboxTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTableTable> {
  $$OutboxTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$OutboxTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTableTable,
          OutboxRow,
          $$OutboxTableTableFilterComposer,
          $$OutboxTableTableOrderingComposer,
          $$OutboxTableTableAnnotationComposer,
          $$OutboxTableTableCreateCompanionBuilder,
          $$OutboxTableTableUpdateCompanionBuilder,
          (
            OutboxRow,
            BaseReferences<_$AppDatabase, $OutboxTableTable, OutboxRow>,
          ),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableTableManager(_$AppDatabase db, $OutboxTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => OutboxTableCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                op: op,
                payloadJson: payloadJson,
                createdAt: createdAt,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                status: status,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityType,
                required String entityId,
                required String op,
                required String payloadJson,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => OutboxTableCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                op: op,
                payloadJson: payloadJson,
                createdAt: createdAt,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                status: status,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTableTable,
      OutboxRow,
      $$OutboxTableTableFilterComposer,
      $$OutboxTableTableOrderingComposer,
      $$OutboxTableTableAnnotationComposer,
      $$OutboxTableTableCreateCompanionBuilder,
      $$OutboxTableTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$AppDatabase, $OutboxTableTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;
typedef $$ExpensesTableTableCreateCompanionBuilder =
    ExpensesTableCompanion Function({
      required String id,
      Value<String?> remoteId,
      Value<String?> ownerId,
      required String category,
      required double amount,
      Value<String?> eventId,
      Value<String?> note,
      Value<String?> receiptUrl,
      required DateTime incurredAt,
      Value<DateTime?> createdAt,
      Value<bool> pending,
      Value<int> rowid,
    });
typedef $$ExpensesTableTableUpdateCompanionBuilder =
    ExpensesTableCompanion Function({
      Value<String> id,
      Value<String?> remoteId,
      Value<String?> ownerId,
      Value<String> category,
      Value<double> amount,
      Value<String?> eventId,
      Value<String?> note,
      Value<String?> receiptUrl,
      Value<DateTime> incurredAt,
      Value<DateTime?> createdAt,
      Value<bool> pending,
      Value<int> rowid,
    });

class $$ExpensesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTableTable> {
  $$ExpensesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptUrl => $composableBuilder(
    column: $table.receiptUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get incurredAt => $composableBuilder(
    column: $table.incurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpensesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTableTable> {
  $$ExpensesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptUrl => $composableBuilder(
    column: $table.receiptUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get incurredAt => $composableBuilder(
    column: $table.incurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpensesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTableTable> {
  $$ExpensesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get receiptUrl => $composableBuilder(
    column: $table.receiptUrl,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get incurredAt => $composableBuilder(
    column: $table.incurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get pending =>
      $composableBuilder(column: $table.pending, builder: (column) => column);
}

class $$ExpensesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTableTable,
          ExpenseRow,
          $$ExpensesTableTableFilterComposer,
          $$ExpensesTableTableOrderingComposer,
          $$ExpensesTableTableAnnotationComposer,
          $$ExpensesTableTableCreateCompanionBuilder,
          $$ExpensesTableTableUpdateCompanionBuilder,
          (
            ExpenseRow,
            BaseReferences<_$AppDatabase, $ExpensesTableTable, ExpenseRow>,
          ),
          ExpenseRow,
          PrefetchHooks Function()
        > {
  $$ExpensesTableTableTableManager(_$AppDatabase db, $ExpensesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String?> eventId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> receiptUrl = const Value.absent(),
                Value<DateTime> incurredAt = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesTableCompanion(
                id: id,
                remoteId: remoteId,
                ownerId: ownerId,
                category: category,
                amount: amount,
                eventId: eventId,
                note: note,
                receiptUrl: receiptUrl,
                incurredAt: incurredAt,
                createdAt: createdAt,
                pending: pending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> remoteId = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                required String category,
                required double amount,
                Value<String?> eventId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> receiptUrl = const Value.absent(),
                required DateTime incurredAt,
                Value<DateTime?> createdAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesTableCompanion.insert(
                id: id,
                remoteId: remoteId,
                ownerId: ownerId,
                category: category,
                amount: amount,
                eventId: eventId,
                note: note,
                receiptUrl: receiptUrl,
                incurredAt: incurredAt,
                createdAt: createdAt,
                pending: pending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpensesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTableTable,
      ExpenseRow,
      $$ExpensesTableTableFilterComposer,
      $$ExpensesTableTableOrderingComposer,
      $$ExpensesTableTableAnnotationComposer,
      $$ExpensesTableTableCreateCompanionBuilder,
      $$ExpensesTableTableUpdateCompanionBuilder,
      (
        ExpenseRow,
        BaseReferences<_$AppDatabase, $ExpensesTableTable, ExpenseRow>,
      ),
      ExpenseRow,
      PrefetchHooks Function()
    >;
typedef $$BookingsTableTableCreateCompanionBuilder =
    BookingsTableCompanion Function({
      required String id,
      Value<String?> remoteId,
      required String studioId,
      required String createdByUserId,
      required String title,
      required String eventType,
      required DateTime date,
      required String startTime,
      required String endTime,
      required String shift,
      Value<String?> clientName,
      Value<String?> clientPhone,
      Value<String?> venue,
      Value<bool> outdoor,
      Value<String?> brideName,
      Value<String?> groomName,
      Value<String?> clientId,
      Value<String?> packageId,
      Value<double?> customPrice,
      Value<double?> coverageHours,
      Value<double?> extraHourRate,
      Value<String?> driveLink,
      Value<String?> clientRequirementsJson,
      Value<String?> notes,
      Value<String?> chiefPhotographerUserId,
      Value<double?> chiefHours,
      Value<bool> hidePaymentFromTeam,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<int> rowid,
    });
typedef $$BookingsTableTableUpdateCompanionBuilder =
    BookingsTableCompanion Function({
      Value<String> id,
      Value<String?> remoteId,
      Value<String> studioId,
      Value<String> createdByUserId,
      Value<String> title,
      Value<String> eventType,
      Value<DateTime> date,
      Value<String> startTime,
      Value<String> endTime,
      Value<String> shift,
      Value<String?> clientName,
      Value<String?> clientPhone,
      Value<String?> venue,
      Value<bool> outdoor,
      Value<String?> brideName,
      Value<String?> groomName,
      Value<String?> clientId,
      Value<String?> packageId,
      Value<double?> customPrice,
      Value<double?> coverageHours,
      Value<double?> extraHourRate,
      Value<String?> driveLink,
      Value<String?> clientRequirementsJson,
      Value<String?> notes,
      Value<String?> chiefPhotographerUserId,
      Value<double?> chiefHours,
      Value<bool> hidePaymentFromTeam,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<int> rowid,
    });

class $$BookingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $BookingsTableTable> {
  $$BookingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studioId => $composableBuilder(
    column: $table.studioId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdByUserId => $composableBuilder(
    column: $table.createdByUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shift => $composableBuilder(
    column: $table.shift,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientPhone => $composableBuilder(
    column: $table.clientPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get venue => $composableBuilder(
    column: $table.venue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get outdoor => $composableBuilder(
    column: $table.outdoor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brideName => $composableBuilder(
    column: $table.brideName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groomName => $composableBuilder(
    column: $table.groomName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageId => $composableBuilder(
    column: $table.packageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get customPrice => $composableBuilder(
    column: $table.customPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get coverageHours => $composableBuilder(
    column: $table.coverageHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get extraHourRate => $composableBuilder(
    column: $table.extraHourRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driveLink => $composableBuilder(
    column: $table.driveLink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientRequirementsJson => $composableBuilder(
    column: $table.clientRequirementsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chiefPhotographerUserId => $composableBuilder(
    column: $table.chiefPhotographerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get chiefHours => $composableBuilder(
    column: $table.chiefHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidePaymentFromTeam => $composableBuilder(
    column: $table.hidePaymentFromTeam,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BookingsTableTable> {
  $$BookingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studioId => $composableBuilder(
    column: $table.studioId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdByUserId => $composableBuilder(
    column: $table.createdByUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shift => $composableBuilder(
    column: $table.shift,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientPhone => $composableBuilder(
    column: $table.clientPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get venue => $composableBuilder(
    column: $table.venue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get outdoor => $composableBuilder(
    column: $table.outdoor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brideName => $composableBuilder(
    column: $table.brideName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groomName => $composableBuilder(
    column: $table.groomName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageId => $composableBuilder(
    column: $table.packageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get customPrice => $composableBuilder(
    column: $table.customPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get coverageHours => $composableBuilder(
    column: $table.coverageHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get extraHourRate => $composableBuilder(
    column: $table.extraHourRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driveLink => $composableBuilder(
    column: $table.driveLink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientRequirementsJson => $composableBuilder(
    column: $table.clientRequirementsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chiefPhotographerUserId => $composableBuilder(
    column: $table.chiefPhotographerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get chiefHours => $composableBuilder(
    column: $table.chiefHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidePaymentFromTeam => $composableBuilder(
    column: $table.hidePaymentFromTeam,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookingsTableTable> {
  $$BookingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get studioId =>
      $composableBuilder(column: $table.studioId, builder: (column) => column);

  GeneratedColumn<String> get createdByUserId => $composableBuilder(
    column: $table.createdByUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get shift =>
      $composableBuilder(column: $table.shift, builder: (column) => column);

  GeneratedColumn<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientPhone => $composableBuilder(
    column: $table.clientPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get venue =>
      $composableBuilder(column: $table.venue, builder: (column) => column);

  GeneratedColumn<bool> get outdoor =>
      $composableBuilder(column: $table.outdoor, builder: (column) => column);

  GeneratedColumn<String> get brideName =>
      $composableBuilder(column: $table.brideName, builder: (column) => column);

  GeneratedColumn<String> get groomName =>
      $composableBuilder(column: $table.groomName, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get packageId =>
      $composableBuilder(column: $table.packageId, builder: (column) => column);

  GeneratedColumn<double> get customPrice => $composableBuilder(
    column: $table.customPrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get coverageHours => $composableBuilder(
    column: $table.coverageHours,
    builder: (column) => column,
  );

  GeneratedColumn<double> get extraHourRate => $composableBuilder(
    column: $table.extraHourRate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get driveLink =>
      $composableBuilder(column: $table.driveLink, builder: (column) => column);

  GeneratedColumn<String> get clientRequirementsJson => $composableBuilder(
    column: $table.clientRequirementsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get chiefPhotographerUserId => $composableBuilder(
    column: $table.chiefPhotographerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get chiefHours => $composableBuilder(
    column: $table.chiefHours,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hidePaymentFromTeam => $composableBuilder(
    column: $table.hidePaymentFromTeam,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pending =>
      $composableBuilder(column: $table.pending, builder: (column) => column);
}

class $$BookingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookingsTableTable,
          BookingRow,
          $$BookingsTableTableFilterComposer,
          $$BookingsTableTableOrderingComposer,
          $$BookingsTableTableAnnotationComposer,
          $$BookingsTableTableCreateCompanionBuilder,
          $$BookingsTableTableUpdateCompanionBuilder,
          (
            BookingRow,
            BaseReferences<_$AppDatabase, $BookingsTableTable, BookingRow>,
          ),
          BookingRow,
          PrefetchHooks Function()
        > {
  $$BookingsTableTableTableManager(_$AppDatabase db, $BookingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> studioId = const Value.absent(),
                Value<String> createdByUserId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<String> endTime = const Value.absent(),
                Value<String> shift = const Value.absent(),
                Value<String?> clientName = const Value.absent(),
                Value<String?> clientPhone = const Value.absent(),
                Value<String?> venue = const Value.absent(),
                Value<bool> outdoor = const Value.absent(),
                Value<String?> brideName = const Value.absent(),
                Value<String?> groomName = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String?> packageId = const Value.absent(),
                Value<double?> customPrice = const Value.absent(),
                Value<double?> coverageHours = const Value.absent(),
                Value<double?> extraHourRate = const Value.absent(),
                Value<String?> driveLink = const Value.absent(),
                Value<String?> clientRequirementsJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> chiefPhotographerUserId = const Value.absent(),
                Value<double?> chiefHours = const Value.absent(),
                Value<bool> hidePaymentFromTeam = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookingsTableCompanion(
                id: id,
                remoteId: remoteId,
                studioId: studioId,
                createdByUserId: createdByUserId,
                title: title,
                eventType: eventType,
                date: date,
                startTime: startTime,
                endTime: endTime,
                shift: shift,
                clientName: clientName,
                clientPhone: clientPhone,
                venue: venue,
                outdoor: outdoor,
                brideName: brideName,
                groomName: groomName,
                clientId: clientId,
                packageId: packageId,
                customPrice: customPrice,
                coverageHours: coverageHours,
                extraHourRate: extraHourRate,
                driveLink: driveLink,
                clientRequirementsJson: clientRequirementsJson,
                notes: notes,
                chiefPhotographerUserId: chiefPhotographerUserId,
                chiefHours: chiefHours,
                hidePaymentFromTeam: hidePaymentFromTeam,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pending: pending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> remoteId = const Value.absent(),
                required String studioId,
                required String createdByUserId,
                required String title,
                required String eventType,
                required DateTime date,
                required String startTime,
                required String endTime,
                required String shift,
                Value<String?> clientName = const Value.absent(),
                Value<String?> clientPhone = const Value.absent(),
                Value<String?> venue = const Value.absent(),
                Value<bool> outdoor = const Value.absent(),
                Value<String?> brideName = const Value.absent(),
                Value<String?> groomName = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String?> packageId = const Value.absent(),
                Value<double?> customPrice = const Value.absent(),
                Value<double?> coverageHours = const Value.absent(),
                Value<double?> extraHourRate = const Value.absent(),
                Value<String?> driveLink = const Value.absent(),
                Value<String?> clientRequirementsJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> chiefPhotographerUserId = const Value.absent(),
                Value<double?> chiefHours = const Value.absent(),
                Value<bool> hidePaymentFromTeam = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookingsTableCompanion.insert(
                id: id,
                remoteId: remoteId,
                studioId: studioId,
                createdByUserId: createdByUserId,
                title: title,
                eventType: eventType,
                date: date,
                startTime: startTime,
                endTime: endTime,
                shift: shift,
                clientName: clientName,
                clientPhone: clientPhone,
                venue: venue,
                outdoor: outdoor,
                brideName: brideName,
                groomName: groomName,
                clientId: clientId,
                packageId: packageId,
                customPrice: customPrice,
                coverageHours: coverageHours,
                extraHourRate: extraHourRate,
                driveLink: driveLink,
                clientRequirementsJson: clientRequirementsJson,
                notes: notes,
                chiefPhotographerUserId: chiefPhotographerUserId,
                chiefHours: chiefHours,
                hidePaymentFromTeam: hidePaymentFromTeam,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pending: pending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookingsTableTable,
      BookingRow,
      $$BookingsTableTableFilterComposer,
      $$BookingsTableTableOrderingComposer,
      $$BookingsTableTableAnnotationComposer,
      $$BookingsTableTableCreateCompanionBuilder,
      $$BookingsTableTableUpdateCompanionBuilder,
      (
        BookingRow,
        BaseReferences<_$AppDatabase, $BookingsTableTable, BookingRow>,
      ),
      BookingRow,
      PrefetchHooks Function()
    >;
typedef $$ClientsTableTableCreateCompanionBuilder =
    ClientsTableCompanion Function({
      required String id,
      Value<String?> remoteId,
      required String studioId,
      required String name,
      required String phone,
      Value<String?> email,
      Value<String?> address,
      Value<DateTime?> dob,
      Value<DateTime?> anniversary,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<int> rowid,
    });
typedef $$ClientsTableTableUpdateCompanionBuilder =
    ClientsTableCompanion Function({
      Value<String> id,
      Value<String?> remoteId,
      Value<String> studioId,
      Value<String> name,
      Value<String> phone,
      Value<String?> email,
      Value<String?> address,
      Value<DateTime?> dob,
      Value<DateTime?> anniversary,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<int> rowid,
    });

class $$ClientsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClientsTableTable> {
  $$ClientsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studioId => $composableBuilder(
    column: $table.studioId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dob => $composableBuilder(
    column: $table.dob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get anniversary => $composableBuilder(
    column: $table.anniversary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClientsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientsTableTable> {
  $$ClientsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studioId => $composableBuilder(
    column: $table.studioId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dob => $composableBuilder(
    column: $table.dob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get anniversary => $composableBuilder(
    column: $table.anniversary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientsTableTable> {
  $$ClientsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get studioId =>
      $composableBuilder(column: $table.studioId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<DateTime> get dob =>
      $composableBuilder(column: $table.dob, builder: (column) => column);

  GeneratedColumn<DateTime> get anniversary => $composableBuilder(
    column: $table.anniversary,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pending =>
      $composableBuilder(column: $table.pending, builder: (column) => column);
}

class $$ClientsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClientsTableTable,
          ClientRow,
          $$ClientsTableTableFilterComposer,
          $$ClientsTableTableOrderingComposer,
          $$ClientsTableTableAnnotationComposer,
          $$ClientsTableTableCreateCompanionBuilder,
          $$ClientsTableTableUpdateCompanionBuilder,
          (
            ClientRow,
            BaseReferences<_$AppDatabase, $ClientsTableTable, ClientRow>,
          ),
          ClientRow,
          PrefetchHooks Function()
        > {
  $$ClientsTableTableTableManager(_$AppDatabase db, $ClientsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> studioId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<DateTime?> dob = const Value.absent(),
                Value<DateTime?> anniversary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientsTableCompanion(
                id: id,
                remoteId: remoteId,
                studioId: studioId,
                name: name,
                phone: phone,
                email: email,
                address: address,
                dob: dob,
                anniversary: anniversary,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pending: pending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> remoteId = const Value.absent(),
                required String studioId,
                required String name,
                required String phone,
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<DateTime?> dob = const Value.absent(),
                Value<DateTime?> anniversary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientsTableCompanion.insert(
                id: id,
                remoteId: remoteId,
                studioId: studioId,
                name: name,
                phone: phone,
                email: email,
                address: address,
                dob: dob,
                anniversary: anniversary,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pending: pending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClientsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClientsTableTable,
      ClientRow,
      $$ClientsTableTableFilterComposer,
      $$ClientsTableTableOrderingComposer,
      $$ClientsTableTableAnnotationComposer,
      $$ClientsTableTableCreateCompanionBuilder,
      $$ClientsTableTableUpdateCompanionBuilder,
      (ClientRow, BaseReferences<_$AppDatabase, $ClientsTableTable, ClientRow>),
      ClientRow,
      PrefetchHooks Function()
    >;
typedef $$AssignmentsTableTableCreateCompanionBuilder =
    AssignmentsTableCompanion Function({
      required String id,
      Value<String?> remoteId,
      required String bookingId,
      required String userId,
      required String role,
      Value<double> payout,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<int> rowid,
    });
typedef $$AssignmentsTableTableUpdateCompanionBuilder =
    AssignmentsTableCompanion Function({
      Value<String> id,
      Value<String?> remoteId,
      Value<String> bookingId,
      Value<String> userId,
      Value<String> role,
      Value<double> payout,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<int> rowid,
    });

class $$AssignmentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AssignmentsTableTable> {
  $$AssignmentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookingId => $composableBuilder(
    column: $table.bookingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get payout => $composableBuilder(
    column: $table.payout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssignmentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AssignmentsTableTable> {
  $$AssignmentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookingId => $composableBuilder(
    column: $table.bookingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get payout => $composableBuilder(
    column: $table.payout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssignmentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssignmentsTableTable> {
  $$AssignmentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get bookingId =>
      $composableBuilder(column: $table.bookingId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<double> get payout =>
      $composableBuilder(column: $table.payout, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pending =>
      $composableBuilder(column: $table.pending, builder: (column) => column);
}

class $$AssignmentsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssignmentsTableTable,
          AssignmentRow,
          $$AssignmentsTableTableFilterComposer,
          $$AssignmentsTableTableOrderingComposer,
          $$AssignmentsTableTableAnnotationComposer,
          $$AssignmentsTableTableCreateCompanionBuilder,
          $$AssignmentsTableTableUpdateCompanionBuilder,
          (
            AssignmentRow,
            BaseReferences<
              _$AppDatabase,
              $AssignmentsTableTable,
              AssignmentRow
            >,
          ),
          AssignmentRow,
          PrefetchHooks Function()
        > {
  $$AssignmentsTableTableTableManager(
    _$AppDatabase db,
    $AssignmentsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssignmentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssignmentsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssignmentsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> bookingId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<double> payout = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssignmentsTableCompanion(
                id: id,
                remoteId: remoteId,
                bookingId: bookingId,
                userId: userId,
                role: role,
                payout: payout,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pending: pending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> remoteId = const Value.absent(),
                required String bookingId,
                required String userId,
                required String role,
                Value<double> payout = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssignmentsTableCompanion.insert(
                id: id,
                remoteId: remoteId,
                bookingId: bookingId,
                userId: userId,
                role: role,
                payout: payout,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pending: pending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssignmentsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssignmentsTableTable,
      AssignmentRow,
      $$AssignmentsTableTableFilterComposer,
      $$AssignmentsTableTableOrderingComposer,
      $$AssignmentsTableTableAnnotationComposer,
      $$AssignmentsTableTableCreateCompanionBuilder,
      $$AssignmentsTableTableUpdateCompanionBuilder,
      (
        AssignmentRow,
        BaseReferences<_$AppDatabase, $AssignmentsTableTable, AssignmentRow>,
      ),
      AssignmentRow,
      PrefetchHooks Function()
    >;
typedef $$PaymentsTableTableCreateCompanionBuilder =
    PaymentsTableCompanion Function({
      required String id,
      Value<String?> remoteId,
      required String bookingId,
      required String kind,
      required double amount,
      Value<String?> method,
      Value<String?> note,
      Value<DateTime?> paidAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<int> rowid,
    });
typedef $$PaymentsTableTableUpdateCompanionBuilder =
    PaymentsTableCompanion Function({
      Value<String> id,
      Value<String?> remoteId,
      Value<String> bookingId,
      Value<String> kind,
      Value<double> amount,
      Value<String?> method,
      Value<String?> note,
      Value<DateTime?> paidAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<int> rowid,
    });

class $$PaymentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTableTable> {
  $$PaymentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookingId => $composableBuilder(
    column: $table.bookingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaymentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTableTable> {
  $$PaymentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookingId => $composableBuilder(
    column: $table.bookingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaymentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTableTable> {
  $$PaymentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get bookingId =>
      $composableBuilder(column: $table.bookingId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pending =>
      $composableBuilder(column: $table.pending, builder: (column) => column);
}

class $$PaymentsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTableTable,
          PaymentRow,
          $$PaymentsTableTableFilterComposer,
          $$PaymentsTableTableOrderingComposer,
          $$PaymentsTableTableAnnotationComposer,
          $$PaymentsTableTableCreateCompanionBuilder,
          $$PaymentsTableTableUpdateCompanionBuilder,
          (
            PaymentRow,
            BaseReferences<_$AppDatabase, $PaymentsTableTable, PaymentRow>,
          ),
          PaymentRow,
          PrefetchHooks Function()
        > {
  $$PaymentsTableTableTableManager(_$AppDatabase db, $PaymentsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> bookingId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String?> method = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> paidAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsTableCompanion(
                id: id,
                remoteId: remoteId,
                bookingId: bookingId,
                kind: kind,
                amount: amount,
                method: method,
                note: note,
                paidAt: paidAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pending: pending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> remoteId = const Value.absent(),
                required String bookingId,
                required String kind,
                required double amount,
                Value<String?> method = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> paidAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsTableCompanion.insert(
                id: id,
                remoteId: remoteId,
                bookingId: bookingId,
                kind: kind,
                amount: amount,
                method: method,
                note: note,
                paidAt: paidAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pending: pending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaymentsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTableTable,
      PaymentRow,
      $$PaymentsTableTableFilterComposer,
      $$PaymentsTableTableOrderingComposer,
      $$PaymentsTableTableAnnotationComposer,
      $$PaymentsTableTableCreateCompanionBuilder,
      $$PaymentsTableTableUpdateCompanionBuilder,
      (
        PaymentRow,
        BaseReferences<_$AppDatabase, $PaymentsTableTable, PaymentRow>,
      ),
      PaymentRow,
      PrefetchHooks Function()
    >;
typedef $$PackagesTableTableCreateCompanionBuilder =
    PackagesTableCompanion Function({
      required String id,
      Value<String?> remoteId,
      required String studioId,
      required String name,
      required double basePrice,
      Value<double> discount,
      Value<double?> coverageHours,
      Value<double?> extraHourRate,
      Value<String?> printSize,
      Value<int?> printQuantity,
      Value<String?> albumText,
      Value<String?> deliveryMethod,
      Value<int?> trailersPerEvent,
      Value<int?> fullVideosPerEvent,
      Value<String?> itemsJson,
      Value<String?> inclusionsJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<int> rowid,
    });
typedef $$PackagesTableTableUpdateCompanionBuilder =
    PackagesTableCompanion Function({
      Value<String> id,
      Value<String?> remoteId,
      Value<String> studioId,
      Value<String> name,
      Value<double> basePrice,
      Value<double> discount,
      Value<double?> coverageHours,
      Value<double?> extraHourRate,
      Value<String?> printSize,
      Value<int?> printQuantity,
      Value<String?> albumText,
      Value<String?> deliveryMethod,
      Value<int?> trailersPerEvent,
      Value<int?> fullVideosPerEvent,
      Value<String?> itemsJson,
      Value<String?> inclusionsJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<int> rowid,
    });

class $$PackagesTableTableFilterComposer
    extends Composer<_$AppDatabase, $PackagesTableTable> {
  $$PackagesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studioId => $composableBuilder(
    column: $table.studioId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get basePrice => $composableBuilder(
    column: $table.basePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get coverageHours => $composableBuilder(
    column: $table.coverageHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get extraHourRate => $composableBuilder(
    column: $table.extraHourRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get printSize => $composableBuilder(
    column: $table.printSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get printQuantity => $composableBuilder(
    column: $table.printQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumText => $composableBuilder(
    column: $table.albumText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryMethod => $composableBuilder(
    column: $table.deliveryMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trailersPerEvent => $composableBuilder(
    column: $table.trailersPerEvent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fullVideosPerEvent => $composableBuilder(
    column: $table.fullVideosPerEvent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inclusionsJson => $composableBuilder(
    column: $table.inclusionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PackagesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PackagesTableTable> {
  $$PackagesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studioId => $composableBuilder(
    column: $table.studioId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get basePrice => $composableBuilder(
    column: $table.basePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get coverageHours => $composableBuilder(
    column: $table.coverageHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get extraHourRate => $composableBuilder(
    column: $table.extraHourRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get printSize => $composableBuilder(
    column: $table.printSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get printQuantity => $composableBuilder(
    column: $table.printQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumText => $composableBuilder(
    column: $table.albumText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryMethod => $composableBuilder(
    column: $table.deliveryMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trailersPerEvent => $composableBuilder(
    column: $table.trailersPerEvent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fullVideosPerEvent => $composableBuilder(
    column: $table.fullVideosPerEvent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inclusionsJson => $composableBuilder(
    column: $table.inclusionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PackagesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PackagesTableTable> {
  $$PackagesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get studioId =>
      $composableBuilder(column: $table.studioId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get basePrice =>
      $composableBuilder(column: $table.basePrice, builder: (column) => column);

  GeneratedColumn<double> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<double> get coverageHours => $composableBuilder(
    column: $table.coverageHours,
    builder: (column) => column,
  );

  GeneratedColumn<double> get extraHourRate => $composableBuilder(
    column: $table.extraHourRate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get printSize =>
      $composableBuilder(column: $table.printSize, builder: (column) => column);

  GeneratedColumn<int> get printQuantity => $composableBuilder(
    column: $table.printQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get albumText =>
      $composableBuilder(column: $table.albumText, builder: (column) => column);

  GeneratedColumn<String> get deliveryMethod => $composableBuilder(
    column: $table.deliveryMethod,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trailersPerEvent => $composableBuilder(
    column: $table.trailersPerEvent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fullVideosPerEvent => $composableBuilder(
    column: $table.fullVideosPerEvent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  GeneratedColumn<String> get inclusionsJson => $composableBuilder(
    column: $table.inclusionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pending =>
      $composableBuilder(column: $table.pending, builder: (column) => column);
}

class $$PackagesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PackagesTableTable,
          PackageRow,
          $$PackagesTableTableFilterComposer,
          $$PackagesTableTableOrderingComposer,
          $$PackagesTableTableAnnotationComposer,
          $$PackagesTableTableCreateCompanionBuilder,
          $$PackagesTableTableUpdateCompanionBuilder,
          (
            PackageRow,
            BaseReferences<_$AppDatabase, $PackagesTableTable, PackageRow>,
          ),
          PackageRow,
          PrefetchHooks Function()
        > {
  $$PackagesTableTableTableManager(_$AppDatabase db, $PackagesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PackagesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PackagesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PackagesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> studioId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> basePrice = const Value.absent(),
                Value<double> discount = const Value.absent(),
                Value<double?> coverageHours = const Value.absent(),
                Value<double?> extraHourRate = const Value.absent(),
                Value<String?> printSize = const Value.absent(),
                Value<int?> printQuantity = const Value.absent(),
                Value<String?> albumText = const Value.absent(),
                Value<String?> deliveryMethod = const Value.absent(),
                Value<int?> trailersPerEvent = const Value.absent(),
                Value<int?> fullVideosPerEvent = const Value.absent(),
                Value<String?> itemsJson = const Value.absent(),
                Value<String?> inclusionsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PackagesTableCompanion(
                id: id,
                remoteId: remoteId,
                studioId: studioId,
                name: name,
                basePrice: basePrice,
                discount: discount,
                coverageHours: coverageHours,
                extraHourRate: extraHourRate,
                printSize: printSize,
                printQuantity: printQuantity,
                albumText: albumText,
                deliveryMethod: deliveryMethod,
                trailersPerEvent: trailersPerEvent,
                fullVideosPerEvent: fullVideosPerEvent,
                itemsJson: itemsJson,
                inclusionsJson: inclusionsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pending: pending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> remoteId = const Value.absent(),
                required String studioId,
                required String name,
                required double basePrice,
                Value<double> discount = const Value.absent(),
                Value<double?> coverageHours = const Value.absent(),
                Value<double?> extraHourRate = const Value.absent(),
                Value<String?> printSize = const Value.absent(),
                Value<int?> printQuantity = const Value.absent(),
                Value<String?> albumText = const Value.absent(),
                Value<String?> deliveryMethod = const Value.absent(),
                Value<int?> trailersPerEvent = const Value.absent(),
                Value<int?> fullVideosPerEvent = const Value.absent(),
                Value<String?> itemsJson = const Value.absent(),
                Value<String?> inclusionsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PackagesTableCompanion.insert(
                id: id,
                remoteId: remoteId,
                studioId: studioId,
                name: name,
                basePrice: basePrice,
                discount: discount,
                coverageHours: coverageHours,
                extraHourRate: extraHourRate,
                printSize: printSize,
                printQuantity: printQuantity,
                albumText: albumText,
                deliveryMethod: deliveryMethod,
                trailersPerEvent: trailersPerEvent,
                fullVideosPerEvent: fullVideosPerEvent,
                itemsJson: itemsJson,
                inclusionsJson: inclusionsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pending: pending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PackagesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PackagesTableTable,
      PackageRow,
      $$PackagesTableTableFilterComposer,
      $$PackagesTableTableOrderingComposer,
      $$PackagesTableTableAnnotationComposer,
      $$PackagesTableTableCreateCompanionBuilder,
      $$PackagesTableTableUpdateCompanionBuilder,
      (
        PackageRow,
        BaseReferences<_$AppDatabase, $PackagesTableTable, PackageRow>,
      ),
      PackageRow,
      PrefetchHooks Function()
    >;
typedef $$StatusHistoryTableTableCreateCompanionBuilder =
    StatusHistoryTableCompanion Function({
      required String id,
      Value<String?> remoteId,
      required String bookingId,
      required String fromStatus,
      required String toStatus,
      required String changedByUserId,
      Value<String?> note,
      required DateTime at,
      Value<bool> pending,
      Value<int> rowid,
    });
typedef $$StatusHistoryTableTableUpdateCompanionBuilder =
    StatusHistoryTableCompanion Function({
      Value<String> id,
      Value<String?> remoteId,
      Value<String> bookingId,
      Value<String> fromStatus,
      Value<String> toStatus,
      Value<String> changedByUserId,
      Value<String?> note,
      Value<DateTime> at,
      Value<bool> pending,
      Value<int> rowid,
    });

class $$StatusHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $StatusHistoryTableTable> {
  $$StatusHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookingId => $composableBuilder(
    column: $table.bookingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromStatus => $composableBuilder(
    column: $table.fromStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toStatus => $composableBuilder(
    column: $table.toStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changedByUserId => $composableBuilder(
    column: $table.changedByUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StatusHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StatusHistoryTableTable> {
  $$StatusHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookingId => $composableBuilder(
    column: $table.bookingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromStatus => $composableBuilder(
    column: $table.fromStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toStatus => $composableBuilder(
    column: $table.toStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changedByUserId => $composableBuilder(
    column: $table.changedByUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StatusHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StatusHistoryTableTable> {
  $$StatusHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get bookingId =>
      $composableBuilder(column: $table.bookingId, builder: (column) => column);

  GeneratedColumn<String> get fromStatus => $composableBuilder(
    column: $table.fromStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toStatus =>
      $composableBuilder(column: $table.toStatus, builder: (column) => column);

  GeneratedColumn<String> get changedByUserId => $composableBuilder(
    column: $table.changedByUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<bool> get pending =>
      $composableBuilder(column: $table.pending, builder: (column) => column);
}

class $$StatusHistoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StatusHistoryTableTable,
          StatusHistoryEntryRow,
          $$StatusHistoryTableTableFilterComposer,
          $$StatusHistoryTableTableOrderingComposer,
          $$StatusHistoryTableTableAnnotationComposer,
          $$StatusHistoryTableTableCreateCompanionBuilder,
          $$StatusHistoryTableTableUpdateCompanionBuilder,
          (
            StatusHistoryEntryRow,
            BaseReferences<
              _$AppDatabase,
              $StatusHistoryTableTable,
              StatusHistoryEntryRow
            >,
          ),
          StatusHistoryEntryRow,
          PrefetchHooks Function()
        > {
  $$StatusHistoryTableTableTableManager(
    _$AppDatabase db,
    $StatusHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StatusHistoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StatusHistoryTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StatusHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> bookingId = const Value.absent(),
                Value<String> fromStatus = const Value.absent(),
                Value<String> toStatus = const Value.absent(),
                Value<String> changedByUserId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StatusHistoryTableCompanion(
                id: id,
                remoteId: remoteId,
                bookingId: bookingId,
                fromStatus: fromStatus,
                toStatus: toStatus,
                changedByUserId: changedByUserId,
                note: note,
                at: at,
                pending: pending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> remoteId = const Value.absent(),
                required String bookingId,
                required String fromStatus,
                required String toStatus,
                required String changedByUserId,
                Value<String?> note = const Value.absent(),
                required DateTime at,
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StatusHistoryTableCompanion.insert(
                id: id,
                remoteId: remoteId,
                bookingId: bookingId,
                fromStatus: fromStatus,
                toStatus: toStatus,
                changedByUserId: changedByUserId,
                note: note,
                at: at,
                pending: pending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StatusHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StatusHistoryTableTable,
      StatusHistoryEntryRow,
      $$StatusHistoryTableTableFilterComposer,
      $$StatusHistoryTableTableOrderingComposer,
      $$StatusHistoryTableTableAnnotationComposer,
      $$StatusHistoryTableTableCreateCompanionBuilder,
      $$StatusHistoryTableTableUpdateCompanionBuilder,
      (
        StatusHistoryEntryRow,
        BaseReferences<
          _$AppDatabase,
          $StatusHistoryTableTable,
          StatusHistoryEntryRow
        >,
      ),
      StatusHistoryEntryRow,
      PrefetchHooks Function()
    >;
typedef $$ReEditRequestsTableTableCreateCompanionBuilder =
    ReEditRequestsTableCompanion Function({
      required String id,
      Value<String?> remoteId,
      required String bookingId,
      required int round,
      Value<String?> editorUserId,
      required DateTime deadline,
      Value<String?> referenceImageUrlsJson,
      Value<String?> notes,
      Value<String> status,
      required String requestedByUserId,
      Value<DateTime> requestedAt,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<int> rowid,
    });
typedef $$ReEditRequestsTableTableUpdateCompanionBuilder =
    ReEditRequestsTableCompanion Function({
      Value<String> id,
      Value<String?> remoteId,
      Value<String> bookingId,
      Value<int> round,
      Value<String?> editorUserId,
      Value<DateTime> deadline,
      Value<String?> referenceImageUrlsJson,
      Value<String?> notes,
      Value<String> status,
      Value<String> requestedByUserId,
      Value<DateTime> requestedAt,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<int> rowid,
    });

class $$ReEditRequestsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ReEditRequestsTableTable> {
  $$ReEditRequestsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookingId => $composableBuilder(
    column: $table.bookingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get round => $composableBuilder(
    column: $table.round,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get editorUserId => $composableBuilder(
    column: $table.editorUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceImageUrlsJson => $composableBuilder(
    column: $table.referenceImageUrlsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestedByUserId => $composableBuilder(
    column: $table.requestedByUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReEditRequestsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ReEditRequestsTableTable> {
  $$ReEditRequestsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookingId => $composableBuilder(
    column: $table.bookingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get round => $composableBuilder(
    column: $table.round,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get editorUserId => $composableBuilder(
    column: $table.editorUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceImageUrlsJson => $composableBuilder(
    column: $table.referenceImageUrlsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestedByUserId => $composableBuilder(
    column: $table.requestedByUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReEditRequestsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReEditRequestsTableTable> {
  $$ReEditRequestsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get bookingId =>
      $composableBuilder(column: $table.bookingId, builder: (column) => column);

  GeneratedColumn<int> get round =>
      $composableBuilder(column: $table.round, builder: (column) => column);

  GeneratedColumn<String> get editorUserId => $composableBuilder(
    column: $table.editorUserId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<String> get referenceImageUrlsJson => $composableBuilder(
    column: $table.referenceImageUrlsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get requestedByUserId => $composableBuilder(
    column: $table.requestedByUserId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pending =>
      $composableBuilder(column: $table.pending, builder: (column) => column);
}

class $$ReEditRequestsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReEditRequestsTableTable,
          ReEditRequestRow,
          $$ReEditRequestsTableTableFilterComposer,
          $$ReEditRequestsTableTableOrderingComposer,
          $$ReEditRequestsTableTableAnnotationComposer,
          $$ReEditRequestsTableTableCreateCompanionBuilder,
          $$ReEditRequestsTableTableUpdateCompanionBuilder,
          (
            ReEditRequestRow,
            BaseReferences<
              _$AppDatabase,
              $ReEditRequestsTableTable,
              ReEditRequestRow
            >,
          ),
          ReEditRequestRow,
          PrefetchHooks Function()
        > {
  $$ReEditRequestsTableTableTableManager(
    _$AppDatabase db,
    $ReEditRequestsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReEditRequestsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReEditRequestsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ReEditRequestsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> bookingId = const Value.absent(),
                Value<int> round = const Value.absent(),
                Value<String?> editorUserId = const Value.absent(),
                Value<DateTime> deadline = const Value.absent(),
                Value<String?> referenceImageUrlsJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> requestedByUserId = const Value.absent(),
                Value<DateTime> requestedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReEditRequestsTableCompanion(
                id: id,
                remoteId: remoteId,
                bookingId: bookingId,
                round: round,
                editorUserId: editorUserId,
                deadline: deadline,
                referenceImageUrlsJson: referenceImageUrlsJson,
                notes: notes,
                status: status,
                requestedByUserId: requestedByUserId,
                requestedAt: requestedAt,
                updatedAt: updatedAt,
                pending: pending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> remoteId = const Value.absent(),
                required String bookingId,
                required int round,
                Value<String?> editorUserId = const Value.absent(),
                required DateTime deadline,
                Value<String?> referenceImageUrlsJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                required String requestedByUserId,
                Value<DateTime> requestedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReEditRequestsTableCompanion.insert(
                id: id,
                remoteId: remoteId,
                bookingId: bookingId,
                round: round,
                editorUserId: editorUserId,
                deadline: deadline,
                referenceImageUrlsJson: referenceImageUrlsJson,
                notes: notes,
                status: status,
                requestedByUserId: requestedByUserId,
                requestedAt: requestedAt,
                updatedAt: updatedAt,
                pending: pending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReEditRequestsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReEditRequestsTableTable,
      ReEditRequestRow,
      $$ReEditRequestsTableTableFilterComposer,
      $$ReEditRequestsTableTableOrderingComposer,
      $$ReEditRequestsTableTableAnnotationComposer,
      $$ReEditRequestsTableTableCreateCompanionBuilder,
      $$ReEditRequestsTableTableUpdateCompanionBuilder,
      (
        ReEditRequestRow,
        BaseReferences<
          _$AppDatabase,
          $ReEditRequestsTableTable,
          ReEditRequestRow
        >,
      ),
      ReEditRequestRow,
      PrefetchHooks Function()
    >;
typedef $$TaskProgressTableTableCreateCompanionBuilder =
    TaskProgressTableCompanion Function({
      required String bookingId,
      required String userId,
      required int percentage,
      Value<String?> note,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<int> rowid,
    });
typedef $$TaskProgressTableTableUpdateCompanionBuilder =
    TaskProgressTableCompanion Function({
      Value<String> bookingId,
      Value<String> userId,
      Value<int> percentage,
      Value<String?> note,
      Value<DateTime> updatedAt,
      Value<bool> pending,
      Value<int> rowid,
    });

class $$TaskProgressTableTableFilterComposer
    extends Composer<_$AppDatabase, $TaskProgressTableTable> {
  $$TaskProgressTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bookingId => $composableBuilder(
    column: $table.bookingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskProgressTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskProgressTableTable> {
  $$TaskProgressTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bookingId => $composableBuilder(
    column: $table.bookingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskProgressTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskProgressTableTable> {
  $$TaskProgressTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bookingId =>
      $composableBuilder(column: $table.bookingId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pending =>
      $composableBuilder(column: $table.pending, builder: (column) => column);
}

class $$TaskProgressTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskProgressTableTable,
          TaskProgressRow,
          $$TaskProgressTableTableFilterComposer,
          $$TaskProgressTableTableOrderingComposer,
          $$TaskProgressTableTableAnnotationComposer,
          $$TaskProgressTableTableCreateCompanionBuilder,
          $$TaskProgressTableTableUpdateCompanionBuilder,
          (
            TaskProgressRow,
            BaseReferences<
              _$AppDatabase,
              $TaskProgressTableTable,
              TaskProgressRow
            >,
          ),
          TaskProgressRow,
          PrefetchHooks Function()
        > {
  $$TaskProgressTableTableTableManager(
    _$AppDatabase db,
    $TaskProgressTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskProgressTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskProgressTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskProgressTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> bookingId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> percentage = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskProgressTableCompanion(
                bookingId: bookingId,
                userId: userId,
                percentage: percentage,
                note: note,
                updatedAt: updatedAt,
                pending: pending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookingId,
                required String userId,
                required int percentage,
                Value<String?> note = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskProgressTableCompanion.insert(
                bookingId: bookingId,
                userId: userId,
                percentage: percentage,
                note: note,
                updatedAt: updatedAt,
                pending: pending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskProgressTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskProgressTableTable,
      TaskProgressRow,
      $$TaskProgressTableTableFilterComposer,
      $$TaskProgressTableTableOrderingComposer,
      $$TaskProgressTableTableAnnotationComposer,
      $$TaskProgressTableTableCreateCompanionBuilder,
      $$TaskProgressTableTableUpdateCompanionBuilder,
      (
        TaskProgressRow,
        BaseReferences<_$AppDatabase, $TaskProgressTableTable, TaskProgressRow>,
      ),
      TaskProgressRow,
      PrefetchHooks Function()
    >;
typedef $$PublicBookingRequestsTableTableCreateCompanionBuilder =
    PublicBookingRequestsTableCompanion Function({
      required String id,
      required String studioId,
      required String title,
      required String eventType,
      required DateTime date,
      required String startTime,
      required String endTime,
      required String shift,
      Value<String?> venue,
      Value<String?> brideName,
      Value<String?> groomName,
      required String clientName,
      required String clientPhone,
      Value<String?> clientEmail,
      Value<String?> notes,
      Value<String> status,
      required DateTime submittedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$PublicBookingRequestsTableTableUpdateCompanionBuilder =
    PublicBookingRequestsTableCompanion Function({
      Value<String> id,
      Value<String> studioId,
      Value<String> title,
      Value<String> eventType,
      Value<DateTime> date,
      Value<String> startTime,
      Value<String> endTime,
      Value<String> shift,
      Value<String?> venue,
      Value<String?> brideName,
      Value<String?> groomName,
      Value<String> clientName,
      Value<String> clientPhone,
      Value<String?> clientEmail,
      Value<String?> notes,
      Value<String> status,
      Value<DateTime> submittedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PublicBookingRequestsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PublicBookingRequestsTableTable> {
  $$PublicBookingRequestsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studioId => $composableBuilder(
    column: $table.studioId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shift => $composableBuilder(
    column: $table.shift,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get venue => $composableBuilder(
    column: $table.venue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brideName => $composableBuilder(
    column: $table.brideName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groomName => $composableBuilder(
    column: $table.groomName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientPhone => $composableBuilder(
    column: $table.clientPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientEmail => $composableBuilder(
    column: $table.clientEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PublicBookingRequestsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PublicBookingRequestsTableTable> {
  $$PublicBookingRequestsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studioId => $composableBuilder(
    column: $table.studioId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shift => $composableBuilder(
    column: $table.shift,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get venue => $composableBuilder(
    column: $table.venue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brideName => $composableBuilder(
    column: $table.brideName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groomName => $composableBuilder(
    column: $table.groomName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientPhone => $composableBuilder(
    column: $table.clientPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientEmail => $composableBuilder(
    column: $table.clientEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PublicBookingRequestsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PublicBookingRequestsTableTable> {
  $$PublicBookingRequestsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get studioId =>
      $composableBuilder(column: $table.studioId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get shift =>
      $composableBuilder(column: $table.shift, builder: (column) => column);

  GeneratedColumn<String> get venue =>
      $composableBuilder(column: $table.venue, builder: (column) => column);

  GeneratedColumn<String> get brideName =>
      $composableBuilder(column: $table.brideName, builder: (column) => column);

  GeneratedColumn<String> get groomName =>
      $composableBuilder(column: $table.groomName, builder: (column) => column);

  GeneratedColumn<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientPhone => $composableBuilder(
    column: $table.clientPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientEmail => $composableBuilder(
    column: $table.clientEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PublicBookingRequestsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PublicBookingRequestsTableTable,
          PublicBookingRequestRow,
          $$PublicBookingRequestsTableTableFilterComposer,
          $$PublicBookingRequestsTableTableOrderingComposer,
          $$PublicBookingRequestsTableTableAnnotationComposer,
          $$PublicBookingRequestsTableTableCreateCompanionBuilder,
          $$PublicBookingRequestsTableTableUpdateCompanionBuilder,
          (
            PublicBookingRequestRow,
            BaseReferences<
              _$AppDatabase,
              $PublicBookingRequestsTableTable,
              PublicBookingRequestRow
            >,
          ),
          PublicBookingRequestRow,
          PrefetchHooks Function()
        > {
  $$PublicBookingRequestsTableTableTableManager(
    _$AppDatabase db,
    $PublicBookingRequestsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PublicBookingRequestsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PublicBookingRequestsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PublicBookingRequestsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> studioId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<String> endTime = const Value.absent(),
                Value<String> shift = const Value.absent(),
                Value<String?> venue = const Value.absent(),
                Value<String?> brideName = const Value.absent(),
                Value<String?> groomName = const Value.absent(),
                Value<String> clientName = const Value.absent(),
                Value<String> clientPhone = const Value.absent(),
                Value<String?> clientEmail = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> submittedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PublicBookingRequestsTableCompanion(
                id: id,
                studioId: studioId,
                title: title,
                eventType: eventType,
                date: date,
                startTime: startTime,
                endTime: endTime,
                shift: shift,
                venue: venue,
                brideName: brideName,
                groomName: groomName,
                clientName: clientName,
                clientPhone: clientPhone,
                clientEmail: clientEmail,
                notes: notes,
                status: status,
                submittedAt: submittedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String studioId,
                required String title,
                required String eventType,
                required DateTime date,
                required String startTime,
                required String endTime,
                required String shift,
                Value<String?> venue = const Value.absent(),
                Value<String?> brideName = const Value.absent(),
                Value<String?> groomName = const Value.absent(),
                required String clientName,
                required String clientPhone,
                Value<String?> clientEmail = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime submittedAt,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PublicBookingRequestsTableCompanion.insert(
                id: id,
                studioId: studioId,
                title: title,
                eventType: eventType,
                date: date,
                startTime: startTime,
                endTime: endTime,
                shift: shift,
                venue: venue,
                brideName: brideName,
                groomName: groomName,
                clientName: clientName,
                clientPhone: clientPhone,
                clientEmail: clientEmail,
                notes: notes,
                status: status,
                submittedAt: submittedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PublicBookingRequestsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PublicBookingRequestsTableTable,
      PublicBookingRequestRow,
      $$PublicBookingRequestsTableTableFilterComposer,
      $$PublicBookingRequestsTableTableOrderingComposer,
      $$PublicBookingRequestsTableTableAnnotationComposer,
      $$PublicBookingRequestsTableTableCreateCompanionBuilder,
      $$PublicBookingRequestsTableTableUpdateCompanionBuilder,
      (
        PublicBookingRequestRow,
        BaseReferences<
          _$AppDatabase,
          $PublicBookingRequestsTableTable,
          PublicBookingRequestRow
        >,
      ),
      PublicBookingRequestRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db, _db.usersTable);
  $$UserPreferencesTableTableTableManager get userPreferencesTable =>
      $$UserPreferencesTableTableTableManager(_db, _db.userPreferencesTable);
  $$NotificationPreferencesTableTableTableManager
  get notificationPreferencesTable =>
      $$NotificationPreferencesTableTableTableManager(
        _db,
        _db.notificationPreferencesTable,
      );
  $$GearItemsTableTableTableManager get gearItemsTable =>
      $$GearItemsTableTableTableManager(_db, _db.gearItemsTable);
  $$TeamInvitesTableTableTableManager get teamInvitesTable =>
      $$TeamInvitesTableTableTableManager(_db, _db.teamInvitesTable);
  $$OutboxTableTableTableManager get outboxTable =>
      $$OutboxTableTableTableManager(_db, _db.outboxTable);
  $$ExpensesTableTableTableManager get expensesTable =>
      $$ExpensesTableTableTableManager(_db, _db.expensesTable);
  $$BookingsTableTableTableManager get bookingsTable =>
      $$BookingsTableTableTableManager(_db, _db.bookingsTable);
  $$ClientsTableTableTableManager get clientsTable =>
      $$ClientsTableTableTableManager(_db, _db.clientsTable);
  $$AssignmentsTableTableTableManager get assignmentsTable =>
      $$AssignmentsTableTableTableManager(_db, _db.assignmentsTable);
  $$PaymentsTableTableTableManager get paymentsTable =>
      $$PaymentsTableTableTableManager(_db, _db.paymentsTable);
  $$PackagesTableTableTableManager get packagesTable =>
      $$PackagesTableTableTableManager(_db, _db.packagesTable);
  $$StatusHistoryTableTableTableManager get statusHistoryTable =>
      $$StatusHistoryTableTableTableManager(_db, _db.statusHistoryTable);
  $$ReEditRequestsTableTableTableManager get reEditRequestsTable =>
      $$ReEditRequestsTableTableTableManager(_db, _db.reEditRequestsTable);
  $$TaskProgressTableTableTableManager get taskProgressTable =>
      $$TaskProgressTableTableTableManager(_db, _db.taskProgressTable);
  $$PublicBookingRequestsTableTableTableManager
  get publicBookingRequestsTable =>
      $$PublicBookingRequestsTableTableTableManager(
        _db,
        _db.publicBookingRequestsTable,
      );
}
