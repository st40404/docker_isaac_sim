# 該 docker 環境是基於 Isaac sim 的 container 來進行封裝的

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
   ```
 * Step3: 編譯 Dockerfile （包裝下載的 container: nvcr.io/nvidia/isaac-sim:5.1.0）
   ```bash
   ./build.sh
   ```
 * Step4: 執行 Isaac sim
   ```bash
   ./run.sh
   ```

  ## 單獨運行容器而不執行 Isaac sim
  ```bash
  docker exec -it isaac-sim-webrtc bash
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