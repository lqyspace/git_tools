[toc]
# git_tools
一些辅助git clone的shell脚本

> run.sh
这个脚本的主要作用是：
- 读取repos.conf，所以提前把git地址按格式填入repos.conf
- 在[]里自定义本地的git仓库存储路径——>相对路径
- 若[]没有自定义路径，会使用git中的部分文件路径

> repos.conf
```shell
[relative_path]
git@github.xxxxxxxxxxxxxxxxxxxx@repo.git

[./]
git@github.xxxxxxxxxxxxxxxxxxxx@repo.git

[]
git@github.xxxxxxxxxxxxxxxxxxxx@repo.git
```