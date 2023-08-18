
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/plugin_api.dart'; // Only import if required functionality is not exposed by default

import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'dart:io';
import 'example_popup.dart';



void main() async {

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {





    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


typedef MarkerCreationCallback = Marker Function(
    LatLng point, Map<String, dynamic> properties);
typedef PolylineCreationCallback = Polyline Function(
    List<LatLng> points, Map<String, dynamic> properties);
typedef PolygonCreationCallback = Polygon Function(List<LatLng> points,
    List<List<LatLng>>? holePointsList, Map<String, dynamic> properties);

/// GeoJsonParser parses the GeoJson and fills three lists of parsed objects
/// which are defined in flutter_map package
/// - list of [Marker]s
/// - list of [Polyline]s
/// - list of [Polygon]s
///
/// One should pass these lists when creating adequate layers in flutter_map.
/// For details see example.
///
/// Currently GeoJson parser supports only FeatureCollection and not GeometryCollection.
/// See the GeoJson Format specification at: https://www.rfc-editor.org/rfc/rfc7946
///
/// For creation of [Marker], [Polyline] and [Polygon] objects the default callback functions
/// are provided which are used in case when no user-defined callback function is provided.
/// To fully customize the  [Marker], [Polyline] and [Polygon] creation one has to write his own
/// callback functions. As a template the default callback functions can be used.
///


class MapMarker extends StatefulWidget {
  String x;
  
  MapMarker(this.x);
  
  @override
  _MapMarkerState createState() => _MapMarkerState();
}


class _MapMarkerState extends State<MapMarker> {
  final key = new GlobalKey();
  

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final dynamic tooltip = key.currentState;
        tooltip.ensureTooltipVisible();
      },
      child: Tooltip(
        key: key,
        message: widget.x,
        textStyle: TextStyle(color: Colors.black),
        padding: EdgeInsets.fromLTRB(10, 10, 10, 15),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Container(
          child: Icon(Icons.dangerous, size:25.0, color: Colors.red.withOpacity(1)),
        ),
      ),
    );
  }
}










class GeoJsonParser {
  /// list of [Marker] objects created as result of parsing
  final List<Marker> markers = [];

  /// list of [Polyline] objects created as result of parsing
  final List<Polyline> polylines = [];

  /// list of [Polygon] objects created as result of parsing
  final List<Polygon> polygons = [];

  /// user defined callback function that creates a [Marker] object
  MarkerCreationCallback? markerCreationCallback;

  /// user defined callback function that creates a [Polyline] object
  PolylineCreationCallback? polyLineCreationCallback;

  /// user defined callback function that creates a [Polygon] object
  PolygonCreationCallback? polygonCreationCallback;

  /// default [Marker] color
  Color? defaultMarkerColor;

  /// default [Marker] icon
  IconData? defaultMarkerIcon;

  /// default [Polyline] color
  Color? defaultPolylineColor;

  /// default [Polyline] stroke
  double? defaultPolylineStroke;

  /// default [Polygon] border color
  Color? defaultPolygonBorderColor;

  /// default [Polygon] fill color
  Color? defaultPolygonFillColor;

  /// default [Polygon] border stroke
  double? defaultPolygonBorderStroke;

  /// default flag if [Polygon] is filled (default is true)
  bool? defaultPolygonIsFilled;

  /// user defined callback function called when the [Marker] is tapped
  void Function(Map<String, dynamic>)? onMarkerTapCallback;

  /// default constructor - all parameters are optional and can be set later with setters
  GeoJsonParser(Color color, 
      {this.markerCreationCallback,
      this.polyLineCreationCallback,
      this.polygonCreationCallback,
      this.defaultMarkerColor,
      this.defaultMarkerIcon,
      this.onMarkerTapCallback,
      this.defaultPolylineColor,
      this.defaultPolylineStroke,
      this.defaultPolygonBorderColor,
      this.defaultPolygonFillColor,
      this.defaultPolygonBorderStroke,
      this.defaultPolygonIsFilled});
      
     

  /// parse GeJson in [String] format
  void parseGeoJsonAsString(String g) {
    return parseGeoJson(jsonDecode(g) as Map<String, dynamic>);
  }

