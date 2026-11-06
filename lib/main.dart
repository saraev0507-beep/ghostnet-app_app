import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GhostNetApp());
}

class GhostNetApp extends StatefulWidget {
  const GhostNetApp({super.key});

  @override
  State<GhostNetApp> createState() => _GhostNetAppState();
}

class _GhostNetAppState extends State<GhostNetApp> {
  bool isDarkTheme = true;
  String currentLang = 'ru';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkTheme = prefs.getBool('dark_theme') ?? true;
    });
  }

  void toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_theme', value);
    setState(() => isDarkTheme = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POLAR HUB',
      debugShowCheckedModeBanner: false,
      theme: isDarkTheme ? _darkTheme : _lightTheme,
      home: MainScreen(
        isDark: isDarkTheme,
        onThemeChanged: toggleTheme,
      ),
    );
  }

  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B0620),
    primaryColor: const Color(0xFFFF2BD6),
    cardColor: const Color(0xFF1B0B3F),
  );

  final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey[100],
    primaryColor: const Color(0xFFFF2BD6),
    cardColor: Colors.white,
  );
}

class MainScreen extends StatefulWidget {
  final bool isDark;
  final Function(bool) onThemeChanged;

  const MainScreen({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool isConnected = false;
  String ipAddress = "0.0.0.0";
  String vpnKey = "";
  final TextEditingController _keyController = TextEditingController();
  List<String> savedKeys = [];
  bool autoSelect = true;

  @override
  void initState() {
    super.initState();
    _loadVpnState();
  }

  Future<void> _loadVpnState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedKeys = prefs.getStringList('keys') ?? [];
      vpnKey = prefs.getString('active_key') ?? "";
      isConnected = prefs.getBool('vpn_status') ?? false;
      autoSelect = prefs.getBool('auto_select') ?? true;
      if (isConnected) ipAddress = "179.254.115.99";
      _keyController.text = vpnKey;
    });
  }

  void toggleVPN() async {
    if (!isConnected && vpnKey.isEmpty) {
      _showSnackbar('Сначала добавь ключ!');
      setState(() => _currentIndex = 1);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isConnected = !isConnected;
      if (isConnected) {
        ipAddress = "179.254.115.99";
        _showSnackbar('VPN Подключен');
      } else {
        ipAddress = "0.0.0.0";
        _showSnackbar('VPN Отключен');
      }
    });
    await prefs.setBool('vpn_status', isConnected);
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF2BD6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveKey() async {
    if (_keyController.text.trim().isEmpty) {
      _showSnackbar('Введи ключ!');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final text = _keyController.text.trim();
    if (!savedKeys.contains(text)) {
      savedKeys.add(text);
      await prefs.setStringList('keys', savedKeys);
    }
    await prefs.setString('active_key', text);
    setState(() => vpnKey = text);
    _showSnackbar('Ключ сохранен!');
  }

  void _pasteFromClipboard() async {
    // Просто заглушка, чтобы не было ошибки
    _showSnackbar('Вставка из буфера...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildMainTab(),
          _buildKeysTab(),
          _buildShopTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: widget.isDark ? const Color(0xFF120829) : Colors.white,
        selectedItemColor: const Color(0xFFFF2BD6),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.vpn_key), label: 'Ключи'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Магазин'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }

  // --- 1. ГЛАВНАЯ ---
  Widget _buildMainTab() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('POLAR HUB 👻', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF2BD6))),
                TextButton(
                  onPressed: () {},
                  child: const Text('Войти в TG', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isConnected ? 'Подключено' : 'Отключено',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isConnected ? Colors.greenAccent : Colors.redAccent),
                  ),
                  const SizedBox(height: 10),
                  Text('IP: $ipAddress\nГермания (Germany)', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: toggleVPN,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isDark ? const Color(0xFF1B0B3F) : Colors.white,
                        border: Border.all(color: isConnected ? const Color(0xFFFF2BD6) : Colors.grey, width: 4),
                        boxShadow: [if (isConnected) BoxShadow(color: const Color(0xFFFF2BD6).withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
                      ),
                      child: Icon(Icons.power_settings_new, size: 60, color: isConnected ? const Color(0xFFFF2BD6) : Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. КЛЮЧИ ---
  Widget _buildKeysTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Мои ключи 🔑', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 20),
            TextField(
              controller: _keyController,
              maxLines: 4,
              style: TextStyle(color: widget.isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'POLAR::...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: widget.isDark ? const Color(0xFF1B0B3F) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2BD6),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Сохранить ключ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. МАГАЗИН ---
  Widget _buildShopTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Магазин 🛒', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 20),
            _buildShopCard('🎁 Пробный доступ', 'Бесплатно на 1 день', 'Бесплатно', () => _showSnackbar('Переход в бота...')),
            const SizedBox(height: 15),
            _buildShopCard('👻 GhostNet VPN', 'Наш быстрый VPN (1 месяц)', '150 ₽ / 100 ⭐', () => _showSnackbar('Переход в бота...')),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(String title, String desc, String price, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1B0B3F) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFFF2BD6).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFFFF2BD6), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 10),
            Text(price, style: TextStyle(color: widget.isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  // --- 4. НАСТРОЙКИ ---
  Widget _buildSettingsTab() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Text('Настройки ⚙️', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 20),
          _buildToggleItem('Темная тема', widget.isDark, widget.onThemeChanged),
          _buildToggleItem('Автовыбор', autoSelect, (val) => setState(() => autoSelect = val)),
          _buildToggleItem('Kill Switch', true, (val) {}),
          _buildToggleItem('Макс. конфиденциальность', true, (val) {}),
          _buildToggleItem('Разрешить чужие VPN', true, (val) {}),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(color: widget.isDark ? const Color(0xFF1B0B3F) : Colors.white, borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(title, style: TextStyle(color: widget.isDark ? Colors.white : Colors.black)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFFF2BD6),
      ),
    );
  }
}
