#Nombre del script: Interval renamer
#Creador: Rolando Muñoz
#Correo: rolando.muar@gmail.com
#Creación: enero-2017
#Descripción: Agrega un reporte de intensidad a la tabla principal
form Intensity_report
    comment Sound folder directory
    sentence sd_folder 
endform

tableID = selected("Table")

#Configurar tabla
Append column: "intensity_minimun"
Append column: "intensity_maximun"
Append column: "intensity_difference"
Append column: "intensity_mean"

#Crear tabla con resumen de valores de la columna file
tablePooledID= Collapse rows: "file", "", "", "", "", ""

#Lecturar variables del  archivo settings.txt

for iRow to Object_'tablePooledID'.nrow
    tg_className$ = Object_'tablePooledID'$[iRow, "file"]
    sd_name$ = (tg_className$ - "TextGrid") + "wav"
    sd_directory$ = sd_folder$ + "/" +sd_name$
    #Abrir archivos de sonido
    soundID = Read from file: sd_directory$
    intensityID = To Intensity: 100, 0, "yes"
    
    for jRow to Object_'tableID'.nrow
        tg_name$ = Object_'tableID'$[jRow, "file"]
        if tg_name$ == tg_className$
            tmin = Object_'tableID'[jRow, "start"]
            tmax = Object_'tableID'[jRow, "end"]
            selectObject: intensityID
            intensity_min = Get minimum: tmin, tmax, "Parabolic"
            intensity_max = Get maximum: tmin, tmax, "Parabolic"
            intensity_difference = intensity_max - intensity_min 
            intensity_mean = Get mean: tmin, tmax, "dB"
            selectObject: tableID
            Set numeric value: jRow, "intensity_minimun", round(intensity_min)
            Set numeric value: jRow, "intensity_maximun", round(intensity_max)
            Set numeric value: jRow, "intensity_difference", round(intensity_difference)
            Set numeric value: jRow, "intensity_mean", round(intensity_mean)
        endif
    endfor
    removeObject: soundID, intensityID
endfor
removeObject: tablePooledID
