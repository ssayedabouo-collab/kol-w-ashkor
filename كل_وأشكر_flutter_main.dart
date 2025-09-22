// كل وأشكر - Demo Flutter app (single-file)
// ملفات إضافية: في pubspec.yaml تحتاج هذه الحزم:
//   cupertino_icons: ^1.0.2
//   csv: ^5.0.0
//   path_provider: ^2.0.0
//   share_plus: ^6.0.0
// ثم شغل: flutter pub get
// لتشغيل: flutter run

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(KolWShokrApp());
}

class KolWShokrApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كل وأشكر',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

// Simple in-memory models
class MenuItemModel {
  final String id;
  final String name;
  final double price;
  MenuItemModel({required this.id, required this.name, this.price = 0});
}

class OrderItem {
  final String userName;
  final String itemId;
  final String itemName;
  final int quantity;
  OrderItem({required this.userName, required this.itemId, required this.itemName, required this.quantity});
}

// Global app state (for demo)
class AppState {
  // sample menu
  List<MenuItemModel> menu = [
    MenuItemModel(id: 'm1', name: 'سندويتش فول'),
    MenuItemModel(id: 'm2', name: 'سندويتش فلافل'),
    MenuItemModel(id: 'm3', name: 'جيبنة مع زعتر'),
    MenuItemModel(id: 'm4', name: 'بيض مسلوق'),
    MenuItemModel(id: 'm5', name: 'عصير برتقال'),
  ];

  // all orders collected (admin will see)
  List<OrderItem> orders = [];

  // add order(s)
  void addOrder(List<OrderItem> newItems) {
    orders.addAll(newItems);
  }
}

final AppState appState = AppState();

// -------------------- Login Page --------------------
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameCtrl = TextEditingController();
  String _role = 'user'; // user or admin

  void _goNext(){
    final name = _nameCtrl.text.trim();
    if(name.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('اكتب اسمك علشان نقدر نسجل الطلب')));
      return;
    }
    if(_role=='admin'){
      // simple admin password check for demo
      showDialog(context: context, builder: (ctx){
        final pwCtrl = TextEditingController();
        return AlertDialog(
          title: Text('كلمة سر الأدمن'),
          content: TextField(controller: pwCtrl, obscureText: true, decoration: InputDecoration(hintText: 'ادخل كلمة السر')),
          actions: [
            TextButton(onPressed: (){ Navigator.of(ctx).pop(); }, child: Text('إلغاء')),
            ElevatedButton(onPressed: (){
              if(pwCtrl.text=='admin123'){
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_)=>AdminHomePage(adminName: name)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('كلمة السر غلط')));
              }
            }, child: Text('دخول')),
          ],
        );
      });
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_)=>UserHomePage(userName: name)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('كل وأشكر - تسجيل')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: 'الاسم')),
            SizedBox(height: 12),
            Row(children: [
              Expanded(child: ListTile(title: Text('مستخدم'), leading: Radio(value: 'user', groupValue: _role, onChanged: (v){ setState(()=> _role = v.toString()); }))),
              Expanded(child: ListTile(title: Text('أدمن'), leading: Radio(value: 'admin', groupValue: _role, onChanged: (v){ setState(()=> _role = v.toString()); }))),
            ]),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _goNext, child: Text('دخول'))
          ],
        ),
      ),
    );
  }
}

// -------------------- User Home --------------------
class UserHomePage extends StatefulWidget {
  final String userName;
  UserHomePage({required this.userName});
  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  // local cart: map itemId -> qty
  Map<String,int> cart = {};

  void _changeQty(String id, int delta){
    setState((){
      final q = (cart[id] ?? 0) + delta;
      if(q<=0) cart.remove(id); else cart[id]=q;
    });
  }

