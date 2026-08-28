// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_diagnostic_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAiDiagnosticCollectionCollection on Isar {
  IsarCollection<AiDiagnosticCollection> get aiDiagnosticCollections =>
      this.collection();
}

const AiDiagnosticCollectionSchema = CollectionSchema(
  name: r'AiDiagnosticCollection',
  id: -7217303530378552451,
  properties: {
    r'aiModel': PropertySchema(
      id: 0,
      name: r'aiModel',
      type: IsarType.string,
    ),
    r'aiProvider': PropertySchema(
      id: 1,
      name: r'aiProvider',
      type: IsarType.string,
    ),
    r'aiResponse': PropertySchema(
      id: 2,
      name: r'aiResponse',
      type: IsarType.string,
    ),
    r'endedAt': PropertySchema(
      id: 3,
      name: r'endedAt',
      type: IsarType.dateTime,
    ),
    r'isFavorite': PropertySchema(
      id: 4,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'mikrotikIp': PropertySchema(
      id: 5,
      name: r'mikrotikIp',
      type: IsarType.string,
    ),
    r'mode': PropertySchema(
      id: 6,
      name: r'mode',
      type: IsarType.string,
    ),
    r'snapshotJson': PropertySchema(
      id: 7,
      name: r'snapshotJson',
      type: IsarType.string,
    ),
    r'startedAt': PropertySchema(
      id: 8,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'tokensUsed': PropertySchema(
      id: 9,
      name: r'tokensUsed',
      type: IsarType.long,
    ),
    r'userQuery': PropertySchema(
      id: 10,
      name: r'userQuery',
      type: IsarType.string,
    )
  },
  estimateSize: _aiDiagnosticCollectionEstimateSize,
  serialize: _aiDiagnosticCollectionSerialize,
  deserialize: _aiDiagnosticCollectionDeserialize,
  deserializeProp: _aiDiagnosticCollectionDeserializeProp,
  idName: r'id',
  indexes: {
    r'mode_startedAt': IndexSchema(
      id: -3675396011913022052,
      name: r'mode_startedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'mode',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'startedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'isFavorite': IndexSchema(
      id: 5742774614603939776,
      name: r'isFavorite',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isFavorite',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _aiDiagnosticCollectionGetId,
  getLinks: _aiDiagnosticCollectionGetLinks,
  attach: _aiDiagnosticCollectionAttach,
  version: '3.1.0+1',
);

int _aiDiagnosticCollectionEstimateSize(
  AiDiagnosticCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.aiModel;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.aiProvider;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.aiResponse.length * 3;
  {
    final value = object.mikrotikIp;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.mode.length * 3;
  {
    final value = object.snapshotJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userQuery.length * 3;
  return bytesCount;
}

void _aiDiagnosticCollectionSerialize(
  AiDiagnosticCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.aiModel);
  writer.writeString(offsets[1], object.aiProvider);
  writer.writeString(offsets[2], object.aiResponse);
  writer.writeDateTime(offsets[3], object.endedAt);
  writer.writeBool(offsets[4], object.isFavorite);
  writer.writeString(offsets[5], object.mikrotikIp);
  writer.writeString(offsets[6], object.mode);
  writer.writeString(offsets[7], object.snapshotJson);
  writer.writeDateTime(offsets[8], object.startedAt);
  writer.writeLong(offsets[9], object.tokensUsed);
  writer.writeString(offsets[10], object.userQuery);
}

AiDiagnosticCollection _aiDiagnosticCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AiDiagnosticCollection();
  object.aiModel = reader.readStringOrNull(offsets[0]);
  object.aiProvider = reader.readStringOrNull(offsets[1]);
  object.aiResponse = reader.readString(offsets[2]);
  object.endedAt = reader.readDateTimeOrNull(offsets[3]);
  object.id = id;
  object.isFavorite = reader.readBool(offsets[4]);
  object.mikrotikIp = reader.readStringOrNull(offsets[5]);
  object.mode = reader.readString(offsets[6]);
  object.snapshotJson = reader.readStringOrNull(offsets[7]);
  object.startedAt = reader.readDateTime(offsets[8]);
  object.tokensUsed = reader.readLongOrNull(offsets[9]);
  object.userQuery = reader.readString(offsets[10]);
  return object;
}

P _aiDiagnosticCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _aiDiagnosticCollectionGetId(AiDiagnosticCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _aiDiagnosticCollectionGetLinks(
    AiDiagnosticCollection object) {
  return [];
}

void _aiDiagnosticCollectionAttach(
    IsarCollection<dynamic> col, Id id, AiDiagnosticCollection object) {
  object.id = id;
}

extension AiDiagnosticCollectionQueryWhereSort
    on QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QWhere> {
  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterWhere>
      anyIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isFavorite'),
      );
    });
  }
}

extension AiDiagnosticCollectionQueryWhere on QueryBuilder<
    AiDiagnosticCollection, AiDiagnosticCollection, QWhereClause> {
  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterWhereClause> idBetween(
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

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterWhereClause> modeEqualToAnyStartedAt(String mode) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'mode_startedAt',
        value: [mode],
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterWhereClause> modeNotEqualToAnyStartedAt(String mode) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mode_startedAt',
              lower: [],
              upper: [mode],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mode_startedAt',
              lower: [mode],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mode_startedAt',
              lower: [mode],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mode_startedAt',
              lower: [],
              upper: [mode],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterWhereClause> modeStartedAtEqualTo(String mode, DateTime startedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'mode_startedAt',
        value: [mode, startedAt],
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
          QAfterWhereClause>
      modeEqualToStartedAtNotEqualTo(String mode, DateTime startedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mode_startedAt',
              lower: [mode],
              upper: [mode, startedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mode_startedAt',
              lower: [mode, startedAt],
              includeLower: false,
              upper: [mode],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mode_startedAt',
              lower: [mode, startedAt],
              includeLower: false,
              upper: [mode],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mode_startedAt',
              lower: [mode],
              upper: [mode, startedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterWhereClause> modeEqualToStartedAtGreaterThan(
    String mode,
    DateTime startedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mode_startedAt',
        lower: [mode, startedAt],
        includeLower: include,
        upper: [mode],
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterWhereClause> modeEqualToStartedAtLessThan(
    String mode,
    DateTime startedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mode_startedAt',
        lower: [mode],
        upper: [mode, startedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterWhereClause> modeEqualToStartedAtBetween(
    String mode,
    DateTime lowerStartedAt,
    DateTime upperStartedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mode_startedAt',
        lower: [mode, lowerStartedAt],
        includeLower: includeLower,
        upper: [mode, upperStartedAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterWhereClause> isFavoriteEqualTo(bool isFavorite) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isFavorite',
        value: [isFavorite],
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterWhereClause> isFavoriteNotEqualTo(bool isFavorite) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isFavorite',
              lower: [],
              upper: [isFavorite],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isFavorite',
              lower: [isFavorite],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isFavorite',
              lower: [isFavorite],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isFavorite',
              lower: [],
              upper: [isFavorite],
              includeUpper: false,
            ));
      }
    });
  }
}

extension AiDiagnosticCollectionQueryFilter on QueryBuilder<
    AiDiagnosticCollection, AiDiagnosticCollection, QFilterCondition> {
  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiModelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'aiModel',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiModelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'aiModel',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiModelEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiModelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aiModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiModelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aiModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiModelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aiModel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiModelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'aiModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiModelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'aiModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
          QAfterFilterCondition>
      aiModelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'aiModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
          QAfterFilterCondition>
      aiModelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'aiModel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiModelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiModel',
        value: '',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiModelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'aiModel',
        value: '',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiProviderIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'aiProvider',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiProviderIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'aiProvider',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiProviderEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiProviderGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aiProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiProviderLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aiProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiProviderBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aiProvider',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiProviderStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'aiProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiProviderEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'aiProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
          QAfterFilterCondition>
      aiProviderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'aiProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
          QAfterFilterCondition>
      aiProviderMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'aiProvider',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiProviderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiProvider',
        value: '',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiProviderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'aiProvider',
        value: '',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiResponseEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiResponse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiResponseGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aiResponse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiResponseLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aiResponse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiResponseBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aiResponse',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiResponseStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'aiResponse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiResponseEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'aiResponse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
          QAfterFilterCondition>
      aiResponseContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'aiResponse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
          QAfterFilterCondition>
      aiResponseMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'aiResponse',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiResponseIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiResponse',
        value: '',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> aiResponseIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'aiResponse',
        value: '',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> endedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endedAt',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> endedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endedAt',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> endedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> endedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> endedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> endedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> isFavoriteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFavorite',
        value: value,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> mikrotikIpIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mikrotikIp',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> mikrotikIpIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mikrotikIp',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> mikrotikIpEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mikrotikIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> mikrotikIpGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mikrotikIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> mikrotikIpLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mikrotikIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> mikrotikIpBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mikrotikIp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> mikrotikIpStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mikrotikIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> mikrotikIpEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mikrotikIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
          QAfterFilterCondition>
      mikrotikIpContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mikrotikIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
          QAfterFilterCondition>
      mikrotikIpMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mikrotikIp',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> mikrotikIpIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mikrotikIp',
        value: '',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> mikrotikIpIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mikrotikIp',
        value: '',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> modeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> modeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> modeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> modeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> modeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> modeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
          QAfterFilterCondition>
      modeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
          QAfterFilterCondition>
      modeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> modeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mode',
        value: '',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> modeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mode',
        value: '',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> snapshotJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'snapshotJson',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> snapshotJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'snapshotJson',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> snapshotJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'snapshotJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> snapshotJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'snapshotJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> snapshotJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'snapshotJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> snapshotJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'snapshotJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> snapshotJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'snapshotJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> snapshotJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'snapshotJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
          QAfterFilterCondition>
      snapshotJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'snapshotJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
          QAfterFilterCondition>
      snapshotJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'snapshotJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> snapshotJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'snapshotJson',
        value: '',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> snapshotJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'snapshotJson',
        value: '',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> startedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> startedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> startedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> startedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> tokensUsedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tokensUsed',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> tokensUsedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tokensUsed',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> tokensUsedEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tokensUsed',
        value: value,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> tokensUsedGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tokensUsed',
        value: value,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> tokensUsedLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tokensUsed',
        value: value,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> tokensUsedBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tokensUsed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> userQueryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> userQueryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> userQueryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> userQueryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userQuery',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> userQueryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> userQueryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
          QAfterFilterCondition>
      userQueryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
          QAfterFilterCondition>
      userQueryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userQuery',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> userQueryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userQuery',
        value: '',
      ));
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection,
      QAfterFilterCondition> userQueryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userQuery',
        value: '',
      ));
    });
  }
}

