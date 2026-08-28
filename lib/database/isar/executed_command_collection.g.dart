// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'executed_command_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetExecutedCommandCollectionCollection on Isar {
  IsarCollection<ExecutedCommandCollection> get executedCommandCollections =>
      this.collection();
}

const ExecutedCommandCollectionSchema = CollectionSchema(
  name: r'ExecutedCommandCollection',
  id: 3461730363160227337,
  properties: {
    r'command': PropertySchema(
      id: 0,
      name: r'command',
      type: IsarType.string,
    ),
    r'diagnosticId': PropertySchema(
      id: 1,
      name: r'diagnosticId',
      type: IsarType.long,
    ),
    r'durationMs': PropertySchema(
      id: 2,
      name: r'durationMs',
      type: IsarType.long,
    ),
    r'error': PropertySchema(
      id: 3,
      name: r'error',
      type: IsarType.string,
    ),
    r'executedAt': PropertySchema(
      id: 4,
      name: r'executedAt',
      type: IsarType.dateTime,
    ),
    r'output': PropertySchema(
      id: 5,
      name: r'output',
      type: IsarType.string,
    ),
    r'riskLevel': PropertySchema(
      id: 6,
      name: r'riskLevel',
      type: IsarType.string,
    ),
    r'success': PropertySchema(
      id: 7,
      name: r'success',
      type: IsarType.bool,
    )
  },
  estimateSize: _executedCommandCollectionEstimateSize,
  serialize: _executedCommandCollectionSerialize,
  deserialize: _executedCommandCollectionDeserialize,
  deserializeProp: _executedCommandCollectionDeserializeProp,
  idName: r'id',
  indexes: {
    r'riskLevel': IndexSchema(
      id: -5764699641590423344,
      name: r'riskLevel',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'riskLevel',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'success': IndexSchema(
      id: -7226122232819089750,
      name: r'success',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'success',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'executedAt_riskLevel': IndexSchema(
      id: 2052638986848362159,
      name: r'executedAt_riskLevel',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'executedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'riskLevel',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _executedCommandCollectionGetId,
  getLinks: _executedCommandCollectionGetLinks,
  attach: _executedCommandCollectionAttach,
  version: '3.1.0+1',
);

int _executedCommandCollectionEstimateSize(
  ExecutedCommandCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.command.length * 3;
  {
    final value = object.error;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.output;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.riskLevel;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _executedCommandCollectionSerialize(
  ExecutedCommandCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.command);
  writer.writeLong(offsets[1], object.diagnosticId);
  writer.writeLong(offsets[2], object.durationMs);
  writer.writeString(offsets[3], object.error);
  writer.writeDateTime(offsets[4], object.executedAt);
  writer.writeString(offsets[5], object.output);
  writer.writeString(offsets[6], object.riskLevel);
  writer.writeBool(offsets[7], object.success);
}

ExecutedCommandCollection _executedCommandCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ExecutedCommandCollection();
  object.command = reader.readString(offsets[0]);
  object.diagnosticId = reader.readLongOrNull(offsets[1]);
  object.durationMs = reader.readLongOrNull(offsets[2]);
  object.error = reader.readStringOrNull(offsets[3]);
  object.executedAt = reader.readDateTime(offsets[4]);
  object.id = id;
  object.output = reader.readStringOrNull(offsets[5]);
  object.riskLevel = reader.readStringOrNull(offsets[6]);
  object.success = reader.readBool(offsets[7]);
  return object;
}

P _executedCommandCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _executedCommandCollectionGetId(ExecutedCommandCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _executedCommandCollectionGetLinks(
    ExecutedCommandCollection object) {
  return [];
}

void _executedCommandCollectionAttach(
    IsarCollection<dynamic> col, Id id, ExecutedCommandCollection object) {
  object.id = id;
}

extension ExecutedCommandCollectionQueryWhereSort on QueryBuilder<
    ExecutedCommandCollection, ExecutedCommandCollection, QWhere> {
  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhere> anySuccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'success'),
      );
    });
  }
}

