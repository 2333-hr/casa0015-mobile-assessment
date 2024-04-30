// © 2020 Flutter Team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import the Google Maps plugin

class Place { // Place class
  final String id; // Place ID
  final LatLng latLng; // Place latitude and longitude
  final String name; // Place name
  final PlaceCategory category; // Place category
  final String? description; // Place description
  final int starRating; // Place star rating
  final bool isCurrentLocation;

  const Place({ // Constructor
    required this.id, // Required parameter: Place ID
    required this.latLng, // Required parameter: Place latitude and longitude
    required this.name, // Required parameter: Place name
    required this.category, // Required parameter: Place category
    this.description, // Optional parameter: Place description
    this.starRating = 0, // Default parameter: Place star rating, default is 0
    this.isCurrentLocation = false,
  }) : assert(starRating >= 0 && starRating <= 5); // Assertion: Star rating should be between 0 and 5

  double get latitude => latLng.latitude; // Get place latitude

  double get longitude => latLng.longitude; // Get place longitude

  Place copyWith({ // Method to copy the object and modify specified fields
    String? id, // Optional parameter: Place ID
    LatLng? latLng, // Optional parameter: Place latitude and longitude
    String? name, // Optional parameter: Place name
    PlaceCategory? category, // Optional parameter: Place category
    String? description, // Optional parameter: Place description
    int? starRating, // Optional parameter: Place star rating
  }) {
    return Place( // Return the modified place object
      id: id ?? this.id, // Use original value if parameter is null
      latLng: latLng ?? this.latLng, // Use original value if parameter is null
      name: name ?? this.name, // Use original value if parameter is null
      category: category ?? this.category, // Use original value if parameter is null
      description: description ?? this.description, // Use original value if parameter is null
      starRating: starRating ?? this.starRating, // Use original value if parameter is null
    );
  }

  @override
  bool operator ==(Object other) => // Equality operator override
      identical(this, other) || // Same object equals
      other is Place && // Same type
          runtimeType == other.runtimeType && // Same runtime type
          id == other.id && // Same ID
          latLng == other.latLng && // Same latitude and longitude
          name == other.name && // Same name
          category == other.category && // Same category
          description == other.description && // Same description
          starRating == other.starRating; // Same star rating

  @override
  int get hashCode => // Hash code calculation method
      id.hashCode ^ // XOR operation on ID hash code
      latLng.hashCode ^ // XOR operation on latitude and longitude hash code
      name.hashCode ^ // XOR operation on name hash code
      category.hashCode ^ // XOR operation on category hash code
      description.hashCode ^ // XOR operation on description hash code
      starRating.hashCode; // XOR operation on star rating hash code
}

enum PlaceCategory { // Place category enumeration
  favorite, // Favorite places
  visited, // Visited places
  wantToGo, // Places to visit
  asdo,
}
