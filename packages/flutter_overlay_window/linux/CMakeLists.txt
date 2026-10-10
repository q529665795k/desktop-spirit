cmake_minimum_required(VERSION 3.14)
set(PACKAGE_NAME "flutter_overlay_window")

# Plugin library
add_library(${PACKAGE_NAME} SHARED
  flutter_overlay_window_plugin.cc
)

# Flutter dependencies
target_link_libraries(${PACKAGE_NAME} PRIVATE flutter)
target_include_directories(${PACKAGE_NAME} PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${FLUTTER_INCLUDE_DIR}
)

set_target_properties(${PACKAGE_NAME} PROPERTIES
  POSITION_INDEPENDENT_CODE TRUE
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED TRUE
)