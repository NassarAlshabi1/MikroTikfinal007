// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProfileCollectionCollection on Isar {
  IsarCollection<ProfileCollection> get profileCollections => this.collection();
}

const ProfileCollectionSchema = CollectionSchema(
  name: r'ProfileCollection',
  id: -6968070136066212965,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'downloadUsedBytes': PropertySchema(
      id: 1,
      name: r'downloadUsedBytes',
      type: IsarType.long,
    ),
    r'lastSyncedAt': PropertySchema(
      id: 2,
      name: r'lastSyncedAt',
      type: IsarType.dateTime,
    ),
    r'mikrotikId': PropertySchema(
      id: 3,
      name: r'mikrotikId',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'rateLimit': PropertySchema(
      id: 5,
      name: r'rateLimit',
      type: IsarType.string,
    ),
    r'sharedUsers': PropertySchema(
      id: 6,
      name: r'sharedUsers',
      type: IsarType.long,
    ),
    r'uploadUsedBytes': PropertySchema(
      id: 7,
      name: r'uploadUsedBytes',
      type: IsarType.long,
    ),
    r'uptimeLimitSeconds': PropertySchema(
      id: 8,
      name: r'uptimeLimitSeconds',
      type: IsarType.long,
    ),
    r'uptimeUsedSeconds': PropertySchema(
      id: 9,
      name: r'uptimeUsedSeconds',
      type: IsarType.long,
    )
  },
  estimateSize: _profileCollectionEstimateSize,
  serialize: _profileCollectionSerialize,
  deserialize: _profileCollectionDeserialize,
  deserializeProp: _profileCollectionDeserializeProp,
  idName: r'id',
  indexes: {
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'mikrotikId': IndexSchema(
      id: -8048573927104812799,
      name: r'mikrotikId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'mikrotikId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _profileCollectionGetId,
  getLinks: _profileCollectionGetLinks,
  attach: _profileCollectionAttach,
  version: '3.1.0+1',
);

int _profileCollectionEstimateSize(
  ProfileCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.mikrotikId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.rateLimit;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _profileCollectionSerialize(
  ProfileCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeLong(offsets[1], object.downloadUsedBytes);
  writer.writeDateTime(offsets[2], object.lastSyncedAt);
  writer.writeString(offsets[3], object.mikrotikId);
  writer.writeString(offsets[4], object.name);
  writer.writeString(offsets[5], object.rateLimit);
  writer.writeLong(offsets[6], object.sharedUsers);
  writer.writeLong(offsets[7], object.uploadUsedBytes);
  writer.writeLong(offsets[8], object.uptimeLimitSeconds);
  writer.writeLong(offsets[9], object.uptimeUsedSeconds);
}

ProfileCollection _profileCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProfileCollection();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.downloadUsedBytes = reader.readLong(offsets[1]);
  object.id = id;
  object.lastSyncedAt = reader.readDateTimeOrNull(offsets[2]);
  object.mikrotikId = reader.readStringOrNull(offsets[3]);
  object.name = reader.readString(offsets[4]);
  object.rateLimit = reader.readStringOrNull(offsets[5]);
  object.sharedUsers = reader.readLong(offsets[6]);
  object.uploadUsedBytes = reader.readLong(offsets[7]);
  object.uptimeLimitSeconds = reader.readLongOrNull(offsets[8]);
  object.uptimeUsedSeconds = reader.readLong(offsets[9]);
  return object;
}

P _profileCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _profileCollectionGetId(ProfileCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _profileCollectionGetLinks(
    ProfileCollection object) {
  return [];
}

void _profileCollectionAttach(
    IsarCollection<dynamic> col, Id id, ProfileCollection object) {
  object.id = id;
}

extension ProfileCollectionByIndex on IsarCollection<ProfileCollection> {
  Future<ProfileCollection?> getByName(String name) {
    return getByIndex(r'name', [name]);
  }

  ProfileCollection? getByNameSync(String name) {
    return getByIndexSync(r'name', [name]);
  }

  Future<bool> deleteByName(String name) {
    return deleteByIndex(r'name', [name]);
  }

  bool deleteByNameSync(String name) {
    return deleteByIndexSync(r'name', [name]);
  }

  Future<List<ProfileCollection?>> getAllByName(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndex(r'name', values);
  }

  List<ProfileCollection?> getAllByNameSync(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'name', values);
  }

  Future<int> deleteAllByName(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'name', values);
  }

  int deleteAllByNameSync(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'name', values);
  }

  Future<Id> putByName(ProfileCollection object) {
    return putByIndex(r'name', object);
  }

  Id putByNameSync(ProfileCollection object, {bool saveLinks = true}) {
    return putByIndexSync(r'name', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByName(List<ProfileCollection> objects) {
    return putAllByIndex(r'name', objects);
  }

  List<Id> putAllByNameSync(List<ProfileCollection> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'name', objects, saveLinks: saveLinks);
  }
}

extension ProfileCollectionQueryWhereSort
    on QueryBuilder<ProfileCollection, ProfileCollection, QWhere> {
  QueryBuilder<ProfileCollection, ProfileCollection, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ProfileCollectionQueryWhere
    on QueryBuilder<ProfileCollection, ProfileCollection, QWhereClause> {
  QueryBuilder<ProfileCollection, ProfileCollection, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterWhereClause>
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

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterWhereClause>
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

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterWhereClause>
      nameEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterWhereClause>
      nameNotEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterWhereClause>
      mikrotikIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'mikrotikId',
        value: [null],
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterWhereClause>
      mikrotikIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mikrotikId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterWhereClause>
      mikrotikIdEqualTo(String? mikrotikId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'mikrotikId',
        value: [mikrotikId],
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterWhereClause>
      mikrotikIdNotEqualTo(String? mikrotikId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mikrotikId',
              lower: [],
              upper: [mikrotikId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mikrotikId',
              lower: [mikrotikId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mikrotikId',
              lower: [mikrotikId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mikrotikId',
              lower: [],
              upper: [mikrotikId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ProfileCollectionQueryFilter
    on QueryBuilder<ProfileCollection, ProfileCollection, QFilterCondition> {
  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
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

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
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

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
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

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      downloadUsedBytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'downloadUsedBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      downloadUsedBytesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'downloadUsedBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      downloadUsedBytesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'downloadUsedBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      downloadUsedBytesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'downloadUsedBytes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
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

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
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

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
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

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      lastSyncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      lastSyncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      lastSyncedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      lastSyncedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      lastSyncedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      lastSyncedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      mikrotikIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mikrotikId',
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      mikrotikIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mikrotikId',
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      mikrotikIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mikrotikId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      mikrotikIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mikrotikId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      mikrotikIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mikrotikId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      mikrotikIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mikrotikId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      mikrotikIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mikrotikId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      mikrotikIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mikrotikId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      mikrotikIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mikrotikId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      mikrotikIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mikrotikId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      mikrotikIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mikrotikId',
        value: '',
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      mikrotikIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mikrotikId',
        value: '',
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      rateLimitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rateLimit',
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      rateLimitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rateLimit',
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      rateLimitEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateLimit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      rateLimitGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rateLimit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      rateLimitLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rateLimit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      rateLimitBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rateLimit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      rateLimitStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rateLimit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      rateLimitEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rateLimit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      rateLimitContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rateLimit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      rateLimitMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rateLimit',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      rateLimitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateLimit',
        value: '',
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      rateLimitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rateLimit',
        value: '',
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      sharedUsersEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sharedUsers',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      sharedUsersGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sharedUsers',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      sharedUsersLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sharedUsers',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      sharedUsersBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sharedUsers',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      uploadUsedBytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uploadUsedBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      uploadUsedBytesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uploadUsedBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      uploadUsedBytesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uploadUsedBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      uploadUsedBytesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uploadUsedBytes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      uptimeLimitSecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uptimeLimitSeconds',
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      uptimeLimitSecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uptimeLimitSeconds',
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      uptimeLimitSecondsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uptimeLimitSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      uptimeLimitSecondsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uptimeLimitSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      uptimeLimitSecondsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uptimeLimitSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      uptimeLimitSecondsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uptimeLimitSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      uptimeUsedSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uptimeUsedSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      uptimeUsedSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uptimeUsedSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      uptimeUsedSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uptimeUsedSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterFilterCondition>
      uptimeUsedSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uptimeUsedSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProfileCollectionQueryObject
    on QueryBuilder<ProfileCollection, ProfileCollection, QFilterCondition> {}

extension ProfileCollectionQueryLinks
    on QueryBuilder<ProfileCollection, ProfileCollection, QFilterCondition> {}

extension ProfileCollectionQuerySortBy
    on QueryBuilder<ProfileCollection, ProfileCollection, QSortBy> {
  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByDownloadUsedBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadUsedBytes', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByDownloadUsedBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadUsedBytes', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByMikrotikId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mikrotikId', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByMikrotikIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mikrotikId', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByRateLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateLimit', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByRateLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateLimit', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortBySharedUsers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedUsers', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortBySharedUsersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedUsers', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByUploadUsedBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadUsedBytes', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByUploadUsedBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadUsedBytes', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByUptimeLimitSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uptimeLimitSeconds', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByUptimeLimitSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uptimeLimitSeconds', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByUptimeUsedSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uptimeUsedSeconds', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      sortByUptimeUsedSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uptimeUsedSeconds', Sort.desc);
    });
  }
}

extension ProfileCollectionQuerySortThenBy
    on QueryBuilder<ProfileCollection, ProfileCollection, QSortThenBy> {
  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByDownloadUsedBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadUsedBytes', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByDownloadUsedBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadUsedBytes', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByMikrotikId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mikrotikId', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByMikrotikIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mikrotikId', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByRateLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateLimit', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByRateLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateLimit', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenBySharedUsers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedUsers', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenBySharedUsersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedUsers', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByUploadUsedBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadUsedBytes', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByUploadUsedBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadUsedBytes', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByUptimeLimitSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uptimeLimitSeconds', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByUptimeLimitSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uptimeLimitSeconds', Sort.desc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByUptimeUsedSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uptimeUsedSeconds', Sort.asc);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QAfterSortBy>
      thenByUptimeUsedSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uptimeUsedSeconds', Sort.desc);
    });
  }
}

extension ProfileCollectionQueryWhereDistinct
    on QueryBuilder<ProfileCollection, ProfileCollection, QDistinct> {
  QueryBuilder<ProfileCollection, ProfileCollection, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QDistinct>
      distinctByDownloadUsedBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'downloadUsedBytes');
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QDistinct>
      distinctByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedAt');
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QDistinct>
      distinctByMikrotikId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mikrotikId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QDistinct>
      distinctByRateLimit({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rateLimit', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QDistinct>
      distinctBySharedUsers() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sharedUsers');
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QDistinct>
      distinctByUploadUsedBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uploadUsedBytes');
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QDistinct>
      distinctByUptimeLimitSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uptimeLimitSeconds');
    });
  }

  QueryBuilder<ProfileCollection, ProfileCollection, QDistinct>
      distinctByUptimeUsedSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uptimeUsedSeconds');
    });
  }
}

extension ProfileCollectionQueryProperty
    on QueryBuilder<ProfileCollection, ProfileCollection, QQueryProperty> {
  QueryBuilder<ProfileCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ProfileCollection, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ProfileCollection, int, QQueryOperations>
      downloadUsedBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'downloadUsedBytes');
    });
  }

  QueryBuilder<ProfileCollection, DateTime?, QQueryOperations>
      lastSyncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedAt');
    });
  }

  QueryBuilder<ProfileCollection, String?, QQueryOperations>
      mikrotikIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mikrotikId');
    });
  }

  QueryBuilder<ProfileCollection, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<ProfileCollection, String?, QQueryOperations>
      rateLimitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rateLimit');
    });
  }

  QueryBuilder<ProfileCollection, int, QQueryOperations> sharedUsersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sharedUsers');
    });
  }

  QueryBuilder<ProfileCollection, int, QQueryOperations>
      uploadUsedBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uploadUsedBytes');
    });
  }

  QueryBuilder<ProfileCollection, int?, QQueryOperations>
      uptimeLimitSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uptimeLimitSeconds');
    });
  }

  QueryBuilder<ProfileCollection, int, QQueryOperations>
      uptimeUsedSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uptimeUsedSeconds');
    });
  }
}
