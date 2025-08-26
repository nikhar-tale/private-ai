# Private AI 🤖🔒

Private AI is a Flutter application that showcases **on-device, offline, multimodal AI**.  
The app can process both **images and text** locally without needing an internet connection, ensuring **privacy-first AI interactions**.

---

## ✨ Features
- **Offline First** – All AI interactions happen on-device.  
- **Multimodal Input** – Understands both images and text prompts.  
- **Powered by Gemma 3N** – Uses Google’s lightweight and efficient Gemma 3 Nano model.  
- **Minimal UI** – Clean, simple, and user-friendly interface.  

---

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/private-ai.git
cd private-ai
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Add Hugging Face Token
Edit `lib/data/gemma_downloader_datasource.dart` and replace the placeholder with your Hugging Face access token:
```dart
const String accessToken = 'YOUR_HUGGING_FACE_TOKEN_HERE';
```

### 4. Run the App
```bash
flutter run
```

---

## 🛠️ Tech Stack
- **Flutter** – UI toolkit  
- **flutter_gemma** – Run Gemma models on-device  
- **image_picker** – Capture/select images  

---

## 🤝 Contributing
Contributions are welcome!  
Feel free to fork the repo, open issues, or submit pull requests.  

---


