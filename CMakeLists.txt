cmake_minimum_required(VERSION 3.16)

project(cake_calculator
    VERSION 1.0.0
    DESCRIPTION "Laboratory work 1, variant 18: Cake Calculator"
    LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GTKMM REQUIRED IMPORTED_TARGET gtkmm-3.0)

add_executable(cake_calculator src/main.cpp)
target_link_libraries(cake_calculator PRIVATE PkgConfig::GTKMM)

target_compile_options(cake_calculator PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall;-Wextra;-Wpedantic>)
