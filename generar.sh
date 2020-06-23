#!/bin/bash

if [ -f *.pdf ]; then

echo -e "\n\e[91mNota: Debe haber solo un archivo PDF en este directorio\n\e[39m"

PS3='Seleccionar una opcion: '

options=("Continuar" "Cancelar")

select opt in "${options[@]}"
do
    case $opt in
        "Continuar")
	 break
            ;;
        "Cancelar")
            exit
            ;;
        *) echo Invalido;;
    esac
done
echo -e "\n"

read -p "Ingresar nombre del directorio de la revista: " name

if [ -d "../$name" ]; then
 echo -e "\n\e[91mEl directorio ya existe!\n\e[39m"

   PS3='¿Sobreescribir/cancelar?: '

   options=("Sobreescribir" "Cancelar")

   select opt in "${options[@]}"
   do
       case $opt in
           "Sobreescribir")
            break
            ;;
           "Cancelar")
            exit
            ;;
           *) echo Inválido;;
       esac
   done
fi

rm -rf revista_nueva/pages
mkdir revista_nueva/pages

#echo -e "\e[91m \e[39m"

echo -e "\n\e[44mPaso 1: Extrayendo...\e[49m\n"
# Ver si queda bien bajar a density 150, para que sean mas livianos los archivos "large"

#convert -verbose -quality 100 -scene 1 -density 200 *.pdf -set colorspace RGB  -colorspace RGB revista_nueva/pages/%d.jpg 
#convert -verbose -quality 100 -scene 1 -density 200 -colorspace CMYK *.pdf -colorspace CMYK -modulate 150,100,111 revista_nueva/pages/%d.jpg 
convert -verbose -quality 100 -scene 1 -density 200 -colorspace CMYK *.pdf -colorspace CMYK revista_nueva/pages/%d.jpg 
#convert -verbose -quality 100 -scene 1 -density 200 *.pdf -modulate 100,100,111 revista_nueva/pages/%d.jpg 

find  revista_nueva/pages -type f -name '*.jpg' -print0 | while IFS= read -r -d '' f; do
  cp -v -- "$f" "${f%.jpg}-large.jpg"
done

echo -e "\n\e[44mPaso 2: Generando imagenes grandes...\e[49m\n"

mogrify -verbose  -format jpg -quality 100 -geometry x1500 revista_nueva/pages/*large*.jpg


echo -e "\n\e[44mPaso 3: Generando imagenes tamaño medio...\e[49m\n"

# hacer imagenes de tamaño medio
# mogrify -resize 50% revista_nueva/pages/*.jpg

find  revista_nueva/pages -iregex '^.*[0-9]\.jpg' -print0 | while IFS= read -r -d '' f; do
#   mogrify -resize 50% "$f"
mogrify -verbose  -format jpg -quality 100 -geometry x650 "$f"
done

echo -e "\n\e[44mPaso 4: Generando miniaturas...\e[49m\n"

echo -e "   \e[34mcopiando...\e[39m"
find  revista_nueva/pages -iregex '^.*[0-9]\.jpg' -print0 | while IFS= read -r -d '' f; do
  cp -- "$f" "${f%.jpg}-thumb.jpg"
done

echo -e "   \e[34mredimensionando...\e[39m"
mogrify -verbose  -format jpg -quality 100 -geometry x100 revista_nueva/pages/*thumb*.jpg


echo -e "\n\e[44mPaso 5: Generando preview para slider...\e[49m\n"

archivos="revista_nueva/pages/1-thumb.jpg"
i=2
while [ -f "revista_nueva/pages/$i-thumb.jpg" ]
  do
    archivos+=" revista_nueva/pages/$i-thumb.jpg"
    ((i++))
  done
montage -verbose -geometry 56x+0+0 -tile 2x $archivos -colorspace RGB -background '#fff' revista_nueva/pages/preview.jpg

echo -e "\n\e[42mPaso 6: Conversion completa.\e[49m\n"

#rm -rf ../revista_nueva
rm -rf ../$name

#chown -R apache:apache revista_nueva
chown -R apache:apache revista_nueva
chmod -R 755 revista_nueva

cp -ra revista_nueva ../$name
cp -ra *.pdf "../$name/$name.pdf"

rm -f revista_nueva/pages/*

echo -e "\e[34mUbicacion de la revista actual:\e[39m \n
/sitio/institucional/difusion/publicaciones/$name\n"
echo -e "\e[94mhttp://www.ing.unlp.edu.ar/sitio/institucional/difusion/publicaciones/$name \e[39m\n"
else
    echo -e "\e[91mNo se encuentra ningun archivo PDF, o hay mas de uno \e[39m"
fi