  /// set default [Marker] color
  set setDefaultMarkerColor(Color color) {
    defaultMarkerColor = color;
  }

  /// set default [Marker] icon
  set setDefaultMarkerIcon(IconData ic) {
    defaultMarkerIcon = ic;
  }

  /// set default [Marker] tap callback function
  void setDefaultMarkerTapCallback(
      Function(Map<String, dynamic> f) onTapFunction) {
    onMarkerTapCallback = onTapFunction;
  }

  /// set default [Polyline] color
  set setDefaultPolylineColor(Color color) {
    defaultPolylineColor = color;
  }

  /// set default [Polyline] stroke
  set setDefaultPolylineStroke(double stroke) {
    defaultPolylineStroke = stroke;
  }

  /// set default [Polygon] fill color
  set setDefaultPolygonFillColor(Color color) {
    defaultPolygonFillColor = color;
  }

  /// set default [Polygon] border stroke
  set setDefaultPolygonBorderStroke(double stroke) {
    defaultPolygonBorderStroke = stroke;
  }

  /// set default [Polygon] border color
  set setDefaultPolygonBorderColorStroke(Color color) {
    defaultPolygonBorderColor = color;
  }

  /// set default [Polygon] setting whether polygon is filled
  set setDefaultPolygonIsFilled(bool filled) {
    defaultPolygonIsFilled = filled;
  }

  /// main GeoJson parsing function
  void parseGeoJson(Map<String, dynamic> g) {
    // set default values if they are not specified by constructor
    markerCreationCallback ??= createDefaultMarker;
    polyLineCreationCallback ??= createDefaultPolyline;
    polygonCreationCallback ??= createDefaultPolygon;
    defaultMarkerColor ??= Colors.red.withOpacity(0.8);
    defaultMarkerIcon ??= Icons.location_pin;
    defaultPolylineColor ??= Colors.blue.withOpacity(0.8);
    defaultPolylineStroke ??= 3.0;
    defaultPolygonBorderColor ??= Colors.black.withOpacity(0.8);
    defaultPolygonFillColor ??= Colors.black.withOpacity(0.1);
    defaultPolygonIsFilled ??= true;
    defaultPolygonBorderStroke ??= 0.1;

    // loop through the GeoJson Map and parse it
    for (Map f in g['features'] as List) {
      String geometryType = f['geometry']['type'].toString();
      switch (geometryType) {
        case 'Point':
          {
            markers.add(
              markerCreationCallback!(
                  LatLng(f['geometry']['coordinates'][1] as double,
                      f['geometry']['coordinates'][0] as double),
                  f['properties'] as Map<String, dynamic>),
            );
          }
          break;
        case 'MultiPoint':
          {
            for (final point in f['geometry']['coordinates'] as List) {
              markers.add(
                markerCreationCallback!(
                    LatLng(point[1] as double, point[0] as double),
                    f['properties'] as Map<String, dynamic>),
              );
            }
          }
          break;
        case 'LineString':
          {
            final List<LatLng> lineString = [];
            for (final coords in f['geometry']['coordinates'] as List) {
              lineString.add(LatLng(coords[1] as double, coords[0] as double));
            }
            polylines.add(polyLineCreationCallback!(
                lineString, f['properties'] as Map<String, dynamic>));
          }
          break;
        case 'MultiLineString':
          {
            for (final line in f['geometry']['coordinates'] as List) {
              final List<LatLng> lineString = [];
              for (final coords in line as List) {
                lineString
                    .add(LatLng(coords[1] as double, coords[0] as double));
              }
              polylines.add(polyLineCreationCallback!(
                  lineString, f['properties'] as Map<String, dynamic>));
            }
          }
          break;
        case 'Polygon':
          {
            final List<LatLng> outerRing = [];
            final List<List<LatLng>> holesList = [];
            int pathIndex = 0;
            for (final path in f['geometry']['coordinates'] as List) {
              final List<LatLng> hole = [];
              for (final coords in path as List<dynamic>) {
                if (pathIndex == 0) {
                  // add to polygon's outer ring
                  outerRing
                      .add(LatLng(coords[1] as double, coords[0] as double));
                } else {
                  // add it to current hole
                  hole.add(LatLng(coords[1] as double, coords[0] as double));
                }
              }
              if (pathIndex > 0) {
                // add hole to the polygon's list of holes
                holesList.add(hole);
              }
              pathIndex++;
            }
            polygons.add(polygonCreationCallback!(
                outerRing, holesList, f['properties'] as Map<String, dynamic>));
          }
          break;
        case 'MultiPolygon':
          {
            for (final polygon in f['geometry']['coordinates'] as List) {
              final List<LatLng> outerRing = [];
              final List<List<LatLng>> holesList = [];
              int pathIndex = 0;
              for (final path in polygon as List) {
                List<LatLng> hole = [];
                for (final coords in path as List<dynamic>) {
                  if (pathIndex == 0) {
                    // add to polygon's outer ring
                    outerRing
                        .add(LatLng(coords[1] as double, coords[0] as double));
                  } else {
                    // add it to a hole
                    hole.add(LatLng(coords[1] as double, coords[0] as double));
                  }
                }
                if (pathIndex > 0) {
                  // add to polygon's list of holes
                  holesList.add(hole);
                }
                pathIndex++;
              }
              polygons.add(polygonCreationCallback!(outerRing, holesList,
                  f['properties'] as Map<String, dynamic>));
            }
          }
          break;
      }
    }
    return;
  }

