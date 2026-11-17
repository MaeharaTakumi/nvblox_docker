"""走行しながら nvblox で地図（メッシュ）を作って表示する（nvblox_node と rviz2）。

起動：ros2 launch /root/nvblox/config/nvblox.launch.py env:=gazebo rviz:=true
  env  ：param/<env>/params.yaml を選び、nvblox_node と rviz2 の両方に渡す（既定 gazebo）
  rviz ：rviz2 を起動するか（既定 true）
nvblox_node は nvblox_ros の実行ファイル（ros2 pkg executables nvblox_ros に nvblox_node がある）で起動する。
"""
import os

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.conditions import IfCondition
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch_ros.actions import Node

# ---------- 定数 ----------
CONFIG_DIR = os.path.dirname(os.path.realpath(__file__))   # このファイルの場所（/root/nvblox/config）
DEFAULT_ENV = 'gazebo'                                     # 環境（param/<env>/）の既定
DEFAULT_RVIZ = 'true'                                      # rviz2 を起動するかの既定
PARAM_DIR = 'param'                                        # 環境ごとのパラメータのフォルダ
PARAM_FILE = 'params.yaml'                                 # 環境のパラメータ（nvblox_node・rviz2 の節）
RVIZ_CONFIG = os.path.join(CONFIG_DIR, 'rviz', 'nvblox.rviz')
CLOUD_TOPIC = '/velodyne_points'                           # nvblox_node の pointcloud の付け替え先
NVBLOX_PKG = 'nvblox_ros'
NVBLOX_EXEC = 'nvblox_node'
NVBLOX_NODE = 'nvblox_node'                                # params.yaml の節の名前と同じにする
RVIZ_NODE = 'rviz2'                                        # 同上


def generate_launch_description():
    """launch の記述を返す。入力：launch 引数 env・rviz。
    出力：nvblox_node と（rviz:=true なら）rviz2 を起動する LaunchDescription。"""
    env = LaunchConfiguration('env')
    rviz = LaunchConfiguration('rviz')
    params = PathJoinSubstitution([CONFIG_DIR, PARAM_DIR, env, PARAM_FILE])

    return LaunchDescription([
        DeclareLaunchArgument('env', default_value=DEFAULT_ENV,
                              description='環境の名前（param/<env>/params.yaml を使う）'),
        DeclareLaunchArgument('rviz', default_value=DEFAULT_RVIZ,
                              description='rviz2 を起動するか'),
        Node(package=NVBLOX_PKG, executable=NVBLOX_EXEC, name=NVBLOX_NODE,
             parameters=[params], remappings=[('pointcloud', CLOUD_TOPIC)], output='screen'),
        Node(package='rviz2', executable='rviz2', name=RVIZ_NODE,
             arguments=['-d', RVIZ_CONFIG], parameters=[params], output='screen',
             condition=IfCondition(rviz)),
    ])
