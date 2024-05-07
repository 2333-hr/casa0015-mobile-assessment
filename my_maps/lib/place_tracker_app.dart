import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:place_tracker/hive_ext.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// Import custom files
import 'place.dart';
import 'place_details.dart';
import 'place_map.dart';
import 'stub_data.dart';

// Enum representing different application views
enum PlaceTrackerViewType {
  map, // Map view mode
  list, // List view mode
}

// Main application class
class PlaceTrackerApp extends StatelessWidget {
  const PlaceTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false, // Disable the debug banner
      routerConfig: GoRouter(routes: [
        // Root route configuration
        GoRoute(
          path: '/',
          builder: (context, state) => _PlaceTrackerHomePage(),
          routes: [
            // Route for displaying place details
            GoRoute(
              path: 'place/:id',
              builder: (context, state) {
                // Retrieve the specific place by its ID
                final id = state.pathParameters['id']!;
                final place = context.read<AppState>().places.singleWhere((place) => place.id == id);
                return PlaceDetails(place: place);
              },
            ),
          ],
        ),
      ]),
    );
  }
}

// Home page of the Place Tracker application
class _PlaceTrackerHomePage extends StatefulWidget {
  _PlaceTrackerHomePage();

  @override
  State<_PlaceTrackerHomePage> createState() => _PlaceTrackerHomePageState();
}

// State for managing the application's main page
class _PlaceTrackerHomePageState extends State<_PlaceTrackerHomePage> {
  LatLng _center = LatLng(45.521563, -122.677433); // Default map center coordinates

