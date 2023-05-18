cmake_minimum_required(VERSION 2.8.3)
project(at_r2_bringup)

find_package(catkin REQUIRED COMPONENTS 
)

catkin_package(
  CATKIN_DEPENDS 
)

install(DIRECTORY config
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/config
)

install(DIRECTORY launch
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/launch
)

