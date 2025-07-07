// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'certificate_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CertificateUploadState {

 PlatformFile? get file; String get password; bool get isLoading; CertificateInfo? get certificateInfo; String? get error;
/// Create a copy of CertificateUploadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateUploadStateCopyWith<CertificateUploadState> get copyWith => _$CertificateUploadStateCopyWithImpl<CertificateUploadState>(this as CertificateUploadState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertificateUploadState&&(identical(other.file, file) || other.file == file)&&(identical(other.password, password) || other.password == password)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.certificateInfo, certificateInfo) || other.certificateInfo == certificateInfo)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,file,password,isLoading,certificateInfo,error);

@override
String toString() {
  return 'CertificateUploadState(file: $file, password: $password, isLoading: $isLoading, certificateInfo: $certificateInfo, error: $error)';
}


}

/// @nodoc
abstract mixin class $CertificateUploadStateCopyWith<$Res>  {
  factory $CertificateUploadStateCopyWith(CertificateUploadState value, $Res Function(CertificateUploadState) _then) = _$CertificateUploadStateCopyWithImpl;
@useResult
$Res call({
 PlatformFile? file, String password, bool isLoading, CertificateInfo? certificateInfo, String? error
});


$CertificateInfoCopyWith<$Res>? get certificateInfo;

}
/// @nodoc
class _$CertificateUploadStateCopyWithImpl<$Res>
    implements $CertificateUploadStateCopyWith<$Res> {
  _$CertificateUploadStateCopyWithImpl(this._self, this._then);

  final CertificateUploadState _self;
  final $Res Function(CertificateUploadState) _then;

/// Create a copy of CertificateUploadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? file = freezed,Object? password = null,Object? isLoading = null,Object? certificateInfo = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
file: freezed == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as PlatformFile?,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,certificateInfo: freezed == certificateInfo ? _self.certificateInfo : certificateInfo // ignore: cast_nullable_to_non_nullable
as CertificateInfo?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of CertificateUploadState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CertificateInfoCopyWith<$Res>? get certificateInfo {
    if (_self.certificateInfo == null) {
    return null;
  }

  return $CertificateInfoCopyWith<$Res>(_self.certificateInfo!, (value) {
    return _then(_self.copyWith(certificateInfo: value));
  });
}
}


/// @nodoc


class _CertificateUploadState implements CertificateUploadState {
  const _CertificateUploadState({this.file, this.password = '', this.isLoading = false, this.certificateInfo, this.error});
  

@override final  PlatformFile? file;
@override@JsonKey() final  String password;
@override@JsonKey() final  bool isLoading;
@override final  CertificateInfo? certificateInfo;
@override final  String? error;

/// Create a copy of CertificateUploadState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateUploadStateCopyWith<_CertificateUploadState> get copyWith => __$CertificateUploadStateCopyWithImpl<_CertificateUploadState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertificateUploadState&&(identical(other.file, file) || other.file == file)&&(identical(other.password, password) || other.password == password)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.certificateInfo, certificateInfo) || other.certificateInfo == certificateInfo)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,file,password,isLoading,certificateInfo,error);

@override
String toString() {
  return 'CertificateUploadState(file: $file, password: $password, isLoading: $isLoading, certificateInfo: $certificateInfo, error: $error)';
}


}

/// @nodoc
abstract mixin class _$CertificateUploadStateCopyWith<$Res> implements $CertificateUploadStateCopyWith<$Res> {
  factory _$CertificateUploadStateCopyWith(_CertificateUploadState value, $Res Function(_CertificateUploadState) _then) = __$CertificateUploadStateCopyWithImpl;
@override @useResult
$Res call({
 PlatformFile? file, String password, bool isLoading, CertificateInfo? certificateInfo, String? error
});


@override $CertificateInfoCopyWith<$Res>? get certificateInfo;

}
/// @nodoc
class __$CertificateUploadStateCopyWithImpl<$Res>
    implements _$CertificateUploadStateCopyWith<$Res> {
  __$CertificateUploadStateCopyWithImpl(this._self, this._then);

  final _CertificateUploadState _self;
  final $Res Function(_CertificateUploadState) _then;

/// Create a copy of CertificateUploadState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? file = freezed,Object? password = null,Object? isLoading = null,Object? certificateInfo = freezed,Object? error = freezed,}) {
  return _then(_CertificateUploadState(
file: freezed == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as PlatformFile?,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,certificateInfo: freezed == certificateInfo ? _self.certificateInfo : certificateInfo // ignore: cast_nullable_to_non_nullable
as CertificateInfo?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of CertificateUploadState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CertificateInfoCopyWith<$Res>? get certificateInfo {
    if (_self.certificateInfo == null) {
    return null;
  }

  return $CertificateInfoCopyWith<$Res>(_self.certificateInfo!, (value) {
    return _then(_self.copyWith(certificateInfo: value));
  });
}
}

// dart format on
