### CMakeLists automatically created with AutoVala
### Do not edit

project (tabletplayer)
cmake_minimum_required (VERSION 2.6)
cmake_policy (VERSION 2.8)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
enable_testing ()

option(BUILD_VALADOC "Build API documentation if Valadoc is available" OFF)

set(HAVE_VALADOC OFF)
if(BUILD_VALADOC)
	find_package(Valadoc)
	if(VALADOC_FOUND)
		set(HAVE_VALADOC ON)
		include(Valadoc)
	else()
		message("Valadoc not found, will not build documentation")
	endif()
endif()

find_package(PkgConfig)

pkg_check_modules(DEPS REQUIRED
	gdk-x11-3.0
	gstreamer-0.10
	glib-2.0
	gtk+-3.0
)

add_subdirectory(src)
add_subdirectory(po)
