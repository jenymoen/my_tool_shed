class Tool {
  String id;
  String name;
  bool isBorrowed;
  DateTime? returnDate;
  String? borrowedBy;

  Tool({
    required this.id,
    required this.name,
    this.isBorrowed = false,
    this.returnDate,
    this.borrowedBy,
  });
}
