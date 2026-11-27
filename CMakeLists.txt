cmake_minimum_required(VERSION 3.14)
project(StorageUiPlugin LANGUAGES CXX)

if(DEFINED ENV{LOGOS_MODULE_BUILDER_ROOT})
    include($ENV{LOGOS_MODULE_BUILDER_ROOT}/cmake/LogosModule.cmake)
else()
    message(FATAL_ERROR "LogosModule.cmake not found. Set LOGOS_MODULE_BUILDER_ROOT.")
endif()

# The plugin entry point is generated from metadata.json.
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/metadata.json" METADATA_JSON)
string(JSON MODULE_NAME GET ${METADATA_JSON} name)

logos_module(
    NAME ${MODULE_NAME}
    REP_FILE src/StorageBackend.rep
    SOURCES
        src/StorageBackend.h
        src/StorageBackend.cpp
    INCLUDE_DIRS
        src
    FIND_PACKAGES
        Qt6Network
    LINK_LIBRARIES
        Qt6::Network
)

# Expose the UI version (from metadata.json) to StorageBackend at compile time.
string(REGEX MATCH "\"version\"[ \t]*:[ \t]*\"([^\"]+)\"" _ "${METADATA_JSON}")
target_compile_definitions(${MODULE_NAME}_module_plugin PRIVATE STORAGE_UI_VERSION="${CMAKE_MATCH_1}")

