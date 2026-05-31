# YOLO AI Coding Dev Container

预装 node / python / bun / uv / claude code / codex 的 Docker 镜像,与 host 共享同一份 Claude / Codex 状态。在隔离容器中以 `--dangerously-skip-permissions` 运行 AI coding。

镜像由 GitHub Actions 多架构构建(amd64 + arm64)并发布到 `ghcr.io/xindaonow/yolo-dev:latest`,直接拉取使用,无需本地构建。

> ⚠️ 请勿同时在 host 与容器中对同一项目运行 `claude`,两者会写入同一份 `.jsonl`。顺序使用无此问题。

## 快速开始

需 Docker + VS Code + Dev Containers 扩展(Windows 用 WSL2,项目置于 WSL 文件系统内)。host 上需已登录 Claude / Codex(容器复用其登录状态),并创建收件箱 `mkdir -p ~/dev-inbox`。

在项目目录下获取配置:

```bash
mkdir -p .devcontainer
curl -fsSL https://raw.githubusercontent.com/xindaonow/yolo-dev/main/templates/devcontainer.remote.json \
  -o .devcontainer/devcontainer.json
```

**用 VS Code:** `code .` → `Cmd+Shift+P` → **Dev Containers: Reopen in Container**

**用命令行:**

```bash
npm install -g @devcontainers/cli      # 一次性安装
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . bash
```

容器内运行:

```bash
claude --dangerously-skip-permissions
# 或 codex
```

首次进入时 Docker 按机器架构自动拉取镜像。已有项目(此前在 host 上运行过 claude)进入容器后,旧对话出现在 `/resume` 中——模板将项目挂载在 host 真实路径,并 bind 了 host 的 `~/.claude`。

## 常用操作

- 关闭容器:`docker ps --filter "label=devcontainer.local_folder=$PWD" --format '{{.ID}}' | xargs -r docker stop`
- 重建容器(修改 devcontainer.json 后):`devcontainer up --workspace-folder . --remove-existing-container`
- 出口防火墙(容器内手动启用,仅放行 Anthropic / OpenAI / npm / pypi / GitHub 等):`sudo /usr/local/bin/init-firewall.sh`

---

## 本地构建镜像(维护者)

修改镜像内容(Dockerfile、防火墙白名单、CLI 版本)时,clone 本仓库后本地构建:

```bash
cd ~/Code/dev-setup
./build.sh                 # 构建 yolo-dev:latest
./build.sh --latest        # 强制拉取最新 Claude / Codex
```

本地构建后用 `templates/devcontainer.json`(image 为本地 `yolo-dev:latest`)。CLI 版本固定在构建时(self-update 已关闭),升级需重建镜像并 rebuild 容器(VS Code `Rebuild Container`,或 CLI `--remove-existing-container`)。

镜像内容:node LTS、python 3.12、bun、uv、claude code、codex,以及 7 天依赖 cooldown(`min-release-age` / `minimumReleaseAge`)。
