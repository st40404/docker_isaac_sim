# docker_isaac_sim

該 docker 環境是基於 Isaac sim 的 container 來進行封裝的


 * System
   - 

   ```bash
   $ chmod +x build.sh
   $ ./buils.sh
   $ chmod +x run.sh
   $ ./run.sh
   ```


 * Step1: 下載 Isaac Sim Docker 映像檔
   ```bash
   $ docker pull nvcr.io/nvidia/isaac-sim:5.1.0
   ```
 * Step2: 建立掛載資料夾
   ```bash
   $ mkdir -p ./docker/isaac-sim/cache/kit
   $ mkdir -p ./docker/isaac-sim/cache/ov
   $ mkdir -p ./docker/isaac-sim/cache/pip
   $ mkdir -p ./docker/isaac-sim/cache/glcache
   $ mkdir -p ./docker/isaac-sim/cache/computecache
   $ mkdir -p ./docker/isaac-sim/logs
   $ mkdir -p ./docker/isaac-sim/data
   $ mkdir -p ./docker/isaac-sim/documents
   ```
 * Step3: 編譯 Dockerfile
   ```bash
   $ ./build.sh
   ```
 * Step4: 執行 Isaac sim
   ```bash
   $ ./run.sh
   ```