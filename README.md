# deckmate
> SteamDeck初始化定制脚本  

## 功能 | funtion
脚本旨在提供中国大陆SteamDeck用户网络优化方案, 并为他们当中的Linux爱好者自动配置最基本的桌面模式语言环境。由于SteamOS的更新可能造成部分自定义内容所在的堆叠层被[覆写导致失效](https://www.bilibili.com/read/cv19654191/), 故脚本倾向于使用Flatpak、rootless容器或调用系统内置应用以确保修改尽可能地持久化.  
* 初始化包管理器和AUR助手
* 修补KDE中文显示 
* 应用商店换源 
* 为桌面模式调用内置iBus中文输入法
* 安装v2ray并通过Chrome或其他浏览器访问其Web-UI(掌机模式/桌面模式通用)

## 使用方法 | useage  
1. 在`deckmate.sh`文件路径下打开Konsole或其他命令行  
2. 运行前请在上游网络准备好加速器或VPN. 在检测到因中国大陆网络阻断时, 脚本倾向于重复尝试直到网络状况改善或用户手动终止执行. 任何节点终止都不会对SteamOS造成破坏性影响  
3. 输入如下命令:  
```  
sudo chmod +x ./deckmate.sh && ./deckmate.sh  
```  
4. 坐和放宽  

## 截图 | screenshot  
![Screenshot](https://user-images.githubusercontent.com/27397756/216623790-b1b1fc85-997c-4042-9674-cbc30d2db7d6.png)
