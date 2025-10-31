En esta oportunidad todos los grupos deberán entregar la solución de bases de datos en MS
SQL Server.
Si la entrega incluye scripts o código fuente, el mismo DEBE estar organizado en un
proyecto/solución de SQL Server Management Studio. Solo se incluirán los archivos en la
versión actual correspondiente a la entrega, y aquellos que se requieran como dependencias
(no deben incluirse versiones anteriores). La solución debe llamarse “GrupoXX” donde XX es
el número del grupo.
Los scripts deben prepararse de tal forma que en cualquier entrega se pueda probar lo
requerido en la consigna. Por tanto, si para ello se deben crear objetos, dependencias, cargar
juegos de prueba, etc., los scripts deben incluir todo lo necesario.
Todos los archivos fuentes (de cualquier tipo) que se entreguen deben comenzar con un
comentario donde conste el enunciado (la parte que se está cumplimentando), fecha de
entrega, número de comisión, número de grupo, nombre de la materia, nombres y DNI de los
alumnos.
El código fuente de generación de objetos (tablas, vistas, store procedures, etc.) y el de
carga de datos iniciales (sea por importación o generación manual o aleatoria) debe estar
preparado para ser ejecutado por archivo, como un solo bloque. Esto significa que debe realizar las validaciones correspondientes para crear/eliminar objetos de forma que dos ejecuciones seguidas no generen datos duplicados ni mensajes de error por objetos
preexistentes.

Uso del repositorio

Cada grupo utilizará un repositorio en github, que generará uno de sus miembros. Todo aporte
al código fuente debe constar en el repositorio, individualizando el trabajo de cada alumno del
grupo. En el documento principal indiquen el Nick (o nombre de usuario) que cada alumno
utiliza en la plataforma github.
Cada grupo deberá incluir al docente asignado en el repositorio en GIT desde el mismo
comienzo del desarrollo. En el documento que acompañe la entrega tendrán que incluir un
enlace al repositorio para que podamos relacionar cada grupo con su repositorio.
Es VITAL que todos los cambios que realicen en el código fuente se registren en GITHUB.
Todos los alumnos componentes del grupo deben registrar todos los cambios en el mismo.
En el readme del repositorio también detallen los nombres de los integrantes del grupo junto
a su Nick (alias) para que podamos identificar a cada uno.
Para la entrega final deberán enviar un archivo comprimido (en formato ZIP, no se aceptará
ningún otro) con la totalidad del código fuente, incluyendo archivos de solución/proyecto. No
incluyan otros archivos -tales como los que les proveemos para importar- ni backups. No
exporten la totalidad de los archivos del repositorio.

Pautas para la denominación y creación de la base de datos

Cada grupo deberá generar una DB con un nombre distinto. Para ello usarán el nombre de la
comisión y del grupo como denominador de la DB. Por ejemplo “Com3900G02”. El formato
es ComXXXXGYY donde XXXX es el código de comisión e YY es el número de grupo con
cero a la izquierda de ser necesario.
Cada archivo SQL que contiene código fuente, sea de creación de componentes, carga o
testing, debe comenzar su nombre con dos dígitos indicando el orden en que deben
ejecutarse. Por ejemplo “00_CreacionSPImportacionCatalogo”. Estos archivos deben
entregarse (como todos los scripts) dentro de un proyecto/solución. Todos deben estar en el
repositorio git del grupo.
También debe presentar un archivo .sql que consista en las invocaciones a los SP creados
para generar la importación. Este archivo (que puede considerarse de testing) debe contener
comentarios para indicar el orden de ejecución.
Los scripts de testing también deben llamarse utilizando un número como prefijo de forma
que su invocación en orden se haga evidente.
Se recomienda revisar periódicamente el foro en Miel de la materia. En el mismo se informará
el agregado de información, pautas o dudas respecto al TP

EJEMPLO=
Grupo12
    00_CreacionDB.sql
    01_TablasPrincipales.sql
    02_SP_ImportarConsorcio.sql
    03_SP_ImportarUF.sql
    04_SP_ImportarPagos.sql
    05_Test_Importaciones.sql
