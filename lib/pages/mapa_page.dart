import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:mapa_app/bloc/mapa/mapa_bloc.dart';
import 'package:mapa_app/bloc/mi_ubicacion/mi_ubicacion_bloc.dart';
import 'package:mapa_app/services/traffic_service.dart';

import 'package:mapa_app/widgets/widgets.dart';
import 'package:polyline/polyline.dart' as Poly;



class MapaPage extends StatefulWidget {

  @override
  _MapaPageState createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {

  @override
  void initState() {
    
    context.bloc<MiUbicacionBloc>().iniciarSeguimiento();
    setSourceAndDestinationIcons();
    super.initState();
  }

  GoogleMapController _googleMapController;
  @override
  void dispose() {
    _googleMapController.dispose();
    context.bloc<MiUbicacionBloc>().cancelarSeguimiento();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [

          BlocBuilder<MiUbicacionBloc, MiUbicacionState>(
            builder: ( _ , state)  => crearMapa( state )
          ),

          Positioned(
            top: 15,
            child: SearchBar()
          ),

          
          MarcadorManual(),

        ],
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [

          BtnUbicacion(),

          //BtnSeguirUbicacion(),

          //BtnMiRuta(),

        ],
      ),
   );

  }

  Widget crearMapa( MiUbicacionState state ) {

    if ( !state.existeUbicacion ) return Center(child: Text('Buscando ubicación...'));

    final mapaBloc = BlocProvider.of<MapaBloc>(context);

    mapaBloc.add( OnNuevaUbicacion( state.ubicacion ) );

    final cameraPosition = new CameraPosition(
      target: state.ubicacion,
      zoom: 15
    );

    void _addMarker(LatLng pos) async {
      if (_origin == null || (_origin != null && _destination != null)) {
        //var pinPositionUp = LatLng(currentLocation.latitude, currentLocation.longitude);
        // Origin is not set OR Origin/Destination are both set
        // Set origin
        setState(() {
          _origin = Marker(
            markerId: MarkerId('originlocationnamemap'),
            infoWindow: const InfoWindow(title: 'Ubicación'),
            icon:sourceIcon,
            position: state.ubicacion,
          );


          // Reset destination
          _destination = null;

         const  coordinates = [
          LatLng(0.0, 0.0),
          LatLng(0.0, 0.0)
        ];

          mapaBloc.add(OnCrearRutaInicioDestino(coordinates, 0.0, 0.0));
        });
      } else {
        // Origin is already set
        // Set destination
        setState(() async {
              
            final trafficService = new TrafficService();
            final mapaBloc = context.bloc<MapaBloc>();
              
            final inicio  = state.ubicacion;
            //final destino = mapaBloc.state.ubicacionCentral;

            final trafficResponse = await trafficService.getCoordsInicioYDestino(inicio, pos);

            final geometry  = trafficResponse.routes[0].geometry;
            final duracion  = trafficResponse.routes[0].duration;
            final distancia = trafficResponse.routes[0].distance;

                
         _destination = Marker(
            markerId: MarkerId('destinationlocationnavemap'),
            infoWindow: InfoWindow(title: 'Destino: ' + (distancia/1000).round().toString() + ' km'/*,snippet: duracion.toString()*/ ),
            icon: destinationIcon,
            position: pos,
          );

    // Decodificar los puntos del geometry
    final points = Poly.Polyline.Decode( encodedString: geometry, precision: 6 ).decodedCoords;
    final List<LatLng> rutaCoordenadas = points.map(
      (point) => LatLng(point[0], point[1])
    ).toList();

    mapaBloc.add( OnCrearRutaInicioDestino(rutaCoordenadas, distancia, duracion) );

    

        });
        //calcularDestino(context);
    }
  }
    return BlocBuilder<MapaBloc, MapaState>(
      builder: (context, _ ) {
        return GoogleMap(
          initialCameraPosition: cameraPosition,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: mapaBloc.initMapa,
          polylines:  mapaBloc.state.polylines.values.toSet(),
          markers: {
              Marker(
                markerId: MarkerId('originlocationnamemap'),
                infoWindow: const InfoWindow(title: 'Ubicación'),
                icon:sourceIcon,
                position: state.ubicacion,
              ),
              
              if (_destination != null) _destination
            },
          onLongPress: _addMarker,
          onCameraMove: ( cameraPosition ) {
            // cameraPosition.target = LatLng central del mapa
            mapaBloc.add( OnMovioMapa( cameraPosition.target ));
          },
        );
      },
    );
   

  }

   BitmapDescriptor sourceIcon;
   BitmapDescriptor destinationIcon;
   Marker _origin;
   Marker _destination;

     void setSourceAndDestinationIcons() async {
    BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.0), 'assets/images/destination_map_marker.png')
        .then((onValue) {
      sourceIcon = onValue;
    });

    BitmapDescriptor.fromAssetImage(const ImageConfiguration(devicePixelRatio: 2.0),
        'assets/images/driving_pin.png')
        .then((onValue) {
      destinationIcon = onValue;
    });
  }


}