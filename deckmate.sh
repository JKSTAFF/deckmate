#!/bin/bash
function loop_exe() { # 简易网络排障, 会重复执行直到网通或者关闭脚本
    CMDLINE=$1
    while true ; do
        sleep 1
        ${CMDLINE} &>/dev/null
        if [ $? == 0 ] ; then
            break
        else
            (( ex_count = ${ex_count} + 1))
            echo -e "\033[31m 错误: 第${ex_count}次执行失败, 请改善网路后重试 \033[0m"
        fi 
    done
}

## 软件仓库初始化
Ini_PkgMan() {
    sudo steamos-readonly disable # 暂停系统写保护
    if [ $? == 0 ]; then
        echo "开始同步在线软体仓库…" 
        sudo pacman-key --init &>/dev/null && sudo pacman-key --populate &>/dev/null
        loop_exe "sudo pacman -Sy"
        if ( ! pacman -Qs paru &>/dev/null || ! pacman -Qs base-devel &>/dev/null ) ; then # 安装AUR助手
            loop_exe "sudo pacman -S paru base-devel --noconfirm"
        fi
        sudo steamos-readonly enable # 重启系统写保护
        if ( ! flatpak remotes --show-details | grep -i .cn &>/dev/null ) ; then # Flat商店镜像加速
            flatpak remote-modify flathub --url=https://mirror.sjtu.edu.cn/flathub && echo -e "\033[32m Flat应用商店已换源 \033[0m" 
        fi
        echo -e "\033[32m 软体仓库已就绪 \033[0m" 
    else 
        echo -e "\033[31m 错误: 硬体型号不匹配, 终止执行 \033[0m"
        exit 1
    fi
}

## 基础汉化
Basic_Sinicization() {
    Ini_PkgMan
    sudo steamos-readonly disable
    loop_exe "sudo pacman -S glibc --noconfirm"
    sudo sed -i "s%#zh_CN.UTF-8 UTF-8%zh_CN.UTF-8 UTF-8%" /etc/locale.gen
    locale-gen &>/dev/null # 区域设置
    loop_exe "sudo pacman -S ki18n plasma fcitx5-chinese-addons --noconfirm" # 修补被SteamOS精简的KDE国际化组件和中文输入法
    echo -e "\033[32m 基础语言包已就绪 \033[0m"
    while true ; do # 可选完整汉化
        read -r -p "是否下载所有软体语言包? 这将消耗大量时间并有可能造成依赖冲突 [y/N]" input10
        case $input10 in
            [yY][eE][sS]|[yY])
                sudo pacman -S $(pacman -Qqn | grep -v "$(pacman -Qmq)") # 刷新系统所有已安装软件的显示语言
                echo -e "\033[32m 完整语言包已就绪 \033[0m"
                break
                ;;
            [nN][oO]|[nN])
                break
                ;;
            *)
            echo -e "\033[31m 错误: 无效输入 \033[0m"
        esac
    done
    echo -e "\033[33m 注意: 你仍需在系统重启后手动配置显示语言 \033[0m"
    sudo steamos-readonly enable
}
 
## 科学上网
Proxy_Setting() {
    if ( ! pacman -Qqm | grep -i v2ray &>/dev/null ) ; then 
        Ini_PkgMan
        sudo steamos-readonly disable
        loop_exe "sudo pacman -S ufw --noconfirm" #安装防火墙(透明代理依赖)并适配KDE图形界面
        loop_exe "paru -S v2raya-bin" #安装v2ray及WebUI
        sudo systemctl disable v2ray --now && sudo systemctl enable v2raya && sudo systemctl restart v2raya #启动科学上网
        echo -e "\033[32m 翻墙核心已就绪 \033[0m"
        sudo steamos-readonly enable
        if ( ! flatpak list | grep -i chrom &>/dev/null ); then # 浏览器检测
            while true ; do
                read -r -p "是否安装Chrome访问管理界面? [Y/n]" input0
                case $input0 in
                    [yY][eE][sS]|[yY])
                        loop_exe "flatpak install flathub com.google.Chrome/x86_64/stable"
                        break
                        ;;
                    [nN][oO]|[nN])
                        break
                        ;;
                    *)
                    echo -e "\033[31m 错误: 无效输入 \033[0m"
                esac
            done
            echo -e "\033[33m 注意: 你仍需手动配置节点 \033[0m"
            xdg-open http://127.0.0.1:2017 &>/dev/null
        fi
    else echo -e "\033[33m 您可能已安装过v2ray. 跳过… \033[0m"
    fi
}

