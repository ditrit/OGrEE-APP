import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:ogree_app/common/api_backend.dart';
import 'package:ogree_app/models/tenant.dart';
import 'package:ogree_app/widgets/tenants/api_stats_view.dart';

import 'common.dart';

// Create a mock for the Tenant class
class MockTenant extends Mock implements Tenant {}

// Create a mock for the fetchTenantStats function
class MockFetchTenantStats extends Mock {
  Future<Map<String, String>> call(any) async {
    print("Hi!");
    return Future.delayed(
        Duration(microseconds: 1), () => {'stat1': '10', 'stat2': '20'});
  }
}

// Create a mock for the fetchTenantApiVersion function
class MockFetchTenantApiVersion extends Mock {
  Future<Map<String, String>> call(any) async {
    print("Hi!");

    return Future.delayed(
        Duration(microseconds: 1), () => {'version': '1.0.0'});
  }
}

void main() {
  group('ApiStatsView', () {
    late Tenant tenant;
    late Function mockFetchTenantStats;
    late Function mockFetchTenantApiVersion;

    setUp(() {
      // Initialize the mocks and test data
      tenant = MockTenant();
      mockFetchTenantStats = MockFetchTenantStats();
      mockFetchTenantApiVersion = MockFetchTenantApiVersion();

      // Set up the mock behaviors
      // when(mockFetchTenantStats(any)).thenAnswer((_) async {
      //   return {'stat1': 10, 'stat2': 20};
      // });
      // when(mockFetchTenantApiVersion(any)).thenAnswer((_) async {
      //   return {'version': '1.0.0'};
      // });

      // Provide the mock objects to the widget under test
      tenant.apiUrl = 'localhost';
      tenant.apiPort = "8080";
    });

    testWidgets('renders loading spinner while fetching stats',
        (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        LocalizationsInjApp(
          child: ApiStatsView(
            tenant: tenant,
          ),
        ),
      );

      // Expect to see the loading spinner
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders stats after fetching stats',
        (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        LocalizationsInjApp(
          child: ApiStatsView(
            tenant: tenant,
          ),
        ),
      );

      // Expect to see the loading spinner
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for the stats to be fetched and the widget to be rebuilt
      await tester.pumpAndSettle();

      // Expect to see the stats in the widget
      expect(find.text('stat1 10'), findsOneWidget);
      expect(find.text('stat2 20'), findsOneWidget);
      expect(find.text('APIversion 1.0.0'), findsOneWidget);
    });

    testWidgets('renders empty message if stats are empty',
        (WidgetTester tester) async {
      // Set up the mock behaviors to return an empty map
      when(mockFetchTenantStats(any)).thenAnswer((_) async {
        print("Hie!");

        return {};
      });

      // Build the widget
      await tester.pumpWidget(
        LocalizationsInjApp(
          child: ApiStatsView(
            tenant: tenant,
          ),
        ),
      );

      // Expect to see the loading spinner
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for the stats to be fetched and the widget to be rebuilt
      await tester.pumpAndSettle();

      // Expect to see the empty message in the widget
      expect(find.text('No projects found'), findsOneWidget);
    });
  });
}
