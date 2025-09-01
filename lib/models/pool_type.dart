// lib/models/pool_type.dart
enum PoolType { private, commercial, fullcar }

extension PoolTypeName on PoolType {
  String get name {
    switch (this) {
      case PoolType.private:
        return 'private';
      case PoolType.commercial:
        return 'commercial';
      case PoolType.fullcar:
        return 'commercial_private'; // server expects this name
    }
  }

  static PoolType fromServer(String? s) {
    switch (s) {
      case 'commercial':
        return PoolType.commercial;
      case 'commercial_private':
        return PoolType.fullcar;
      case 'private':
      default:
        return PoolType.private;
    }
  }
}
