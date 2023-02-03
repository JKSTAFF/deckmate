# deckmate
> SteamDeck初始化定制脚本  

## 功能 | funtion
脚本旨在提供中国大陆SteamDeck用户网络优化方案, 并为他们当中的Linux爱好者自动配置最基本的桌面模式语言环境
* 初始化包管理器和AUR助手
* 修补KDE中文显示 
* 应用商店换源 
* 安装fcitx5中文输入法
* 安装v2ray-core并通过Chrome或其他浏览器访问其Web-UI

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
