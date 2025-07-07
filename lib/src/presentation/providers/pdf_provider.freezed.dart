// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pdf_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PdfState {
  File? get pdfFile => throw _privateConstructorUsedError;
  File? get signedPdfFile => throw _privateConstructorUsedError;
  int get pageCount => throw _privateConstructorUsedError;
  int get currentPage => throw _privateConstructorUsedError;
  PDFViewController? get controller => throw _privateConstructorUsedError;
  SignaturePosition? get signaturePosition =>
      throw _privateConstructorUsedError;
  bool get isSigning => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of PdfState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PdfStateCopyWith<PdfState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PdfStateCopyWith<$Res> {
  factory $PdfStateCopyWith(PdfState value, $Res Function(PdfState) then) =
      _$PdfStateCopyWithImpl<$Res, PdfState>;
  @useResult
  $Res call({
    File? pdfFile,
    File? signedPdfFile,
    int pageCount,
    int currentPage,
    PDFViewController? controller,
    SignaturePosition? signaturePosition,
    bool isSigning,
    bool isLoading,
    String? error,
  });
}

/// @nodoc
class _$PdfStateCopyWithImpl<$Res, $Val extends PdfState>
    implements $PdfStateCopyWith<$Res> {
  _$PdfStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PdfState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pdfFile = freezed,
    Object? signedPdfFile = freezed,
    Object? pageCount = null,
    Object? currentPage = null,
    Object? controller = freezed,
    Object? signaturePosition = freezed,
    Object? isSigning = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            pdfFile: freezed == pdfFile
                ? _value.pdfFile
                : pdfFile // ignore: cast_nullable_to_non_nullable
                      as File?,
            signedPdfFile: freezed == signedPdfFile
                ? _value.signedPdfFile
                : signedPdfFile // ignore: cast_nullable_to_non_nullable
                      as File?,
            pageCount: null == pageCount
                ? _value.pageCount
                : pageCount // ignore: cast_nullable_to_non_nullable
                      as int,
            currentPage: null == currentPage
                ? _value.currentPage
                : currentPage // ignore: cast_nullable_to_non_nullable
                      as int,
            controller: freezed == controller
                ? _value.controller
                : controller // ignore: cast_nullable_to_non_nullable
                      as PDFViewController?,
            signaturePosition: freezed == signaturePosition
                ? _value.signaturePosition
                : signaturePosition // ignore: cast_nullable_to_non_nullable
                      as SignaturePosition?,
            isSigning: null == isSigning
                ? _value.isSigning
                : isSigning // ignore: cast_nullable_to_non_nullable
                      as bool,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PdfStateImplCopyWith<$Res>
    implements $PdfStateCopyWith<$Res> {
  factory _$$PdfStateImplCopyWith(
    _$PdfStateImpl value,
    $Res Function(_$PdfStateImpl) then,
  ) = __$$PdfStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    File? pdfFile,
    File? signedPdfFile,
    int pageCount,
    int currentPage,
    PDFViewController? controller,
    SignaturePosition? signaturePosition,
    bool isSigning,
    bool isLoading,
    String? error,
  });
}

/// @nodoc
class __$$PdfStateImplCopyWithImpl<$Res>
    extends _$PdfStateCopyWithImpl<$Res, _$PdfStateImpl>
    implements _$$PdfStateImplCopyWith<$Res> {
  __$$PdfStateImplCopyWithImpl(
    _$PdfStateImpl _value,
    $Res Function(_$PdfStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PdfState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pdfFile = freezed,
    Object? signedPdfFile = freezed,
    Object? pageCount = null,
    Object? currentPage = null,
    Object? controller = freezed,
    Object? signaturePosition = freezed,
    Object? isSigning = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _$PdfStateImpl(
        pdfFile: freezed == pdfFile
            ? _value.pdfFile
            : pdfFile // ignore: cast_nullable_to_non_nullable
                  as File?,
        signedPdfFile: freezed == signedPdfFile
            ? _value.signedPdfFile
            : signedPdfFile // ignore: cast_nullable_to_non_nullable
                  as File?,
        pageCount: null == pageCount
            ? _value.pageCount
            : pageCount // ignore: cast_nullable_to_non_nullable
                  as int,
        currentPage: null == currentPage
            ? _value.currentPage
            : currentPage // ignore: cast_nullable_to_non_nullable
                  as int,
        controller: freezed == controller
            ? _value.controller
            : controller // ignore: cast_nullable_to_non_nullable
                  as PDFViewController?,
        signaturePosition: freezed == signaturePosition
            ? _value.signaturePosition
            : signaturePosition // ignore: cast_nullable_to_non_nullable
                  as SignaturePosition?,
        isSigning: null == isSigning
            ? _value.isSigning
            : isSigning // ignore: cast_nullable_to_non_nullable
                  as bool,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$PdfStateImpl implements _PdfState {
  const _$PdfStateImpl({
    this.pdfFile,
    this.signedPdfFile,
    this.pageCount = 0,
    this.currentPage = 0,
    this.controller,
    this.signaturePosition,
    this.isSigning = false,
    this.isLoading = false,
    this.error,
  });

  @override
  final File? pdfFile;
  @override
  final File? signedPdfFile;
  @override
  @JsonKey()
  final int pageCount;
  @override
  @JsonKey()
  final int currentPage;
  @override
  final PDFViewController? controller;
  @override
  final SignaturePosition? signaturePosition;
  @override
  @JsonKey()
  final bool isSigning;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'PdfState(pdfFile: $pdfFile, signedPdfFile: $signedPdfFile, pageCount: $pageCount, currentPage: $currentPage, controller: $controller, signaturePosition: $signaturePosition, isSigning: $isSigning, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PdfStateImpl &&
            (identical(other.pdfFile, pdfFile) || other.pdfFile == pdfFile) &&
            (identical(other.signedPdfFile, signedPdfFile) ||
                other.signedPdfFile == signedPdfFile) &&
            (identical(other.pageCount, pageCount) ||
                other.pageCount == pageCount) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.controller, controller) ||
                other.controller == controller) &&
            (identical(other.signaturePosition, signaturePosition) ||
                other.signaturePosition == signaturePosition) &&
            (identical(other.isSigning, isSigning) ||
                other.isSigning == isSigning) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    pdfFile,
    signedPdfFile,
    pageCount,
    currentPage,
    controller,
    signaturePosition,
    isSigning,
    isLoading,
    error,
  );

  /// Create a copy of PdfState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PdfStateImplCopyWith<_$PdfStateImpl> get copyWith =>
      __$$PdfStateImplCopyWithImpl<_$PdfStateImpl>(this, _$identity);
}

abstract class _PdfState implements PdfState {
  const factory _PdfState({
    final File? pdfFile,
    final File? signedPdfFile,
    final int pageCount,
    final int currentPage,
    final PDFViewController? controller,
    final SignaturePosition? signaturePosition,
    final bool isSigning,
    final bool isLoading,
    final String? error,
  }) = _$PdfStateImpl;

  @override
  File? get pdfFile;
  @override
  File? get signedPdfFile;
  @override
  int get pageCount;
  @override
  int get currentPage;
  @override
  PDFViewController? get controller;
  @override
  SignaturePosition? get signaturePosition;
  @override
  bool get isSigning;
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of PdfState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PdfStateImplCopyWith<_$PdfStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
