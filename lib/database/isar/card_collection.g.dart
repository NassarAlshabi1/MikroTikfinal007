// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCardCollectionCollection on Isar {
  IsarCollection<CardCollection> get cardCollections => this.collection();
}

const CardCollectionSchema = CollectionSchema(
  name: r'CardCollection',
  id: -2691129583880583819,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'downloadBytes': PropertySchema(
      id: 1,
      name: r'downloadBytes',
      type: IsarType.long,
    ),
    r'expiresAt': PropertySchema(
      id: 2,
      name: r'expiresAt',
      type: IsarType.dateTime,
    ),
    r'generationJobId': PropertySchema(
      id: 3,
      name: r'generationJobId',
      type: IsarType.string,
    ),
    r'lastUsedAt': PropertySchema(
      id: 4,
      name: r'lastUsedAt',
      type: IsarType.dateTime,
    ),
    r'mikrotikUserId': PropertySchema(
      id: 5,
      name: r'mikrotikUserId',
      type: IsarType.string,
    ),
    r'password': PropertySchema(
      id: 6,
      name: r'password',
      type: IsarType.string,
    ),
    r'profileId': PropertySchema(
      id: 7,
      name: r'profileId',
      type: IsarType.long,
    ),
    r'sharedUsers': PropertySchema(
      id: 8,
      name: r'sharedUsers',
      type: IsarType.long,
    ),
    r'status': PropertySchema(
      id: 9,
      name: r'status',
      type: IsarType.string,
    ),
    r'totalBytes': PropertySchema(
      id: 10,
      name: r'totalBytes',
      type: IsarType.long,
    ),
    r'totalDownloadGB': PropertySchema(
      id: 11,
      name: r'totalDownloadGB',
      type: IsarType.double,
    ),
    r'totalUploadGB': PropertySchema(
      id: 12,
      name: r'totalUploadGB',
      type: IsarType.double,
    ),
    r'uploadBytes': PropertySchema(
      id: 13,
      name: r'uploadBytes',
      type: IsarType.long,
    ),
    r'uptimeSeconds': PropertySchema(
      id: 14,
      name: r'uptimeSeconds',
      type: IsarType.long,
    ),
    r'username': PropertySchema(
      id: 15,
      name: r'username',
      type: IsarType.string,
    )
  },
  estimateSize: _cardCollectionEstimateSize,
  serialize: _cardCollectionSerialize,
  deserialize: _cardCollectionDeserialize,
  deserializeProp: _cardCollectionDeserializeProp,
  idName: r'id',
  indexes: {
    r'username': IndexSchema(
      id: -2899563114555695793,
      name: r'username',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'username',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'profileId': IndexSchema(
      id: 6052971939042612300,
      name: r'profileId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'profileId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'status_createdAt': IndexSchema(
      id: -8848012524557575184,
      name: r'status_createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'status',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'generationJobId_status': IndexSchema(
      id: 5771875388090575119,
      name: r'generationJobId_status',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'generationJobId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
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
  getId: _cardCollectionGetId,
  getLinks: _cardCollectionGetLinks,
  attach: _cardCollectionAttach,
  version: '3.1.0+1',
);

int _cardCollectionEstimateSize(
  CardCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.generationJobId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mikrotikUserId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.password;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.username.length * 3;
  return bytesCount;
}

void _cardCollectionSerialize(
  CardCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeLong(offsets[1], object.downloadBytes);
  writer.writeDateTime(offsets[2], object.expiresAt);
  writer.writeString(offsets[3], object.generationJobId);
  writer.writeDateTime(offsets[4], object.lastUsedAt);
  writer.writeString(offsets[5], object.mikrotikUserId);
  writer.writeString(offsets[6], object.password);
  writer.writeLong(offsets[7], object.profileId);
  writer.writeLong(offsets[8], object.sharedUsers);
  writer.writeString(offsets[9], object.status);
  writer.writeLong(offsets[10], object.totalBytes);
  writer.writeDouble(offsets[11], object.totalDownloadGB);
  writer.writeDouble(offsets[12], object.totalUploadGB);
  writer.writeLong(offsets[13], object.uploadBytes);
  writer.writeLong(offsets[14], object.uptimeSeconds);
  writer.writeString(offsets[15], object.username);
}

CardCollection _cardCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CardCollection();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.downloadBytes = reader.readLong(offsets[1]);
  object.expiresAt = reader.readDateTimeOrNull(offsets[2]);
  object.generationJobId = reader.readStringOrNull(offsets[3]);
  object.id = id;
  object.lastUsedAt = reader.readDateTimeOrNull(offsets[4]);
  object.mikrotikUserId = reader.readStringOrNull(offsets[5]);
  object.password = reader.readStringOrNull(offsets[6]);
  object.profileId = reader.readLong(offsets[7]);
  object.sharedUsers = reader.readLong(offsets[8]);
  object.status = reader.readString(offsets[9]);
  object.uploadBytes = reader.readLong(offsets[13]);
  object.uptimeSeconds = reader.readLong(offsets[14]);
  object.username = reader.readString(offsets[15]);
  return object;
}

P _cardCollectionDeserializeProp<P>(
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
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (reader.readDouble(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cardCollectionGetId(CardCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cardCollectionGetLinks(CardCollection object) {
  return [];
}

void _cardCollectionAttach(
    IsarCollection<dynamic> col, Id id, CardCollection object) {
  object.id = id;
}

extension CardCollectionByIndex on IsarCollection<CardCollection> {
  Future<CardCollection?> getByUsername(String username) {
    return getByIndex(r'username', [username]);
  }

  CardCollection? getByUsernameSync(String username) {
    return getByIndexSync(r'username', [username]);
  }

  Future<bool> deleteByUsername(String username) {
    return deleteByIndex(r'username', [username]);
  }

  bool deleteByUsernameSync(String username) {
    return deleteByIndexSync(r'username', [username]);
  }

  Future<List<CardCollection?>> getAllByUsername(List<String> usernameValues) {
    final values = usernameValues.map((e) => [e]).toList();
    return getAllByIndex(r'username', values);
  }

  List<CardCollection?> getAllByUsernameSync(List<String> usernameValues) {
    final values = usernameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'username', values);
  }

  Future<int> deleteAllByUsername(List<String> usernameValues) {
    final values = usernameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'username', values);
  }

  int deleteAllByUsernameSync(List<String> usernameValues) {
    final values = usernameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'username', values);
  }

  Future<Id> putByUsername(CardCollection object) {
    return putByIndex(r'username', object);
  }

  Id putByUsernameSync(CardCollection object, {bool saveLinks = true}) {
    return putByIndexSync(r'username', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUsername(List<CardCollection> objects) {
    return putAllByIndex(r'username', objects);
  }

  List<Id> putAllByUsernameSync(List<CardCollection> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'username', objects, saveLinks: saveLinks);
  }
}

extension CardCollectionQueryWhereSort
    on QueryBuilder<CardCollection, CardCollection, QWhere> {
  QueryBuilder<CardCollection, CardCollection, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhere> anyProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'profileId'),
      );
    });
  }
}

