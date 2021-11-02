if (BUILD_PYTHON_PROTO)
    protobuf_generate_python(PROTO_PY data.proto)
    add_custom_target(dump_python_proto_target ALL DEPENDS ${PROTO_PY})
    add_custom_command(TARGET dump_python_proto_target POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy ${PROTO_PY} ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS 
    person.proto
    score.proto
    value.proto
)

add_library(data_proto STATIC ${PROTO_SRCS} ${PROTO_HDRS})
target_include_directories(data_proto PUBLIC ${Protobuf_INCLUDE_DIRS})
target_link_libraries(data_proto PUBLIC protobuf::libprotobuf)
