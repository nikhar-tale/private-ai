import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:private_ai/data/downloader_datasource.dart';
import 'package:private_ai/domain/download_model.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  InferenceModel? _inferenceModel;
  InferenceChat? _chat;

  final List<Message> _messages = [];

  bool _isModelLoading = true;
  String _loadingMessage = 'Initializing...';
  double? _downloadProgress;
  bool _isAwaitingResponse = false;

  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedImage;
  String? _selectedImageName;

  final _textController = TextEditingController();

  late final GemmaDownloaderDataSource _downloaderDataSource;

  @override
  void initState() {
    super.initState();
    _downloaderDataSource = GemmaDownloaderDataSource(
      model: DownloadModel(
        modelUrl:
            'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
        modelFilename: 'gemma-3n-E4B-it-int4.task',
      ),
    );
    _initializeModel();
  }

Future<void> _initializeModel() async {
  try {
    final gemma = FlutterGemmaPlugin.instance;
    final modelManager = gemma.modelManager;

    // 1) Make sure the model file exists (your downloader)
    final isModelOnDisk = await _downloaderDataSource.checkModelExistence();
    if (!isModelOnDisk) {
      setState(() {
        _loadingMessage = 'Downloading Gemma 3N...';
        _downloadProgress = 0;
      });

      await _downloaderDataSource.downloadModel(
        token: accessToken,
        onProgress: (p) => setState(() => _downloadProgress = p),
      );
    }

    // 2) Register the local file path with Gemma (this is the missing step)
    final modelPath = await _downloaderDataSource.getFilePath();
    await modelManager.setModelPath(modelPath);

    setState(() {
      _loadingMessage = 'Initializing model...';
      _downloadProgress = null;
    });

    // 3) Create the inference model + chat
    _inferenceModel = await gemma.createModel(
      modelType: ModelType.gemmaIt,
      supportImage: true,         // you’re using a Gemma 3 Nano vision model
      maxTokens: 512,            // 0.9.0 docs recommend higher for multimodal
      // preferredBackend: PreferredBackend.gpu, // optional, if you want GPU
    );

    _chat = await _inferenceModel!.createChat(supportImage: true);

    setState(() {
      _isModelLoading = false;
    });
  } catch (e) {
    debugPrint("Error initializing model: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize AI model: $e'),
                 backgroundColor: Colors.red),
      );
    }
    setState(() => _isModelLoading = false);
  }
}


  Future<void> _pickImage() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = bytes;
          _selectedImageName = pickedFile.name;
        });
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Image selection error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // UI Enhancement: Added an emoji to the title and gave the AppBar a cleaner look.
        title: const Text('Private AI ✨'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
      ),
      body: Container(
        // UI Enhancement: Added a subtle gradient background.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: _isModelLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      _loadingMessage,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (_downloadProgress != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32.0,
                          vertical: 16.0,
                        ),
                        child: LinearProgressIndicator(
                          value: _downloadProgress,
                        ),
                      ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      reverse: true, // Show latest messages at the bottom
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 16.0,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        // To show messages from bottom to top
                        final message = _messages[_messages.length - 1 - index];
                        return ChatMessageWidget(message: message);
                      },
                    ),
                  ),
                  if (_isAwaitingResponse)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Gemma is thinking...'),
                        ],
                      ),
                    ),
                  _buildChatInputArea(),
                ],
              ),
      ),
    );
  }

  Widget _buildChatInputArea() {
    return Container(
      // UI Enhancement: Styled the input area for a cleaner, modern look.
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(13, 0, 0, 0),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedImage!,
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Material(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() => _selectedImage = null);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    onPressed: _pickImage,
                    color: Colors.blue.shade700,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Translate this menu...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.send),
                    onPressed: _isAwaitingResponse ? null : _sendMessage,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

 void _sendMessage() async {
  final text = _textController.text.trim();
  final image = _selectedImage;

  if (text.isEmpty && image == null) return;
  if (_isAwaitingResponse) return;

  setState(() => _isAwaitingResponse = true);

  // 1) Build the right message kind
  final Message userMessage;
  if (image != null && text.isNotEmpty) {
    userMessage = Message.withImage(text: text, imageBytes: image, isUser: true);
  } else if (image != null && text.isEmpty) {
    userMessage = Message.withImage(
      text: "Please translate this menu into English.",
      imageBytes: image,
      isUser: true,
    );
  } else {
    userMessage = Message.text(text: text, isUser: true);
  }

  // 2) Push to UI, clear inputs
  setState(() {
    _messages.add(userMessage);
    _selectedImage = null;
    _selectedImageName = null;
  });
  _textController.clear();
  FocusScope.of(context).unfocus();

  try {
    // 3) Send to chat & stream tokens into a single placeholder
    await _chat!.addQueryChunk(userMessage);

    final responsePlaceholder = Message(text: '', isUser: false);
    setState(() => _messages.add(responsePlaceholder));

    final stream = _chat!.generateChatResponseAsync();
    await for (final token in stream) {
      if (!mounted) return;
      setState(() {
        final last = _messages.last;
        _messages[_messages.length - 1] = last.copyWith(text: last.text + token);
      });
    }
  } catch (e) {
    debugPrint("Error during chat generation: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating response: $e'),
                 backgroundColor: Colors.red),
      );
      setState(() {
        if (_messages.isNotEmpty && !_messages.last.isUser) {
          _messages.removeLast();
        }
      });
    }
  } finally {
    if (mounted) setState(() => _isAwaitingResponse = false);
  }
}

}

class ChatMessageWidget extends StatelessWidget {
  final Message message;

  const ChatMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // UI Enhancement: Styled chat bubbles for better visual distinction.
    final radius = Radius.circular(16);
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser ? Colors.blue.shade600 : Colors.white;
    final textColor = isUser ? Colors.white : Colors.black87;
    final borderRadius = BorderRadius.only(
      topLeft: radius,
      topRight: radius,
      bottomLeft: isUser ? radius : Radius.zero,
      bottomRight: isUser ? Radius.zero : radius,
    );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    message.imageBytes!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (message.text.isNotEmpty)
              MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(p: TextStyle(color: textColor, fontSize: 15)),
              ),
          ],
        ),
      ),
    );
  }
}