  /// default function for creating tappable [Marker]
  Widget defaultTappableMarker(Map<String, dynamic> properties,
      void Function(Map<String, dynamic>) onMarkerTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      //child : Icon(defaultMarkerIcon, color: defaultMarkerColor),
    
      
      child: GestureDetector(
        onTap: () {
          stderr.writeln('print me');
          onMarkerTap(properties);
        },
        child: Icon(Icons.dangerous, size:25.0, color: Colors.black.withOpacity(1)),
      ),
      
      
    
    );
  }

  /// default callback function for creating [Marker]
  Marker createDefaultMarker(LatLng point, Map<String, dynamic> properties) {
    String result = '';
    properties.forEach((key, value) {
      result += '$key : $value\n';
    });


    return Marker(
      width: 30.0,
      height: 30.0,
      point: point,
      //builder: (context) => defaultTappableMarker(properties, markerTapped),
      //builder: (_) => Icon(Icons.dangerous, size:30.0, color: Colors.black.withOpacity(1)),
      //rotateAlignment: AnchorAlign.top.rotationAlignment,
      builder: (context) => MapMarker(result),
    );
  }

  /// default callback function for creating [Polyline]
  Polyline createDefaultPolyline(
      List<LatLng> points, Map<String, dynamic> properties) {
    return Polyline(
        points: points,
        color: defaultPolylineColor!,
        strokeWidth: defaultPolylineStroke!);
  }

  /// default callback function for creating [Polygon]
  Polygon createDefaultPolygon(List<LatLng> outerRing,
      List<List<LatLng>>? holesList, Map<String, dynamic> properties) {
    return Polygon(
      points: outerRing,
      holePointsList: holesList,
      borderColor: defaultPolygonBorderColor!,
      color: defaultPolygonFillColor!,
      isFilled: true,
      borderStrokeWidth: defaultPolygonBorderStroke!,
    );
  }

  /// default callback function called when tappable [Marker] is tapped
  void markerTapped(Map<String, dynamic> map) {
    if (onMarkerTapCallback != null) {
      onMarkerTapCallback!(map);
    }
  }
}



Future<String> loadAsset(String n) async {
  return await rootBundle.loadString('assets/$n.json');
}

