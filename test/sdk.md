# 学习途径
官网、客服、多个github demo, jd.com可以查看miracast的设备,可帮助理解。

http://www.wirelessdisplay.cn/

# 需要学习的概念
真 4K 极致投屏、widi Sink(是win10的协议)、 HDCP、H264, AAC

## H264 AND AAC
Transmission is transmitted using TCP protocol, audio is AAC, and video data is H264

## Miracast
Miracast is a standard for wireless connections from devices(such as laptops, tablets, or smartphones) to displays (such as TVs, monitors or projectors,) introduced in 2012, It can roughly by described as "HDMI over Wi-Fi", replacing the cable from device to the display.

## WiDi
Wireless Display (WiDi) was technology developed by Intel that enabled users to stream music, movies, photos, videos and apps without wires from a compatible computer to a compatible HDTV or through the use of an adapter with other HDTVs or monitors. Intel WiDi supported HD 1080p video quality, 5.1 surround sound, and low latency for interacting with applications sent to the TV from a PC.

WiDi was discontinued in 2015 in favour of Miracast, a standard developed by the Wi-Fi Alliance and natively supported by Windows 8.1 and later.

## Airplay Introduction
Airplay 是由苹果公司开发后个专有协议集，允许设备之间的无线流传输。Originally implemented only in Apple's software and devices, it was called AirTunes and used for audio only.

Airplay 有四个主要功能: music playing, video playing, picture playing and mirror playing. 图片功能从 IOS9 移除，由 mirror 功能实现。

为了实现AirPlay的镜像服务器端功能，我们应该从以下几个方面考虑它：发现过程/协商过程/视频传输/解密过程


# 产品中心
无线投屏/无线投影SDK开发套件 是一套完整的应用开发套件，支持多种协议，支持单路和多路2种无线投屏显示模式，覆盖多平台，用户可以基于此SDK开发适用于不同行业需求的定制化应用，为行业用户提供更加丰富的多屏互动应用场景。
## 分类
* Miracast SDK
* Airplay Server SDK
* iOS APP SDK
* Windows PC 投屏
* Android APP 投屏
* 无线投屏 SDK

# 乐播投屏SDK与必捷投屏SDK
1. 乐播投屏SDK可以轻松实现将视频流媒体(mp4,flv)和直播流媒体(rtmp,hls,http-flv)的视频内容推送到智能电视端进行播放,但好像只支持单路，另外乐联协议是私有的协议

# 疑问
1. 必捷投屏只支持四屏吗？

# SDK demo
[AirPlay demo](https://github.com/wirelessdisplay)

[PC demo](https://github.com/wirelessdisplay/PCDisplay) 与 `Windows-APP-Mirror-SDK` 是同一个项目

[Miracast demo](https://github.com/wirelessdisplay/Miracast)

[Android demo](https://github.com/wirelessdisplay/Android-APP-Mirror)

## SDK 用途
SDK | 用途
--- | ---
AirPlay-SDK | 苹果无线保护协议，是一个 receiver 开发工具包，支持多个 Apple 设备
WIDI-SDK | 由微软和因特尔共同开发，可支持多个 Sources
Miracast-SDK | 由谷歌运行，可同时支持多个 Android 设备
Windows-APP-Mirror-SDK | 是一个开发端的开发包，需要运行在windows,支持客户端的发送
Android-APP-Mirror-SDK | 运行在安卓接收者开发包，能支持安卓/windows/mac电脑发送
Demo_download | Airplay Mirror/PC Mirror/Android APP Mirror

## AirPlay-SDK 实践




SDK功能
能不能不显示，直接把流推到一个rtmp服务器
或者把屏幕集成后每一个是不是独立的？