extension CardCollectionQueryWhere
    on QueryBuilder<CardCollection, CardCollection, QWhereClause> {
  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause> idBetween(
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

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      usernameEqualTo(String username) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'username',
        value: [username],
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      usernameNotEqualTo(String username) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'username',
              lower: [],
              upper: [username],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'username',
              lower: [username],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'username',
              lower: [username],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'username',
              lower: [],
              upper: [username],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      profileIdEqualTo(int profileId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'profileId',
        value: [profileId],
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      profileIdNotEqualTo(int profileId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [],
              upper: [profileId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [profileId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [profileId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [],
              upper: [profileId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      profileIdGreaterThan(
    int profileId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'profileId',
        lower: [profileId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      profileIdLessThan(
    int profileId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'profileId',
        lower: [],
        upper: [profileId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      profileIdBetween(
    int lowerProfileId,
    int upperProfileId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'profileId',
        lower: [lowerProfileId],
        includeLower: includeLower,
        upper: [upperProfileId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      statusEqualToAnyCreatedAt(String status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status_createdAt',
        value: [status],
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      statusNotEqualToAnyCreatedAt(String status) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status_createdAt',
              lower: [],
              upper: [status],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status_createdAt',
              lower: [status],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status_createdAt',
              lower: [status],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status_createdAt',
              lower: [],
              upper: [status],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      statusCreatedAtEqualTo(String status, DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status_createdAt',
        value: [status, createdAt],
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      statusEqualToCreatedAtNotEqualTo(String status, DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status_createdAt',
              lower: [status],
              upper: [status, createdAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status_createdAt',
              lower: [status, createdAt],
              includeLower: false,
              upper: [status],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status_createdAt',
              lower: [status, createdAt],
              includeLower: false,
              upper: [status],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status_createdAt',
              lower: [status],
              upper: [status, createdAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      statusEqualToCreatedAtGreaterThan(
    String status,
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'status_createdAt',
        lower: [status, createdAt],
        includeLower: include,
        upper: [status],
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      statusEqualToCreatedAtLessThan(
    String status,
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'status_createdAt',
        lower: [status],
        upper: [status, createdAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      statusEqualToCreatedAtBetween(
    String status,
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'status_createdAt',
        lower: [status, lowerCreatedAt],
        includeLower: includeLower,
        upper: [status, upperCreatedAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      generationJobIdIsNullAnyStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'generationJobId_status',
        value: [null],
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      generationJobIdIsNotNullAnyStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'generationJobId_status',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      generationJobIdEqualToAnyStatus(String? generationJobId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'generationJobId_status',
        value: [generationJobId],
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      generationJobIdNotEqualToAnyStatus(String? generationJobId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generationJobId_status',
              lower: [],
              upper: [generationJobId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generationJobId_status',
              lower: [generationJobId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generationJobId_status',
              lower: [generationJobId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generationJobId_status',
              lower: [],
              upper: [generationJobId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      generationJobIdStatusEqualTo(String? generationJobId, String status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'generationJobId_status',
        value: [generationJobId, status],
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterWhereClause>
      generationJobIdEqualToStatusNotEqualTo(
          String? generationJobId, String status) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generationJobId_status',
              lower: [generationJobId],
              upper: [generationJobId, status],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generationJobId_status',
              lower: [generationJobId, status],
              includeLower: false,
              upper: [generationJobId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generationJobId_status',
              lower: [generationJobId, status],
              includeLower: false,
              upper: [generationJobId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generationJobId_status',
              lower: [generationJobId],
              upper: [generationJobId, status],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CardCollectionQueryFilter
    on QueryBuilder<CardCollection, CardCollection, QFilterCondition> {
  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
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

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
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

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
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

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      downloadBytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'downloadBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      downloadBytesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'downloadBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      downloadBytesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'downloadBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      downloadBytesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'downloadBytes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      expiresAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'expiresAt',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      expiresAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'expiresAt',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      expiresAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      expiresAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      expiresAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      expiresAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expiresAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      generationJobIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'generationJobId',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      generationJobIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'generationJobId',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      generationJobIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'generationJobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      generationJobIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'generationJobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      generationJobIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'generationJobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      generationJobIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'generationJobId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      generationJobIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'generationJobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      generationJobIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'generationJobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      generationJobIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'generationJobId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      generationJobIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'generationJobId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      generationJobIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'generationJobId',
        value: '',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      generationJobIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'generationJobId',
        value: '',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
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

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
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

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      lastUsedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastUsedAt',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      lastUsedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastUsedAt',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      lastUsedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUsedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      lastUsedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUsedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      lastUsedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUsedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      lastUsedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUsedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      mikrotikUserIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mikrotikUserId',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      mikrotikUserIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mikrotikUserId',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      mikrotikUserIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mikrotikUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      mikrotikUserIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mikrotikUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      mikrotikUserIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mikrotikUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      mikrotikUserIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mikrotikUserId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      mikrotikUserIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mikrotikUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      mikrotikUserIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mikrotikUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      mikrotikUserIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mikrotikUserId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      mikrotikUserIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mikrotikUserId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      mikrotikUserIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mikrotikUserId',
        value: '',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      mikrotikUserIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mikrotikUserId',
        value: '',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      passwordIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'password',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      passwordIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'password',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      passwordEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'password',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      passwordGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'password',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      passwordLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'password',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      passwordBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'password',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      passwordStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'password',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      passwordEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'password',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      passwordContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'password',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      passwordMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'password',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      passwordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'password',
        value: '',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      passwordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'password',
        value: '',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      profileIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profileId',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      profileIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'profileId',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      profileIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'profileId',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      profileIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'profileId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      sharedUsersEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sharedUsers',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
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

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
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

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
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

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
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

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
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

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
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

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
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

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
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

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
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

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      totalBytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      totalBytesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      totalBytesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      totalBytesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalBytes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      totalDownloadGBEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalDownloadGB',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      totalDownloadGBGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalDownloadGB',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      totalDownloadGBLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalDownloadGB',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      totalDownloadGBBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalDownloadGB',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      totalUploadGBEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalUploadGB',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      totalUploadGBGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalUploadGB',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      totalUploadGBLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalUploadGB',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      totalUploadGBBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalUploadGB',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      uploadBytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uploadBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      uploadBytesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uploadBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      uploadBytesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uploadBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      uploadBytesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uploadBytes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      uptimeSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uptimeSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      uptimeSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uptimeSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      uptimeSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uptimeSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      uptimeSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uptimeSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      usernameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      usernameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      usernameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      usernameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'username',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      usernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      usernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      usernameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      usernameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'username',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      usernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: '',
      ));
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterFilterCondition>
      usernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'username',
        value: '',
      ));
    });
  }
}

extension CardCollectionQueryObject
    on QueryBuilder<CardCollection, CardCollection, QFilterCondition> {}

extension CardCollectionQueryLinks
    on QueryBuilder<CardCollection, CardCollection, QFilterCondition> {}

extension CardCollectionQuerySortBy
    on QueryBuilder<CardCollection, CardCollection, QSortBy> {
  QueryBuilder<CardCollection, CardCollection, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByDownloadBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadBytes', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByDownloadBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadBytes', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy> sortByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByGenerationJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generationJobId', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByGenerationJobIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generationJobId', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByLastUsedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByLastUsedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByMikrotikUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mikrotikUserId', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByMikrotikUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mikrotikUserId', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy> sortByPassword() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'password', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByPasswordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'password', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy> sortByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortBySharedUsers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedUsers', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortBySharedUsersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedUsers', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByTotalBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalBytes', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByTotalBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalBytes', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByTotalDownloadGB() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDownloadGB', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByTotalDownloadGBDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDownloadGB', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByTotalUploadGB() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalUploadGB', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByTotalUploadGBDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalUploadGB', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByUploadBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadBytes', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByUploadBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadBytes', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByUptimeSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uptimeSeconds', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByUptimeSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uptimeSeconds', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy> sortByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      sortByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }
}

extension CardCollectionQuerySortThenBy
    on QueryBuilder<CardCollection, CardCollection, QSortThenBy> {
  QueryBuilder<CardCollection, CardCollection, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByDownloadBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadBytes', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByDownloadBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadBytes', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy> thenByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByGenerationJobId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generationJobId', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByGenerationJobIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generationJobId', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByLastUsedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByLastUsedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByMikrotikUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mikrotikUserId', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByMikrotikUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mikrotikUserId', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy> thenByPassword() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'password', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByPasswordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'password', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy> thenByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenBySharedUsers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedUsers', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenBySharedUsersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedUsers', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByTotalBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalBytes', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByTotalBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalBytes', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByTotalDownloadGB() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDownloadGB', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByTotalDownloadGBDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDownloadGB', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByTotalUploadGB() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalUploadGB', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByTotalUploadGBDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalUploadGB', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByUploadBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadBytes', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByUploadBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadBytes', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByUptimeSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uptimeSeconds', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByUptimeSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uptimeSeconds', Sort.desc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy> thenByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QAfterSortBy>
      thenByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }
}

extension CardCollectionQueryWhereDistinct
    on QueryBuilder<CardCollection, CardCollection, QDistinct> {
  QueryBuilder<CardCollection, CardCollection, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<CardCollection, CardCollection, QDistinct>
      distinctByDownloadBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'downloadBytes');
    });
  }

  QueryBuilder<CardCollection, CardCollection, QDistinct>
      distinctByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expiresAt');
    });
  }

  QueryBuilder<CardCollection, CardCollection, QDistinct>
      distinctByGenerationJobId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'generationJobId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QDistinct>
      distinctByLastUsedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUsedAt');
    });
  }

  QueryBuilder<CardCollection, CardCollection, QDistinct>
      distinctByMikrotikUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mikrotikUserId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QDistinct> distinctByPassword(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'password', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QDistinct>
      distinctByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profileId');
    });
  }

  QueryBuilder<CardCollection, CardCollection, QDistinct>
      distinctBySharedUsers() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sharedUsers');
    });
  }

  QueryBuilder<CardCollection, CardCollection, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CardCollection, CardCollection, QDistinct>
      distinctByTotalBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalBytes');
    });
  }

  QueryBuilder<CardCollection, CardCollection, QDistinct>
      distinctByTotalDownloadGB() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalDownloadGB');
    });
  }

  QueryBuilder<CardCollection, CardCollection, QDistinct>
      distinctByTotalUploadGB() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalUploadGB');
    });
  }

  QueryBuilder<CardCollection, CardCollection, QDistinct>
      distinctByUploadBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uploadBytes');
    });
  }

  QueryBuilder<CardCollection, CardCollection, QDistinct>
      distinctByUptimeSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uptimeSeconds');
    });
  }

  QueryBuilder<CardCollection, CardCollection, QDistinct> distinctByUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'username', caseSensitive: caseSensitive);
    });
  }
}

