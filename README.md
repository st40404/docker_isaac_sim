# 該 docker 環境是基於 Isaac sim 的 container 來進行封裝的
  ## Isaac sim 5.1 環境建議
  * driver verison 580.159.03
  * IsaacLab version V2.3.2

  ## 包裝 Isaac sim
 * Step1: 下載 Isaac Sim Docker 映像檔到 Local 端的 Container 中
   ```bash
   docker pull nvcr.io/nvidia/isaac-sim:5.1.0
   ```
 * Step2: 建立掛載資料夾
   ```bash
   mkdir -p ./docker/isaac-sim/cache/kit
   mkdir -p ./docker/isaac-sim/cache/ov
   mkdir -p ./docker/isaac-sim/cache/pip
   mkdir -p ./docker/isaac-sim/cache/glcache
   mkdir -p ./docker/isaac-sim/cache/computecache
   mkdir -p ./docker/isaac-sim/logs
   mkdir -p ./docker/isaac-sim/data
   mkdir -p ./docker/isaac-sim/documents
   mkdir -p ./isaac-lab-logs
   ```
 * Step3: 編譯 Dockerfile （包裝下載的 container: nvcr.io/nvidia/isaac-sim:5.1.0）
   ```bash
   ./build.sh
   ```
 * Step4: 執行 Isaac sim
   ```bash
   ./run.sh
   ```

 ## Isaac Lab（已內建於映像檔）
 * 版本：`v2.3.2`（對應 Isaac Sim 5.1）
 * 容器內路徑：`/root/work/IsaacLab`
 * 驗證安裝（在容器 Shell 內）：
   ```bash
   /root/work/src/docker/verify_isaac_lab.sh
   ```
 * 快速測試 RL 訓練（headless）：
   ```bash
   cd /root/work/IsaacLab
   ./isaaclab.sh -p scripts/reinforcement_learning/rsl_rl/train.py --task=Isaac-Ant-v0 --headless
   ```
 * 訓練 log 路徑（容器內）：`/root/work/IsaacLab/logs/rsl_rl/ant/<時間戳>/`（內含 `model_*.pt`）
 * **log 已掛載到主機**（`run.sh` 自動建立）：
   * 主機：`src/isaac-lab-logs/`
   * 容器：`/root/work/IsaacLab/logs/`
   * 重跑 `./run.sh` 後 checkpoint 仍保留，無需重新訓練
 * 若先前在容器內訓練、尚未掛載時產生的 log，需手動複製一次到主機：
   ```bash
   cp -r /root/work/IsaacLab/logs/rsl_rl /root/work/src/isaac-lab-logs/
   ```

 ## BeyondMimic（whole_body_tracking）

 原始碼掛載在 `/root/work/src/whole_body_tracking`（與 `robot_lab` 同層）。**不建議**把 `pip install -e` 寫進 Dockerfile 的 `/root/work/src/...`（會被 volume 蓋掉）。

 ### 自動安裝（entrypoint）

 `./run.sh` 啟動容器時，`entrypoint.sh` 會呼叫 `docker/setup_beyondmimic.sh`（冪等）：

 * 若存在 `whole_body_tracking` → `isaaclab.sh -p -m pip install -e ...`
 * 若缺少 `unitree_description` → 自動下載官方 G1 資產

 略過自動安裝：

 ```bash
 SKIP_BEYONDMIMIC_SETUP=1 ./run.sh
 ```

 ### 手動安裝 / 重裝

 容器內（或 `docker exec` 進入後）：

 ```bash
 /root/work/src/docker/setup_beyondmimic.sh
 ```

 強制重裝 extension、並重新下載 unitree 資產：

 ```bash
 /root/work/src/docker/setup_beyondmimic.sh --force-pip --download-unitree
 ```

 ### Isaac Lab 2.3.x 相容（BeyondMimic 官方為 2.1）

 本映像為 **Isaac Sim 5.1 + Isaac Lab 2.3.2**（RTX 50 系列需 Sim 5.1）。`whole_body_tracking` 已做最小修補：

 * `scripts/rsl_rl/train.py`：移除 Isaac Lab 2.3 已刪除的 `dump_pickle`，僅保留 `dump_yaml`

 驗證安裝與任務註冊（約 1 分鐘，會啟動 headless Sim）：

 ```bash
 /root/work/src/docker/verify_beyondmimic.sh
 ```

 驗證 pip（**不要用** `-c "import whole_body_tracking"`，會缺 `pxr`）：

 ```bash
 cd /root/work/IsaacLab
 ./isaaclab.sh -p -m pip show whole_body_tracking
 ```

 訓練範例見 `/root/work/src/whole_body_tracking/README.md`（需 WandB motion registry、`--headless`）。

 ### start-isaac 出現 `libcublas` / `libcusparseLt` / `torch.Tensor` 錯誤

 Isaac Lab 安裝後 PyTorch 為 **2.7.0+cu128**，需在 **kit 內建 Python 的 `sys.path`** 下找到 `site-packages/nvidia/cublas` 等 CUDA 12 函式庫。僅設 `LD_LIBRARY_PATH` 或手動 `source isaac_cuda_env.sh` 後再跑舊版 `start-isaac` 仍可能失敗。

 **請改用**（`src/` 掛載內，通常不必重建映像）：

 ```bash
 start-isaac
 # 或
 /root/work/src/docker/start_isaac.sh
 ```

 `start-isaac` 為 `/usr/local/bin` 可執行檔（任何 shell 皆可用）；重建映像前若找不到，請直接用上面第二行路徑。

 `isaac_cuda_env.sh` 會：
 1. source `setup_python_env.sh`
 2. 將 `omni.isaac.ml_archive` 的 CUDA 12 函式庫 symlink 到 `site-packages/nvidia/`
 3. 設定 `LD_LIBRARY_PATH`（含 `cusparselt` 等）

 重建映像後 `start-isaac` alias 與 Terminator 會自動呼叫 `start_isaac.sh`。

  ## 測試 Ant 訓練結果（play.py）

 使用 `play.py` 載入 checkpoint 做推論。**不需**先執行 `start-isaac`；也**不要**與 `start-isaac` 同時跑（會搶 GPU／埠）。

 確認 checkpoint 存在：
 ```bash
 cd /root/work/IsaacLab
 ls -lt logs/rsl_rl/ant/
 ls -lh logs/rsl_rl/ant/<你的run資料夾>/
 ```

 **checkpoint 參數說明**：`--checkpoint` 需傳**完整路徑**（或相對於目前目錄的可讀路徑），不能只寫 `model_999.pt`。指定某次訓練時，通常只需 `--load_run <資料夾名>`，會自動載入該 run 內最新的 `model_*.pt`。

 ### 方法一：X11 視窗即時觀看 play 推論（推薦）

 載入 checkpoint 後以 Isaac Sim 視窗即時播放 Ant 推論。**不要**加 `--headless`、`--video`、`--livestream`。

 主機先執行：
 ```bash
 xhost +local:docker
 ```

 容器內：
 ```bash
 cd /root/work/IsaacLab
 ./isaaclab.sh -p scripts/reinforcement_learning/rsl_rl/play.py \
   --task=Isaac-Ant-v0 \
   --num_envs 4 \
   --load_run 2026-07-01_13-57-04
 ```

 `--load_run` 填 `logs/rsl_rl/ant/` 下的訓練資料夾名（僅資料夾名，不含路徑）；不指定時會自動載入最新 run 的最新 `model_*.pt`。

 可能會跳出 Isaac Sim 視窗；Docker 內 X11 轉發較不穩定，但這是目前 **play.py 即時觀看最可靠** 的方式。容器內若出現 `carb.audio` 相關警告可忽略，不影響模擬。

 指定特定 checkpoint 檔時，請用完整路徑：
 ```bash
 --checkpoint logs/rsl_rl/ant/2026-07-01_13-57-04/model_999.pt
 ```

 ### 方法二：WebRTC 即時觀看（僅適用 start-isaac）

 **重要**：`start-isaac` + WebRTC Client 可正常顯示 Isaac Sim GUI；但 `play.py --livestream` 在 Isaac Lab v2.3.2 常見**連線成功卻灰畫面**（無 video 串流）。要看 Ant checkpoint 推論請用**方法一（X11）**或**方法三（錄影）**。

 `AppRun` 只會開啟 Client 視窗，**不會自動有畫面**；須等容器內 `start-isaac` 啟動完成後，在 Client 輸入 `127.0.0.1` 並按 **Connect**。

 **不要**與 `play.py` 同時執行（會搶 TCP 49100 / UDP 47998）。若用 `./run.sh` 開 Terminator，請先在上方面板 `Ctrl+C` 停掉 `start-isaac` 再跑 play，或反之。

 步驟（以 `start-isaac` 驗證 WebRTC / 手動操作 Sim 為主）：

 1. 容器內執行 `start-isaac`（等出現 `Isaac Sim Full Streaming App is loaded` 類似訊息後再連線）：
    ```bash
    start-isaac
    ```
 2. 主機開 WebRTC Client（見下方「在 local 端安裝 Isaac Sim WebRTC Streaming Client」）：
    ```bash
    cd ~/isaac_sim_ws/src/squashfs-root
    ./AppRun --no-sandbox
    ```
 3. Client 中 Server 填 `127.0.0.1`（`run.sh` 使用 `--network host`），按 **Connect**，等待數秒至數十秒。
 4. 若連上但黑畫面，在 Client 選單 **View → Reload**。

 **WebRTC 排查**（仍無畫面時）：

 * 確認 `start-isaac` 有在跑：`docker exec isaac-sim-webrtc pgrep -af runheadless`
 * 確認埠已監聽（在主機執行）：
   ```bash
   ss -tulnp | grep -E '49100|47998'
   ```
 * 若 `start-isaac` 可連但 `play.py --livestream 1` 灰畫面，屬已知現象，請改用**方法一（X11）**或**方法三（錄影）**。

 ### 方法三：錄影後播放（headless，無即時畫面）

 使用 `--headless --video` 在背景錄製 mp4，**不會**開啟 WebRTC 或 X11 視窗；錄完 `video_length` 步數後自動結束：

 ```bash
 cd /root/work/IsaacLab
 ./isaaclab.sh -p scripts/reinforcement_learning/rsl_rl/play.py \
   --task=Isaac-Ant-v0 \
   --headless \
   --video \
   --video_length 200 \
   --num_envs 16 \
   --load_run 2026-07-01_13-57-04
 ```

 影片路徑：`logs/rsl_rl/ant/2026-07-01_13-57-04/videos/play/rl-video-step-0.mp4`（主機對應 `src/isaac-lab-logs/rsl_rl/ant/...`）

 複製到主機掛載目錄：
 ```bash
 cp logs/rsl_rl/ant/<你的run資料夾>/videos/play/*.mp4 /root/work/src/
 ```

 ### 其他

 * 看訓練曲線（TensorBoard）：
   ```bash
   cd /root/work/IsaacLab
   ./isaaclab.sh -p -m tensorboard.main --logdir logs/rsl_rl/ant --bind_all
   ```
   瀏覽器開啟 `http://localhost:6006`
 * 使用官方預訓練模型（未自行訓練時）：
   ```bash
   ./isaaclab.sh -p scripts/reinforcement_learning/rsl_rl/play.py \
     --task=Isaac-Ant-v0 \
     --headless \
     --video \
     --use_pretrained_checkpoint \
     --num_envs 16
   ```

 * 使用 Ctrl+c 離開 docker 後，需要手動關閉 container，避免在背景中執行 Isaac sim
   ```bash
   docker stop isaac-sim-webrtc
   ```

  ## 單獨運行容器而不執行 Isaac sim
  ```bash
  docker exec -it isaac-sim-webrtc bash
  # docker exec 不會走 entrypoint，首次請手動：
  /root/work/src/docker/setup_beyondmimic.sh
  ```



  ## 在 local 端安裝 Isaac Sim WebRTC Streaming Client
  - 下載印象檔
      ```bash
      https://docs.isaacsim.omniverse.nvidia.com/5.0.0/installation/download.html
      ```
  - 更改下載的印象檔的權限
      ```bash
      chmod +x isaacsim-webrtc-streaming-client-1.1.4-linux-x64.AppImage
      ```
  - 執行
      ```bash
      ./isaacsim-webrtc-streaming-client-1.1.4-linux-x64.AppImage
      ```
      - 若是執行遇到問題（則需要安裝相關套件以及更改權限）
          ```bash
          sudo apt install libfuse2
          ```
          - 先把 AppImage 解開
              ```bash
              ./isaacsim-webrtc-streaming-client-1.1.4-linux-x64.AppImage --appimage-extract
              ```
          - 找到 chrome-sandbox
              ```bash
              cd squashfs-root
              find . -name chrome-sandbox
              ```
          - 改擁有者與權限
              ```bash
              sudo chown root:root chrome-sandbox
              sudo chmod 4755 chrome-sandbox
              ```
          - 啟動 Client
              ```bash
              ./AppRun
              ```