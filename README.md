# InventorySystem

Sistema de inventario desarrollado en **Godot 4.4.1** como parte de un proyecto de videojuego de mayor escala.

Por motivos de desarrollo y protección del proyecto principal, sus diferentes sistemas están siendo desarrollados y presentados de forma independiente. Este repositorio contiene únicamente el "Sistema de Inventario", aislado del resto de sistemas del juego.

Objetivo

El objetivo de este proyecto es desarrollar un sistema de inventario modular, escalable y reutilizable, capaz de gestionar diferentes tipos de objetos y sus propiedades sin depender directamente de la lógica específica del juego principal.

El sistema está diseñado para permitir la incorporación progresiva de nuevas funcionalidades, objetos y reglas de inventario manteniendo una estructura organizada y fácil de mantener.

# Características

Actualmente, el sistema se encuentra en desarrollo.

Entre sus objetivos se encuentran:

* Gestión de objetos del inventario.
* Definición de objetos mediante recursos `.tres`.
* Separación entre los datos de los objetos y la lógica del inventario.
* Interfaz para visualizar los objetos disponibles.
* Sistema preparado para incorporar diferentes tipos de objetos.
* Arquitectura modular para facilitar futuras ampliaciones.
* Posibilidad de integrar el sistema posteriormente con otros sistemas del juego principal.

# Arquitectura

El sistema busca mantener una separación clara entre:

Datos de los objetos
        ↓
Recursos (.tres)
        ↓
Sistema de inventario
        ↓
Interfaz de usuario

Los objetos se almacenan como recursos independientes, permitiendo modificar sus propiedades sin necesidad de modificar directamente la lógica principal del inventario.

Esta separación facilita la reutilización de los objetos y permite ampliar el sistema sin reconstruir su estructura fundamental.

# Recursos

Los objetos del inventario utilizan recursos de Godot (`.tres`) para almacenar sus datos.

Esto permite que cada objeto pueda tener sus propias propiedades y que nuevos objetos puedan crearse sin necesidad de crear un script independiente para cada uno.

# Estado del proyecto

En desarrollo. Este repositorio representa una implementación progresiva del sistema. Algunas funcionalidades pueden encontrarse en fase de prototipo y serán reemplazadas o ampliadas a medida que avance el desarrollo.

# Roadmap

* [x] Estructura inicial del proyecto
* [x] Recursos `.tres` para objetos
* [ ] Sistema base de inventario
* [ ] Gestión de slots
* [ ] Interfaz de inventario
* [ ] Interacción con objetos
* [ ] Sistema de selección
* [ ] Sistema de equipamiento
* [ ] Integración con otros sistemas
* [ ] Optimización y limpieza

# Tecnologías

Godot 4
GDScript
Godot Resources (`.tres`)

# Nota

Este proyecto se encuentra en desarrollo activo. La arquitectura y algunas funcionalidades pueden cambiar a medida que se realicen pruebas y se incorporen nuevos sistemas.
