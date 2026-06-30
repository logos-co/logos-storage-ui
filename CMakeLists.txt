cmake_minimum_required(VERSION 3.14)
project(StorageUiPlugin LANGUAGES CXX)

if(DEFINED ENV{LOGOS_MODULE_BUILDER_ROOT})
    include($ENV{LOGOS_MODULE_BUILDER_ROOT}/cmake/LogosModule.cmake)
else()
    message(FATAL_ERROR "LogosModule.cmake not found. Set LOGOS_MODULE_BUILDER_ROOT.")
endif()

logos_module(
    NAME storage_ui
    REP_FILE src/StorageBackend.rep
    SOURCES
        src/StorageInterface.h
        src/StorageUIPlugin.h
        src/StorageUIPlugin.cpp
        src/StorageBackend.h
        src/StorageBackend.cpp
    FIND_PACKAGES
        Qt6Network
    LINK_LIBRARIES
        Qt6::Network
)

# Expose the UI version (from metadata.json) to StorageBackend at compile time.
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/metadata.json" _ui_metadata)
string(REGEX MATCH "\"version\"[ \t]*:[ \t]*\"([^\"]+)\"" _ "${_ui_metadata}")
target_compile_definitions(storage_ui_module_plugin PRIVATE STORAGE_UI_VERSION="${CMAKE_MATCH_1}")
