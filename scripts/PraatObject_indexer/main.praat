include ./../lib_preferences.proc
include lib_indexer.proc

###################################################################################
#Lecturar variables

beginPause: "Warning"
     comment: "If you continue, you'll lost your progress. Are you sure?"
clicked = endPause: "Yes", "No", 1

if clicked = 2
    exitScript()
endif

###Establecer direcciones de los archivos de la carpeta .preferences
folder_dir_preference$ = "./../../.preferences/"
file_dir_index$ = folder_dir_preference$ + "TextGrid_index.txt"
file_dir_index_backup$ = folder_dir_preference$ + "TextGrid_index_backup.txt"
file_dir_preferences$ = folder_dir_preference$ + "preferences.txt"
file_dir_stops$ = folder_dir_preference$ + "target_stops.txt"
file_dir_phrases$ = folder_dir_preference$ + "target_phrases.txt"

##Desde archivos temporales
@lib_preference.preferences_get_field_content_from: file_dir_preferences$, "textGrid_folder_dir"
tg_folder$ = lib_preference.preferences_get_field_content_from.return$

@lib_preference.preferences_get_field_content_from: file_dir_preferences$, "sound_folder_dir"
sd_folder$ = lib_preference.preferences_get_field_content_from.return$

@lib_preference.preferences_get_field_content_from: file_dir_preferences$, "phone_tier"
phone_tier = number(lib_preference.preferences_get_field_content_from.return$)

@lib_preference.preferences_get_field_content_from: file_dir_preferences$, "word_tier"
word_tier = number(lib_preference.preferences_get_field_content_from.return$)

@lib_preference.preferences_get_field_content_from: file_dir_preferences$, "code_tier"
code_tier = number(lib_preference.preferences_get_field_content_from.return$)

@lib_preference.preferences_get_field_content_from: file_dir_preferences$, "phoneme_b_forms"
phoneme_b$ = lib_preference.preferences_get_field_content_from.return$

@lib_preference.preferences_get_field_content_from: file_dir_preferences$, "phoneme_d_forms"
phoneme_d$ = lib_preference.preferences_get_field_content_from.return$

@lib_preference.preferences_get_field_content_from: file_dir_preferences$, "phoneme_g_forms"
phoneme_g$ = lib_preference.preferences_get_field_content_from.return$

if fileReadable(file_dir_index_backup$)
    deleteFile: file_dir_index_backup$
endif
if fileReadable(file_dir_index$)
    deleteFile: file_dir_index$
endif

#Crear tabla donde se vacearán los datos
tableID = Create Table with column names: "table", 0, "key_value speaker file code word_orth previous_pause phone_transcribed tmin tmax"

#Abrir los archivos tg uno por uno
stringsID = Create Strings as file list: "fileList", tg_folder$ + "/*.TextGrid"
nStrings = Get number of strings
for iString to nStrings
    selectObject: stringsID
    tg_name$ = Get string: iString
    sd_name$ = (tg_name$ - ".TextGrid") + ".wav"
    if endsWith(tg_name$, "09.TextGrid")
        goto CONTINUE
    endif
    tg_fullname$ = tg_folder$+"/"+tg_name$
    sd_fullname$ = sd_folder$+"/"+sd_name$
    if fileReadable(tg_fullname$) and fileReadable(sd_fullname$)
        #Crear index
        runScript: "indexer_index.praat", tg_fullname$, file_dir_stops$, file_dir_phrases$, phone_tier, word_tier, code_tier, phoneme_b$, phoneme_d$, phoneme_g$

        tableID_temp = selected("Table")
        tableID_main = tableID
        plusObject: tableID_main
        tableID = Append
        removeObject: tableID_temp, tableID_main
        endif
    label CONTINUE
endfor

removeObject: stringsID
selectObject: tableID

#Realizar arreglos para compatibilizar con el script Finder
Append column: "tmid"
Formula: "tmid", "self[""tmin""] + (self[""tmax""] - self[""tmin""])/2"
Formula: "file", "self$[""file""] + "".TextGrid"""
Set column label (label): "tmin", "start"
Set column label (label): "tmax", "end"
Rename: "TextGrid_index"
Remove column: "speaker"
Remove column: "code"
Remove column: "word_orth"

##Guardar tabla
selectObject: tableID
Save as tab-separated file: file_dir_index$
removeObject: tableID

#Juntar tablas
runScript: "indexer_join_tables.praat", file_dir_index$, file_dir_stops$, "key_value"

#Generar reporte de intensidad
runScript: "indexer_intensity_report.praat", sd_folder$

#Reordenar columnas
runScript: "indexer_organize_columns.praat"
@lib_indexer.add_check_column
Save as tab-separated file: file_dir_index$

#Mensaje final
beginPause: "Index" 
comment: "The index has been built successfully."
clicked = endPause: "Continue", 1
