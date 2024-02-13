import 'dart:async';
import 'dart:math';
import 'package:custom_map_markers/custom_map_markers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart' as loc;
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyBcA4klUGzIamW7PC-nERoW9zcEVCWjLfg",
            authDomain: "location-e5cc0.firebaseapp.com",
            projectId: "location-e5cc0",
            storageBucket: "location-e5cc0.appspot.com",
            messagingSenderId: "132021888954",
            appId: "1:132021888954:web:9a8e12d10f6b4b1c93df83"
        )
    );
    print("Initialize is OK");
  } catch(e) {
    print("Initialize failed: $e");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Dashboard("id_here"),
    );
  }
}

class Dashboard extends StatefulWidget {
  final String user_id;

  Dashboard(this.user_id);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  late loc.Location location;
  late GoogleMapController _controller;
  bool _added = false;
  StreamSubscription<loc.LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    fetchData();
    location = loc.Location();
    WidgetsBinding.instance!.addObserver(this);
    _initLocationTracking();
  }

  void _initLocationTracking() {
    _locationSubscription = location.onLocationChanged.listen(
          (loc.LocationData currentLocation) {
        if (_added) {
          _updateMarkerPosition(currentLocation.latitude!, currentLocation.longitude!);
        }
      },
    );
  }
  @override
  void dispose() {
    _locationSubscription?.cancel();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  void _updateMarkerPosition(double latitude, double longitude) async {
    await _controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 14.47,
        ),
      ),
    );
  }
  Future<QuerySnapshot> fetchData() async {
    return await FirebaseFirestore.instance.collection('location').get();
  }

  // Create a Map to store the color for each marker
  Map<String, Color> markerColors = {};

  List<MarkerData> _createMarkersFromData(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      // If the marker doesn't have an associated color yet, create one
      if (!markerColors.containsKey(doc.id)) {
        markerColors[doc.id] = Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
      }

      return MarkerData(
        marker: Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(doc['latitude'], doc['longitude']),
        ),
        child: _customMarker(doc['name'], Colors.red), // Use the color from the map
      );
    }).toList();
  }

  Widget _customMarker(String symbol, Color color) {
    return Container(
        child: Column(
          children: [
            Container(
              width: 20,
              height: 10,
              decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.all(Radius.circular(5))
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 4,
                    fontStyle: FontStyle.normal,
                    decoration: TextDecoration.none, // This removes the underline
                  ),
                ),
              ),
            ),
            Stack(
              children: [
                Icon(
                  Icons.location_pin,
                  color: color,
                  size: 20,
                ),
                Positioned(
                  left: 5,
                  top: 3,
                  child: Container(
                    width: 10,
                    height: 10,
                    child: CircleAvatar(
                      backgroundImage: AssetImage('assets/images/user.png'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance.collection('location').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                      'There is no Active User',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      )
                  ),
                ],
              ),
            );
          }

          var markers = _createMarkersFromData(snapshot.data!);
          return CustomGoogleMapMarkerBuilder(
            customMarkers: markers,
            builder: (BuildContext context, Set<Marker>? markers) {
              if (markers == null) {
                return const Center(child: CircularProgressIndicator());
              }
              var firstMarker = markers.first;
              return GoogleMap(
                mapType: MapType.normal,
                markers: markers,
                initialCameraPosition: CameraPosition(
                  target: firstMarker.position,
                  zoom: 13,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _controller = controller;
                },
              );
            },
          );
           },
        );
    }
}