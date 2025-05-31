# 🏝️ Dynamic Toolbox

A beautiful and powerful Dynamic Island-inspired productivity hub for macOS, bringing iPhone's Dynamic Island experience to your Mac desktop.

![Dynamic Island Demo](https://img.shields.io/badge/Platform-macOS%2015.1+-blue?style=flat-square)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Framework-green?style=flat-square)

## ✨ Features

### 🤖 **AI Assistant**
- **Local AI Integration** powered by Ollama (completely private)
- **Multiple AI Tools**: Chat, Code Assistant, Text Processor, Error Explainer, and Quick Prompts
- **Code Analysis**: Explain, review, optimize, debug, document, and refactor code
- **Text Processing**: Summarize, translate, rewrite, expand, and simplify text
- **Debug Helper**: Analyze error messages and stack traces for solutions
- **Smart Setup**: One-click Ollama installation and model management
- **Live Streaming**: Real-time AI responses with typing indicators
- **Context Aware**: Maintains conversation history for better assistance

### 📋 **Clipboard Manager**
- Smart history tracking for text, images, and files
- Pin important items for quick access
- Visual previews with thumbnails and icons

### 🚀 **Quick Apps Launcher**
- Drag & drop apps for instant setup
- One-click access to your favorite applications
- Beautiful app icon display

### 📊 **System Monitor**
- Real-time CPU, memory, and disk usage
- Animated charts and visualizations
- Color-coded system health indicators

### 🌤️ **Weather Display**
- Current temperature and conditions
- Location-based weather information
- Clean, minimalist interface

### ⏱️ **Pomodoro Timer**
- Customizable focus and break sessions
- Continues running when app is closed
- Session statistics and progress tracking
- Beautiful circular progress indicator

### 📐 **Unit Converter**
- Length, weight, temperature, and currency conversions
- **Live Exchange Rates** for accurate currency conversion
- Quick value buttons and popular conversion pairs
- Comprehensive unit support with swap functionality

### ⚙️ **Developer Tools**
- JSON formatter, minifier, and validator
- Base64 encoder and decoder
- Hash generator (MD5, SHA1, SHA256, SHA512)
- Drag & drop file hashing support

## 🎨 **Design Features**

- **Glassmorphism UI** with translucent materials and dynamic shadows
- **Responsive Interface** with scrollable tabs and adaptive layouts
- **Smooth Animations** and micro-interactions throughout
- **Customizable Tabs** - enable only the features you need

## 🔧 **Technical Highlights**

- **Persistent State** - your settings and data are preserved
- **Background Processing** - timers and monitoring continue when minimized
- **System Integration** - native clipboard monitoring and notifications
- **Performance Optimized** - efficient updates and memory management
- **Local AI Processing** - all AI computations run locally for privacy
- **Live Data Feeds** - real-time weather and currency exchange rates

## 📋 **Requirements**

- **macOS**: 15.1 or later
- **Xcode**: 16.0 or later
- **Swift**: 5.9 or later
- **Architecture**: Intel or Apple Silicon
- **For AI Features**: [Ollama](https://ollama.ai) (optional, for AI Assistant functionality)

## 🤖 **AI Assistant Setup**

To use the AI Assistant feature:

1. **Install Ollama**: Visit [ollama.ai](https://ollama.ai) and download for macOS
2. **Start Ollama**: Use the "Start Ollama" button in the app or run `ollama serve` in Terminal
3. **Download Models**: Recommended models include:
   - `ollama pull llama3.2:3b` (fast, 2GB)
   - `ollama pull codellama:7b` (code-focused, 3.8GB)
   - `ollama pull deepseek-llm:67b` (advanced, 38GB)
4. **Connect**: The app will automatically detect and connect to Ollama

## 🎯 **Usage**

1. **Launch the App**: Click on the notch area or use the menu bar
2. **Configure Tabs**: Use the tab selector to enable your preferred features
3. **Customize Settings**: Drag apps, set timer durations, configure units
4. **AI Assistance**: Enable AI Assistant tab and follow setup instructions for local AI
5. **Enjoy Productivity**: Access all tools from one beautiful interface

## 🚀 **Roadmap**

- [x] AI Assistant with local Ollama integration
- [x] Live currency exchange rates
- [ ] Calendar integration
- [ ] Notes and quick capture
- [ ] Network monitoring
- [ ] Custom themes
- [ ] Plugin system
- [ ] Shortcuts integration
- [ ] Menu bar mode
- [ ] More AI models and providers

## 📄 **License**

This project is open source and available under the [MIT License](LICENSE).

## 🙏 **Acknowledgments**

- Inspired by Apple's Dynamic Island design
- Built with SwiftUI and modern macOS frameworks
- AI features powered by [Ollama](https://ollama.ai)
- Exchange rates provided by [ExchangeRate-API](https://exchangerate-api.com)
- Thanks to the macOS development community

---

**Made with ❤️ for macOS productivity enthusiasts**
