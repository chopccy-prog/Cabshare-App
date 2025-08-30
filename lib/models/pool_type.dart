// lib/models/pool_type.dart
enum PoolType { private, commercial, fullcar }

extension PoolTypeApi on PoolType {
  String get apiValue {
    switch (this) {
      case PoolType.private:
        return 'private';
      case PoolType.commercial:
        return 'commercial';
      case PoolType.fullcar:
        return 'fullcar';
    }
  }

  String get label {
    switch (this) {
      case PoolType.private:
        return 'Private pool';
      case PoolType.commercial:
        return 'Commercial pool';
      case PoolType.fullcar:
        return 'Full car';
    }
  }

  static PoolType fromApi(String? v) {
    switch (v) {
      case 'commercial':
        return PoolType.commercial;
      case 'fullcar':
        return PoolType.fullcar;
      case 'private':
      default:
        return PoolType.private;
    }
  }
}
