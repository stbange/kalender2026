# The pinned engine owns all WebSocket IO. Its native SDL stream needs a TLS filter for secure invites.
find_package(Git REQUIRED)
find_package(OpenSSL 1.1.1 REQUIRED)
set(engine_root "${CMAKE_CURRENT_SOURCE_DIR}/engine")
set(net_overlay "${CMAKE_CURRENT_BINARY_DIR}/native-engine")
set(net_patch "${CMAKE_CURRENT_SOURCE_DIR}/cmake/engine-native-network.patch")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${net_patch}")

file(GLOB engine_headers CONFIGURE_DEPENDS "${engine_root}/include/engine/*.h")
foreach(header IN LISTS engine_headers)
    get_filename_component(name "${header}" NAME)
    configure_file("${header}" "${net_overlay}/include/engine/${name}" COPYONLY)
endforeach()
configure_file("${engine_root}/src/eng_net.c" "${net_overlay}/src/eng_net.c" COPYONLY)
execute_process(
    COMMAND "${CMAKE_COMMAND}" -E env "GIT_CEILING_DIRECTORIES=${CMAKE_CURRENT_BINARY_DIR}"
            "${GIT_EXECUTABLE}" apply --no-index --whitespace=nowarn "${net_patch}"
    WORKING_DIRECTORY "${net_overlay}"
    COMMAND_ERROR_IS_FATAL ANY)

get_target_property(engine_sources libengine SOURCES)
list(REMOVE_ITEM engine_sources "${engine_root}/src/eng_net.c")
set_property(TARGET libengine PROPERTY SOURCES "${engine_sources}")
target_sources(libengine PRIVATE "${net_overlay}/src/eng_net.c" "${CMAKE_CURRENT_SOURCE_DIR}/src/eng_net_tls.c")
target_include_directories(libengine BEFORE PUBLIC "${net_overlay}/include")
target_include_directories(libengine PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
target_compile_definitions(libengine PRIVATE ENG_HAS_OPENSSL=1)
# The existing service can host six independent eight-player groups.
target_compile_definitions(libengine PUBLIC ENG_NET_MAX_CLIENTS=48)
target_link_libraries(libengine PRIVATE OpenSSL::SSL OpenSSL::Crypto)

if(HALL_COVERAGE)
    set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/src/eng_net_tls.c" TARGET_DIRECTORY libengine
        PROPERTIES COMPILE_OPTIONS "--coverage;-O0;-g")
endif()
