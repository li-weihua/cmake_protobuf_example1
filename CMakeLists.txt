cmake_minimum_required(VERSION 3.18)

project(Test LANGUAGES CXX)

if (NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 14)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_EXTENSIONS OFF) # do not use gnu extension
endif()

option(BUILD_PYTHON_PROTO "whether compile python proto" OFF)

set(PROTOBUF_NAMESPACE "google_private")

add_compile_options("-Dgoogle=${PROTOBUF_NAMESPACE}")

set(DEFAULT_PROTOBUF_VERSION 3.14.0)
if (NOT DEFINED PROTOBUF_VERSION)
    set(PROTOBUF_VERSION ${DEFAULT_PROTOBUF_VERSION})
endif()

include(cmake/protobuf.cmake)
configure_protobuf(${PROTOBUF_VERSION} ${PROTOBUF_NAMESPACE})

add_subdirectory(proto)

add_executable(run main.cc)

target_include_directories(run PUBLIC "${CMAKE_BINARY_DIR}")

target_link_libraries(run PUBLIC data_proto)
