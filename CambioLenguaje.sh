#!/bin/bash
#?ES-Espanol
#?EN-Inglés
#?FR-Francés


###############################################################################################
# AUTOR: Alberto Cuervo Prieto
# GRADO INGENIERÍA INFORMÁTICA AÑO 2023-24 || Asignatura Sistemas Operativos
#TUTOR: José Manuel Saiz Diez
################################################################################################
# Este script nos permite manejar las traducciones de los comentarios de los archivos .sh 
# de los subdirectorios, teniendo las opciones de:
# REFERENCIAR, CAMBIAR REFERENCIAS, RE-REFERENCIAR, AÑADIR Y ELIMINAR LENGUAJE
################################################################################################




# Nombre de este script
file_name="$0"

#Inicializamos el lenguaje actual de los scripts
actual_language="ES"

#Inicializamos el lenguaje al que vamos a cambiar los scripts
change_language="FR"

# Array inicial de idiomas
declare -a languages=()
declare -a full_languages=()

##################################################
# Función para guardar los idiomas en el archivo
##################################################

save_languages(){
	local inicio=2
	local i=0
	for save_lang in "${languages[@]}"; do
		sed -i "${inicio}i #?${save_lang}-${full_languages[i]}" "$file_name"
		#sed -i "${inicio}s/.*/#?${save_lang}/" "$file_name"
		((inicio++))
		((i++))	
	done
}


###################################
#Elimina los lenguajes guardados
###################################

