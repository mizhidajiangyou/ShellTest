# ShellTest
纯shell的接口测试工具，适合接入devOps

* 使用前运行check_env.sh，确保环境变量SHELL_HOME为当前项目目录(末尾带上/)
* bash版本仅支持4以上版本，
  * mac可以在恢复模式下将/opt/homebrew/opt/bash/bin/bash 替换/bin/bash
  * 或修改默认解释器chsh -s /opt/homebrew/opt/bash/bin/bash
  * 或直接使用高版本的bash命令运行
  * 或在shebang行指定默认解释器位置
