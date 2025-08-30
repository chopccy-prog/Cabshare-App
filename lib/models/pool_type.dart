enum PoolType {
  privatePool,        // white plate
  commercialPool,     // yellow plate (shared)
  commercialPrivate,  // full-car with home pickup
}

extension PoolTypeX on PoolType {
  String get apiValue {
    switch (this) {
      case PoolType.privatePool: return 'private';
      case PoolType.commercialPool: return 'commercial';
      case PoolType.commercialPrivate: return 'commercial_private';
    }
  }

  String get label {
    switch (this) {
      case PoolType.privatePool: return 'Private pool';
      case PoolType.commercialPool: return 'Commercial pool';
      case PoolType.commercialPrivate: return 'Commercial private';
    }
  }
}
