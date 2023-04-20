// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Tenant {
  String name;
  String customerPassword;
  String apiUrl;
  String webUrl;
  bool hasWeb;
  bool hasCli;

  Tenant(this.name, this.customerPassword, this.apiUrl, this.webUrl,
      this.hasWeb, this.hasCli);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'customerPassword': customerPassword,
      'apiUrl': apiUrl,
      'webUrl': webUrl,
      'hasWeb': hasWeb,
      'hasCli': hasCli,
    };
  }

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
        map['name'].toString(),
        map['customerPassword'].toString(),
        map['apiUrl'].toString(),
        map['webUrl'].toString(),
        map['hasWeb'],
        map['hasCli']);
  }

  String toJson() => json.encode(toMap());

  factory Tenant.fromJson(String source) =>
      Tenant.fromMap(json.decode(source) as Map<String, dynamic>);
}
