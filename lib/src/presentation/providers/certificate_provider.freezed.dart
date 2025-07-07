// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'certificate_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CertificateUploadState {
  PlatformFile? get file => throw _privateConstructorUsedError;
  String get password => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  CertificateInfo? get certificateInfo => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of CertificateUploadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CertificateUploadStateCopyWith<CertificateUploadState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CertificateUploadStateCopyWith<$Res> {
  factory $CertificateUploadStateCopyWith(
    CertificateUploadState value,
    $Res Function(CertificateUploadState) then,
  ) = _$CertificateUploadStateCopyWithImpl<$Res, CertificateUploadState>;
  @useResult
  $Res call({
    PlatformFile? file,
    String password,
    bool isLoading,
    CertificateInfo? certificateInfo,
    String? error,
  });

  $CertificateInfoCopyWith<$Res>? get certificateInfo;
}

/// @nodoc
class _$CertificateUploadStateCopyWithImpl<
  $Res,
  $Val extends CertificateUploadState
>
    implements $CertificateUploadStateCopyWith<$Res> {
  _$CertificateUploadStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CertificateUploadState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? file = freezed,
    Object? password = null,
    Object? isLoading = null,
    Object? certificateInfo = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            file: freezed == file
                ? _value.file
                : file // ignore: cast_nullable_to_non_nullable
                      as PlatformFile?,
            password: null == password
                ? _value.password
                : password // ignore: cast_nullable_to_non_nullable
                      as String,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            certificateInfo: freezed == certificateInfo
                ? _value.certificateInfo
                : certificateInfo // ignore: cast_nullable_to_non_nullable
                      as CertificateInfo?,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of CertificateUploadState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CertificateInfoCopyWith<$Res>? get certificateInfo {
    if (_value.certificateInfo == null) {
      return null;
    }

    return $CertificateInfoCopyWith<$Res>(_value.certificateInfo!, (value) {
      return _then(_value.copyWith(certificateInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CertificateUploadStateImplCopyWith<$Res>
    implements $CertificateUploadStateCopyWith<$Res> {
  factory _$$CertificateUploadStateImplCopyWith(
    _$CertificateUploadStateImpl value,
    $Res Function(_$CertificateUploadStateImpl) then,
  ) = __$$CertificateUploadStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    PlatformFile? file,
    String password,
    bool isLoading,
    CertificateInfo? certificateInfo,
    String? error,
  });

  @override
  $CertificateInfoCopyWith<$Res>? get certificateInfo;
}

/// @nodoc
class __$$CertificateUploadStateImplCopyWithImpl<$Res>
    extends
        _$CertificateUploadStateCopyWithImpl<$Res, _$CertificateUploadStateImpl>
    implements _$$CertificateUploadStateImplCopyWith<$Res> {
  __$$CertificateUploadStateImplCopyWithImpl(
    _$CertificateUploadStateImpl _value,
    $Res Function(_$CertificateUploadStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CertificateUploadState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? file = freezed,
    Object? password = null,
    Object? isLoading = null,
    Object? certificateInfo = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _$CertificateUploadStateImpl(
        file: freezed == file
            ? _value.file
            : file // ignore: cast_nullable_to_non_nullable
                  as PlatformFile?,
        password: null == password
            ? _value.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        certificateInfo: freezed == certificateInfo
            ? _value.certificateInfo
            : certificateInfo // ignore: cast_nullable_to_non_nullable
                  as CertificateInfo?,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$CertificateUploadStateImpl implements _CertificateUploadState {
  const _$CertificateUploadStateImpl({
    this.file,
    this.password = '',
    this.isLoading = false,
    this.certificateInfo,
    this.error,
  });

  @override
  final PlatformFile? file;
  @override
  @JsonKey()
  final String password;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final CertificateInfo? certificateInfo;
  @override
  final String? error;

  @override
  String toString() {
    return 'CertificateUploadState(file: $file, password: $password, isLoading: $isLoading, certificateInfo: $certificateInfo, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CertificateUploadStateImpl &&
            (identical(other.file, file) || other.file == file) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.certificateInfo, certificateInfo) ||
                other.certificateInfo == certificateInfo) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    file,
    password,
    isLoading,
    certificateInfo,
    error,
  );

  /// Create a copy of CertificateUploadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CertificateUploadStateImplCopyWith<_$CertificateUploadStateImpl>
  get copyWith =>
      __$$CertificateUploadStateImplCopyWithImpl<_$CertificateUploadStateImpl>(
        this,
        _$identity,
      );
}

abstract class _CertificateUploadState implements CertificateUploadState {
  const factory _CertificateUploadState({
    final PlatformFile? file,
    final String password,
    final bool isLoading,
    final CertificateInfo? certificateInfo,
    final String? error,
  }) = _$CertificateUploadStateImpl;

  @override
  PlatformFile? get file;
  @override
  String get password;
  @override
  bool get isLoading;
  @override
  CertificateInfo? get certificateInfo;
  @override
  String? get error;

  /// Create a copy of CertificateUploadState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CertificateUploadStateImplCopyWith<_$CertificateUploadStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