  void _submitOrder(){
    if(cart.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('السلة فاضية')));
      return;
    }
    final items = cart.entries.map((e){
      final menuItem = appState.menu.firstWhere((m)=>m.id==e.key);
      return OrderItem(userName: widget.userName, itemId: e.key, itemName: menuItem.name, quantity: e.value);
    }).toList();
    appState.addOrder(items);
    setState(()=> cart.clear());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تسجيل طلبك')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('قائمة الإفطار - ${widget.userName}'), actions: [IconButton(icon: Icon(Icons.list_alt), onPressed: ()=> Navigator.of(context).push(MaterialPageRoute(builder: (_)=>MyOrdersPage(userName: widget.userName))))]),
      body: ListView.builder(
        itemCount: appState.menu.length,
        itemBuilder: (ctx, idx){
          final item = appState.menu[idx];
          final qty = cart[item.id] ?? 0;
          return ListTile(
            title: Text(item.name),
            subtitle: Text('الكمية: $qty'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: Icon(Icons.remove), onPressed: ()=> _changeQty(item.id, -1)),
              IconButton(icon: Icon(Icons.add), onPressed: ()=> _changeQty(item.id, 1)),
            ]),
          );
        },
      ),
      bottomNavigationBar: SafeArea(child: Padding(padding: EdgeInsets.all(8), child: Row(children: [Expanded(child: ElevatedButton(onPressed: _submitOrder, child: Text('أرسل طلبي')))]))),
    );
  }
}

class MyOrdersPage extends StatelessWidget {
  final String userName;
  MyOrdersPage({required this.userName});
  @override
  Widget build(BuildContext context) {
    final myOrders = appState.orders.where((o)=> o.userName==userName).toList();
    return Scaffold(
      appBar: AppBar(title: Text('طلباتي')),
      body: myOrders.isEmpty ? Center(child: Text('لسه مفيش طلبات ليك')) : ListView.builder(
        itemCount: myOrders.length,
        itemBuilder: (ctx, i){
          final o = myOrders[i];
          return ListTile(title: Text(o.itemName), subtitle: Text('العدد: ${o.quantity}'));
        },
      ),
    );
  }
}

// -------------------- Admin Home --------------------
class AdminHomePage extends StatefulWidget {
  final String adminName;
  AdminHomePage({required this.adminName});
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  bool ordersOpen = true;

  Map<String,int> aggregate(){
    final Map<String,int> map = {};
    for(var o in appState.orders){
      map[o.itemName] = (map[o.itemName] ?? 0) + o.quantity;
    }
    return map;
  }

  Future<String> _exportCsv() async {
    final rows = <List<dynamic>>[];
    rows.add(['اسم الموظف','الصنف','الكمية']);
    for(var o in appState.orders){
      rows.add([o.userName, o.itemName, o.quantity]);
    }
    String csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/kol_w_shokr_orders.csv');
    await file.writeAsString(csv, encoding: utf8);
    return file.path;
  }

  void _shareCsv() async {
    final path = await _exportCsv();
    await Share.shareXFiles([XFile(path)], text: 'ملف طلبات كل وأشكر');
  }

  void _clearOrders(){
    setState(()=> appState.orders.clear());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم مسح الطلبات')));
  }

  @override
  Widget build(BuildContext context) {
    final agg = aggregate();
    return Scaffold(
      appBar: AppBar(title: Text('لوحة الأدمن - ${widget.adminName}')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [Expanded(child: Text('حالة استقبال الطلبات: ${ordersOpen?"مفتوح":"مغلق"}')), SizedBox(width:8), ElevatedButton(onPressed: (){ setState(()=> ordersOpen = !ordersOpen); }, child: Text(ordersOpen? 'اقفل الطلبات':'افتح الطلبات'))]),
            SizedBox(height:12),
            Text('الطلبات المجمعة:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height:8),
            Expanded(child: appState.orders.isEmpty ? Center(child: Text('لا يوجد طلبات بعد')) : ListView.builder(
              itemCount: agg.keys.length,
              itemBuilder: (ctx, i){
                final key = agg.keys.elementAt(i);
                return ListTile(title: Text(key), trailing: Text('${agg[key]}'));
              },
            )),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: appState.orders.isEmpty ? null : _shareCsv, child: Text('استخراج CSV ومشاركته'))),
              SizedBox(width: 8),
              ElevatedButton(onPressed: appState.orders.isEmpty ? null : _clearOrders, child: Text('مسح الطلبات')),
            ])
          ],
        ),
      ),
    );
  }
}

// End of file