extension CardCollectionQueryProperty
    on QueryBuilder<CardCollection, CardCollection, QQueryProperty> {
  QueryBuilder<CardCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CardCollection, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CardCollection, int, QQueryOperations> downloadBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'downloadBytes');
    });
  }

  QueryBuilder<CardCollection, DateTime?, QQueryOperations>
      expiresAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expiresAt');
    });
  }

  QueryBuilder<CardCollection, String?, QQueryOperations>
      generationJobIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'generationJobId');
    });
  }

  QueryBuilder<CardCollection, DateTime?, QQueryOperations>
      lastUsedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUsedAt');
    });
  }

  QueryBuilder<CardCollection, String?, QQueryOperations>
      mikrotikUserIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mikrotikUserId');
    });
  }

  QueryBuilder<CardCollection, String?, QQueryOperations> passwordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'password');
    });
  }

  QueryBuilder<CardCollection, int, QQueryOperations> profileIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profileId');
    });
  }

  QueryBuilder<CardCollection, int, QQueryOperations> sharedUsersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sharedUsers');
    });
  }

  QueryBuilder<CardCollection, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<CardCollection, int, QQueryOperations> totalBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalBytes');
    });
  }

  QueryBuilder<CardCollection, double, QQueryOperations>
      totalDownloadGBProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalDownloadGB');
    });
  }

  QueryBuilder<CardCollection, double, QQueryOperations>
      totalUploadGBProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalUploadGB');
    });
  }

  QueryBuilder<CardCollection, int, QQueryOperations> uploadBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uploadBytes');
    });
  }

  QueryBuilder<CardCollection, int, QQueryOperations> uptimeSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uptimeSeconds');
    });
  }

  QueryBuilder<CardCollection, String, QQueryOperations> usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'username');
    });
  }
}
