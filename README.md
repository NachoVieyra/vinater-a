# Vinatería SUI 🍷

Este proyecto es un contrato inteligente (smart contract) para la blockchain de Sui, desarrollado en el lenguaje Move. Simula el backend de una vinatería, permitiendo a un administrador gestionar productos y a los usuarios comprarlos de forma segura y descentralizada.

## 📜 Descripción General

El contrato establece un sistema simple pero robusto para la venta de bienes digitales. Se definen dos roles principales:

1.  **Administrador (Admin):** Es la dirección que despliega el contrato. Recibe una capacidad especial (`AdminCap`) que le otorga permisos exclusivos para crear nuevos productos y retirar las ganancias de la tienda.
2.  **Comprador (Usuario):** Cualquier usuario de la red Sui que puede comprar los productos ofrecidos por el administrador.

El flujo de trabajo es seguro y transparente: los fondos de las ventas se almacenan en un objeto compartido (`CajaRegistradora`) y solo el admin puede retirarlos.

## ✨ Cómo Funciona

El contrato se basa en tres objetos (structs) principales:

* `AdminCap`: Un objeto de capacidad que funciona como una "llave de administrador". Es intransferible y se requiere para ejecutar funciones privilegiadas.
* `CajaRegistradora`: Un objeto compartido que actúa como la tesorería de la tienda. Guarda todos los fondos (`SUI`) recaudados de las ventas. Al ser compartido, cualquier función puede interactuar con él para depositar dinero.
* `Producto`: Representa un artículo en venta. Contiene un nombre, descripción y precio. A diferencia de otros modelos de tiendas, en este contrato **los productos son acuñados y poseídos por el admin** antes de ser transferidos directamente al comprador durante la venta.

## 🚀 Cómo Usarlo (Guía de Comandos)

A continuación se detallan los pasos para desplegar e interactuar con el contrato usando la Sui CLI.

### Prerrequisitos

* Tener la [Sui CLI](https://docs.sui.io/guides/developer/getting-started/sui-install) instalada.
* Tener una dirección con SUI en la red deseada (Testnet, Mainnet).

### Paso 1: Desplegar el Contrato

Navega a la raíz de tu proyecto en la terminal y ejecuta:

```bash
sui client publish --gas-budget 100000000 --json
```

Este comando compilará y desplegará tu contrato. La salida en formato `--json` es muy importante. Deberás guardar los siguientes IDs de los objetos creados:

* **Package ID:** La dirección de tu paquete de contratos.
* **AdminCap ID:** El ID del objeto `AdminCap` que te pertenece.
* **CajaRegistradora ID:** El ID del objeto compartido `CajaRegistradora`.

### Paso 2: Agregar un Producto (Como Admin)

Solo el poseedor del `AdminCap` puede crear nuevos productos. El producto creado será enviado a la wallet del admin.

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module tienda \
  --function agregar_producto \
  --args <ADMIN_CAP_ID> "Vino Cosecha Especial" "Tinto de uva Merlot, 750ml" 2000000000 \
  --gas-budget 50000000
```

* Reemplaza `<PACKAGE_ID>` y `<ADMIN_CAP_ID>` con los tuyos.
* Los argumentos son: nombre, descripción y precio en MIST (en el ejemplo, `2000000000` MIST = 2 SUI).
* De la salida de esta transacción, **guarda el ID del `Producto` creado**.

### Paso 3: Comprar un Producto

Para comprar, un usuario debe interactuar con el producto que el admin posee. El comprador proporciona el pago y recibe el `Producto` a cambio.

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module tienda \
  --function comprar_producto \
  --args <PRODUCTO_ID> <CAJA_REGISTRADORA_ID> <COIN_ID_PARA_PAGAR> \
  --gas-budget 50000000
```

* `<PRODUCTO_ID>`: El ID del vino que el admin creó.
* `<CAJA_REGISTRADORA_ID>`: El ID del objeto compartido.
* `<COIN_ID_PARA_PAGAR>`: El ID de un objeto `Coin<SUI>` que el comprador usará para pagar.

### Paso 4: Retirar Fondos de la Tienda (Como Admin)

El admin puede retirar todas las ganancias acumuladas en la `CajaRegistradora`.

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module tienda \
  --function retirar_fondos \
  --args <ADMIN_CAP_ID> <CAJA_REGISTRADORA_ID> \
  --gas-budget 50000000
```

Los fondos serán transferidos como un nuevo objeto `Coin<SUI>` a la wallet del admin.

## 📁 Estructura del Módulo `vinateria::tienda`

* **Structs:**
    * `AdminCap`: Capacidad de administrador.
    * `CajaRegistradora`: Tesorería compartida.
    * `Producto`: Objeto que representa un artículo.
* **Entry Functions:**
    * `agregar_producto`: Para que el admin cree nuevos productos.
    * `comprar_producto`: Para que los usuarios adquieran un producto.
    * `retirar_fondos`: Para que el admin recolecte las ganancias.