extension ExecutedCommandCollectionQueryWhere on QueryBuilder<
    ExecutedCommandCollection, ExecutedCommandCollection, QWhereClause> {
  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
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

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
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

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhereClause> riskLevelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'riskLevel',
        value: [null],
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhereClause> riskLevelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'riskLevel',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhereClause> riskLevelEqualTo(String? riskLevel) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'riskLevel',
        value: [riskLevel],
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhereClause> riskLevelNotEqualTo(String? riskLevel) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'riskLevel',
              lower: [],
              upper: [riskLevel],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'riskLevel',
              lower: [riskLevel],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'riskLevel',
              lower: [riskLevel],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'riskLevel',
              lower: [],
              upper: [riskLevel],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhereClause> successEqualTo(bool success) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'success',
        value: [success],
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhereClause> successNotEqualTo(bool success) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'success',
              lower: [],
              upper: [success],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'success',
              lower: [success],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'success',
              lower: [success],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'success',
              lower: [],
              upper: [success],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhereClause> executedAtEqualToAnyRiskLevel(DateTime executedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'executedAt_riskLevel',
        value: [executedAt],
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhereClause> executedAtNotEqualToAnyRiskLevel(DateTime executedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'executedAt_riskLevel',
              lower: [],
              upper: [executedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'executedAt_riskLevel',
              lower: [executedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'executedAt_riskLevel',
              lower: [executedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'executedAt_riskLevel',
              lower: [],
              upper: [executedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhereClause> executedAtGreaterThanAnyRiskLevel(
    DateTime executedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'executedAt_riskLevel',
        lower: [executedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhereClause> executedAtLessThanAnyRiskLevel(
    DateTime executedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'executedAt_riskLevel',
        lower: [],
        upper: [executedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhereClause> executedAtBetweenAnyRiskLevel(
    DateTime lowerExecutedAt,
    DateTime upperExecutedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'executedAt_riskLevel',
        lower: [lowerExecutedAt],
        includeLower: includeLower,
        upper: [upperExecutedAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterWhereClause> executedAtEqualToRiskLevelIsNull(DateTime executedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'executedAt_riskLevel',
        value: [executedAt, null],
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
          QAfterWhereClause>
      executedAtEqualToRiskLevelIsNotNull(DateTime executedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'executedAt_riskLevel',
        lower: [executedAt, null],
        includeLower: false,
        upper: [
          executedAt,
        ],
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
          QAfterWhereClause>
      executedAtRiskLevelEqualTo(DateTime executedAt, String? riskLevel) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'executedAt_riskLevel',
        value: [executedAt, riskLevel],
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
          QAfterWhereClause>
      executedAtEqualToRiskLevelNotEqualTo(
          DateTime executedAt, String? riskLevel) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'executedAt_riskLevel',
              lower: [executedAt],
              upper: [executedAt, riskLevel],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'executedAt_riskLevel',
              lower: [executedAt, riskLevel],
              includeLower: false,
              upper: [executedAt],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'executedAt_riskLevel',
              lower: [executedAt, riskLevel],
              includeLower: false,
              upper: [executedAt],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'executedAt_riskLevel',
              lower: [executedAt],
              upper: [executedAt, riskLevel],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ExecutedCommandCollectionQueryFilter on QueryBuilder<
    ExecutedCommandCollection, ExecutedCommandCollection, QFilterCondition> {
  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> commandEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'command',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> commandGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'command',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> commandLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'command',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> commandBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'command',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> commandStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'command',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> commandEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'command',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
          QAfterFilterCondition>
      commandContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'command',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
          QAfterFilterCondition>
      commandMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'command',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> commandIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'command',
        value: '',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> commandIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'command',
        value: '',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> diagnosticIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'diagnosticId',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> diagnosticIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'diagnosticId',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> diagnosticIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'diagnosticId',
        value: value,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> diagnosticIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'diagnosticId',
        value: value,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> diagnosticIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'diagnosticId',
        value: value,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> diagnosticIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'diagnosticId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> durationMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'durationMs',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> durationMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'durationMs',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> durationMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> durationMsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> durationMsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationMs',
        value: value,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> durationMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> errorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'error',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> errorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'error',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> errorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> errorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> errorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> errorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'error',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> errorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> errorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
          QAfterFilterCondition>
      errorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'error',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
          QAfterFilterCondition>
      errorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'error',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> errorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'error',
        value: '',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> errorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'error',
        value: '',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> executedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'executedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> executedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'executedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> executedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'executedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> executedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'executedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
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

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
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

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
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

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> outputIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'output',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> outputIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'output',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> outputEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'output',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> outputGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'output',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> outputLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'output',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> outputBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'output',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> outputStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'output',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> outputEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'output',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
          QAfterFilterCondition>
      outputContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'output',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
          QAfterFilterCondition>
      outputMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'output',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> outputIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'output',
        value: '',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> outputIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'output',
        value: '',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> riskLevelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'riskLevel',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> riskLevelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'riskLevel',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> riskLevelEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'riskLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> riskLevelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'riskLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> riskLevelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'riskLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> riskLevelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'riskLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> riskLevelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'riskLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> riskLevelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'riskLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
          QAfterFilterCondition>
      riskLevelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'riskLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
          QAfterFilterCondition>
      riskLevelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'riskLevel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> riskLevelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'riskLevel',
        value: '',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> riskLevelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'riskLevel',
        value: '',
      ));
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterFilterCondition> successEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'success',
        value: value,
      ));
    });
  }
}

extension ExecutedCommandCollectionQueryObject on QueryBuilder<
    ExecutedCommandCollection, ExecutedCommandCollection, QFilterCondition> {}

extension ExecutedCommandCollectionQueryLinks on QueryBuilder<
    ExecutedCommandCollection, ExecutedCommandCollection, QFilterCondition> {}

extension ExecutedCommandCollectionQuerySortBy on QueryBuilder<
    ExecutedCommandCollection, ExecutedCommandCollection, QSortBy> {
  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortByCommand() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'command', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortByCommandDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'command', Sort.desc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortByDiagnosticId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diagnosticId', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortByDiagnosticIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diagnosticId', Sort.desc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortByDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.desc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortByError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'error', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortByErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'error', Sort.desc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortByExecutedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedAt', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortByExecutedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedAt', Sort.desc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortByOutput() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'output', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortByOutputDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'output', Sort.desc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortByRiskLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'riskLevel', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortByRiskLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'riskLevel', Sort.desc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortBySuccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'success', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> sortBySuccessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'success', Sort.desc);
    });
  }
}

extension ExecutedCommandCollectionQuerySortThenBy on QueryBuilder<
    ExecutedCommandCollection, ExecutedCommandCollection, QSortThenBy> {
  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenByCommand() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'command', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenByCommandDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'command', Sort.desc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenByDiagnosticId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diagnosticId', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenByDiagnosticIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diagnosticId', Sort.desc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenByDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.desc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenByError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'error', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenByErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'error', Sort.desc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenByExecutedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedAt', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenByExecutedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedAt', Sort.desc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenByOutput() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'output', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenByOutputDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'output', Sort.desc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenByRiskLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'riskLevel', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenByRiskLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'riskLevel', Sort.desc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenBySuccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'success', Sort.asc);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection,
      QAfterSortBy> thenBySuccessDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'success', Sort.desc);
    });
  }
}

