// Stub file for File when running on web
// This file is used as a replacement for dart:io File when compiling for web

class File {
  final String path;
  
  File(this.path);
  
  Future<bool> exists() async => false;
  Future<File> copy(String newPath) async => File(newPath);
  Future<List<int>> readAsBytes() async => [];
}

