// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'certificate_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CertificateInfo {
  String get subject =>
      throw _privateConstructorUsedError; // Who the certificate belongs to
  String get issuer =>
      throw _privateConstructorUsedError; // Who issued the certificate
  DateTime get validFrom => throw _privateConstructorUsedError;
  DateTime get validTo => throw _privateConstructorUsedError;
  bool get isTrusted => throw _privateConstructorUsedError;

  /// Create a copy of CertificateInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CertificateInfoCopyWith<CertificateInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CertificateInfoCopyWith<$Res> {
  factory $CertificateInfoCopyWith(
    CertificateInfo value,
    $Res Function(CertificateInfo) then,
  ) = _$CertificateInfoCopyWithImpl<$Res, CertificateInfo>;
  @useResult
  $Res call({
    String subject,
    String issuer,
    DateTime validFrom,
    DateTime validTo,
    bool isTrusted,
  });
}

/// @nodoc
class _$CertificateInfoCopyWithImpl<$Res, $Val extends CertificateInfo>
    implements $CertificateInfoCopyWith<$Res> {
  _$CertificateInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CertificateInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subject = null,
    Object? issuer = null,
    Object? validFrom = null,
    Object? validTo = null,
    Object? isTrusted = null,
  }) {
    return _then(
      _value.copyWith(
            subject: null == subject
                ? _value.subject
                : subject // ignore: cast_nullable_to_non_nullable
                      as String,
            issuer: null == issuer
                ? _value.issuer
                : issuer // ignore: cast_nullable_to_non_nullable
                      as String,
            validFrom: null == validFrom
                ? _value.validFrom
                : validFrom // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            validTo: null == validTo
                ? _value.validTo
                : validTo // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isTrusted: null == isTrusted
                ? _value.isTrusted
                : isTrusted // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CertificateInfoImplCopyWith<$Res>
    implements $CertificateInfoCopyWith<$Res> {
  factory _$$CertificateInfoImplCopyWith(
    _$CertificateInfoImpl value,
    $Res Function(_$CertificateInfoImpl) then,
  ) = __$$CertificateInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String subject,
    String issuer,
    DateTime validFrom,
    DateTime validTo,
    bool isTrusted,
  });
}

/// @nodoc
class __$$CertificateInfoImplCopyWithImpl<$Res>
    extends _$CertificateInfoCopyWithImpl<$Res, _$CertificateInfoImpl>
    implements _$$CertificateInfoImplCopyWith<$Res> {
  __$$CertificateInfoImplCopyWithImpl(
    _$CertificateInfoImpl _value,
    $Res Function(_$CertificateInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CertificateInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subject = null,
    Object? issuer = null,
    Object? validFrom = null,
    Object? validTo = null,
    Object? isTrusted = null,
  }) {
    return _then(
      _$CertificateInfoImpl(
        subject: null == subject
            ? _value.subject
            : subject // ignore: cast_nullable_to_non_nullable
                  as String,
        issuer: null == issuer
            ? _value.issuer
            : issuer // ignore: cast_nullable_to_non_nullable
                  as String,
        validFrom: null == validFrom
            ? _value.validFrom
            : validFrom // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        validTo: null == validTo
            ? _value.validTo
            : validTo // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isTrusted: null == isTrusted
            ? _value.isTrusted
            : isTrusted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$CertificateInfoImpl implements _CertificateInfo {
  const _$CertificateInfoImpl({
    required this.subject,
    required this.issuer,
    required this.validFrom,
    required this.validTo,
    this.isTrusted = false,
  });

  @override
  final String subject;
  // Who the certificate belongs to
  @override
  final String issuer;
  // Who issued the certificate
  @override
  final DateTime validFrom;
  @override
  final DateTime validTo;
  @override
  @JsonKey()
  final bool isTrusted;

  @override
  String toString() {
    return 'CertificateInfo(subject: $subject, issuer: $issuer, validFrom: $validFrom, validTo: $validTo, isTrusted: $isTrusted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CertificateInfoImpl &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.issuer, issuer) || other.issuer == issuer) &&
            (identical(other.validFrom, validFrom) ||
                other.validFrom == validFrom) &&
            (identical(other.validTo, validTo) || other.validTo == validTo) &&
            (identical(other.isTrusted, isTrusted) ||
                other.isTrusted == isTrusted));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, subject, issuer, validFrom, validTo, isTrusted);

  /// Create a copy of CertificateInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CertificateInfoImplCopyWith<_$CertificateInfoImpl> get copyWith =>
      __$$CertificateInfoImplCopyWithImpl<_$CertificateInfoImpl>(
        this,
        _$identity,
      );
}

abstract class _CertificateInfo implements CertificateInfo {
  const factory _CertificateInfo({
    required final String subject,
    required final String issuer,
    required final DateTime validFrom,
    required final DateTime validTo,
    final bool isTrusted,
  }) = _$CertificateInfoImpl;

  @override
  String get subject; // Who the certificate belongs to
  @override
  String get issuer; // Who issued the certificate
  @override
  DateTime get validFrom;
  @override
  DateTime get validTo;
  @override
  bool get isTrusted;

  /// Create a copy of CertificateInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CertificateInfoImplCopyWith<_$CertificateInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