## 非Steam游戏转译支持
Proton_Setting() {
    if [ -d "$HOME" ] ; then
        if [ ! -d "$HOME/.steam/root/compatibilitytools.d" ] ; then
            mkdir "$HOME/.steam/root/compatibilitytools.d"
        else rm -rf $HOME/.steam/root/compatibilitytools.d/* 
        fi
        echo "开始下载Proton-GE最新版本…"
        loop_exe "curl -sLOJ $(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep browser_download_url | cut -d\" -f4 | egrep .tar.gz)"
        tar -xf GE-Proton*.tar.gz -C $HOME/.steam/root/compatibilitytools.d/
        rm ./GE-Proton*.tar.gz
        if ( ! flatpak list | grep -i protonup &>/dev/null ) ; then # 安装Proton图形管理界面
            Ini_PkgMan
            loop_exe "flatpak install flathub net.davidotek.pupgui2"
        fi
        echo -e "\033[32m 转译层配置界面已就绪 \033[0m"
    else echo -e "\033[31m 错误: Steam未正确安装, 跳过… \033[0m"
    fi
}

## 收尾作业
End_Phase() {
    while true ; do # 清理安装残留
        read -r -p "是否清理残留安装文件? [Y/n]" input3
        case $input3 in
            [yY][eE][sS]|[yY])
                sudo steamos-readonly disable &>/dev/null
                sudo pacman -Qtdq | sudo pacman -Rs - &>/dev/null
                sudo pacman -Sc
                paru -c &>/dev/null
                sudo steamos-readonly enable &>/dev/null
                echo -e "\033[32m 系统写保护已启用 \033[0m" 
                break
                ;;
            [nN][oO]|[nN])
                break
                ;;
            *)
                echo -e "\033[31m 错误: 无效输入 \033[0m"
        esac
    done
    while true ; do # 重启确认
        read -r -p "是否重启? [Y/n]" input4
        case $input4 in
            [yY][eE][sS]|[yY])
                reboot
                ;;
            [nN][oO]|[nN])
                break
                ;;
            *)
                echo -e "\033[31m 错误: 无效输入 \033[0m"
        esac
    done
    read -s -n1 -p "按任意键结束脚本…"
}

## ASCII ART
echo -e "\033[31m ██████╗ ███████╗ ██████╗██╗  ██╗███╗   ███╗ █████╗ ████████╗███████╗ \033[0m"
echo -e "\033[33m ██╔══██╗██╔════╝██╔════╝██║ ██╔╝████╗ ████║██╔══██╗╚══██╔══╝██╔════╝ \033[0m"
echo -e "\033[32m ██║  ██║█████╗  ██║     █████╔╝ ██╔████╔██║███████║   ██║   █████╗ \033[0m"
echo -e "\033[36m ██║  ██║██╔══╝  ██║     ██╔═██╗ ██║╚██╔╝██║██╔══██║   ██║   ██╔══╝ \033[0m"
echo -e "\033[34m ██████╔╝███████╗╚██████╗██║  ██╗██║ ╚═╝ ██║██║  ██║   ██║   ███████╗ \033[0m"
echo -e "\033[35m ╚═════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ \033[0m"
echo " ######################## Vector Di-gi©2023 ######################### "

## SteamDeck检测
if [ "$(id -u)" != "0" ] ; then
    echo "正在识别设备所有者, 请进行提权验证"
    sudo -v
    if [ $? != 0 ]; then
        passwd
    fi
    echo -e "\033[32m 用户鉴权通过 \033[0m"
else 
    echo -e "\033[31m 错误, 执行权限不足或敏感. 正在结束… \033[0m"
    exit 1
fi

echo "正在检测系统语言…"
if [[ "$(echo $LANG)" != zh_* ]]; then
    echo -e "\033[33m 注意: 非中文环境 \033[0m"
    while true
        do 
            read -r -p "是否变更系统语言为简中? [Y/n]" input0
            case $input0 in
                [yY][eE][sS]|[yY])
                    Basic_Sinicization
                    break
                    ;;
                [nN][oO]|[nN])
                    break
                    ;;
                *)
                    echo -e "\033[31m 错误: 无效输入 \033[0m"
            esac
        done
else echo -e "\033[32m 系统已经是中文环境 \033[0m"
fi

echo "正在检测网络连接性…"
if ( ! curl steamcommunity.com -m 10 &>/dev/null ) ; then # 10s内不响应视为Steam社区裸连被阻断
    echo -e "\033[33m 警告: Steam服务器连接性不佳 \033[0m"
    while true
        do 
            read -r -p "是否部署科学上网? [Y/n]" input1
            case $input1 in
                [yY][eE][sS]|[yY])
                    Proxy_Setting
                    break
                    ;;
                [nN][oO]|[nN])
                    break
                    ;;
                *)
                    echo -e "\033[31m 错误: 无效输入 \033[0m"
            esac
        done
else echo -e "\033[32m Steam服务器连接正常 \033[0m"
fi

echo "正在检测三方游戏兼容性…"
if [ ! -d ~/.steam/root/compatibilitytools.d/"$(curl -s "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest" | grep "browser_download_url.*\.tar\.gz" | cut -d \" -f 4 | sed "s|.*/||" | sed "s|\.tar\.gz||")" ] ; then
    while true
        do 
            read -r -p "是否安装/更新三方游戏转译兼容层? [Y/n]" input2
            case $input2 in
                [yY][eE][sS]|[yY])
                    Proton_Setting
                    break
                    ;;
                [nN][oO]|[nN])
                    break
                    ;;
                *)
                    echo -e "\033[31m 错误: 无效输入 \033[0m"
            esac
        done
else echo -e "\033[32m Proton-GE已是最新版本 \033[0m"
fi

End_Phase
exit