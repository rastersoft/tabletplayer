### CMakeLists automatically created with AutoVala
### Do not edit

file(GLOB list_data RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *)
foreach(file_data ${list_data})
	IF(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${file_data})
		install(DIRECTORY
			${file_data}
		DESTINATION
			share/doc/tabletplayer
		)
	ELSE()
		install(FILES
			${file_data}
		DESTINATION
			share/doc/tabletplayer
		)
	ENDIF()
endforeach()

