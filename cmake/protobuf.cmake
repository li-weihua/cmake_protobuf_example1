# Downloads and builds a given protobuf version, generating a protobuf target
# with the include dir and binaries imported
include(ExternalProject)

macro(configure_protobuf VERSION PROTOBUF_NAMESPACE)
    set(protobufPackage "protobuf-cpp-${VERSION}.tar.gz")
    set(Protobuf_PKG_URL "https://github.com/google/protobuf/releases/download/v${VERSION}/${protobufPackage}")
    set(Protobuf_INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR})
    set(Protobuf_TARGET third_party.protobuf)

    set(PROTOBUF_CFLAGS "-Dgoogle=${PROTOBUF_NAMESPACE}")
    set(PROTOBUF_CXXFLAGS "-Dgoogle=${PROTOBUF_NAMESPACE}")

    ExternalProject_Add(${Protobuf_TARGET}
        PREFIX ${Protobuf_TARGET}
        URL ${Protobuf_PKG_URL}
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ${CMAKE_COMMAND} ${Protobuf_INSTALL_DIR}/${Protobuf_TARGET}/src/${Protobuf_TARGET}/cmake
            -G${CMAKE_GENERATOR}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON
            -DCMAKE_C_FLAGS=${PROTOBUF_CFLAGS}
            -DCMAKE_CXX_FLAGS=${PROTOBUF_CXXFLAGS}
            -DCMAKE_INSTALL_PREFIX=${Protobuf_INSTALL_DIR}/${Protobuf_TARGET}
            -Dprotobuf_BUILD_TESTS=OFF
            -Dprotobuf_BUILD_EXAMPLES=OFF
            -Dprotobuf_WITH_ZLIB=OFF
        SOURCE_SUBDIR cmake
        BINARY_DIR ${Protobuf_INSTALL_DIR}/${Protobuf_TARGET}/src/${Protobuf_TARGET}
    )

    set(Protobuf_BIN_DIR "${CMAKE_BINARY_DIR}/${Protobuf_TARGET}/bin")
    find_file (CENTOS_FOUND centos-release PATHS /etc)
    if (CENTOS_FOUND)
        set(Protobuf_LIB_DIR "${CMAKE_BINARY_DIR}/${Protobuf_TARGET}/lib64")
    else (CENTOS_FOUND)
        set(Protobuf_LIB_DIR "${CMAKE_BINARY_DIR}/${Protobuf_TARGET}/lib")
    endif (CENTOS_FOUND)
    set(Protobuf_INCLUDE_DIR "${CMAKE_BINARY_DIR}/${Protobuf_TARGET}/include")
    set(Protobuf_INCLUDE_DIRS "${CMAKE_BINARY_DIR}/${Protobuf_TARGET}/include")
    set(Protobuf_PROTOC_EXECUTABLE  "${Protobuf_BIN_DIR}/protoc")
    if (CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(Protobuf_LIBRARY "${Protobuf_LIB_DIR}/libprotobufd.a")
        set(Protobuf_PROTOC_LIBRARY "${Protobuf_LIB_DIR}/libprotocd.a")
        set(Protobuf_LITE_LIBRARY "${Protobuf_LIB_DIR}/libprotobuf-lited.a")
    else()
        set(Protobuf_LIBRARY "${Protobuf_LIB_DIR}/libprotobuf.a")
        set(Protobuf_PROTOC_LIBRARY "${Protobuf_LIB_DIR}/libprotoc.a")
        set(Protobuf_LITE_LIBRARY "${Protobuf_LIB_DIR}/libprotobuf-lite.a")
    endif()
    set(protolibType STATIC)

    add_library(protobuf::libprotobuf ${protolibType} IMPORTED)
    set_target_properties(protobuf::libprotobuf PROPERTIES
        IMPORTED_LOCATION "${Protobuf_LIBRARY}"
    )

    add_library(protobuf::libprotobuf-lite ${protolibType} IMPORTED)
    set_target_properties(protobuf::libprotobuf-lite PROPERTIES
        IMPORTED_LOCATION "${Protobuf_LITE_LIBRARY}"
    )

    add_library(protobuf::libprotoc ${protolibType} IMPORTED)
    add_dependencies(protobuf::libprotoc ${Protobuf_TARGET})
    set_target_properties(protobuf::libprotoc PROPERTIES
        IMPORTED_LOCATION "${Protobuf_PROTOC_LIBRARY}"
    )

    add_executable(protobuf::protoc IMPORTED)
    add_dependencies(protobuf::protoc ${Protobuf_TARGET})
    set_target_properties(protobuf::protoc PROPERTIES
        IMPORTED_LOCATION "${Protobuf_PROTOC_EXECUTABLE}"
    )

    add_library(Protobuf INTERFACE)
    target_include_directories(Protobuf INTERFACE "${Protobuf_INCLUDE_DIR}")
    target_link_libraries(Protobuf INTERFACE protobuf::libprotobuf)
    message(STATUS "Using libprotobuf ${Protobuf_LIBRARY}")
endmacro()


# protobuf_generate function
function(protobuf_generate)
    include(CMakeParseArguments) # Needed only for CMake 3.4 and earlier
    set(_singleargs LANGUAGE OUT_VAR)
    set(_multiargs PROTOS)
    cmake_parse_arguments(protobuf_generate "" "${_singleargs}" "${_multiargs}" "${ARGN}")

    set(protobuf_extensions)
    if(protobuf_generate_LANGUAGE STREQUAL cpp)
        set(protobuf_extensions .pb.h .pb.cc)
    elseif(protobuf_generate_LANGUAGE STREQUAL python)
        set(protobuf_extensions _pb2.py)
    endif()

    set(generated_srcs_all)

    foreach(proto ${protobuf_generate_PROTOS})
        get_filename_component(PROTO_NAME "${proto}" NAME_WLE)
        get_filename_component(PROTO_DIR "${proto}" DIRECTORY)

        file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${PROTO_DIR})
        message(STATUS ${CMAKE_CURRENT_BINARY_DIR})

        set(PROTOBUF_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/${PROTO_DIR}")
        set(PROTO_ABS_FILE "${CMAKE_CURRENT_SOURCE_DIR}/${proto}")
        set(PROTO_INCLUDE_PATH "-I${CMAKE_CURRENT_SOURCE_DIR}/${PROTO_DIR}")

        set(generated_srcs)
        foreach(ext ${protobuf_extensions})
            list(APPEND generated_srcs "${PROTOBUF_OUTPUT_DIR}/${PROTO_NAME}${ext}")
        endforeach()
        list(APPEND generated_srcs_all ${generated_srcs})
        message("generated_srcs: ${generated_srcs}")

        add_custom_command(
            OUTPUT ${generated_srcs}
            COMMAND LIBRARY_PATH=${Protobuf_LIB_DIR} ${Protobuf_PROTOC_EXECUTABLE}
            ARGS --${protobuf_generate_LANGUAGE}_out  ${PROTOBUF_OUTPUT_DIR} ${PROTO_INCLUDE_PATH} ${PROTO_ABS_FILE}
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
            DEPENDS ${PROTO_ABS_FILE} protobuf::libprotobuf Protobuf protobuf::protoc
            COMMENT "Running ${protobuf_generate_LANGUAGE} protocol buffer compiler on ${proto}"
            VERBATIM
          )
    endforeach()
    set_source_files_properties(${generated_srcs_all} PROPERTIES GENERATED TRUE)
    set(${protobuf_generate_OUT_VAR} ${generated_srcs_all} PARENT_SCOPE)
endfunction()


function(protobuf_generate_cpp SRCS HDRS)
    set(proto_files "${ARGN}")
    set(proto_output_files)
    protobuf_generate(LANGUAGE cpp OUT_VAR proto_output_files PROTOS ${proto_files})

    set(SOURCES)
    set(HEADERS)
    foreach(_file ${proto_output_files})
        if(_file MATCHES "cc$")
          list(APPEND SOURCES ${_file})
        else()
          list(APPEND HEADERS ${_file})
        endif()
    endforeach()
    set(${SRCS} ${SOURCES} PARENT_SCOPE)
    set(${HDRS} ${HEADERS} PARENT_SCOPE)
endfunction()


function(protobuf_generate_python PROTO_PY)
    set(proto_files "${ARGN}")
    set(proto_output_files)
    protobuf_generate(LANGUAGE python OUT_VAR proto_output_files PROTOS ${proto_files})
    set(${PROTO_PY} ${proto_output_files} PARENT_SCOPE)
endfunction()
