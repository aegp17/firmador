// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pdf_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PdfState {

 File? get pdfFile; File? get signedPdfFile; int get pageCount; int get currentPage; PDFViewController? get controller; SignaturePosition? get signaturePosition; bool get isSigning; bool get isLoading; String? get error;
/// Create a copy of PdfState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfStateCopyWith<PdfState> get copyWith => _$PdfStateCopyWithImpl<PdfState>(this as PdfState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfState&&(identical(other.pdfFile, pdfFile) || other.pdfFile == pdfFile)&&(identical(other.signedPdfFile, signedPdfFile) || other.signedPdfFile == signedPdfFile)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.controller, controller) || other.controller == controller)&&(identical(other.signaturePosition, signaturePosition) || other.signaturePosition == signaturePosition)&&(identical(other.isSigning, isSigning) || other.isSigning == isSigning)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,pdfFile,signedPdfFile,pageCount,currentPage,controller,signaturePosition,isSigning,isLoading,error);

@override
String toString() {
  return 'PdfState(pdfFile: $pdfFile, signedPdfFile: $signedPdfFile, pageCount: $pageCount, currentPage: $currentPage, controller: $controller, signaturePosition: $signaturePosition, isSigning: $isSigning, isLoading: $isLoading, error: $error)';
}


}

/// @nodoc
abstract mixin class $PdfStateCopyWith<$Res>  {
  factory $PdfStateCopyWith(PdfState value, $Res Function(PdfState) _then) = _$PdfStateCopyWithImpl;
@useResult
$Res call({
 File? pdfFile, File? signedPdfFile, int pageCount, int currentPage, PDFViewController? controller, SignaturePosition? signaturePosition, bool isSigning, bool isLoading, String? error
});




}
/// @nodoc
class _$PdfStateCopyWithImpl<$Res>
    implements $PdfStateCopyWith<$Res> {
  _$PdfStateCopyWithImpl(this._self, this._then);

  final PdfState _self;
  final $Res Function(PdfState) _then;

/// Create a copy of PdfState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pdfFile = freezed,Object? signedPdfFile = freezed,Object? pageCount = null,Object? currentPage = null,Object? controller = freezed,Object? signaturePosition = freezed,Object? isSigning = null,Object? isLoading = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
pdfFile: freezed == pdfFile ? _self.pdfFile : pdfFile // ignore: cast_nullable_to_non_nullable
as File?,signedPdfFile: freezed == signedPdfFile ? _self.signedPdfFile : signedPdfFile // ignore: cast_nullable_to_non_nullable
as File?,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,controller: freezed == controller ? _self.controller : controller // ignore: cast_nullable_to_non_nullable
as PDFViewController?,signaturePosition: freezed == signaturePosition ? _self.signaturePosition : signaturePosition // ignore: cast_nullable_to_non_nullable
as SignaturePosition?,isSigning: null == isSigning ? _self.isSigning : isSigning // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _PdfState implements PdfState {
  const _PdfState({this.pdfFile, this.signedPdfFile, this.pageCount = 0, this.currentPage = 0, this.controller, this.signaturePosition, this.isSigning = false, this.isLoading = false, this.error});
  

@override final  File? pdfFile;
@override final  File? signedPdfFile;
@override@JsonKey() final  int pageCount;
@override@JsonKey() final  int currentPage;
@override final  PDFViewController? controller;
@override final  SignaturePosition? signaturePosition;
@override@JsonKey() final  bool isSigning;
@override@JsonKey() final  bool isLoading;
@override final  String? error;

/// Create a copy of PdfState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PdfStateCopyWith<_PdfState> get copyWith => __$PdfStateCopyWithImpl<_PdfState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PdfState&&(identical(other.pdfFile, pdfFile) || other.pdfFile == pdfFile)&&(identical(other.signedPdfFile, signedPdfFile) || other.signedPdfFile == signedPdfFile)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.controller, controller) || other.controller == controller)&&(identical(other.signaturePosition, signaturePosition) || other.signaturePosition == signaturePosition)&&(identical(other.isSigning, isSigning) || other.isSigning == isSigning)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,pdfFile,signedPdfFile,pageCount,currentPage,controller,signaturePosition,isSigning,isLoading,error);

@override
String toString() {
  return 'PdfState(pdfFile: $pdfFile, signedPdfFile: $signedPdfFile, pageCount: $pageCount, currentPage: $currentPage, controller: $controller, signaturePosition: $signaturePosition, isSigning: $isSigning, isLoading: $isLoading, error: $error)';
}


}

/// @nodoc
abstract mixin class _$PdfStateCopyWith<$Res> implements $PdfStateCopyWith<$Res> {
  factory _$PdfStateCopyWith(_PdfState value, $Res Function(_PdfState) _then) = __$PdfStateCopyWithImpl;
@override @useResult
$Res call({
 File? pdfFile, File? signedPdfFile, int pageCount, int currentPage, PDFViewController? controller, SignaturePosition? signaturePosition, bool isSigning, bool isLoading, String? error
});




}
/// @nodoc
class __$PdfStateCopyWithImpl<$Res>
    implements _$PdfStateCopyWith<$Res> {
  __$PdfStateCopyWithImpl(this._self, this._then);

  final _PdfState _self;
  final $Res Function(_PdfState) _then;

/// Create a copy of PdfState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pdfFile = freezed,Object? signedPdfFile = freezed,Object? pageCount = null,Object? currentPage = null,Object? controller = freezed,Object? signaturePosition = freezed,Object? isSigning = null,Object? isLoading = null,Object? error = freezed,}) {
  return _then(_PdfState(
pdfFile: freezed == pdfFile ? _self.pdfFile : pdfFile // ignore: cast_nullable_to_non_nullable
as File?,signedPdfFile: freezed == signedPdfFile ? _self.signedPdfFile : signedPdfFile // ignore: cast_nullable_to_non_nullable
as File?,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,controller: freezed == controller ? _self.controller : controller // ignore: cast_nullable_to_non_nullable
as PDFViewController?,signaturePosition: freezed == signaturePosition ? _self.signaturePosition : signaturePosition // ignore: cast_nullable_to_non_nullable
as SignaturePosition?,isSigning: null == isSigning ? _self.isSigning : isSigning // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
