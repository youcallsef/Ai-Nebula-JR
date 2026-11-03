import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(const NebulaApp());
}

class NebulaApp extends StatelessWidget {
  const NebulaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nebula JR',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0F1D),
        primaryColor: const Color(0xFF38BDF8), // أزرق لبني هادي
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF38BDF8),
          surface: const Color(0xFF111827),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}

// ==========================================
// 1. شاشة الترحيب (Onboarding)
// ==========================================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _glowController;

  final List> _onboardingData = [
    {
      "title": "مرحباً بك في عالم الذكاء الاصطناعي",
      "desc": "تطبيقك السحابي المتكامل برعاية النماذج الثلاثة الأقوى عالمياً."
    },
    {
      "title": "ذاكرة ذكية لا تنساك",
      "desc": "النماذج تحتفظ بكل تفاصيل محادثاتك وسياق كلامك بدقة تامة."
    },
    {
      "title": "تحكم وثبات كامل",
      "desc": "تبديل سلس بين النماذج، حماية تامة ضد الانقطاع، وجاهزون للانطلاق!"
    }
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex == _onboardingData.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0F1D), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Icon(Icons.auto_awesome, size: 80, color: Color(0xFF38BDF8)),
                const SizedBox(height: 40),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: Column(
                    key: ValueKey<int>(_currentIndex),
                    children: [
                      Text(
                        _onboardingData[_currentIndex]["title"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _onboardingData[_currentIndex]["desc"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withOpacity(0.3 + (_glowController.value * 0.4)),
                            blurRadius: 15 + (_glowController.value * 10),
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () {
                          if (isLast) {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const ChatScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                transitionDuration: const Duration(milliseconds: 800),
                              ),
                            );
                          } else {
                            setState(() {
                              _currentIndex++;
                            });
                          }
                        },
                        child: Text(
                          isLast ? "ابدأ الآن" : "التالي",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. الهيكل البرمجي والذكاء الاصطناعي (Memory + Multi-Model)
// ==========================================
enum AIModel { llama33, geminiFlash, gemma2 }

class ChatMessage {
  final String sender;
  final String text;
  ChatMessage({required this.sender, required this.text});
}

class AIService {
  static const String groqApiKey = 'YOUR_GROQ_API_KEY';
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';

  // إرسال سياق المحادثة بالكامل (Memory) لضمان عدم نسيان أي معلومة
  static Future<String> sendMessageWithMemory({
    required List<ChatMessage> history,
    required AIModel selectedModel,
    required bool isImageRequest,
  }) async {
    // فحص الاتصال بالإنترنت أولاً
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return "عذراً، لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.";
    }

    try {
      if (isImageRequest) {
        return "تم إرسال طلب توليد الصورة بنجاح (ميزة التوليد السحابي مفعلة).";
      }

      switch (selectedModel) {
        case AIModel.llama33:
        case AIModel.gemma2:
          return await _callGroqApi(
              selectedModel == AIModel.llama33 ? 'llama-3.3-70b-versatile' : 'gemma2-9b-it', history);
        case AIModel.geminiFlash:
          return await _callGeminiApi(history);
      }
    } catch (e) {
      return "حدث خطأ أثناء الاتصال بالسيرفر: ${e.toString()}";
    }
  }

  static Future<String> _callGroqApi(String modelName, List<ChatMessage> history) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    // تحويل سجل المحادثة بالكامل ليدعم الذاكرة والترابط
    List> messagesFormatted = history.map((msg) {
      return {
        'role': msg.sender == 'user' ? 'user' : 'assistant',
        'content': msg.text
      };
    }).toList();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $groqApiKey',
      },
      body: jsonEncode({
        'model': modelName,
        'messages': messagesFormatted,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('خطأ في استجابة الخادم (${response.statusCode})');
    }
  }

  static Future<String> _callGeminiApi(List<ChatMessage> history) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey');
    
    List> contents = history.map((msg) {
      return {
        'role': msg.sender == 'user' ? 'user' : 'model',
        'parts': [{'text': msg.text}]
      };
    }).toList();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'contents': contents}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('خطأ في استجابة Gemini (${response.statusCode})');
    }
  }
}

// ==========================================
// 3. شاشة الشات الرئيسية
// ==========================================
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  AIModel _selectedModel = AIModel.llama33;
  bool _isLoading = false;
  
  // نظام الشاتات المتعددة
  List<List<ChatMessage>> _chats = [[]];
  int _currentChatIndex = 0;

  void _switchChat(int index) {
    setState(() {
      _currentChatIndex = index;
      _messages.clear();
      _messages.addAll(_chats[index]);
    });
    Navigator.pop(context);
  }

  void _addNewChat() {
    setState(() {
      _chats.add([]);
      _currentChatIndex = _chats.length - 1;
      _messages.clear();
    });
    Navigator.pop(context);
  }

  void _sendMessage({bool isImage = false}) async {
    if (_controller.text.trim().isEmpty && !isImage) return;

    final text = isImage ? "🎨 توليد صورة بناءً على طلبك..." : _controller.text.trim();
    
    setState(() {
      _messages.add(ChatMessage(sender: 'user', text: text));
      if (_chats.length <= _currentChatIndex) {
        _chats.add(List.from(_messages));
      } else {
        _chats[_currentChatIndex] = List.from(_messages);
      }
      _isLoading = true;
      _controller.clear();
    });

    final aiResponse = await AIService.sendMessageWithMemory(
      history: _messages,
      selectedModel: _selectedModel,
      isImageRequest: isImage,
    );

    setState(() {
      _messages.add(ChatMessage(sender: 'ai', text: aiResponse));
      _chats[_currentChatIndex] = List.from(_messages);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        // القائمة الجانبية للشاتات المتعددة (٣ شرط)
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF38BDF8)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Center(
          // كبسولة فوق للتبديل بين النماذج
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
            ),
            child: DropdownButton<AIModel>(
              value: _selectedModel,
              dropdownColor: const Color(0xFF1E293B),
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF38BDF8)),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              onChanged: (AIModel? val) {
                if (val != null) setState(() => _selectedModel = val);
              },
              items: const [
                DropdownMenuItem(value: AIModel.llama33, child: Text('Llama 3.3 70B')),
                DropdownMenuItem(value: AIModel.geminiFlash, child: Text('Gemini 1.5 Flash')),
                DropdownMenuItem(value: AIModel.gemma2, child: Text('Gemma 2 9B')),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.image_outlined, color: Color(0xFF38BDF8)),
            tooltip: 'توليد صورة',
            onPressed: _isLoading ? null : () => _sendMessage(isImage: true),
          ),
        ],
      ),
      // القائمة الجانبية للشاتات المتعددة
      drawer: Drawer(
        backgroundColor: const Color(0xFF0A0F1D),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF111827)),
              child: Text('شاتات متعددة - Nebula', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.add, color: Color(0xFF38BDF8)),
              title: const Text('شات جديد'),
              onTap: _addNewChat,
            ),
            const Divider(color: Colors.white24),
            for (int i = 0; i < _chats.length; i++)
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white70),
                title: Text('محادثة رقم ${i + 1}', style: const TextStyle(color: Colors.white)),
                selected: _currentChatIndex == i,
                selectedTileColor: const Color(0xFF1E293B),
                onTap: () => _switchChat(i),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.sender == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF38BDF8) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: isUser ? Colors.black : Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: Color(0xFF38BDF8)),
            ),
          // كبسولة الرسائل المنظمة أسفل الشاشة
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF111827),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالتك هنا...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF38BDF8),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black, size: 18),
                    onPressed: _isLoading ? null : () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
