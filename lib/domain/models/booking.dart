enum BookingStatus {
  pending,
  confirmed,
  completed,
  cancelled,
}

/// Domain model representing a decoration booking.
class Booking {
  const Booking({
    required this.id,
    required this.clientName,
    required this.eventName,
    required this.date,
    required this.location,
    required this.status,
    required this.totalPrice,
  });

  final String id;
  final String clientName;
  final String eventName;
  final DateTime date;
  final String location;
  final BookingStatus status;
  final double totalPrice;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Booking &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
