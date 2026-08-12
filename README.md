# InventorySystem

Sistema de inventario desarrollado en Godot 4.4.1 como parte de un proyecto de videojuego de mayor escala.

Por motivos de desarrollo, experimentación y protección del proyecto principal, sus diferentes sistemas están siendo desarrollados y presentados de forma independiente.

Este repositorio contiene únicamente el Sistema de Inventario, aislado del resto de sistemas del juego.

El objetivo es construir un inventario modular y reutilizable que pueda evolucionar progresivamente desde un prototipo funcional hasta un sistema completo de gestión de objetos.

# Objetivo

El objetivo de este proyecto es desarrollar un sistema de inventario modular, escalable y reutilizable, capaz de gestionar diferentes tipos de objetos, sus propiedades y sus estados sin depender directamente de la lógica específica del juego principal.

El sistema está diseñado para permitir la incorporación progresiva de:

* nuevos objetos;
* diferentes tamaños;
* categorías;
* equipamiento;
* consumibles;
* combinaciones;
* estados individuales;
* sonidos;
* interacción entre objetos;
* diferentes inventarios.

La arquitectura busca mantener separadas la información de los objetos, la lógica del inventario y su representación visual.

# Concepto

El inventario utiliza una cuadrícula basada en casillas de:

16 × 16 píxeles

Actualmente existen dos espacios principales:

PlayerInventory
8 × 8 casillas
128 × 128 píxeles

y:

ExternalInventory
16 × 16 casillas
256 × 256 píxeles

Los objetos pueden ocupar una o varias casillas dependiendo de sus dimensiones.

Por ejemplo:

1 × 1
2 × 1
1 × 2
2 × 2
4 × 4

Esto permite representar objetos de diferentes tamaños dentro de una misma cuadrícula.

# Características

El sistema se encuentra en desarrollo, pero actualmente contempla o está preparado para las siguientes funcionalidades:

# Inventario

* Inventario basado en cuadrícula.
* Inventario de personaje de 8 × 8.
* Inventario externo de 16 × 16.
* Objetos de diferentes tamaños.
* Detección de espacio disponible.
* Colocación y eliminación de objetos.
* Movimiento de objetos.
* Transferencia entre inventarios.

# Interacción

* Drag & Drop.
* Preview de colocación.
* Detección de posiciones válidas e inválidas.
* Rotación de objetos.
* Cámara libre.
* Pan mediante botón central del mouse.
* Zoom mediante rueda del mouse.

# Objetos

* Recursos `.tres` para definir objetos.
* Iconos independientes.
* Categorías de objetos.
* Slots de equipamiento.
* Descripciones.
* Sonidos asociados.
* Estado individual mediante `ItemInstance`.

# Combinaciones

El sistema permite diseñar recetas de combinación entre objetos.

Por ejemplo:

Jam + Bread
     ↓
Bread with Jam

Jam + Ham
     ↓
Ham with Jam

Jam + Health Potion
     ↓
Health Potion with Jam

Jam + Ring
     ↓
Jam Ring

Las combinaciones se mantienen separadas de la lógica principal del grid.

# Equipamiento

Los objetos equipables pueden asignarse a diferentes slots, como:

HEAD
CHEST
LEFT_ARM
RIGHT_ARM

Una característica importante del sistema es que equipar un objeto no lo elimina del inventario.

Por ejemplo:

Inventory

Sword
Shield
Helmet

puede coexistir con:

Equipment

RIGHT_ARM → Sword
LEFT_ARM  → Shield
HEAD       → Helmet

La misma instancia del objeto permanece dentro del inventario y es referenciada por el sistema de equipamiento.

# Consumibles

Los objetos consumibles pueden utilizarse desde el menú contextual.

Ejemplos:

Bread
Ham
Health Potion
Water

Los objetos pueden tener uno o varios usos.

El estado de consumo pertenece a la instancia individual del objeto, no al recurso `.tres`.

# Water

El objeto `Water` utiliza un sistema de tres consumos.

