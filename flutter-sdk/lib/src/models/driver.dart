enum DriverStatus { active, inactive }

class Driver {
  const Driver({
    required this.id,
    required this.name,
    required this.vrn,
    required this.status,
    required this.cardBalancePaise,
  });

  final String id;
  final String name;
  final String vrn;
  final DriverStatus status;
  final int cardBalancePaise;

  factory Driver.fromJson(Map<String, dynamic> j) {
    return Driver(
      id: j['id'] as String,
      name: j['name'] as String,
      vrn: j['vrn'] as String,
      status: (j['status'] as String) == 'Inactive'
          ? DriverStatus.inactive
          : DriverStatus.active,
      cardBalancePaise: (j['cardBalancePaise'] as num).toInt(),
    );
  }

  Driver copyWith({
    String? id,
    String? name,
    String? vrn,
    DriverStatus? status,
    int? cardBalancePaise,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      vrn: vrn ?? this.vrn,
      status: status ?? this.status,
      cardBalancePaise: cardBalancePaise ?? this.cardBalancePaise,
    );
  }
}
