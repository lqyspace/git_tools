#!/bin/bash
# 日志文件
ROOT_DIR=$(pwd)
LOG_FILE="$ROOT_DIR/git_errors.log"

log_error() {
    local repo_url=$1
    local reason=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[ERROR] 时间: $timestamp | 仓库: $repo_url | 原因: $reason" >> "$LOG_FILE"
}

# 函数：检查并拉去仓库
check_or_clone_repo() {
    local target_dir=$1
    local repo_url=$2
    local branch=$3

    # 确保目录和仓库地址有效
    if [[ -z "$target_dir" || -z "$repo_url" ]]; then
        echo "fatal: 目录或仓库地址不能为空"
        log_error "$repo_url" "目录或仓库地址不能为空"
        return 1
    fi

    echo "*******目标地址：${target_dir}——目标仓库：${repo_url}（分支：${branch:-master}）*******"
    # 保存当前目录并且切换
    pushd . > /dev/null

    # 检查目录是否存在
    if [ -d "$target_dir" ]; then
        echo "目录已经存在：$target_dir"
        cd "$target_dir" || { echo "进入目录失败"; log_error "$repo_url" "进入目录失败"; popd > /dev/null; exit 1; }

        # 检查是否已经有该仓库
        if [ -d ".git" ]; then
            echo "切换到分支：${branch:-master}"
            git fetch origin || { echo "git fetch 失败"; log_error "$repo_url" "git fetch 失败"; popd > /dev/null; exit 1; }
            git checkout "${branch:-master}" || { echo "切换分支失败: ${branch:-master}"; log_error "$repo_url" "切换分支失败: ${branch:-master}"; popd > /dev/null; exit 1; }
            echo "拉取最新代码：$repo_url"
            git pull || { echo "git pull 失败"; log_error "$repo_url" "git pull 失败"; popd > /dev/null; exit 1; }
        else 
            echo "当前目录不是Git仓库，重新克隆：$repo_url"
            cd .. && git clone -b "${branch:-master}" "$repo_url" || { echo "git clone 失败"; log_error "$repo_url" "git clone 失败"; popd > /dev/null; exit 1; }
        fi
    else
        echo "目录不存在，创建并克隆仓库：$target_dir + $repo_url"
        mkdir -p "$target_dir" && cd "$target_dir" || { echo "创建目录失败"; log_error "$repo_url" "创建目录失败"; popd > /dev/null; exit 1; }
        cd .. && git clone -b "${branch:-master}" "$repo_url" || { echo "git clone -b ${branch:-master} 失败"; log_error "$repo_url" "git clone 失败"; popd > /dev/null; exit 1; }
    fi
    echo -e "*******END*******\n"
    popd > /dev/null # 返回初始目录，隐藏输出
}

# 主程序：批量处理多个目录和仓库
main() {
    # 本地配置文件
    local config_file="./repos.conf"

    if [ ! -f "$config_file" ]; then
        echo "配置文件不存在：$config_file"
        exit 1
    fi

    # 当前目录变量
    local current_dir=""

    # 逐行读取配置文件
    while IFS= read -r line || [[ -n "$line" ]]; do
        # 移除行首和行尾的空白字符
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # 跳过空行
        [[ -z "$line" ]] && continue
        echo "当前行：$line";

        # 判断是否为目录名
        if [[ "$line" =~ \[(.*)\] ]]; then
            # 使用正则表达式捕获目录名
            current_dir="${BASH_REMATCH[1]}"  # 提取括号内的内容
            echo "处理目录：$current_dir"
            continue
        fi
        
        # 判断current_dir是否为空，如果为空则使用默认路径
        if [[ -z "$current_dir" ]]; then
            current_dir=$(echo "$line" | sed -E 's|.*iot/(.*)/.*|\1|')
        fi
        echo "当前目录：$current_dir"

        # 解析仓库地址和分支
        repo_url=$(echo "$line" | awk -F',' '{print $1}')
        branch=$(echo "$line" | awk -F',' '{print $2}')
        branch=${branch:-master} # 如果分支为空，设置为默认分支 master

        # 如果不是目录名，则认为是仓库地址
        if [[ -n "$current_dir" ]]; then
            echo "处理仓库：$repo_url (分支: $branch)"
            tmp=$(echo "$repo_url" | sed 's/\.git$//' | awk -F/ '{print $NF}')
            echo "tmp: $tmp"
            check_or_clone_repo "$current_dir/$tmp" "$repo_url" "$branch"
        fi
    done < "$config_file"

    echo -e "\n所有错误已记录到日志文件: $LOG_FILE"
}

# 执行主函数
main
