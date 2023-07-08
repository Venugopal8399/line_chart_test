import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'gs.dart';
import 'sheetscolumn.dart';
Future<void> main() async {
  await SheetsFlutter.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'SUMANA TECHNOLOGIES'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer? timer, period;
  ChartSeriesController? _chartSeriesController;
  ChartSeriesController? _schartSeriesController;
  final _fsc = FlutterSerialCommunication();
  List<DeviceInfo> connectedDevices = [];
  DeviceInfo device = DeviceInfo();
  bool device_conn = false;
  bool connection = false;
  List rbits = [];
  int progress = 0;
  Random random = Random();
  late String datetime;
  var cid = 'NULL';

  @override
  void initState() {
    super.initState();
    _connect();
    timer = Timer.periodic(const Duration(seconds: 6), updateDataSource);
  }
  Future<void> _connect() async {
    while (!connection) {
      connectedDevices = await _fsc.getAvailableDevices();
      if (connectedDevices.isNotEmpty) {
        device = connectedDevices.first;
        if (await _fsc.connect(device, 115200)) {
          setState(() {
            device_conn = true;
            connection = true;
          });
          _senddata();
        } else if (device_conn == false) {
          _connect();
        }
      }
    }
  }
  uploaddata() async {
    final feedback = {
      SheetsColumn.Res:rbits[0],
      SheetsColumn.Temparature:rbits[1],
      SheetsColumn.Cpu_Load:(rbits[2] << 8) | rbits[3],
      SheetsColumn.Stack_Load:(rbits[4] << 8) | rbits[5],
      SheetsColumn.Cloud_id:rbits.last,
    };
    SheetsFlutter.insert([feedback]);
  }

  //this method used to send the data to the cp2102
  // this method will work if the data is
  Future<void> _senddata() async {
    if (device_conn == true) {
      List<int> uint8ByteList = List<int>.filled(8, 0);
      uint8ByteList[0]=2;
      uint8ByteList[7] =66;
      List<int> positions = [2, 3, 4, 5, 6];
      for (int position in positions) {
        uint8ByteList[position] = random.nextInt(90);
      }
      await _fsc.write(
          Uint8List.fromList(uint8ByteList));
    }
  }

  // this method used to read the recieved bytes from the cp2102 microcontroller.
  // this method will called every 12 seconds if there are any data that received.
  Future<void> _receivedata() async {
    // await Future.delayed(const Duration(seconds: 2));
    EventChannel eventChannel = _fsc.getSerialMessageListener();
    eventChannel.receiveBroadcastStream().listen((event) {
      rbits = event;
      cid= rbits.last.toString();
      setState(() {
        rbits;
        cid;
        cpudata.add(Cpudata(count, (rbits[2] << 8) | rbits[3]));
        stackdata.add(Stackdata(count,(rbits[4] << 8) | rbits[5]));
        uploaddata();
      });
    });

  }
  List<Cpudata> cpudata =[
    Cpudata(0, 42),
    Cpudata(1, 47),
    Cpudata(2, 33),
    Cpudata(3, 49),
    Cpudata(4, 54),
  ];
  List<Stackdata> stackdata =[
    Stackdata(0, 42),
    Stackdata(1, 47),
    Stackdata(2, 33),
    Stackdata(3, 49),
    Stackdata(4, 54),
  ];
  int count = 5;
  @override
  Widget build(BuildContext context) {

    bool status = device_conn;
    late int temp;
    if (device_conn == true) {
      temp = rbits[1];
    }
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          title: Container(
            padding: const EdgeInsets.all(9.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: const BorderRadius.all(Radius.circular(
                      7.0) //                 <--- border radius here
                  ),
            ),
            child: const Text(
              'SUMANA TECHNOLOGIES',
              style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.normal,
              ),
            ),
          )),
      body: ListView(children: [
        Column(
          children: <Widget>[
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: SizedBox(
                          width: 170,
                          height: 200,
                          child: Card(
                            margin: const EdgeInsets.all(15),
                            color: Colors.white,
                            shadowColor: Colors.blueGrey,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(24.0),
                              ),
                            ),
                            elevation: 12,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Device Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  // when cp2102 is connected to the device then switch will turn into green.
                                  Switch(
                                    activeColor: Colors.green,
                                    value: status,
                                    onChanged: (bool value) {},
                                  ),
                                  const Text(
                                    'Cloud ID',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),


                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(
                                              2.0) //                 <--- border radius here
                                          ),
                                    ),

                                    // this is the section where cloud id will be displayed in the  text widget
                                    child: Text(
                                      cid,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 11,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: Card(
                            margin: const EdgeInsets.all(15),
                            color: Colors.white,
                            shadowColor: Colors.grey,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(24.0),
                              ),
                            ),
                            elevation: 12,
                            // this is a futurbuilder widget waiting for the data to receive in th rbits list if the list it full with the data then the the temperature will be diaplayed
                            // if the rbits list is empty then the circular progress indicator will be displayed until the rbits list has data.
                            child: FutureBuilder<void>(
                                future: _receivedata(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<void> snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(65.0),
                                      child: CircularProgressIndicator(),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}}');
                                    // this is the condition where if the list it empty then circle progress widget will dipalyed.
                                  } else if (rbits.isEmpty) {
                                    return const SizedBox(
                                      height: 190,
                                      width: 190,
                                      child: Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {

                                    // this is starting line of temperature widget
                                    return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: CircularPercentIndicator(
                                          radius: 70,
                                          lineWidth: 10,
                                          circularStrokeCap:
                                              CircularStrokeCap.round,
                                          percent:
                                              rbits[1].toDouble() /
                                                  100,
                                          animation: true,
                                          center: Text('$temp °F'),
                                          linearGradient: const LinearGradient(
                                            colors: [
                                              Colors.orangeAccent,
                                              Colors.blue
                                            ],
                                            stops: [
                                              0.1,
                                              0.5,
                                            ],
                                          ),
                                        ));
                                    //this is end line of the temperature widget

                                  }
                                }),
                          ),
                        ),
                      ))
                ],
              ),
            ),

            // this is the start line of cpu load chart.
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  width: 420,
                  height: 300,
                  child: Card(
                    color: Colors.white,
                    shadowColor: Colors.blueGrey,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(24.0),
                      ),
                    ),
                    elevation: 12,
                    child: Column(
                      children: [
                        Flexible(
                          flex: 9,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 8.0, left: 8.0, right: 8.0),
                            child: Center(
                              child: SfCartesianChart(
                                        primaryYAxis: NumericAxis(),
                                        primaryXAxis: NumericAxis(),
                                        series:<ChartSeries>[
                                          // Renders line chart
                                          LineSeries<Cpudata, int>(
                                              onRendererCreated: (ChartSeriesController controller) {
                                                _chartSeriesController = controller;
                                              },
                                              dataSource: cpudata,
                                              xValueMapper: (Cpudata cdata, _) => cdata.c1,
                                              yValueMapper: (Cpudata cdata, _) => cdata.c2,
                                              dataLabelSettings: const DataLabelSettings(isVisible: true)
                                          )
                                        ],
                                      )
                            ),
                          ),
                        ),
                        const Flexible(
                          child: Text(
                            'CPU LOAD',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // this is the end line of the cpu load chart

            // this is the stack load chart beginning.
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  width: 420,
                  height: 300,
                  child: Card(
                    color: Colors.white,
                    shadowColor: Colors.blueGrey,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(24.0),
                      ),
                    ),
                    elevation: 12,
                    child: Column(
                      children: [
                        Flexible(
                          flex: 9,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 8.0, left: 8.0, right: 8.0),
                            child: Center(
                              child: SfCartesianChart(
                                        primaryYAxis: NumericAxis(),
                                        primaryXAxis: NumericAxis(),
                                        series:<ChartSeries>[
                                          // Renders line chart
                                          LineSeries<Stackdata, int>(
                                              onRendererCreated: (ChartSeriesController controller) {
                                                _schartSeriesController = controller;
                                              },
                                              dataSource: stackdata,
                                              xValueMapper: (Stackdata cdata, _) => cdata.s1,
                                              yValueMapper: (Stackdata cdata, _) => cdata.s2,
                                            dataLabelSettings: const DataLabelSettings(isVisible: true)
                                          )
                                        ],
                                      )
                            ),
                          ),
                        ),
                        const Flexible(
                          child: Text(
                            'STACK LOAD',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // this is the end of the stack load chart widget
          ],
        ),
      ]),
    );
  }
  timestamp(){
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    DateTime tsdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    datetime = "${tsdate.hour}/${tsdate.minute}/${tsdate.second}";
    setState(() {
      datetime;
    });
  }
  // updating the data into the chart every 12 seonds
  // removing the first byte and adding the data to the last position of the list
  updateDataSource(Timer timer) {
    _senddata();
    _receivedata();
    setState(() {

    });

    if (count >= 10) {
      cpudata.removeAt(0);
      _chartSeriesController?.updateDataSource(addedDataIndexes: <int>[cpudata.length-1],
          removedDataIndexes: <int>[0]);
      stackdata.removeAt(0);
      _schartSeriesController?.updateDataSource(addedDataIndexes: <int>[stackdata.length-1],
          removedDataIndexes: <int>[0]);
    }
    count = count + 1;
  }
}
// this is a cpu model class which handles cpu bytes
class Cpudata {
  int c1;
  int c2;
  Cpudata(this.c1, this.c2);
}
// this is a stack model calss which handles stack bytes
class Stackdata{
  int s1;
  int s2;
  Stackdata(this.s1,this.s2);
}