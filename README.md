<p align="center">
  <img src="assets/icon.png" width="120" alt="MobileOllama Icon"/>
</p>

<h1 align="center">MobileOllama</h1>

<p align="center">
  A clean mobile chat interface for the <a href="https://ollama.com">Ollama</a> API — no distractions, just chat.
</p>

---
 
## About

MobileOllama brings the Ollama experience to your phone (currently mainly for Android). Connect to the Ollama cloud API, pick a model, and start chatting all from a simple, ChatGPT-inspired interface. Your conversations are saved locally so you can pick up where you left off.

## Features

- **Chat with any Ollama model** — switch models on the fly from the top bar
- **Markdown rendering** — assistant responses render with full Markdown support (headings, bold, code blocks, tables, lists, etc.)
- **Streaming responses** — tokens appear in real-time as the model generates them
- **Chat history** — swipe from the left to browse and manage past conversations
- **System prompt** — set a custom system prompt to shape the model's behavior
- **Image attachments** — send images for multimodal models that support vision
- **Model compatibility notes** — advisory in settings about image support and model compatibility
- **Custom API endpoint** — connect to the Ollama cloud or your own local/network server
- **Dark & Light theme** — defaults to dark mode, switchable in settings
- **API key authentication** — your key is stored locally on your device

## Screenshots

<p align="center">
  <img src="assets/chat.jpg" width="280" alt="Chat Screen"/>
  &nbsp;&nbsp;&nbsp;
  <img src="assets/sidechats.jpg" width="280" alt="Chat History"/>
</p>

<p align="center">
  <img src="assets/settings1.jpg" width="280" alt="Settings"/>
  &nbsp;&nbsp;&nbsp;
  <img src="assets/settings2.jpg" width="280" alt="Settings continued"/>
</p>

## Getting Started

1. Make sure you have [Flutter](https://flutter.dev/docs/get-started/install) installed.
2. Clone the repo:
   ```bash
   git clone https://github.com/Le0nyx/MobileOllama.git
   cd MobileOllama
   ```
3. Install dependencies and run:
   ```bash
   flutter pub get
   flutter run
   ```
4. Open **Settings** in the app, paste your Ollama API key, choose your API endpoint (cloud or local), select a model, and start chatting.

## Model Compatibility

Not all models behave the same:

- **Image support** — Some models (e.g. LLaVA, Gemma 3, Moondream) can understand attached images, while most are text-only.
- **Compatibility** — Some models may not work with certain API endpoints or configurations. If a model isn't responding, try a different one.

These are also explained in the **Settings** screen under "Model Capability".

## Built With

- [Flutter](https://flutter.dev) & Dart
- [Provider](https://pub.dev/packages/provider) for state management
- [SharedPreferences](https://pub.dev/packages/shared_preferences) for local storage
- [Ollama API](https://ollama.com) for model inference
- [flutter_markdown](https://pub.dev/packages/flutter_markdown) for Markdown rendering

<br>

## License

[MIT](LICENSE)