extension AiDiagnosticCollectionQueryObject on QueryBuilder<
    AiDiagnosticCollection, AiDiagnosticCollection, QFilterCondition> {}

extension AiDiagnosticCollectionQueryLinks on QueryBuilder<
    AiDiagnosticCollection, AiDiagnosticCollection, QFilterCondition> {}

extension AiDiagnosticCollectionQuerySortBy
    on QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QSortBy> {
  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByAiModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiModel', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByAiModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiModel', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByAiProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiProvider', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByAiProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiProvider', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByAiResponse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiResponse', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByAiResponseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiResponse', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByEndedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByMikrotikIp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mikrotikIp', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByMikrotikIpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mikrotikIp', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortBySnapshotJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotJson', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortBySnapshotJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotJson', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByTokensUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokensUsed', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByTokensUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokensUsed', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByUserQuery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userQuery', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      sortByUserQueryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userQuery', Sort.desc);
    });
  }
}

extension AiDiagnosticCollectionQuerySortThenBy on QueryBuilder<
    AiDiagnosticCollection, AiDiagnosticCollection, QSortThenBy> {
  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByAiModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiModel', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByAiModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiModel', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByAiProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiProvider', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByAiProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiProvider', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByAiResponse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiResponse', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByAiResponseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiResponse', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByEndedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByMikrotikIp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mikrotikIp', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByMikrotikIpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mikrotikIp', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenBySnapshotJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotJson', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenBySnapshotJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotJson', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByTokensUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokensUsed', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByTokensUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokensUsed', Sort.desc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByUserQuery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userQuery', Sort.asc);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QAfterSortBy>
      thenByUserQueryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userQuery', Sort.desc);
    });
  }
}

