# Dynamic Toolbox
Made for Macbooks that have a notch, other Macbook should be able to use it too.
Few tools in there, depending on your habits, those tools can be helpful at times.  
The search function in AI chat is not very complete yet. 

## Disclaimer:
This app allows users to chat with Large Langauge Models that are running in Ollama. AI-generated content may be inaccurate or incomplete. Please verify information independently before relying on it.

![Dynamic Toolbox](https://img.shields.io/badge/Platform-macOS%2015.1+-blue?style=flat-square)
![Swift](https://img.shields.io/badge/Built%20with-SwiftUI-orange?style=flat-square)

Page and Download - https://stevelisz.github.io/macOS-DynamicToolbox/

Or you can build this app yourself. Just run `./build-release.sh` under root directory.
## Features

### AI Assistant
Chat with AI models locally on your Mac. Supports code review, writing assistance, file analysis, and web search.

**Capabilities:**
- Code explanation and debugging help
- Text summarization and rewriting
- File drop analysis for text and images
- Web search integration for current information
- Conversation history with context awareness

**Setup:** Install [Ollama](https://ollama.ai) and download a model like `llama3.2:3b`

### Clipboard Manager
Automatically saves your copy history with search and pin functionality.

**Features:**
- History of copied text, images, and files
- Pin important items
- Search through clipboard history
- One-click re-copying

### Quick App Launcher
Drag and drop apps from Finder to create a personal launcher.

**Features:**
- Add apps by dragging from Finder
- One-click app launching
- Clean grid layout with app icons

### System Monitor
Real-time system performance monitoring.

**Displays:**
- CPU usage per core (Performance/Efficiency cores on Apple Silicon)
- GPU usage with historical graph
- RAM usage with memory pressure indication
- SSD usage and available space

### Weather
Location-based current weather display.

**Features:**
- Current temperature and conditions
- Automatic location detection
- Minimal weather interface

### Pomodoro Timer
Focus timer using the Pomodoro Technique.

**Features:**
- Customizable work and break durations
- Visual progress indicator
- Background operation when app is hidden
- Session tracking

### Unit Converter
Convert between various units with live data.

**Supported:**
- Length, weight, temperature conversions
- Live currency exchange rates
- Quick preset buttons
- Unit swapping

### Developer Tools
Common development utilities.

**Tools:**
- JSON formatter and validator
- Base64 encoding/decoding
- Hash generation (MD5, SHA1, SHA256, SHA512)
- File hash calculation via drag and drop

## Installation

1. Download from the releases page
2. Open the app
3. Click on your Mac's notch area to access tools
4. Optional: Install Ollama for AI features

## System Requirements

- macOS 15.1 or later
- Compatible with all Mac models
- ~50MB storage for the app
- Additional space for AI models if using AI features

## Usage

The app places an interactive area in your Mac's notch. Click to open the toolbox interface. Select the tab for the tool you want to use.

## License

MIT License - see LICENSE file for details.
