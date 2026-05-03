# Audio-Enhancer-Pro
音频高速批量增强工具，支持音量调节、动态平衡、多线程处理，也可以将多种格式的音频转换为mp3格式。A high-speed batch audio enhancement tool based on PowerShell and FFmpeg.
## **中文说明书：极速音频增强工具 Pro v2.1**
<img width="1099" height="1280" alt="image" src="https://github.com/user-attachments/assets/0fad258a-e9bb-4838-a46b-a7a4cde8320d" />

### **1. 软件简介**
本工具是一款基于 PowerShell 和 FFmpeg 核心开发的轻量级音频批处理脚本，转换速度非常快。它专为需要快速提升音频音量、统一音频规格的用户设计。也可以将多种格式的音频转换为mp3格式。通过简洁的图形界面（GUI），用户无需输入复杂的命令行即可实现高质量的音频处理。

### **2. 运行环境要求（必备条件）**
为了确保脚本正常运行，您的电脑必须满足以下条件：
*   **操作系统**：Windows 10 或 Windows 11（需支持 PowerShell 5.1 及以上版本）。
*   **核心组件**：
    *   **ffmpeg.exe**：必须放置在与本脚本相同的文件夹内。它是处理音频的核心引擎。
    *   **ffprobe.exe**：建议放置在同级文件夹内。若缺失，脚本将无法读取原始比特率，转而使用默认设置。
*   **权限要求**：首次运行可能需要以管理员身份在 PowerShell 中执行 `Set-ExecutionPolicy RemoteSigned` 命令以解除脚本执行限制。
*   **依赖库**：脚本依赖 .NET 框架（通常 Windows 自带）来渲染图形界面。

### **3. 功能特性**
*   **批量处理**：支持多种音频格式（MP3, WAV, M4a, FLAC, AAC）的自动化调节音量和转换格式为MP3。
*   **多线程加速**：充分利用多核 CPU 性能，支持多文件同步处理。
*   **智能防爆音**：内置硬件限幅器（Limiter），在提升音量的同时防止声音失真。
*   **交互便捷**：支持文件夹拖拽导入和实时处理日志查看。

### **4. 参数调整说明**
*   **音频文件夹路径**：指定原始音频目录。支持输入、浏览选择或文件夹拖拽。
*   **音量调节**：通过滑动条调节。1.0x 代表原音，2.5x（约 增加8dB）是常见的增强幅度。脚本已内置限幅保护。
*   **并发处理数**：建议设置为 CPU 核心数，以平衡速度与系统稳定性。
*   **比特率设置**：可选择“使用原始比特率”以保持音质和文件大小，或“固定比特率”来改变音质和文件大小。
*   **启用动态平衡**：自动调整音频波形。适用于录音电平不稳的文件，默认不勾选。

### **5. 最优设置推荐**
*   **有声书/播客**：音量 2.0x 到3.0x，固定比特率 64kbps，没有出现爆音可以不开启动态平衡。
*   **高保真音乐**：音量 1.5x (3.5dB)，使用原始比特率，关闭动态平衡。
*   **极速转换**：降低比特率，并将并发处理数设置为 CPU 核心数的最高值。

---

### **1. Software Introduction**
This tool is a lightweight audio batch processing script developed based on PowerShell and the FFmpeg core, featuring extremely fast conversion speeds. It is designed for users who need to quickly boost audio volume and unify audio specifications. It can also convert various audio formats into MP3. Through a concise Graphical User Interface (GUI), users can achieve high-quality audio processing without entering complex command lines.

### **2. Running Environment Requirements (Prerequisites)**
To ensure the script runs correctly, your computer must meet the following conditions:
*   **Operating System**: Windows 10 or Windows 11 (requires PowerShell 5.1 or higher).
*   **Core Components**:
    *   **ffmpeg.exe**: Must be placed in the same folder as this script. it is the core engine for processing audio.
    *   **ffprobe.exe**: Recommended to be placed in the same folder. If missing, the script will be unable to read the original bitrate and will revert to default settings.
*   **Permission Requirements**: For the first run, you may need to execute the command `Set-ExecutionPolicy RemoteSigned` in PowerShell as an Administrator to lift script execution restrictions.
*   **Dependent Libraries**: The script relies on the .NET Framework (usually included with Windows) to render the graphical interface.

### **3. Features**
*   **Batch Processing**: Supports automated volume adjustment and MP3 format conversion for multiple audio formats (MP3, WAV, M4a, FLAC, AAC).
*   **Multi-threaded Acceleration**: Fully utilizes multi-core CPU performance and supports simultaneous processing of multiple files.
*   **Intelligent Anti-clipping**: Built-in hardware Limiter to prevent sound distortion while increasing volume.
*   **Convenient Interaction**: Supports folder drag-and-drop import and real-time processing log viewing.

### **4. Parameter Adjustment Description**
*   **Audio Folder Path**: Specifies the original audio directory. Supports manual input, browsing to select, or folder drag-and-drop.
*   **Volume Adjustment**: Adjusted via a slider. 1.0x represents the original sound, and 2.5x (approx. +8dB) is a common enhancement level. The script has built-in limiting protection.
*   **Concurrent Processing Number**: Recommended to be set to the number of CPU cores to balance speed and system stability.
*   **Bitrate Settings**: You can choose "Use Original Bitrate" to maintain audio quality and file size, or "Fixed Bitrate" to change quality and file size.
*   **Enable Dynamic Normalization**: Automatically adjusts the audio waveform. Suitable for files with unstable recording levels; unchecked by default.

### **5. Optimal Settings Recommendation**
*   **Audiobooks/Podcasts**: Volume 2.0x to 3.0x, Fixed Bitrate 64kbps; if no clipping occurs, Dynamic Normalization does not need to be enabled.
*   **Hi-Fi Music**: Volume 1.5x (3.5dB), use Original Bitrate, and disable Dynamic Normalization.
*   **Ultra-Fast Conversion**: Lower the bitrate and set the concurrent processing number to the maximum number of CPU cores.