  @override
  Widget build(BuildContext context) {
    var state = Provider.of<AppState>(context); // Get the current application state
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
              child: Icon(Icons.pin_drop, size: 24.0),
            ),
            Text('Location Logbook'),
          ],
        ),
        actions: [
          // Button to toggle between map and list views
          Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 0.0, 16.0, 0.0),
            child: IconButton(
              icon: Icon(
                state.viewType == PlaceTrackerViewType.map
                    ? Icons.list
                    : Icons.map,
                size: 32.0,
              ),
              onPressed: () {
                state.setViewType(
                  state.viewType == PlaceTrackerViewType.map
                      ? PlaceTrackerViewType.list
                      : PlaceTrackerViewType.map,
                );
              },
            ),
          ),
          // Button to open the place search dialog
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(Icons.search),
              onPressed: () async {
                final Place? selectedPlace = await showPlaceSearch(context);
                if (selectedPlace != null) {
                  goToPlace(context, selectedPlace);
                }
              },
            ),
          ),
        ],
      ),
      // IndexedStack switches between map and list views based on current view type
      body: IndexedStack(
        index: state.viewType == PlaceTrackerViewType.map ? 0 : 1,
        children: [
          PlaceMap(center: _center), // Map view widget
          _PlaceListView(), // List view widget
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _getCurrentLocation(context); // Fetch the current location and add a new place
        },
        child: Icon(Icons.add),
      ),
    );
  }

  // Function to get the user's current location and update the map center
  void _getCurrentLocation(BuildContext context) async {
    print('Requesting location permission...');
    // Request location permission
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      print('Location permission granted');
      // Fetch the current position
      print('Getting current position...');
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      print('Current position: $position');
      // Update map center with current position
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });
      // Create a new place object with the current location
      final place = Place(
        id: UniqueKey().toString(),
        latLng: LatLng(position.latitude, position.longitude),
        name: 'New Place',
        category: PlaceCategory.visited,
      );
      print('Adding new place: $place');
      // Add the new place to the application state
      context.read<AppState>().setPlaces([...context.read<AppState>().places, place]);

      // Fetch the weather data for the current location
      print('Fetching weather data...');
      _fetchWeatherData(position.latitude, position.longitude, context);
    } else {
      print('Location permission not granted');
    }
  }

  // Function to fetch weather data based on the provided coordinates
  void _fetchWeatherData(double latitude, double longitude, BuildContext context) async {
    // Construct the API request URL
    final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,precipitation,rain,showers,snowfall');

    try {
      // Execute an HTTP GET request
      final response = await http.get(url);

      // Check the response status code
      if (response.statusCode == 200) {
        // Parse the response data
        final jsonData = jsonDecode(response.body);
        final Map<String, dynamic> currentData = jsonData['current'] as Map<String, dynamic>;

        // Extract weather data from the response
        double temperature = _toDouble(currentData['temperature_2m']);
        double humidity = _toDouble(currentData['relative_humidity_2m']);
        double precipitation = _toDouble(currentData['precipitation']);
        double rain = _toDouble(currentData['rain']);
        double showers = _toDouble(currentData['showers']);
        double snowfall = _toDouble(currentData['snowfall']);

        // Display weather information in a dialog
        _showWeatherDialog(context, temperature, humidity, precipitation, rain, showers, snowfall);
      } else {
        print('Failed to fetch weather data: ${response.statusCode}');
      }
    } catch (error) {
      _showWeatherDialog(context, 20, 30, 40, 50, 60, 70); // Example data if an error occurs
      print('Error fetching weather data: $error');
    }
  }

  // Convert a value to double safely, handling potential nulls
  double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // Display a dialog with weather data
  void _showWeatherDialog(
    BuildContext context,
    double temperature,
    double humidity,
    double precipitation,
    double rain,
    double showers,
    double snowfall) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Weather Information'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Temperature: ${temperature.toStringAsFixed(1)}°C'),
                Text('Humidity: ${humidity.toStringAsFixed(1)}%'),
                Text('Precipitation: ${precipitation.toStringAsFixed(1)} mm'),
                Text('Rain: ${rain.toStringAsFixed(1)} mm'),
                Text('Showers: ${showers.toStringAsFixed(1)} mm'),
                Text('Snowfall: ${snowfall.toStringAsFixed(1)} cm'),
              ],
            ),
          ),
          actions: [
            // Close the dialog
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // Function to show a place search dialog and return a selected place
  Future<Place?> showPlaceSearch(BuildContext context) async {
    TextEditingController searchController = TextEditingController();
    return showDialog<Place?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search Place'),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(hintText: 'Enter place name'),
          ),
          actions: [
            // Search button: Retrieve and return a place with the specified name
            TextButton(
              child: const Text('Search'),
              onPressed: () {
                final placeName = searchController.text;
                final place = context.read<AppState>().places.firstWhere(
                      (place) => place.name.toLowerCase() == placeName.toLowerCase(),
                      orElse: () => Place(
                        id: UniqueKey().toString(),
                        latLng: LatLng(0, 0),
                        name: placeName,
                        category: PlaceCategory.visited,
                      ),
                    );
                Navigator.of(context).pop(place); // Close dialog with the selected place
              },
            ),
            // Cancel button: Close the dialog without selection
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
          ],
        );
      },
    );
  }

  // Navigate to a specified place on the map
  void goToPlace(BuildContext context, Place place) {
    // Set the map center to the specified place's coordinates
    setState(() {
      _center = place.latLng;
    });
    // Update the application's view mode to map
    context.read<AppState>().setViewType(PlaceTrackerViewType.map);
  }
}

// List view displaying places
class _PlaceListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var state = Provider.of<AppState>(context); // Get the application state
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: state.places.length,
      itemBuilder: (BuildContext context, int index) {
        // Build each item representing a place
        return _PlaceListItem(
          place: state.places[index],
        );
      },
    );
  }
}

// List item widget representing a single place
class _PlaceListItem extends StatelessWidget {
  final Place place; // Place data for the item
  const _PlaceListItem({required this.place});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.pin_drop),
        title: Text(place.name), // Display the place name
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlaceDetails(place: place))),
      ),
    );
  }
}