Color dgreen = Color.fromARGB(147, 4, 131, 42);
Color green = Color.fromARGB(149, 2, 236, 61);
Color yellow = Color.fromARGB(147, 248, 252, 3);
Color orange = Color.fromARGB(146, 255, 94, 1);
Color red = Color.fromARGB(146, 189, 0, 0);

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  GeoJsonParser poly_sgtrendah = GeoJsonParser(dgreen);
  GeoJsonParser poly_rendah = GeoJsonParser(green);
  GeoJsonParser poly_sedang = GeoJsonParser(yellow);
  GeoJsonParser poly_tinggi = GeoJsonParser(orange);
  GeoJsonParser poly_sgttinggi = GeoJsonParser(red);
  GeoJsonParser poly_his = GeoJsonParser(red);
  final mapController = MapController();
  late Position userpos;
  late FollowOnLocationUpdate _followOnLocationUpdate;
  late StreamController<double?> _followCurrentLocationStreamController;
  late final Stream<Position?> _geolocatorStream;
  bool suicchi = false;


  @override
  void initState(){
    super.initState();
    const factory = LocationMarkerDataStreamFactory();
    _geolocatorStream = factory.defaultPositionStreamSource().asBroadcastStream();
    _followOnLocationUpdate = FollowOnLocationUpdate.always;
    _followCurrentLocationStreamController = StreamController<double?>();
    poly_sgtrendah.setDefaultPolygonFillColor = dgreen;
    poly_sgtrendah.setDefaultPolygonBorderColorStroke = dgreen;
    poly_rendah.setDefaultPolygonFillColor = green;
    poly_rendah.setDefaultPolygonBorderColorStroke = green;
    poly_sedang.setDefaultPolygonFillColor = yellow;
    poly_sedang.setDefaultPolygonBorderColorStroke = yellow;
    poly_tinggi.setDefaultPolygonFillColor = orange;
    poly_tinggi.setDefaultPolygonBorderColorStroke = orange;
    poly_sgttinggi.setDefaultPolygonFillColor = red;
    poly_sgttinggi.setDefaultPolygonBorderColorStroke = red;

    readFromJson();

  }

 @override
  void dispose() {
    _followCurrentLocationStreamController.close();
    super.dispose();
  }

  

  void readFromJson() async {
    
    String rendah = await loadAsset('rendah');
    String sgtrendah = await loadAsset('sangat_rendah');
    String sedang = await loadAsset('sedang');
    String tinggi = await loadAsset('tinggi');
    String sgttinggi = await loadAsset('sangat_tinggi');
    String his = await loadAsset('his');

    poly_sgtrendah.parseGeoJsonAsString(sgtrendah);
    poly_rendah.parseGeoJsonAsString(rendah);
    poly_sedang.parseGeoJsonAsString(sedang);
    poly_tinggi.parseGeoJsonAsString(tinggi);
    poly_sgttinggi.parseGeoJsonAsString(sgttinggi);
    poly_his.parseGeoJsonAsString(his);
    userpos = await Geolocator.getCurrentPosition();
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.




    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options:MapOptions(
              center: LatLng(-7.916823774004072, 110.28358419551404),
              zoom:16,
              minZoom: 14,
              maxZoom : 18,
              onMapReady: () {
                mapController.move(LatLng(-7.916823774004072, 110.2845841955140),16);
              }

            ),
            nonRotatedChildren: [
              Positioned(
                right:20,
                bottom:20,
                child: FloatingActionButton(onPressed: (){
                  
                  /*
                  setState(
                    () => _followOnLocationUpdate = FollowOnLocationUpdate.always,
                  );
                  _followCurrentLocationStreamController.add(18);
                  */
                  if(!suicchi){
                    mapController.move(LatLng(userpos.latitude,userpos.longitude),16);
                    suicchi = true;
                  }
                  else{
                    mapController.move(LatLng(-7.916823774004072, 110.2845841955140),16);
                    suicchi = false;
                  }
                  
                


                  },
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                  )
                
                ,)
              )
            ],
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app', 
              ),
              
              PolygonLayer(polygons:poly_rendah.polygons,polygonCulling:true),
              PolygonLayer(polygons:poly_sgtrendah.polygons,polygonCulling:true),
              PolygonLayer(polygons:poly_sedang.polygons,polygonCulling:true),
              PolygonLayer(polygons:poly_tinggi.polygons,polygonCulling:true),
              PolygonLayer(polygons:poly_sgttinggi.polygons,polygonCulling:true),
              
             
              
              /*
              PopupMarkerLayer(options: PopupMarkerLayerOptions(markers: poly_his.markers,
              popupDisplayOptions: PopupDisplayOptions(
                builder: (BuildContext context, Marker marker) =>
                  ExamplePopup(marker),
              ))),
              */

              CurrentLocationLayer(),
              MarkerLayer(markers:poly_his.markers),
            ],
          )
        ],
      )
    );
    
    /*
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  
  */
  }
}