extension ExecutedCommandCollectionQueryWhereDistinct on QueryBuilder<
    ExecutedCommandCollection, ExecutedCommandCollection, QDistinct> {
  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection, QDistinct>
      distinctByCommand({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'command', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection, QDistinct>
      distinctByDiagnosticId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'diagnosticId');
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection, QDistinct>
      distinctByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationMs');
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection, QDistinct>
      distinctByError({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'error', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection, QDistinct>
      distinctByExecutedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'executedAt');
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection, QDistinct>
      distinctByOutput({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'output', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection, QDistinct>
      distinctByRiskLevel({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'riskLevel', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExecutedCommandCollection, ExecutedCommandCollection, QDistinct>
      distinctBySuccess() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'success');
    });
  }
}

extension ExecutedCommandCollectionQueryProperty on QueryBuilder<
    ExecutedCommandCollection, ExecutedCommandCollection, QQueryProperty> {
  QueryBuilder<ExecutedCommandCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ExecutedCommandCollection, String, QQueryOperations>
      commandProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'command');
    });
  }

  QueryBuilder<ExecutedCommandCollection, int?, QQueryOperations>
      diagnosticIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'diagnosticId');
    });
  }

  QueryBuilder<ExecutedCommandCollection, int?, QQueryOperations>
      durationMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationMs');
    });
  }

  QueryBuilder<ExecutedCommandCollection, String?, QQueryOperations>
      errorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'error');
    });
  }

  QueryBuilder<ExecutedCommandCollection, DateTime, QQueryOperations>
      executedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'executedAt');
    });
  }

  QueryBuilder<ExecutedCommandCollection, String?, QQueryOperations>
      outputProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'output');
    });
  }

  QueryBuilder<ExecutedCommandCollection, String?, QQueryOperations>
      riskLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'riskLevel');
    });
  }

  QueryBuilder<ExecutedCommandCollection, bool, QQueryOperations>
      successProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'success');
    });
  }
}
