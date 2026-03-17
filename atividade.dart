import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class Tarefa {
  String titulo;
  bool concluida;
  String? horario;

  Tarefa({
    required this.titulo,
    this.concluida = false,
    this.horario,
  });

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'concluida': concluida,
        'horario': horario,
      };

  static Tarefa fromJson(Map<String, dynamic> json) => Tarefa(
        titulo: json['titulo'],
        concluida: json['concluida'],
        horario: json['horario'],
      );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ListaTarefas(),
    );
  }
}

class ListaTarefas extends StatefulWidget {
  @override
  _ListaTarefasState createState() => _ListaTarefasState();
}

class _ListaTarefasState extends State<ListaTarefas> {
  List<Tarefa> tarefas = [];
  TextEditingController controller = TextEditingController();
  TimeOfDay? horarioSelecionado;

  @override
  void initState() {
    super.initState();
    carregarTarefas();
  }

  Future<void> salvarTarefas() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> lista =
        tarefas.map((t) => jsonEncode(t.toJson())).toList();
    prefs.setStringList('tarefas', lista);
  }

  Future<void> carregarTarefas() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? lista = prefs.getStringList('tarefas');

    if (lista != null) {
      setState(() {
        tarefas = lista
            .map((t) => Tarefa.fromJson(jsonDecode(t)))
            .toList();
      });
    }
  }

  void adicionarTarefa() {
    if (controller.text.isNotEmpty) {
      setState(() {
        tarefas.add(Tarefa(
          titulo: controller.text,
          horario: horarioSelecionado != null
              ? formatarHorario(horarioSelecionado!)
              : null,
        ));
        controller.clear();
        horarioSelecionado = null;
      });
      salvarTarefas();
    }
  }

  void removerTarefa(int index) {
    setState(() {
      tarefas.removeAt(index);
    });
    salvarTarefas();
  }

  void toggleConcluida(int index) {
    setState(() {
      tarefas[index].concluida = !tarefas[index].concluida;
    });
    salvarTarefas();
  }

  Future<void> selecionarHorario() async {
    TimeOfDay? escolhido = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (escolhido != null) {
      setState(() {
        horarioSelecionado = escolhido;
      });
    }
  }

  String formatarHorario(TimeOfDay horario) {
    return "${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        title: Text("Minhas Tarefas"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Nova tarefa...",
                          hintStyle: TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Color(0xFF1E1E1E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.access_time, color: Colors.white),
                      onPressed: selecionarHorario,
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.green),
                      onPressed: adicionarTarefa,
                    ),
                  ],
                ),
                if (horarioSelecionado != null)
                  Text(
                    "⏰ ${formatarHorario(horarioSelecionado!)}",
                    style: TextStyle(color: Colors.green),
                  ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: tarefas.length,
              itemBuilder: (context, index) {
                final tarefa = tarefas[index];

                return Card(
                  color: Color(0xFF1E1E1E),
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: tarefa.concluida,
                      onChanged: (_) => toggleConcluida(index),
                      activeColor: Colors.green,
                    ),
                    title: Text(
                      tarefa.titulo,
                      style: TextStyle(
                        color: Colors.white,
                        decoration: tarefa.concluida
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: tarefa.horario != null
                        ? Text(
                            "⏰ ${tarefa.horario}",
                            style: TextStyle(color: Colors.grey),
                          )
                        : null,
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => removerTarefa(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}