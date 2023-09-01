import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_place/google_place.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DotEnv().load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GooglePlace? _googlePlace;
  List<AutocompletePrediction> predictions = [];

  @override
  void initState() {
    String? apiKey = dotenv.env['API_KEY'];

    if (apiKey != null) {
      _googlePlace = GooglePlace(apiKey);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.only(right: 20, left: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                  labelText: "Search",
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blue,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.black54,
                      width: 2.0,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    autoCompleteSearch(value);
                  } else {
                    if (predictions.length > 0 && mounted) {
                      setState(() {
                        predictions = [];
                      });
                    }
                  }
                },
              ),
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: predictions.length,
                  itemBuilder: (context, index) {
                    String description = predictions[index].description ?? "";
                    String placeId = predictions[index].placeId ?? "";

                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          Icons.pin_drop,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(description),
                      onTap: () {
                        debugPrint(predictions[index].placeId);

                        if (_googlePlace == null) {
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsPage(
                              placeId: placeId,
                              googlePlace: _googlePlace!,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 10),
                child: Image.asset("assets/powered_by_google.png"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void autoCompleteSearch(String value) async {
    if (_googlePlace == null) {
      return;
    }

    var result = await _googlePlace?.autocomplete.get(value);

    if (result != null && result.predictions != null && mounted) {
      setState(() {
        predictions = result.predictions!;
      });
    }
  }
}

class DetailsPage extends StatefulWidget {
  final String placeId;
  final GooglePlace googlePlace;

  DetailsPage({
    Key? key,
    required this.placeId,
    required this.googlePlace,
  }) : super(key: key);

  @override
  DetailsPageState createState() => DetailsPageState();
}

class DetailsPageState extends State<DetailsPage> {
  DetailsResult? _detailsResult;
  List<Uint8List> _images = [];

  @override
  void initState() {
    getDetails(widget.placeId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Details"),
        backgroundColor: Colors.blueAccent,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          getDetails(widget.placeId);
        },
        child: Icon(Icons.refresh),
      ),
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.only(right: 20, left: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 250,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.memory(
                            _images[index],
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: _detailsResult == null
                      ? SizedBox.shrink()
                      : ListView(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(left: 15, top: 10),
                              child: Text(
                                "Details",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _detailsResult?.types != null
                                ? Container(
                                    margin: EdgeInsets.only(left: 15, top: 10),
                                    height: 50,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _detailsResult?.types?.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          margin: EdgeInsets.only(right: 10),
                                          child: Chip(
                                            label: Text(
                                              _detailsResult!.types![index],
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: Colors.blueAccent,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Container(),
                            Container(
                              margin: EdgeInsets.only(left: 15, top: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Icon(Icons.location_on),
                                ),
                                title: Text(
                                  _detailsResult?.formattedAddress != null
                                      ? 'Address: ${_detailsResult?.formattedAddress}'
                                      : "Address: null",
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 15, top: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Icon(Icons.location_searching),
                                ),
                                title: Text(
                                  _detailsResult?.geometry != null &&
                                          _detailsResult?.geometry?.location !=
                                              null
                                      ? 'Geometry: ${_detailsResult?.geometry?.location?.lat.toString()},${_detailsResult?.geometry?.location?.lng.toString()}'
                                      : "Geometry: null",
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 15, top: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Icon(Icons.timelapse),
                                ),
                                title: Text(
                                  _detailsResult?.utcOffset != null
                                      ? 'UTC offset: ${_detailsResult?.utcOffset.toString()} min'
                                      : "UTC offset: null",
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 15, top: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Icon(Icons.rate_review),
                                ),
                                title: Text(
                                  _detailsResult?.rating != null
                                      ? 'Rating: ${_detailsResult?.rating.toString()}'
                                      : "Rating: null",
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 15, top: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Icon(Icons.attach_money),
                                ),
                                title: Text(
                                  _detailsResult?.priceLevel != null
                                      ? 'Price level: ${_detailsResult?.priceLevel.toString()}'
                                      : "Price level: null",
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 20, bottom: 10),
                child: Image.asset("assets/powered_by_google.png"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void getDetails(String placeId) async {
    DetailsResponse? response = await widget.googlePlace.details.get(placeId);

    if (response != null && response.result != null && mounted) {
      setState(() {
        _detailsResult = response.result;
        _images = [];
      });

      if (response.result?.photos != null) {
        List<Photo> photos = response.result?.photos ?? [];

        for (var photo in photos) {
          if (photo.photoReference != null) {
            getPhoto(photo.photoReference!);
          }
        }
      }
    }
  }

  void getPhoto(String photoReference) async {
    Uint8List? result =
        await widget.googlePlace.photos.get(photoReference, 400, 400);

    if (result != null && mounted) {
      setState(() {
        _images.add(result);
      });
    }
  }
}
