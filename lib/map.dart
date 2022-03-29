import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_mapbox_navigation/library.dart';



/*void main() => runApp(MyApp());*/

class Map extends StatefulWidget {
  const Map({Key? key}) : super(key: key);

  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  String _platformVersion = 'Unknown';
  String _instruction = "";
  final _origin = WayPoint(
      name: "Way Point 1",
      latitude: 23.13802709392114,
      longitude: -82.38634281619676);
  final _stop1 = WayPoint(
      name: "Way Point 2",
      latitude: 23.097498187496733,
      longitude: -82.36800257799578);

  MapBoxNavigation? _directions;
  MapBoxOptions? _options;

  final bool _isMultipleStop = false;
  double? _distanceRemaining ;
  double? _durationRemaining ;
  MapBoxNavigationViewController? _controller;
  bool _routeBuilt = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initialize() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    _directions = MapBoxNavigation(onRouteEvent: _onEmbeddedRouteEvent);
    _options = MapBoxOptions(
        initialLatitude: 23.13802709392114,
        initialLongitude: -82.38634281619676,
        zoom: 15.0,
        tilt: 0.0,
        bearing: 0.0,
        enableRefresh: false,
        alternatives: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: false,
        allowsUTurnAtWayPoints: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        //mapStyleUrlDay: "mapbox://styles/alexcarcharing/cl1b0qnmw000o15lya6puwhik",
        mapStyleUrlDay: "mapbox://styles/alexcarcharing/cl1b0v8im000q15ly9kn8yaj0",
        mapStyleUrlNight: "mapbox://styles/alexcarcharing/cl1b0v8im000q15ly9kn8yaj0",
        units: VoiceUnits.imperial,
        simulateRoute: false,
        animateBuildRoute: true,
        longPressDestinationEnabled: true,
        language: "es");

    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await _directions!.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('La Nave MapBox'),
        ),
        body: Center(
          child: Column(children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          child: const Text("Start A to B"),
                          onPressed: () async {
                            var wayPoints = <WayPoint>[];
                            wayPoints.add(_origin);
                            wayPoints.add(_stop1);

                            await _directions!.startNavigation(
                                wayPoints: wayPoints,
                                options: MapBoxOptions(
                                    //initialLatitude: 23.13802709392114,
                                    //initialLongitude: -82.38634281619676,
                                    zoom: 45.0,
                                    bearing: 45.0,
                                    mode: MapBoxNavigationMode.drivingWithTraffic,
                                    simulateRoute: false,
                                    //voiceInstructionsEnabled: false,
                                    //bannerInstructionsEnabled: false,
                                    //mapStyleUrlDay: "mapbox://styles/alexcarcharing/cl1b0qnmw000o15lya6puwhik",
                                    language: "es",
                                    animateBuildRoute: true,
                                    units: VoiceUnits.imperial));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            /*Expanded(
              flex: 1,
              child: Container(
                color: Colors.white,
                child: MapBoxNavigationView(
                    options: _options,
                    onRouteEvent: _onEmbeddedRouteEvent,
                    onCreated:
                        (MapBoxNavigationViewController controller) async {
                      _controller = controller;
                      controller.initialize();
                    }),
              ),
            )*/
          ]),
        ),
      ),
    );
  }

  Future<void> _onEmbeddedRouteEvent(e) async {
    _distanceRemaining = await _directions!.distanceRemaining;
    _durationRemaining = await _directions!.durationRemaining;

    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        var progressEvent = e.data as RouteProgressEvent;
        if (progressEvent.currentStepInstruction != null) {
          _instruction = progressEvent.currentStepInstruction!;
        }
        break;
      case MapBoxEvent.route_building:
      case MapBoxEvent.route_built:
        setState(() {
          _routeBuilt = true;
        });
        break;
      case MapBoxEvent.route_build_failed:
        setState(() {
          _routeBuilt = false;
        });
        break;
      case MapBoxEvent.navigation_running:
        setState(() {
          _isNavigating = true;
        });
        break;
      case MapBoxEvent.on_arrival:
        if (!_isMultipleStop) {
          await Future.delayed(const Duration(seconds: 3));
          await _controller!.finishNavigation();
        } else {}
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        setState(() {
          _routeBuilt = false;
          _isNavigating = false;
        });
        break;
      default:
        break;
    }
    setState(() {});
  }
}