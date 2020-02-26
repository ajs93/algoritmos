# Algoritmos GIBIO

Algoritmos varios para el GIBIO

-------------------------------------------------------------------------------------------------------------------

THI (Threshold Independent):
Algoritmo implementado basado en el artículo "Threshold-Independent QRS Detection Using the Dynamic Plosion Index - A. G. Ramakrishnan ; A. P. Prathosh ; T. V. Ananthapadmanabha".

Hay versiones con mejoras implementadas, basadas en estadística y las debilidades propias del algoritmo (el algoritmo siempre asume que en la ventana temporal de análisis existe un complejo QRS, siendo un causante de muchos falsos positivos).

-------------------------------------------------------------------------------------------------------------------

AIP (Arbitrary Impulsive Pseudo Periodic detector) también llamado:
VDoPPP (Versatile Detector of Pseudo Periodic Patterns):
Algoritmo basado en un matched filter y estadística robusta para la detección no únicamente de complejos QRS, sino también patrones en otros tipos de señales como pueden ser señales de presión de sangre y ECGs de naturalezas ajenas a seres humanos, en particular, roedores.

Los scripts quedaron con el nombre "aip".

El algoritmo fue presentado en el congreso Computing in Cardiology (CinC) - 2018: http://www.cinc.org/archives/2018/pdf/CinC2018-379.pdf

-------------------------------------------------------------------------------------------------------------------

Ambos algoritmos fueron diseñados para poder ser utilizados con el ECG-Kit: https://marianux.github.io/ect-kit/
