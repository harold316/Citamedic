import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplicación de servicios médicos',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: Text('Aplicación de servicios médicos')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AgendarCita()),
              );
            },
            child: Text('Agendar Cita'),
          ),
        ),
      ),
    );
  }
}

class AgendarCita extends StatelessWidget {
  const AgendarCita({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agendar Cita')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VerCitas()),
            );
          },
          child: Text('Ver Citas'),
        ),
      ),
    );
  }
}

class VerCitas extends StatelessWidget {
  const VerCitas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ver Citas')),
      body: Center(child: Text('Ver las citas...')),
    );
  }
}
