import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'models/employee.dart';
import 'database/database_helper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EmployeeForm(),
    );
  }
}

class EmployeeForm extends StatefulWidget {
  @override
  _EmployeeFormState createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _sign = GlobalKey<SignatureState>();

  String _name = '';
  String _lastName = '';
  String _cedula = '';
  String _position = 'Supervisor';
  String _area = 'Financiera';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Empleado'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Apellido'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el apellido';
                  }
                  return null;
                },
                onSaved: (value) => _lastName = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Cédula'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la cédula';
                  }
                  return null;
                },
                onSaved: (value) => _cedula = value!,
              ),
              DropdownButtonFormField<String>(
                value: _position,
                decoration: InputDecoration(labelText: 'Cargo'),
                items: ['Supervisor', 'Líder', 'Operario']
                    .map((label) => DropdownMenuItem(
                  child: Text(label),
                  value: label,
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _position = value!;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                value: _area,
                decoration: InputDecoration(labelText: 'Área'),
                items: ['Financiera', 'Talento Humano', 'Operaciones']
                    .map((label) => DropdownMenuItem(
                  child: Text(label),
                  value: label,
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _area = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              Text('Firma:'),
              Container(
                height: 200,
                child: Signature(
                  color: Colors.black,
                  key: _sign,
                  onSign: () {
                    final sign = _sign.currentState;
                    debugPrint('${sign?.points.length} points in signature');
                  },
                  backgroundPainter: _WatermarkPaint("2.0", "2.0"),
                  strokeWidth: 5.0,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Guardar'),
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final sign = _sign.currentState;
      final image = await sign!.getData();
      final pngBytes = await _convertImageToBytes(image);
      final encoded = base64.encode(pngBytes);

      final employee = Employee(
        name: _name,
        lastName: _lastName,
        cedula: _cedula,
        position: _position,
        area: _area,
        signature: encoded,
      );

      try {
        int id = await DatabaseHelper.instance.insert(employee.toMap());
        Fluttertoast.showToast(
            msg: "Empleado registrado con éxito",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0
        );
        _formKey.currentState!.reset();
        _sign.currentState!.clear();
      } catch (e) {
        print(e);
        Fluttertoast.showToast(
          msg: "Error al registrar empleado",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  Future<Uint8List> _convertImageToBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}

class _WatermarkPaint extends CustomPainter {
  final String price;
  final String watermark;

  _WatermarkPaint(this.price, this.watermark);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 10.0, Paint()..color = Colors.blue.withOpacity(0.2));
  }

  @override
  bool shouldRepaint(_WatermarkPaint oldDelegate) {
    return oldDelegate != this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _WatermarkPaint && runtimeType == other.runtimeType && price == other.price && watermark == other.watermark;

  @override
  int get hashCode => price.hashCode ^ watermark.hashCode;
}