clean_languages(){
	local inicio=2
	local i=0
	local max=${#languages[@]}
	for ((i=0; i<max; i++))
	do
		sed -i "${inicio}d" "${file_name}"
	done
}


####################################################
#Imprimir los lenguajes del sistema por pantalla
###################################################

print_languages(){

	echo -e "\nLenguajes en el sistema:"
	echo "${full_languages[@]}"

}

############################################################################################
#Escanear este archivo en busca de los idiomas guardados y actualizar los arrays de idiomas
############################################################################################

find_languages(){
    local comment
    local i=0
    declare -a found_languages

    # Leer línea por línea del archivo
    while IFS= read -r line; do
        # Buscar comentarios que comiencen con "#?" seguido de un espacio y luego el código de idioma
        if [[ $line =~ ^\s*#\?([A-Za-z]+) ]]; then
            # Extraer el código de idioma del comentario (sin el signo de interrogación)
            comment="${BASH_REMATCH[1]}"
            
            # Buscar el nombre completo del idioma
            full_language=$(grep -o "#?$(echo $comment)-[A-Za-z ]*" <<< "$line" | cut -d '-' -f 2)

            # Agregar el código de idioma y el nombre completo al array
            found_languages[$i]="$comment"
            full_languages[$i]="$full_language"
            ((i++))
        fi
    done < "$file_name"

	echo ""
    # Mostrar los idiomas encontrados
    echo "Idiomas encontrados:"
    echo "${full_languages[@]}"
    languages=("${found_languages[@]}")
    echo ""
    echo "-----------------------------------------------------------------------------------"
    echo ""
}



##########################################################################################################
# Función para mostrar los elementos del array languages con su índice para que el usuario los seleccione
##########################################################################################################

show_languages() {
    # Recorremos el array e imprimimos cada elemento con su índice
    echo -e "\nElige un idioma con su índice"
    for ((i = 0; i < ${#full_languages[@]}; i++)); do
        echo "$((i+1)): ${full_languages[$i]}"
    done
}

##################################
#Pantalla de inicio del programa
###################################

welcome_screen(){
	echo "_____________________________________________________________________________________"
	echo "PROGRAMA PARA REALIZAR TRADUCCIONES EN LOS CÓDIGOS DE GESTIÓN DE LOS SUBDIRECTORIOS"
	echo "VERSIÓN 3.1"
	echo "Autor: ALBERTO CUERVO PRIETO"
	echo "Tutor: JOSÉ MANUEL SÁIZ DIEZ"
	echo "Grado Ing. Informática (2023-2024)"
	echo "Universidad de Burgos"
	echo -e "_____________________________________________________________________________________\n\n"
}

###################################
# Función para mostrar el menú
##################################

show_menu() {
    echo ""
    echo "============================================================================================================="
    echo "1. Crear referencias en scripts ya comentados(Sin referencias) y sincronizar referencias de todos los idiomas"
    echo "2. Cambiar lenguaje de scripts ya referenciados"
    echo "3. Re-referenciar scripts (Reescribir números de las referencias)"
    echo "4. Añadir lenguaje"
    echo "5. Eliminar lenguaje"
    echo "6. Salir"
    echo "============================================================================================================="
}

#################################################################################################################
# Comprobamos la validez de los índices, se introducen por parámetro el lenguaje actual y al que queremos cambiar
# Parámetro1: lenguaje actual
# Parámetro2: lenguaje al que vamos a cambiar
#################################################################################################################

check_valid_data() {
    local j=$1
    local k=$2
    local total_languages=${#languages[@]}
    
    if [[ $j -gt 0 && $j -le $total_languages && $k -gt 0 && $k -le $total_languages ]]; then
        return 0 # Datos válidos
    else
        return 1 # Datos no válidos
    fi
}

########################################################################################################
# Añadimos referencias a los scripts y metemos los comentarios a su archivo de lenguaje correspondiente
# Parámetro1: directorio sobre el que están los archivos a re-referenciar
# Parámetro2: lenguaje actual
#########################################################################################################

change_comment_start() {
    local directory="$1"
    local language="$2"
    local num=10

    # Encuentra todos los archivos .sh dentro del directorio dado y sus subdirectorios
    find "$directory" -mindepth 2 -type f -name "*.sh" -print0 | while IFS= read -r -d '' file; do
        # Obtener el nombre base del archivo sin la extensión
        base_name=$(basename "$file" .sh)
        # Definir el archivo de salida
        output_file="./$(dirname "$file")/${language}${base_name}.txt"
        # Definir el archivo temporal
        temp_file=$(mktemp)

        echo "Creando referencias en $base_name"

        # Procesar el archivo, modificarlo y redirigir los comentarios modificados al archivo de salida
        awk -v num=10 -v language="$language" -v output_file="$output_file" '
        BEGIN {
            OFS = ""
            # Abrir el archivo de salida para escribir los comentarios modificados
            out = output_file
            print "" > out # Limpiar el archivo de salida
        }
        {
            if ($0 !~ /"[^"]*#[^"]*"/ && $0 !~ /\([^()#]*#[^()#]*\)/ && $0 !~ /{[^{}#]*#[^{}#]*}/ && $0 !~ /\[.*#.*\]/ && $0 !~ /{#/ && $0 ~ /#/ && $0 !~ /^#!/ && $0 !~ /##/) {
                if (index($0, "#") != 1) {
                    # Encuentra la posición del primer "#" en la línea
                    pos = index($0, "#")
                    # Modifica el comentario desde el "#" hacia la derecha
                    modified_comment = "#-" language num "-" substr($0, pos + 1)
                    $0 = substr($0, 1, pos - 1) "#-" language num "-" substr($0, pos + 1)
                } else {
                    # Modifica el comentario desde el inicio de la línea
                    modified_comment = "#-" language num "-" substr($0,1)
                    $0 = modified_comment
                }
                # Escribir el comentario modificado al archivo de salida
                print modified_comment > out
                # Reemplazar la línea actual con el comentario modificado
                num+=10
            }
            if($0!=""){
                print $0
            }
        }
        ' "$file" > "$temp_file"

        # Reemplazar el archivo original con el archivo temporal
        mv "$temp_file" "$file"

        echo "Referencias creadas y comentarios copiados al lenguaje $language"
    done
}

############################################################################################
#Copiamos los comentarios que tenemos en los scripts al fichero de lenguaje correspondiente
# Parámetro1: directorio en el que encontrar los archivos
# Parámetro2: lenguaje actual
#############################################################################################

copy_comments() {
    local directory="$1"
    local language="$2"

    # Encuentra todos los archivos .sh dentro del directorio dado y sus subdirectorios
    find "$directory" -mindepth 2 -type f -name "*.sh" -print0 | while IFS= read -r -d '' file; do
        # Obtener el nombre base del archivo sin la extensión
        base_name=$(basename "$file" .sh)
        # Definir el archivo de salida
        output_file="./$(dirname "$file")/${language}${base_name}.txt"
        # Definir el archivo temporal
        temp_file=$(mktemp)

        echo "Creando referencias en $base_name"

        # Procesar el archivo, modificarlo y redirigir los comentarios modificados al archivo de salida
        awk -v language="$language" -v output_file="$output_file" '
        BEGIN {
            OFS = ""
            # Abrir el archivo de salida para escribir los comentarios modificados
            out = output_file
            print "" > out # Limpiar el archivo de salida
        }
        {
            if ($0 ~ /#-/) {
                if (index($0, "#") != 1) {
                    # Encuentra la posición del primer "#" en la línea
                    pos = index($0, "#")
                    # Modifica el comentario desde el "#" hacia la derecha
                    modified_comment = "#"substr($0, pos + 1)
                } else {
                    # Modifica el comentario desde el inicio de la línea
                    modified_comment = substr($0,1)
                }
                # Escribir el comentario modificado al archivo de salida
                print modified_comment > out
                # Reemplazar la línea actual con el comentario modificado
            }
            if($0!=""){
                print $0
            }            
        }
        ' "$file" > "$temp_file"

        # Reemplazar el archivo original con el archivo temporal
        mv "$temp_file" "$file"

        echo "Referencias creadas y comentarios copiados al lenguaje $language"
    done
}


##################################################
# Función para realizar re-referenciado
# Parámetro1: lenguaje actual de re-referenciado 
##################################################

re_reference() {

	local lang=$1
	

	find "./" -mindepth 2 -type f -name "*.sh" -print0 | while IFS= read -r -d '' file; do
	    local current_value=10
	    local input_file=$file
	    local output=""
		echo "Reescribiendo referencias en $(basename "$file" .sh)"
	    # Leemos todo el archivo en memoria y lo procesamos línea por línea
	    while IFS= read -r line; do
	        # Verificamos si la línea coincide con el patrón de las referencias
	        if [[ $line =~ \#\-[[:upper:]][[:upper:]]([0-9]+)\- ]]; then
	        	patron="s/${lang}[0-9]\+-/${lang}${current_value}-/"
	            # Reemplazamos el número en la línea con el valor actual de la variable
	            line=$(echo "$line" | sed "$patron")
	            # Incrementamos la variable en 10
	            current_value=$((current_value + 10))
	        # Si es un comentario sin referencia se la añadimos
	        elif [[ ! $line =~ \"[^\"]*\#[^\"]*\" && ! $line =~ \([^()#]*#[^()#]*\) && ! $line =~ \{[^{}#]*#[^{}#]*\} && ! $line =~ \[.*#.*\] && ! $line =~ \{# && $line =~ \# && ! $line =~ ^\#!/ && ! $line =~ \#\# ]]; then
	        	patron="s/\#/\#\-${lang}${current_value}-/"
	        	line=$(echo "$line" | sed "$patron")
	        	current_value=$((current_value + 10))
	        fi
	        # Agregamos la línea al contenido que se va a escribir de nuevo al archivo
		       output+="$line"$'\n'
	    done < "$input_file"

	    # Escribimos todo el contenido procesado de vuelta en el archivo
	    echo -n "$output" > "$input_file"
	    
	    for lan in "${languages[@]}"; do
			base_name=$(basename "$file" .sh)
		    # Definir el archivo de salida
		    comments_file="./$(dirname "$file")/${lan}${base_name}.txt"
			local current_value=10
			local input_file=$comments_file
			local output=""
			
			# Leemos todo el archivo en memoria y lo procesamos línea por línea
			while IFS= read -r line; do
			    # Verificamos si la línea coincide con el patrón
			    if [[ $line =~ \#\- ]]; then
			    	patron="s/${lan}[0-9]\+-/${lan}${current_value}-/"
			        # Reemplazamos el número en la línea con el valor actual de la variable
			        line=$(echo "$line" | sed "$patron")
			        # Incrementamos la variable en 10
			        current_value=$((current_value + 10))
			    fi
			    # Agregamos la línea al contenido que se va a escribir de nuevo al archivo
				   output+="$line"$'\n'
			done < "$input_file"
			# Escribimos todo el contenido procesado de vuelta en el archivo
	    	echo -n "$output" > "$input_file"
		done
	    
	done
	
	

    
}

##############################################################################################################
# Definimos la función para reemplazar comentarios, copiamos los comentarios de un archivo de lenguaje y los pegamos en el script
# Parámetro1: directorio sobre el que realizar la búsqueda de archivos 
# Parámetro2: lenguaje actual 
##############################################################################################################


replace_comments() {
    local directory="$1"
    local language="$2"
    local num=1

    # Encuentra todos los archivos .sh dentro del directorio dado y sus subdirectorios
    find "$directory" -mindepth 2 -type f -name "*.sh" -print0 | while IFS= read -r -d '' file; do
        # Obtener el nombre base del archivo sin la extensión
        base_name=$(basename "$file" .sh)
        # Definir el archivo de salida
        comments_file="./$(dirname "$file")/${language}${base_name}.txt"
        temp_file="$(mktemp)"

        echo "Cambiando comentarios en $base_name al idioma $language"

        # Procesar el archivo, modificarlo y redirigir los comentarios modificados a un archivo temporal
        awk -v num=1 -v temp_file="$temp_file" -v language="$language" -v comments_file="$comments_file" '
        BEGIN {
            OFS = ""
            # Inicializar el contador de líneas
            num = 0
            # Leer el archivo de comentarios y almacenar cada línea en un elemento del array
            while ((getline < comments_file) > 0) {
                num++
                comments_array[num] = $0
            }
            close(comments_file)
            num = 2
        }
        {
            if ($0 ~ /#-/) {
                if (index($0, "#") != 1) {
                    # Encuentra la posición del primer "#" en la línea
                    pos = index($0, "#")
                    # Modifica el comentario desde el "#" hacia la derecha
                    modified_comment = comments_array[num]
                    $0 = substr($0, 1, pos - 1) modified_comment
                } else {
                    # Modifica el comentario desde el inicio de la línea
                    modified_comment = comments_array[num]
                    $0 = modified_comment
                }
                # Reemplazar la línea actual con el comentario modificado
                num++
            }
            if($0!=""){
            	print $0
            }
        }
        ' "$file" > "$temp_file"

        # Mover el archivo temporal al archivo original
        mv "$temp_file" "$file"
    done
}

###################################################
# Función que crea los archivos de lenguaje vacíos
# Parámetro1: lenguaje actual
###################################################

create_reference_files() {
        
    local lang=$1
    # Crear el archivo de salida para cada lenguaje
    contador=10
    
    # Encontrar y procesar los archivos
    find "./" -mindepth 2 -type f -name "*.sh" -print0 | while IFS= read -r -d '' file; do
    	contador=10
        echo "Procesando archivo: $(basename "$file")"
        echo "" > "./$(dirname "$file")/$lang$(basename "$file" .sh).txt"    
            # Leer cada línea del archivo y verificar si contiene "#-"
        while IFS= read -r line; do
            if [[ $line == *"#-"* ]]; then
                    echo "#-$lang$contador-" >> "./$(dirname "$file")/$lang$(basename "$file" .sh).txt"
                ((contador+=10))
            fi
        done < "$file"
    done
    echo "Creados los archivos de lenguaje vacíos en el idioma $lang"  
}


#############################################################################################################
# Función para comparar y sincronizar referencias en archivos de diferentes idiomas con el introducido por parámetro a la función
# Parámetro1: lenguaje actual
#############################################################################################################

sync_references() {
    local lang="$1"
    echo ""
    echo "Sincronizando referencias (Esto puede tardar algún minuto)"
    find "./" -mindepth 2 -type f -name "*.sh" -print0 | while IFS= read -r -d '' file; do
        for languag in "${languages[@]}";do
			local contador=0
			echo "$(basename "$file" .sh) en $languag"
			# Leer cada línea del archivo de entrada y compararlo
			while IFS= read -r linea; do
				
				local numero=$(echo "$linea" | grep -oP "#-${lang}\K\d+")
				if [ "$lang" != "$languag" ] && ! grep -q "#-$languag$numero-" "./$(dirname "$file")/$languag$(basename "$file" .sh).txt" && [ -n "$numero" ]; then

					sed -i "${contador}a\\#-${languag}${numero}-" "./$(dirname "$file")/${languag}$(basename "$file" .sh).txt"
					
				fi
				((contador++))
			done < "./$(dirname "$file")/$lang$(basename "$file" .sh).txt"
		done
    done

}

################################################
# Función para verificar si el idioma es válido
# Parámetro1: lenguaje introducido
################################################

validate_language() {
    local lang="$1"
    # Verifica si la longitud del idioma es exactamente 2 caracteres
    if [ ${#lang} -eq 2 ]; then
        # Verifica si el idioma está en mayúsculas
        if [[ "$lang" == [A-Z][A-Z] ]]; then
            return 0  # El idioma es válido
        else
            return 1  # El idioma no está en mayúsculas
        fi
    else
        return 1  # El idioma no tiene 2 caracteres
    fi
}

###############################################
# Con esta función añadimos un nuevo lenguaje
###############################################

add_language() {
    read -p "Ingrese el nuevo idioma en mayúsculas (2 caracteres): " new_lang
    read -p "Ingrese el nombre completo del idioma: " new_full_lang
    # Verifica si el nuevo idioma es válido
    if validate_language "$new_lang"; then
        # Agrega el nuevo idioma al array
        clean_languages
        languages+=("$new_lang")
        full_languages+=("$new_full_lang")
        save_languages
        create_reference_files "$new_lang"
        echo "¡Idioma '$new_full_lang' añadido con éxito!"
        find_languages
        
        
    else
        echo "Error: El idioma debe estar en mayúsculas y tener exactamente 2 caracteres."
    fi
}

#####################################
# Función para eliminar un lenguaje
#####################################

delete_language() {
    show_languages
    read -p "Ingrese el idioma a eliminar " j
    k=1
    if check_valid_data "$j" "$k" ; then
		del_lang=${languages[$((j-1))]}
		clean_languages
		new_languages=()
		for lang in "${languages[@]}"; do
			if [ "$lang" != "$del_lang" ]; then
			    new_languages+=("$lang")
			fi
		done
		languages=("${new_languages[@]}")
		
		del_full_lang=${full_languages[$((j-1))]}
		new_full_languages=()
		for full_lang in "${full_languages[@]}"; do
			if [ "$full_lang" != "$del_full_lang" ]; then
			    new_full_languages+=("$full_lang")
			fi
		done
		full_languages=("${new_full_languages[@]}")
		
		save_languages
		find_languages
	else
		echo "Introduce datos válidos"
	fi
}


find_languages
welcome_screen

#Creamos archivos VACÍOS de idioma si no existen
echo -e "\nCOMPROBAMOS SI EXISTEN ARCHIVOS DE IDIOMA, EN CASO NEGATIVO CREAMOS LOS ARCHIVOS -->>>>VACÍOS<<<<--\n"
for lang in "${languages[@]}"; do
    # Comprobar si existe al menos un fichero .txt que inicie con el idioma actual
	if ls ./*/"${lang}"*.txt 1> /dev/null 2>&1; then
	    echo "Existen archivos .txt que comienzan con $lang"
	else
	    echo "No existen archivos .txt que comiencen con $lang"
	    create_reference_files "$lang" 
	fi
done

# Bucle principal del menú
while true; do
    print_languages
    show_menu
    read -p "Seleccione una opción: " option
    case $option in
        1) 
        show_languages 
        read -p "¿Cuál es el lenguaje actual? " j
        k=1
        if  check_valid_data "$j" "$k" ; then
			actual_language=${languages[$((j-1))]}
			change_comment_start "./" "$actual_language"
			sync_references "$actual_language"
		else
			echo "Introduce datos válidos"
		fi
        ;;
        
        2) 
        show_languages 
        read -p "¿Cuál es el lenguaje actual? " j
		read -p "¿Cuál es el lenguaje al que quieres cambiar? " k

		if check_valid_data "$j" "$k"; then
			actual_language=${languages[$((j-1))]}
			change_language=${languages[$((k-1))]}
			copy_comments "./" "$actual_language"
		    sync_references "$actual_language" 
		    replace_comments "./" "$change_language"    
		else
			echo "Introduce datos válidos"
		fi


        ;;
        3) 
        show_languages 
        read -p "¿Cuál es el lenguaje actual? " j
        k=1
        if  check_valid_data "$j" "$k" ; then
			actual_language=${languages[$((j-1))]}
			re_reference "$actual_language"
		else
			echo "Introduce datos válidos"
		fi    
        ;;
        
        4) add_language "ES";;
        5) delete_language;;
        6) echo -e "\nSaliendo..."; break ;;
        
        *) echo "Opción no válida";;
    esac
    clear
done
