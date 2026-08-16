// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_generation_job.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCardGenerationJobCollection on Isar {
  IsarCollection<CardGenerationJob> get cardGenerationJobs => this.collection();
}

const CardGenerationJobSchema = CollectionSchema(
  name: r'CardGenerationJob',
  id: -3763032767098087720,
  properties: {
    r'completedAt': PropertySchema(
      id: 0,
      name: r'completedAt',
      type: IsarType.dateTime,
    ),
    r'configurationFingerprint': PropertySchema(
      id: 1,
      name: r'configurationFingerprint',
      type: IsarType.string,
    ),
    r'confirmedCount': PropertySchema(
      id: 2,
      name: r'confirmedCount',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'failedCount': PropertySchema(
      id: 4,
      name: r'failedCount',
      type: IsarType.long,
    ),
    r'isResumable': PropertySchema(
      id: 5,
      name: r'isResumable',
      type: IsarType.bool,
    ),
    r'isTerminal': PropertySchema(
      id: 6,
      name: r'isTerminal',
      type: IsarType.bool,
    ),
    r'jobId': PropertySchema(
      id: 7,
      name: r'jobId',
      type: IsarType.string,
    ),
    r'lastError': PropertySchema(
      id: 8,
      name: r'lastError',
      type: IsarType.string,
    ),
    r'lastUsername': PropertySchema(
      id: 9,
      name: r'lastUsername',
      type: IsarType.string,
    ),
    r'nextIndex': PropertySchema(
      id: 10,
      name: r'nextIndex',
      type: IsarType.long,
    ),
    r'parametersJson': PropertySchema(
      id: 11,
      name: r'parametersJson',
      type: IsarType.string,
    ),
    r'plannedUsersJson': PropertySchema(
      id: 12,
      name: r'plannedUsersJson',
      type: IsarType.string,
    ),
    r'profileName': PropertySchema(
      id: 13,
      name: r'profileName',
      type: IsarType.string,
    ),
    r'requestedCount': PropertySchema(
      id: 14,
      name: r'requestedCount',
      type: IsarType.long,
    ),
    r'reservedCount': PropertySchema(
      id: 15,
      name: r'reservedCount',
      type: IsarType.long,
    ),
    r'routerAddress': PropertySchema(
      id: 16,
      name: r'routerAddress',
      type: IsarType.string,
    ),
    r'serviceMode': PropertySchema(
      id: 17,
      name: r'serviceMode',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 18,
      name: r'status',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 19,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _cardGenerationJobEstimateSize,
  serialize: _cardGenerationJobSerialize,
  deserialize: _cardGenerationJobDeserialize,
  deserializeProp: _cardGenerationJobDeserializeProp,
  idName: r'id',
  indexes: {
    r'jobId': IndexSchema(
      id: 7916160552736803877,
      name: r'jobId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'jobId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'status': IndexSchema(
      id: -107785170620420283,
      name: r'status',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'status',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cardGenerationJobGetId,
  getLinks: _cardGenerationJobGetLinks,
  attach: _cardGenerationJobAttach,
  version: '3.1.0+1',
);

int _cardGenerationJobEstimateSize(
  CardGenerationJob object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.configurationFingerprint;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.jobId.length * 3;
  {
    final value = object.lastError;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lastUsername;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.parametersJson.length * 3;
  {
    final value = object.plannedUsersJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.profileName.length * 3;
  {
    final value = object.routerAddress;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.serviceMode.length * 3;
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _cardGenerationJobSerialize(
  CardGenerationJob object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.completedAt);
  writer.writeString(offsets[1], object.configurationFingerprint);
  writer.writeLong(offsets[2], object.confirmedCount);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeLong(offsets[4], object.failedCount);
  writer.writeBool(offsets[5], object.isResumable);
  writer.writeBool(offsets[6], object.isTerminal);
  writer.writeString(offsets[7], object.jobId);
  writer.writeString(offsets[8], object.lastError);
  writer.writeString(offsets[9], object.lastUsername);
  writer.writeLong(offsets[10], object.nextIndex);
  writer.writeString(offsets[11], object.parametersJson);
  writer.writeString(offsets[12], object.plannedUsersJson);
  writer.writeString(offsets[13], object.profileName);
  writer.writeLong(offsets[14], object.requestedCount);
  writer.writeLong(offsets[15], object.reservedCount);
  writer.writeString(offsets[16], object.routerAddress);
  writer.writeString(offsets[17], object.serviceMode);
  writer.writeString(offsets[18], object.status);
  writer.writeDateTime(offsets[19], object.updatedAt);
}

CardGenerationJob _cardGenerationJobDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CardGenerationJob();
  object.completedAt = reader.readDateTimeOrNull(offsets[0]);
  object.configurationFingerprint = reader.readStringOrNull(offsets[1]);
  object.confirmedCount = reader.readLong(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.failedCount = reader.readLong(offsets[4]);
  object.id = id;
  object.jobId = reader.readString(offsets[7]);
  object.lastError = reader.readStringOrNull(offsets[8]);
  object.lastUsername = reader.readStringOrNull(offsets[9]);
  object.nextIndex = reader.readLong(offsets[10]);
  object.parametersJson = reader.readString(offsets[11]);
  object.plannedUsersJson = reader.readStringOrNull(offsets[12]);
  object.profileName = reader.readString(offsets[13]);
  object.requestedCount = reader.readLong(offsets[14]);
  object.reservedCount = reader.readLong(offsets[15]);
  object.routerAddress = reader.readStringOrNull(offsets[16]);
  object.serviceMode = reader.readString(offsets[17]);
  object.status = reader.readString(offsets[18]);
  object.updatedAt = reader.readDateTime(offsets[19]);
  return object;
}

P _cardGenerationJobDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cardGenerationJobGetId(CardGenerationJob object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cardGenerationJobGetLinks(
    CardGenerationJob object) {
  return [];
}

void _cardGenerationJobAttach(
    IsarCollection<dynamic> col, Id id, CardGenerationJob object) {
  object.id = id;
}

extension CardGenerationJobByIndex on IsarCollection<CardGenerationJob> {
  Future<CardGenerationJob?> getByJobId(String jobId) {
    return getByIndex(r'jobId', [jobId]);
  }

  CardGenerationJob? getByJobIdSync(String jobId) {
    return getByIndexSync(r'jobId', [jobId]);
  }

  Future<bool> deleteByJobId(String jobId) {
    return deleteByIndex(r'jobId', [jobId]);
  }

  bool deleteByJobIdSync(String jobId) {
    return deleteByIndexSync(r'jobId', [jobId]);
  }

  Future<List<CardGenerationJob?>> getAllByJobId(List<String> jobIdValues) {
    final values = jobIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'jobId', values);
  }

  List<CardGenerationJob?> getAllByJobIdSync(List<String> jobIdValues) {
    final values = jobIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'jobId', values);
  }

  Future<int> deleteAllByJobId(List<String> jobIdValues) {
    final values = jobIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'jobId', values);
  }

  int deleteAllByJobIdSync(List<String> jobIdValues) {
    final values = jobIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'jobId', values);
  }

  Future<Id> putByJobId(CardGenerationJob object) {
    return putByIndex(r'jobId', object);
  }

  Id putByJobIdSync(CardGenerationJob object, {bool saveLinks = true}) {
    return putByIndexSync(r'jobId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByJobId(List<CardGenerationJob> objects) {
    return putAllByIndex(r'jobId', objects);
  }

  List<Id> putAllByJobIdSync(List<CardGenerationJob> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'jobId', objects, saveLinks: saveLinks);
  }
}

extension CardGenerationJobQueryWhereSort
    on QueryBuilder<CardGenerationJob, CardGenerationJob, QWhere> {
  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CardGenerationJobQueryWhere
    on QueryBuilder<CardGenerationJob, CardGenerationJob, QWhereClause> {
  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterWhereClause>
      jobIdEqualTo(String jobId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'jobId',
        value: [jobId],
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterWhereClause>
      jobIdNotEqualTo(String jobId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [],
              upper: [jobId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [jobId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [jobId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'jobId',
              lower: [],
              upper: [jobId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterWhereClause>
      statusEqualTo(String status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status',
        value: [status],
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterWhereClause>
      statusNotEqualTo(String status) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CardGenerationJobQueryFilter
    on QueryBuilder<CardGenerationJob, CardGenerationJob, QFilterCondition> {
  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      completedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      completedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      completedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      completedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      completedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      completedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      configurationFingerprintIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'configurationFingerprint',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      configurationFingerprintIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'configurationFingerprint',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      configurationFingerprintEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configurationFingerprint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      configurationFingerprintGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'configurationFingerprint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      configurationFingerprintLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'configurationFingerprint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      configurationFingerprintBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'configurationFingerprint',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      configurationFingerprintStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'configurationFingerprint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      configurationFingerprintEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'configurationFingerprint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      configurationFingerprintContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'configurationFingerprint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      configurationFingerprintMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'configurationFingerprint',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      configurationFingerprintIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configurationFingerprint',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      configurationFingerprintIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'configurationFingerprint',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      confirmedCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'confirmedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      confirmedCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'confirmedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      confirmedCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'confirmedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      confirmedCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'confirmedCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      failedCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'failedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      failedCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'failedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      failedCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'failedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      failedCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'failedCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      isResumableEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isResumable',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      isTerminalEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isTerminal',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      jobIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      jobIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      jobIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      jobIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'jobId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      jobIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      jobIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      jobIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'jobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      jobIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'jobId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      jobIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jobId',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      jobIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'jobId',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastError',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastError',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastErrorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastErrorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastErrorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastErrorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastError',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastErrorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastErrorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastErrorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastErrorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastError',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastErrorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastError',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastErrorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastError',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastUsernameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastUsername',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastUsernameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastUsername',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastUsernameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastUsernameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastUsernameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastUsernameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUsername',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastUsernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastUsernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastUsernameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastUsernameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastUsername',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastUsernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUsername',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      lastUsernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastUsername',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      nextIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      nextIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      nextIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      nextIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      parametersJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      parametersJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      parametersJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      parametersJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parametersJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      parametersJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'parametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      parametersJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'parametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      parametersJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'parametersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      parametersJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'parametersJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      parametersJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parametersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      parametersJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'parametersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      plannedUsersJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'plannedUsersJson',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      plannedUsersJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'plannedUsersJson',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      plannedUsersJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'plannedUsersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      plannedUsersJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'plannedUsersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      plannedUsersJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'plannedUsersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      plannedUsersJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'plannedUsersJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      plannedUsersJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'plannedUsersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      plannedUsersJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'plannedUsersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      plannedUsersJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'plannedUsersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      plannedUsersJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'plannedUsersJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      plannedUsersJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'plannedUsersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      plannedUsersJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'plannedUsersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      profileNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      profileNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'profileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      profileNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'profileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      profileNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'profileName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      profileNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'profileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      profileNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'profileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      profileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'profileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      profileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'profileName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      profileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profileName',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      profileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'profileName',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      requestedCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requestedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      requestedCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'requestedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      requestedCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'requestedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      requestedCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'requestedCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      reservedCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reservedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      reservedCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reservedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      reservedCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reservedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      reservedCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reservedCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      routerAddressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'routerAddress',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      routerAddressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'routerAddress',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      routerAddressEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'routerAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      routerAddressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'routerAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      routerAddressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'routerAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      routerAddressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'routerAddress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      routerAddressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'routerAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      routerAddressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'routerAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      routerAddressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'routerAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      routerAddressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'routerAddress',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      routerAddressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'routerAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      routerAddressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'routerAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      serviceModeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serviceMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      serviceModeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serviceMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      serviceModeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serviceMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      serviceModeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serviceMode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      serviceModeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'serviceMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      serviceModeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'serviceMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      serviceModeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serviceMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      serviceModeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serviceMode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      serviceModeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serviceMode',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      serviceModeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serviceMode',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CardGenerationJobQueryObject
    on QueryBuilder<CardGenerationJob, CardGenerationJob, QFilterCondition> {}

extension CardGenerationJobQueryLinks
    on QueryBuilder<CardGenerationJob, CardGenerationJob, QFilterCondition> {}

extension CardGenerationJobQuerySortBy
    on QueryBuilder<CardGenerationJob, CardGenerationJob, QSortBy> {
  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByConfigurationFingerprint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationFingerprint', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByConfigurationFingerprintDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationFingerprint', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByConfirmedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confirmedCount', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByConfirmedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confirmedCount', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByFailedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedCount', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByFailedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedCount', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByIsResumable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isResumable', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByIsResumableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isResumable', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByIsTerminal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTerminal', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByIsTerminalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTerminal', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByJobIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByLastUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsername', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByLastUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsername', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByNextIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextIndex', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByNextIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextIndex', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByParametersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parametersJson', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByParametersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parametersJson', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByPlannedUsersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plannedUsersJson', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByPlannedUsersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plannedUsersJson', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByProfileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileName', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByProfileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileName', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByRequestedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestedCount', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByRequestedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestedCount', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByReservedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservedCount', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByReservedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservedCount', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByRouterAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routerAddress', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByRouterAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routerAddress', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByServiceMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceMode', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByServiceModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceMode', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CardGenerationJobQuerySortThenBy
    on QueryBuilder<CardGenerationJob, CardGenerationJob, QSortThenBy> {
  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByConfigurationFingerprint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationFingerprint', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByConfigurationFingerprintDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationFingerprint', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByConfirmedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confirmedCount', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByConfirmedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confirmedCount', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByFailedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedCount', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByFailedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedCount', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByIsResumable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isResumable', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByIsResumableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isResumable', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByIsTerminal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTerminal', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByIsTerminalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTerminal', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByJobIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobId', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByLastUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsername', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByLastUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsername', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByNextIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextIndex', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByNextIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextIndex', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByParametersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parametersJson', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByParametersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parametersJson', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByPlannedUsersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plannedUsersJson', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByPlannedUsersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plannedUsersJson', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByProfileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileName', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByProfileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileName', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByRequestedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestedCount', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByRequestedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestedCount', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByReservedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservedCount', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByReservedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservedCount', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByRouterAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routerAddress', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByRouterAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routerAddress', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByServiceMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceMode', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByServiceModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceMode', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CardGenerationJobQueryWhereDistinct
    on QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct> {
  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAt');
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByConfigurationFingerprint({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'configurationFingerprint',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByConfirmedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'confirmedCount');
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByFailedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'failedCount');
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByIsResumable() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isResumable');
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByIsTerminal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isTerminal');
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct> distinctByJobId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jobId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByLastError({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastError', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByLastUsername({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUsername', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByNextIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextIndex');
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByParametersJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parametersJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByPlannedUsersJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'plannedUsersJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByProfileName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profileName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByRequestedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'requestedCount');
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByReservedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reservedCount');
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByRouterAddress({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'routerAddress',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByServiceMode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serviceMode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardGenerationJob, CardGenerationJob, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension CardGenerationJobQueryProperty
    on QueryBuilder<CardGenerationJob, CardGenerationJob, QQueryProperty> {
  QueryBuilder<CardGenerationJob, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CardGenerationJob, DateTime?, QQueryOperations>
      completedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAt');
    });
  }

  QueryBuilder<CardGenerationJob, String?, QQueryOperations>
      configurationFingerprintProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'configurationFingerprint');
    });
  }

  QueryBuilder<CardGenerationJob, int, QQueryOperations>
      confirmedCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'confirmedCount');
    });
  }

  QueryBuilder<CardGenerationJob, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CardGenerationJob, int, QQueryOperations> failedCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'failedCount');
    });
  }

  QueryBuilder<CardGenerationJob, bool, QQueryOperations>
      isResumableProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isResumable');
    });
  }

  QueryBuilder<CardGenerationJob, bool, QQueryOperations> isTerminalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isTerminal');
    });
  }

  QueryBuilder<CardGenerationJob, String, QQueryOperations> jobIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jobId');
    });
  }

  QueryBuilder<CardGenerationJob, String?, QQueryOperations>
      lastErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastError');
    });
  }

  QueryBuilder<CardGenerationJob, String?, QQueryOperations>
      lastUsernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUsername');
    });
  }

  QueryBuilder<CardGenerationJob, int, QQueryOperations> nextIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextIndex');
    });
  }

  QueryBuilder<CardGenerationJob, String, QQueryOperations>
      parametersJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parametersJson');
    });
  }

  QueryBuilder<CardGenerationJob, String?, QQueryOperations>
      plannedUsersJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'plannedUsersJson');
    });
  }

  QueryBuilder<CardGenerationJob, String, QQueryOperations>
      profileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profileName');
    });
  }

  QueryBuilder<CardGenerationJob, int, QQueryOperations>
      requestedCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'requestedCount');
    });
  }

  QueryBuilder<CardGenerationJob, int, QQueryOperations>
      reservedCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reservedCount');
    });
  }

  QueryBuilder<CardGenerationJob, String?, QQueryOperations>
      routerAddressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'routerAddress');
    });
  }

  QueryBuilder<CardGenerationJob, String, QQueryOperations>
      serviceModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serviceMode');
    });
  }

  QueryBuilder<CardGenerationJob, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<CardGenerationJob, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
