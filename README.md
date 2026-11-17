# nvblox_docker

nvblox（NVIDIA Isaac ROS の GPU による 3D 再構成）で、走行しながら地図（メッシュ）を作って RViz2 で表示するコンテナ。
点群と TF は Gazebo（コンテナ `20261002`）と自己位置推定（コンテナ `test`）が出すものを使う。

- Isaac ROS 4.6（Ubuntu 24.04・ROS 2 Jazzy・CUDA 13.2）。他のコンテナ（Humble）とは DDS で通信する。
- 自分でビルドするコードは無い。設定（launch・パラメータ・RViz）はホストの `config/` をコンテナの `/root/nvblox/config` に割り当てる。

（作成中。使い方は段階 3 で書く）
