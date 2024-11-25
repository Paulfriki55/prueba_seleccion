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
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
          ),
        ),
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
        elevation: 0,
        actions: [
          Tooltip(
            message: 'Ver lista de empleados',
            child: IconButton(
              icon: Icon(Icons.list),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EmployeeListScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Add the company logo here
                Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: Image.asset(
                    'assets/logo.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField('Nombre', (value) => _name = value!),
                        SizedBox(height: 16),
                        _buildTextField('Apellido', (value) => _lastName = value!),
                        SizedBox(height: 16),
                        _buildTextField('Cédula', (value) => _cedula = value!),
                        SizedBox(height: 16),
                        _buildDropdownField('Cargo', _position, ['Supervisor', 'Líder', 'Operario'],
                                (value) => setState(() => _position = value!)),
                        SizedBox(height: 16),
                        _buildDropdownField('Área', _area, ['Financiera', 'Talento Humano', 'Operaciones'],
                                (value) => setState(() => _area = value!)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text('Firma:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
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
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Guardar', style: TextStyle(fontSize: 18)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _submitForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String?) onSaved) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese $label';
        }
        return null;
      },
      onSaved: onSaved,
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
      ),
      items: items
          .map((label) => DropdownMenuItem(
        child: Text(label),
        value: label,
      ))
          .toList(),
      onChanged: onChanged,
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

class EmployeeListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Empleados'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.instance.queryAllRows(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No hay empleados registrados.'));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var employee = Employee.fromMap(snapshot.data![index]);
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: CircleAvatar(
                        child: Text(employee.name[0] + employee.lastName[0]),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      title: Text(
                        '${employee.name} ${employee.lastName}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text('Cédula: ${employee.cedula}'),
                          Text('Cargo: ${employee.position}'),
                          Text('Área: ${employee.area}'),
                        ],
                      ),
                      trailing: employee.signature != null
                          ? Image.memory(
                        base64Decode(employee.signature),
                        width: 50,
                        height: 50,
                      )
                          : Icon(Icons.no_photography),
                      onTap: () {
                        // TODO: Implement employee details view
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Detalles del empleado (por implementar)')),
                        );
                      },
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}