Una instancia nueva comienza con:

3 / 3

Después del primer consumo:

2 / 3

Después del segundo:

1 / 3

Después del tercero:

0 / 3

Cuando llega a cero, la instancia se consume completamente y desaparece del inventario.

La cantidad restante se representa mediante una barra visual utilizando:

WaterBar1.png
WaterBar2.png
WaterBar3.png

El estado pertenece a `ItemInstance`, permitiendo que diferentes botellas puedan tener cantidades independientes.

Por ejemplo:

Water A → 3 / 3
Water B → 2 / 3
Water C → 1 / 3

# Controles

Los controles principales del prototipo son:

| Acción                     | Control                              |
| -------------------------- | ------------------------------------ |
| Seleccionar / mover objeto | Botón izquierdo                      |
| Menú contextual            | Botón derecho                        |
| Rotar objeto               | `R`                                  |
| Mover cámara               | Botón central + movimiento del mouse |
| Zoom                       | Rueda del mouse                      |

El sistema está diseñado para que la cámara y el zoom afecten únicamente a la representación visual y no modifiquen la lógica de las cuadrículas.

# Rotación

Los objetos que permiten rotación pueden girarse mediante:

R

durante el Drag & Drop.

Cada pulsación gira el objeto 90°.

Por ejemplo:

2 × 1

puede convertirse en:

1 × 2

La rotación modifica el `Placement` del objeto y no altera el recurso `.tres`.

# Menú contextual

El botón derecho permite acceder a las acciones disponibles para cada objeto.

Las opciones dependen de sus propiedades y estado.

Un objeto equipable puede mostrar:


Equipar        
Combinar       

Un objeto ya equipado:


Desequipar     
Combinar       


Un consumible:


Usar           
Combinar       


Esto permite ampliar posteriormente el menú con acciones adicionales sin modificar la lógica fundamental del inventario.

# Arquitectura

El sistema busca mantener una separación clara entre:

Datos
  ↓
Instancias
  ↓
Lógica
  ↓
Interfaz

Una representación simplificada de la arquitectura es:

ItemData
   │
   ↓
ItemInstance
   │
   ├──────────────→ InventoryGrid
   │                     │
   │                     ↓
   │                  ItemUI
   │
   ├──────────────→ EquipmentSystem
   │
   └──────────────→ Consumable System


ItemData
   │
   ↓
CombinationData
   │
   ↓
InventoryCombiner

Cada sistema tiene una responsabilidad específica.

# ItemData

`ItemData` contiene la información estática de un objeto.

Entre sus propiedades pueden encontrarse:

item_id
icon
size_x
size_y
category
equip_slot
description
inventory_sound

Esta información se almacena mediante recursos `.tres`.

Un mismo `ItemData` puede utilizarse para crear múltiples instancias del mismo tipo de objeto.

# ItemInstance

`ItemInstance` representa una instancia concreta de un objeto durante la ejecución del juego.

Esto permite separar:

ItemData

de:

Estado runtime

Por ejemplo:

Water.tres
    ↓
Water Instance A → 3/3
Water Instance B → 1/3

Ambas instancias utilizan el mismo recurso base, pero poseen estados independientes.

Esto también permite ampliar posteriormente el sistema con características como:

* durabilidad;
* munición;
* usos restantes;
* estados especiales;
* propiedades únicas.

# InventoryGrid

`InventoryGrid` es responsable de la lógica espacial del inventario.

Entre sus responsabilidades se encuentran:

* determinar qué casillas están ocupadas;
* comprobar si un objeto puede colocarse;
* colocar objetos;
* eliminar objetos;
* mover objetos;
* rotar objetos;
* encontrar posiciones disponibles;
* controlar las dimensiones de los objetos.

La lógica del grid trabaja con casillas y no depende directamente de la representación visual.

Por esta razón, el zoom o el movimiento de cámara no afectan al funcionamiento interno del inventario.

# InventoryUI

`InventoryUI` representa visualmente un `InventoryGrid`.

