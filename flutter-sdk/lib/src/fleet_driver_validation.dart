/// Indian mobile MSISDN — Android `validIndianMobile10`.
bool validIndianMobile10(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  final ten = d.length <= 10 ? d : d.substring(d.length - 10);
  if (ten.length != 10) return false;
  final first = int.tryParse(ten[0]);
  if (first == null) return false;
  return first >= 6 && first <= 9;
}
