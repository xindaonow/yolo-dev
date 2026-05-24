# YOLO AI Coding Dev Container

烤进 node / python / bun / uv / claude code / codex 的 Docker 镜像,和 host 共享同一份 Claude/Codex 状态。

> ⚠️ 别同时在 host 和容器里对同一个项目跑 `claude`(会抢写同一份 `.jsonl`)。串行用没问题。

## 一次性准备

```bash
cd ~/Code/dev-setup
./build.sh         # 构建 yolo-dev:latest 镜像
```

前提:Docker Desktop 已运行,host 上已登录过 Claude / Codex(容器直接复用,不用再登录)。

## 新项目 / 已有项目 都一样

下面的步骤对**新项目和已有项目通用**——同一个模板。已有项目(之前在 host 上跑过 claude 的)进容器后,旧对话会自动出现在 `/resume` 里,因为模板把项目挂在 host 真实路径、并 bind 了 host 的 `~/.claude`。

## 用 VS Code

```bash
mkdir -p ~/Code/my-project/.devcontainer
cp ~/Code/dev-setup/templates/devcontainer.json ~/Code/my-project/.devcontainer/
code ~/Code/my-project
```

`Cmd+Shift+P` → **Dev Containers: Reopen in Container**,然后 terminal 里直接:

```bash
claude --dangerously-skip-permissions
# 或 codex
```

## 用命令行

```bash
npm install -g @devcontainers/cli      # 一次性安装

mkdir -p ~/Code/my-project/.devcontainer
cp ~/Code/dev-setup/templates/devcontainer.json ~/Code/my-project/.devcontainer/
cd ~/Code/my-project

devcontainer up --workspace-folder .            # 启动
devcontainer exec --workspace-folder . bash     # 进 shell
```

进入后直接 `claude` / `codex`。

- 关闭容器:`docker ps --filter "label=devcontainer.local_folder=$PWD" --format '{{.ID}}' | xargs -r docker stop`
- 重建容器(改了 devcontainer.json 后):`devcontainer up --workspace-folder . --remove-existing-container`

## 更新 Claude / Codex 版本

镜像装的是**构建时最新版**(self-update 已关,所以运行时不会变)。要升级,直接重建镜像:

```bash
cd ~/Code/dev-setup && ./build.sh
```

重建后,已存在的项目容器要 rebuild 才用新版(VS Code: `Rebuild Container`;CLI: `--remove-existing-container`)。

## 可选:出口防火墙

容器内手动启用(只放行 Anthropic / OpenAI / npm / pypi / GitHub 等):

```bash
sudo /usr/local/bin/init-firewall.sh
```