extension AiDiagnosticCollectionQueryWhereDistinct
    on QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QDistinct> {
  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QDistinct>
      distinctByAiModel({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aiModel', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QDistinct>
      distinctByAiProvider({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aiProvider', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QDistinct>
      distinctByAiResponse({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aiResponse', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QDistinct>
      distinctByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endedAt');
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QDistinct>
      distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QDistinct>
      distinctByMikrotikIp({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mikrotikIp', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QDistinct>
      distinctByMode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QDistinct>
      distinctBySnapshotJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'snapshotJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QDistinct>
      distinctByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAt');
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QDistinct>
      distinctByTokensUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tokensUsed');
    });
  }

  QueryBuilder<AiDiagnosticCollection, AiDiagnosticCollection, QDistinct>
      distinctByUserQuery({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userQuery', caseSensitive: caseSensitive);
    });
  }
}

extension AiDiagnosticCollectionQueryProperty on QueryBuilder<
    AiDiagnosticCollection, AiDiagnosticCollection, QQueryProperty> {
  QueryBuilder<AiDiagnosticCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AiDiagnosticCollection, String?, QQueryOperations>
      aiModelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiModel');
    });
  }

  QueryBuilder<AiDiagnosticCollection, String?, QQueryOperations>
      aiProviderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiProvider');
    });
  }

  QueryBuilder<AiDiagnosticCollection, String, QQueryOperations>
      aiResponseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiResponse');
    });
  }

  QueryBuilder<AiDiagnosticCollection, DateTime?, QQueryOperations>
      endedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endedAt');
    });
  }

  QueryBuilder<AiDiagnosticCollection, bool, QQueryOperations>
      isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<AiDiagnosticCollection, String?, QQueryOperations>
      mikrotikIpProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mikrotikIp');
    });
  }

  QueryBuilder<AiDiagnosticCollection, String, QQueryOperations>
      modeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mode');
    });
  }

  QueryBuilder<AiDiagnosticCollection, String?, QQueryOperations>
      snapshotJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'snapshotJson');
    });
  }

  QueryBuilder<AiDiagnosticCollection, DateTime, QQueryOperations>
      startedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAt');
    });
  }

  QueryBuilder<AiDiagnosticCollection, int?, QQueryOperations>
      tokensUsedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tokensUsed');
    });
  }

  QueryBuilder<AiDiagnosticCollection, String, QQueryOperations>
      userQueryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userQuery');
    });
  }
}
