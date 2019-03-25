#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void){
	FILE *archivo_a_leer;
	FILE *archivo_a_escribir;
	
	char *renglon_leido;
	int contador;
	
	renglon_leido = malloc(sizeof(char) * 256);
	
	if(renglon_leido == NULL){
		perror("Error en malloc");
		exit(EXIT_FAILURE);
	}
	
	archivo_a_leer = fopen("recordings_rata.txt", "r+");
	
	if(archivo_a_leer == NULL){
		perror("Error abriendo archivo a leer");
		exit(EXIT_FAILURE);
	}
	
	archivo_a_escribir = fopen("recordings_rata_ok.txt", "w");
	
	if(archivo_a_escribir == NULL){
		perror("Error creando el archivo a escribir");
		exit(EXIT_FAILURE);
	}
	
	contador = 0;
	
	do{
		renglon_leido = fgets(renglon_leido, 256, archivo_a_leer);
		
		if((contador % 2 == 0) && contador != 0){
			// Renglones que me importan
			renglon_leido[strlen(renglon_leido) - 5] = '\n';
			renglon_leido[strlen(renglon_leido) - 4] = '\0';
			
			if(fputs(renglon_leido, archivo_a_escribir) == EOF){
				perror("Error escribiendo en archivo");
				
				free(renglon_leido);
				
				fclose(archivo_a_leer);
				fclose(archivo_a_escribir);
				
				exit(EXIT_FAILURE);
			}
		}
		
		contador++;
		contador %= 4;
	}while(renglon_leido != NULL);
	
	free(renglon_leido);
	
	fclose(archivo_a_leer);
	fclose(archivo_a_escribir);
	
	return 0;
}
