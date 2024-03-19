// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers/todo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TodoImpl _$$TodoImplFromJson(Map<String, dynamic> json) => _$TodoImpl(
      description: json['description'] as String,
      id: json['id'] as String,
      completed: json['completed'] as bool? ?? false,
      createdAt: const DateTimeTimestampConverter()
          .fromJson(json['createdAt'] as Timestamp),
    );

Map<String, dynamic> _$$TodoImplToJson(_$TodoImpl instance) =>
    <String, dynamic>{
      'description': instance.description,
      'id': instance.id,
      'completed': instance.completed,
      'createdAt':
          const DateTimeTimestampConverter().toJson(instance.createdAt),
    };
