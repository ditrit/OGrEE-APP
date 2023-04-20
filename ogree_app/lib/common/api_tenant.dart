part of 'api_backend.dart';

Future<Map<String, dynamic>> fetchTenantStats(String tenantUrl, String apiToken,
    {http.Client? client}) async {
  print("API get Tenant Stats $tenantUrl");
  client ??= http.Client();
  Uri url = Uri.parse('$tenantUrl/api/stats');
  final response = await client.get(url, headers: getHeader(apiToken));
  print(response.statusCode);
  if (response.statusCode == 200) {
    print(response.body);
    Map<String, dynamic> data = json.decode(response.body);
    return data;
  } else {
    throw Exception('${response.statusCode}: Failed to load objects');
  }
}

Future<Map<String, dynamic>> fetchTenantApiVersion(
    String tenantUrl, String apiToken,
    {http.Client? client}) async {
  print("API get Tenant Version $tenantUrl");
  client ??= http.Client();
  Uri url = Uri.parse('$tenantUrl/api/version');
  final response = await client.get(url, headers: getHeader(apiToken));
  print(response.statusCode);
  if (response.statusCode == 200) {
    print(response.body);
    Map<String, dynamic> data = json.decode(response.body);
    data = (Map<String, dynamic>.from(data["data"]));
    return data;
  } else {
    throw Exception('${response.statusCode}: Failed to load objects');
  }
}

Future<List<User>> fetchApiUsers(String tenantUrl, String apiToken,
    {http.Client? client}) async {
  print("API get users $tenantUrl");
  client ??= http.Client();
  Uri url = Uri.parse('$tenantUrl/api/users');
  final response = await client.get(url, headers: getHeader(apiToken));
  print(response.statusCode);
  if (response.statusCode == 200) {
    print(response.body);
    Map<String, dynamic> data = json.decode(response.body);
    print(data["data"]);
    print(data["data"].runtimeType);
    List<User> users = [];
    for (var user in List<Map<String, dynamic>>.from(data["data"])) {
      users.add(User.fromMap(user));
    }
    print(users);
    return users;
  } else {
    throw Exception('${response.statusCode}: Failed to load objects');
  }
}

Future<String> createUser(User user) async {
  print("API create User");
  Uri url = Uri.parse('$tenantUrl/api/users');
  final response = await http.post(url,
      body: user.toJson(), headers: getHeader(tenantToken));
  print(response.statusCode);
  if (response.statusCode == 201) {
    return "";
  } else {
    var data = json.decode(response.body);
    return data["message"].toString();
  }
}

Future<String> createDomain(Domain domain) async {
  print("API create Domain");
  Uri url = Uri.parse('$tenantUrl/api/domains');
  final response = await http.post(url,
      body: domain.toJson(), headers: getHeader(tenantToken));
  print(response.statusCode);
  if (response.statusCode == 201) {
    return "";
  } else {
    var data = json.decode(response.body);
    return data["message"].toString();
  }
}

Future<String> removeObject(String objName, String objType,
    {http.Client? client}) async {
  print("API delete object $objType");
  client ??= http.Client();
  Uri url = Uri.parse('$tenantUrl/api/$objType/$objName');
  final response = await client.delete(url, headers: getHeader(tenantToken));
  print(response.statusCode);
  if (response.statusCode == 200) {
    return "";
  } else {
    var data = json.decode(response.body);
    return data["message"].toString();
  }
}

Future<Domain?> fetchDomain(String name) async {
  print("API create Domain");
  Uri url = Uri.parse('$tenantUrl/api/domains/$name');
  final response = await http.get(url, headers: getHeader(tenantToken));
  print(response.statusCode);
  if (response.statusCode >= 200 && response.statusCode < 300) {
    print(response.body);
    Map<String, dynamic> data = json.decode(response.body);
    Domain domain = Domain.fromMap(data["data"]);
    return domain;
  } else {
    return null;
  }
}

Future<String> updateDomain(String currentDomainId, Domain domain) async {
  print("API update Domain");
  Uri url = Uri.parse('$tenantUrl/api/domains/$currentDomainId');
  final response = await http.put(url,
      body: domain.toJson(), headers: getHeader(tenantToken));
  print(response.statusCode);
  if (response.statusCode == 200) {
    return "";
  } else {
    var data = json.decode(response.body);
    return data["message"].toString();
  }
}

Future<String> updateUser(User user) async {
  print("API update Domain");
  Uri url = Uri.parse('$tenantUrl/api/domains/${user.id}');
  final response =
      await http.put(url, body: user.toJson(), headers: getHeader(tenantToken));
  print(response.statusCode);
  if (response.statusCode == 200) {
    return "";
  } else {
    var data = json.decode(response.body);
    return data["message"].toString();
  }
}