Sus responsabilidades principales incluyen:

* representar el fondo;
* mostrar objetos;
* convertir posiciones de pantalla a casillas;
* convertir casillas a posiciones visuales;
* actualizar la interfaz;
* gestionar la representación de los objetos.

La interfaz no debe convertirse en la fuente de verdad del inventario.

# ItemUI

`ItemUI` representa visualmente una `ItemInstance`.

Puede mostrar:

* icono;
* tamaño;
* rotación;
* preview;
* indicador de equipamiento;
* barra de agua;
* información relacionada con el objeto.

Los cambios visuales deben derivarse del estado real de la instancia.

# InventoryCombiner

Las combinaciones se mantienen separadas del `InventoryGrid`.

El sistema utiliza datos de recetas para determinar:

Objeto A + Objeto B
        ↓
    Resultado

Esto permite añadir nuevas combinaciones sin introducir condiciones específicas dentro del código principal del inventario.

# EquipmentSystem

`EquipmentSystem` mantiene los objetos actualmente equipados.

Los slots funcionan conceptualmente como:

HEAD
CHEST
LEFT_ARM
RIGHT_ARM

El sistema mantiene referencias a las mismas `ItemInstance` que existen en el inventario.

Por tanto:

InventoryGrid
       │
       └── Sword Instance
               │
               └── EquipmentSystem.RIGHT_ARM

No se crea una segunda instancia para representar el objeto equipado.

# Consumibles

Los consumibles utilizan el estado runtime de `ItemInstance`.

El flujo general es:

RMB
 ↓
Usar
 ↓
Validar objeto
 ↓
Consumir
 ↓
Actualizar estado
 ↓
Actualizar UI
 ↓
Si llega a 0
 ↓
Eliminar instancia

Los efectos específicos de gameplay se podrán conectar posteriormente.

Esto permite que el sistema de inventario permanezca independiente de sistemas como:

* salud;
* hambre;
* sed;
* estadísticas;
* combate.

# Audio

Los objetos pueden tener sonidos asociados mediante `inventory_sound`.

Actualmente se contemplan los siguientes sonidos:

| Archivo                 | Uso                                       |
| ----------------------- | ----------------------------------------- |
| `cloth-inventory.wav`   | Escudo, arco                              |
| `leather_inventory.wav` | Pan, jamón, explosivo, poción, Jam, huevo |
| `metal-clash.wav`       | Armadura y espadas                        |
| `ring_inventory.wav`    | Anillos                                   |
| `turn_page.wav`         | Libro                                     |
| `sell_buy_item.wav`     | Reservado para futuras funciones          |

Los archivos de audio forman parte de los recursos del proyecto y no se generan dinámicamente.

# Recursos de objetos

Los objetos se almacenan como recursos independientes:

res://inventory/data/

Cada recurso `.tres` puede definir las características de un objeto sin necesidad de crear un script independiente.

Esto facilita añadir nuevos objetos.

Conceptualmente:

Sword.tres
Shield.tres
Bread.tres
Water.tres
...

Cada recurso puede utilizar un icono diferente y tener propiedades propias.

# Organización del proyecto

La estructura principal sigue una separación por responsabilidad:

inventory/
├── data/
│   ├── items/
│   └── combinations/
│
├── logic/
│   └── inventory_grid.gd
│
└── ui/
    ├── inventory_ui.gd
    ├── item_ui.gd
    └── inventory_demo.gd

Los recursos gráficos y de audio se mantienen separados:

sprites/
SFX/

La estructura puede evolucionar a medida que se incorporen nuevos módulos.

# Principios de diseño

El sistema sigue varios principios:

# Separación de responsabilidades

El grid no controla el equipamiento.

El equipamiento no controla la posición del objeto.

La UI no es la fuente de verdad.

Las recetas no están codificadas directamente dentro del grid.

# Estado independiente

Los datos estáticos se almacenan en `ItemData`.

Los estados individuales se almacenan en `ItemInstance`.

# No duplicación

