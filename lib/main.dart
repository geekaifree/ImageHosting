import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const ImageHostingApp());
class ImageHostingApp extends StatelessWidget {
  const ImageHostingApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: '图床上传工具', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.pink, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.pink, useMaterial3: true, brightness: Brightness.dark),
    home: const ImageHostingHomePage());
}

class UploadRecord {
  String id, url, name, format, size;
  DateTime time;
  UploadRecord({required this.id, required this.url, required this.name, required this.format, required this.size, required this.time});
  Map<String, dynamic> toJson() => {'id': id, 'url': url, 'name': name, 'format': format, 'size': size, 'time': time.toIso8601String()};
  factory UploadRecord.fromJson(Map<String, dynamic> j) => UploadRecord(id: j['id'], url: j['url'], name: j['name'], format: j['format'], size: j['size'], time: DateTime.parse(j['time']));
}

class ImageHostingHomePage extends StatefulWidget {
  const ImageHostingHomePage({super.key});
  @override
  State<ImageHostingHomePage> setState() => _ImageHostingHomePageState();
}

class _ImageHostingHomePageState extends State<ImageHostingHomePage> {
  List<UploadRecord> _records = [];
  String _hosting = 'SM.MS';
  final _hostings = ['SM.MS', 'GitHub', 'Imgur', '七牛云', '阿里云OSS'];
  String _format = 'Markdown';
  final _formats = ['Markdown', 'HTML', 'URL', 'BBCode'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString('upload_records');
    if (d != null) setState(() => _records = (json.decode(d) as List).map((e) => UploadRecord.fromJson(e)).toList());
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('upload_records', json.encode(_records.map((e) => e.toJson()).toList()));
  }

  void _simulateUpload() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final record = UploadRecord(id: id, url: 'https://i.imgur.com/${id.substring(0, 8)}.png', name: 'image_${_records.length + 1}.png', format: 'PNG', size: '${100 + DateTime.now().millisecond % 500}KB', time: DateTime.now());
    setState(() => _records.insert(0, record));
    _save();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('上传成功: ${record.name}'), behavior: SnackBarBehavior.floating));
  }

  String _getLink(UploadRecord r) {
    switch (_format) {
      case 'Markdown': return '![${r.name}](${r.url})';
      case 'HTML': return '<img src="${r.url}" alt="${r.name}" />';
      case 'URL': return r.url;
      case 'BBCode': return '[img]${r.url}[/img]';
      default: return r.url;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🖼️ 图床上传'), centerTitle: true, actions: [
        PopupMenuButton<String>(icon: const Icon(Icons.more_vert), itemBuilder: (ctx) => _formats.map((f) => PopupMenuItem(value: f, child: Text(f))).toList(), onSelected: (v) => setState(() => _format = v)),
      ]),
      body: Column(children: [
        // 图床选择
        Card(margin: const EdgeInsets.all(12), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('图床服务', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _hostings.map((h) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(h), selected: _hosting == h, onSelected: (_) => setState(() => _hosting = h)))).toList())),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _simulateUpload, icon: const Icon(Icons.cloud_upload), label: const Text('上传图片'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)))),
        ]))),
        // 上传记录
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [Text('上传记录 (${_records.length})', style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), Text('格式: $_format', style: const TextStyle(color: Colors.grey, fontSize: 12))])),
        const SizedBox(height: 8),
        Expanded(child: _records.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.cloud_upload, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('点击上传图片', style: TextStyle(color: Colors.grey.shade500))])) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: _records.length, itemBuilder: (ctx, i) {
          final r = _records[i];
          return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(8)), child: const Center(child: Icon(Icons.image, color: Colors.pink))),
            title: Text(r.name),
            subtitle: Text('${r.format} • ${r.size} • ${_formatTime(r.time)}', style: const TextStyle(fontSize: 12)),
            trailing: IconButton(icon: const Icon(Icons.copy, size: 20), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已复制: $_format链接'), behavior: SnackBarBehavior.floating))),
          ));
        })),
      ]),
    );
  }

  String _formatTime(DateTime t) => '${t.month}/${t.day} ${t.hour}:${t.minute.toString().padLeft(2, '0')}';
}
