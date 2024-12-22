## YOUChat_Proxy for Linux 部署指南

本项目提供了一个在 Linux 环境下部署 YOUChat Proxy 的简易方法，特别感谢 **YIWANG** 的持续维护和贡献。

**项目地址：** [https://github.com/YIWANG-sketch/YOUChat_Proxy/](https://github.com/YIWANG-sketch/YOUChat_Proxy/)

---

### 食用建议

为了获得最佳的使用体验，我们强烈建议您在 **Windows 操作系统** 上直接安装 YOUChat Proxy。通过调用浏览器的方式，可以有效地绕过 Cloudflare 的 JS Challenge。

由于 Debian 系统比 Windows 系统占用更少的系统资源，因此该安装方案特别适用于 VPS **资源受限**（内存及 CPU 资源较少）的环境。

**注意：** 当使用的 IP 质量不佳，或者短时间内发送过多请求时，可能会触发 Cloudflare 的 5 秒盾验证机制。

---

### Linux 部署教程 (Debian 12 测试通过)

为了避免代理配置的麻烦，建议在**境外 VPS** 上运行此程序。

**步骤：**

1. **连接服务器:** 使用 SSH 客户端连接到您的目标服务器。

2. **执行安装脚本:** 在终端中输入以下指令：

    ```bash
    bash <(wget -qO- -o- https://raw.githubusercontent.com/ColorSource/YOUChat_Proxy_Linux/refs/heads/main/YOUChat_Proxy_Install.sh)
    ```

3. **查看安装状态:** 当出现提示信息后，可以使用以下命令查看安装状态：

    ```bash
    screen -r youchat_proxy
    ```

4. **安装完成提示:** 安装过程结束后，系统将显示类似于以下的输出信息：

    ```
    本项目依赖Chrome或Edge浏览器，请勿关闭弹出的浏览器窗口。如果出现错误请检查是否已安装Chrome或Edge浏览器。
    第0个cookie无效，请重新获取。
    未检测到有效的DS或stytch_session字段。
    已添加 0 个 cookie
    开始验证cookie有效性...
    订阅信息汇总：
    开始网络监控...
    验证完毕，有效cookie数量 0
    开启 多账号模式
    ```

5. **修改配置:**

    *   使用 `Ctrl + C` 键停止当前运行的脚本。
    *   进入 `YOUChat_Proxy/` 目录。
    *   编辑 `config.mjs` 和 `start.sh` 两个文件，将文件中的相关配置参数修改为您自己的配置。

6. **重新运行:** 再次执行步骤 2 的安装脚本：

    ```bash
    bash <(wget -qO- -o- https://raw.githubusercontent.com/ColorSource/YOUChat_Proxy_Linux/refs/heads/main/YOUChat_Proxy_Install.sh)
    ```

7. **查看运行状态:** 使用以下命令查看运行状态：

    ```bash
    screen -r youchat_proxy
    ```

    不出意外，您应该可以看到程序正常运行了。 🎉