Una instancia de objeto representa un único objeto real dentro del inventario.

Equiparlo no crea una copia.

# Extensibilidad

Los sistemas están diseñados para poder conectarse posteriormente con otros sistemas del videojuego sin depender directamente de ellos.

# Estado del proyecto

El proyecto se encuentra en **desarrollo activo**.

La implementación actual representa una etapa de prototipo y arquitectura inicial. Algunas partes pueden cambiar mientras se realizan pruebas y se incorporan nuevas funcionalidades.

La prioridad actual es conseguir un sistema funcional y estable antes de integrarlo con el proyecto principal.

# Roadmap

# Base

* [x] Estructura inicial del proyecto
* [x] Recursos `.tres` para objetos
* [x] Separación entre datos y lógica
* [x] Inventario de personaje 8 × 8
* [x] Inventario externo 16 × 16
* [x] Fondos de inventario
* [x] `InventoryGrid`

# Interacción

* [x] Movimiento de objetos
* [x] Drag & Drop
* [x] Rotación
* [x] Preview de colocación
* [x] Transferencia entre inventarios
* [x] Cámara libre
* [x] Pan
* [x] Zoom

# Objetos

* [x] `ItemData`
* [x] `ItemInstance`
* [x] Iconos
* [x] Categorías
* [x] Descripciones
* [x] Sonidos asociados

# Combinaciones

* [x] Sistema de recetas
* [x] Menú contextual
* [x] Modo de combinación
* [x] Resultados de combinación
* [x] Validación de espacio
* [x] Combinaciones atómicas

# Equipamiento

* [x] Slots de equipamiento
* [x] Equipar objetos
* [x] Desequipar objetos
* [x] Reemplazar objetos equipados
* [x] Mantener objetos equipados dentro del inventario
* [x] Indicador visual de equipamiento

# Consumibles

* [x] Acción `Usar`
* [x] Usos individuales mediante `ItemInstance`
* [x] Eliminación al llegar a cero
* [x] Water con 3 usos
* [x] Barra visual de Water
* [ ] Implementación de efectos de gameplay
* [ ] Integración con sistemas de salud/hambre/sed

# Futuro

* [ ] Integración con el proyecto principal
* [ ] Integración con combate
* [ ] Integración con estadísticas
* [ ] Sistema de armas
* [ ] Sistema de durabilidad
* [ ] Sistema de munición
* [ ] Sistema de tiendas
* [ ] Optimización
* [ ] Limpieza final de arquitectura
* [ ] Pruebas automatizadas

# Tecnologías

* Godot 4.4.1
* GDScript
* Godot Resources (`.tres`)
* Pixel Art
* Node2D / Control
* Camera2D

# Filosofía del proyecto

Este repositorio no pretende ser solamente una demostración visual de un inventario.

El objetivo es desarrollar una base que pueda utilizarse posteriormente dentro de un proyecto de mayor escala.

La prioridad es mantener una arquitectura sencilla pero suficientemente flexible para incorporar nuevas mecánicas sin convertir el sistema en una colección de dependencias difíciles de mantener.

El inventario debe encargarse del inventario.

El equipamiento debe encargarse del equipamiento.

Las combinaciones deben encargarse de las combinaciones.

Y los datos de los objetos deben permanecer separados de la lógica que los utiliza.

# Estado actual

> Development / Prototype

El proyecto continúa evolucionando y algunas decisiones arquitectónicas pueden cambiar durante el desarrollo.

Las funcionalidades marcadas como completadas representan sistemas implementados o integrados en el prototipo actual; las funcionalidades pendientes forman parte de las siguientes etapas de desarrollo.

# Créditos y Atribución

* [Inventory Sound Effects](https://opengameart.org/content/inventory-sound-effects) por 'artisticdude' (subido por Ogrebane), disponible en OpenGameArt.org bajo licencia [CC-BY 3.0](https://creativecommons.org/licenses/by/3.0/).
  * Tipo: Efecto de sonido
  * Modificaciones: Ninguna
