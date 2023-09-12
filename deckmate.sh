#!/bin/bash
function loop_exe() { # 简易网络排障, 会重复执行直到网通或者关闭脚本
    CMDLINE=$1
    while true ; do
        sleep 1
        ${CMDLINE}
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
        echo "正在初始化包管理器…" 
        loop_exe "sudo pacman-key --init && sudo pacman-key --populate && sudo pacman -Sy &>/dev/null"
        if ( ! pacman -Qs paru &>/dev/null ) ; then # 安装AUR助手
            while true ; do
                read -r -p "是否引入用户软件仓库(可选)? [Y/n]" input7
                case $input7 in
                    [yY][eE][sS]|[yY])
                        loop_exe "sudo pacman -S paru --noconfirm"
                        break
                        ;;
                    [nN][oO]|[nN])
                        break
                        ;;
                    *)
                    echo -e "\033[31m 错误: 无效输入 \033[0m"
                esac
            done
        fi
        echo -e "\033[32m 软件仓库初始化完成 \033[0m"
        sudo steamos-readonly enable # 重启系统写保护
        if ( ! flatpak remotes --show-details | grep -i .cn &>/dev/null ) ; then # Flat商店镜像加速
            flatpak remote-modify flathub --url=https://mirror.sjtu.edu.cn/flathub && echo -e "\033[32m Flatpak应用商店已换源 \033[0m"
        fi
    fi
}

## 汉化
Basic_Sinicization() {
    Ini_PkgMan
    sudo steamos-readonly disable
    sudo sed -i "s%#zh_CN.UTF-8 UTF-8%zh_CN.UTF-8 UTF-8%" /etc/locale.gen # 区域设置
    loop_exe "sudo pacman -S glibc --noconfirm"
    loop_exe "sudo pacman -S ki18n plasma --noconfirm" # 修补被SteamOS精简的KDE国际化组件
    echo -e "\033[32m 基础语言包已就绪 \033[0m"
    while true ; do # 可选完整汉化
        read -r -p "是否下载所有软体语言包(可选)? 这将消耗大量时间并有可能造成依赖冲突 [y/N]" input5
        case $input5 in
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
    if ( ! cat $HOME/.bash_profile | grep -i ibus &>/dev/null ) ; then  # 激活桌面模式输入法图标
            sed -i '$a \export XMODIFIERS=@im=ibus\nexport QT_IM_MODULE=ibus\nibus-daemon -drx' $HOME/.bash_profile && ibus-daemon -drx && echo -e "\033[33m 注意: 你仍需在系统重启后在ibus设置中手动添加中文输入法 \033[0m"
    fi
}
 
## 科学上网
Proxy_Setting() {
    if ( ! systemctl --user status container-v2raya.service &>/dev/null ) ; then 
        if ( ! podman --version &>/dev/null ) ; then # rootless模式安装podman
            loop_exe "curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/extras/install-podman | sh -s -- --prefix ~/.local &>/dev/null"
            echo -e "\033[32m rootless容器环境已就绪 \033[0m"
        fi
        loop_exe "podman create -it --name v2raya --restart=unless-stopped --label io.containers.autoupdate=registry --cgroup-parent=v2raya.slice --security-opt no-new-privileges --cap-drop all --network host --volume ~/.config/v2raya:/etc/v2raya:z docker.io/mzz2017/v2raya:latest"
        #启动科学上网
        podman generate systemd --name v2raya > ~/.config/systemd/user/container-v2raya.service && systemctl --user daemon-reload && systemctl --user enable --now container-v2raya.service
        echo -e "\033[32m 翻墙核心已就绪 \033[0m"
        if ( ! flatpak list | grep -i chrom &>/dev/null ); then # 浏览器检测
            while true ; do
                read -r -p "是否安装Chrome访问管理界面(可选)? [Y/n]" input6
                case $input6 in
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
            xdg-open http://localhost:2017 &>/dev/null
        fi
        echo -e "\033[33m 注意: 你仍需手动配置节点 \033[0m"
    else echo -e "\033[33m 您可能已安装过v2rayA. 跳过… \033[0m"
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
        rm ./GE-Proton*.tar.gz &>/dev/null
        loop_exe "curl -LOJ# $(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep browser_download_url | cut -d\" -f4 | grep -E .tar.gz)"
        rm -rf $HOME/.steam/root/compatibilitytools.d/*
        tar -xf GE-Proton*.tar.gz -C $HOME/.steam/root/compatibilitytools.d/
        rm ./GE-Proton*.tar.gz &>/dev/null
        echo -e "\033[33m 注意: 你仍需在重启后手动配置游戏兼容设置 \033[0m"
        if ( ! flatpak list | grep -i protonup &>/dev/null ) ; then # 安装Proton图形管理界面
            while true ; do
                read -r -p "是否安装Proton图形管理界面(可选)? [Y/n]" input8
                case $input8 in
                    [yY][eE][sS]|[yY])
                        Ini_PkgMan
                        loop_exe "flatpak install flathub net.davidotek.pupgui2 &>/dev/null"
                        echo -e "\033[32m Proton图形管理界面已就绪 \033[0m"
                        break
                        ;;
                    [nN][oO]|[nN])
                        break
                        ;;
                    *)
                    echo -e "\033[31m 错误: 无效输入 \033[0m"
                esac
            done
        fi
    fi
}

## 收尾作业
End_Phase() {
    while true ; do # 清理安装残留
        read -r -p "是否清理残留安装文件? [Y/n]" input3
        case $input3 in
            [yY][eE][sS]|[yY])
                sudo steamos-readonly disable &>/dev/null
                sudo pacman -Rs $(sudo pacman -Qtdq) &>/dev/null
                sudo pacman -Sc
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
        echo -e "\033[31m 请设置初始用户密码… \033[0m"
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
if [ ! -d $HOME/.steam/root/compatibilitytools.d/"$(curl -s "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest" | grep "browser_download_url.*\.tar\.gz" | cut -d \" -f 4 | sed "s|.*/||" | sed "s|\.tar\.gz||")" ] ; then
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
