module vinateria::tienda {
    // --- Imports con Sintaxis Explícita ---
    use sui::object;
    use sui::transfer;
    use sui::tx_context;
    use sui::balance;
    use sui::coin;
    use sui::sui;

    // --- Errores ---
    const EPrecioIncorrecto: u64 = 1;
    const ECajaVacia: u64 = 2;

    // --- Objetos (Structs) ---

    /// Capacidad que solo el dueño de la tienda posee.
    public struct AdminCap has key, store {
        id: object::UID
    }

    /// Objeto compartido que guarda las ganancias de la tienda.
    public struct CajaRegistradora has key, store {
        id: object::UID,
        fondos: balance::Balance<sui::SUI>
    }

    /// Representa un producto (ej. una botella de vino).
    public struct Producto has key, store {
        id: object::UID,
        nombre: vector<u8>,
        descripcion: vector<u8>,
        precio: u64
    }

    // --- Funciones ---

    /// Se ejecuta una sola vez al desplegar el contrato.
    fun init(ctx: &mut tx_context::TxContext) {
        // 1. Crear la capacidad de admin y enviarla al desplegador.
        transfer::public_transfer(
            AdminCap { id: object::new(ctx) },
            tx_context::sender(ctx)
        );

        // 2. Crear la CajaRegistradora y compartirla para que todos la puedan usar.
        transfer::share_object(
            CajaRegistradora {
                id: object::new(ctx),
                fondos: balance::zero()
            }
        );
    }

    /// ENTRY: Permite al admin agregar un nuevo producto.
    /// El producto se transfiere al admin, quien se convierte en su dueño.
    public entry fun agregar_producto(
        _cap: &AdminCap,
        nombre: vector<u8>,
        descripcion: vector<u8>,
        precio: u64,
        ctx: &mut tx_context::TxContext
    ) {
        let producto = Producto {
            id: object::new(ctx),
            nombre,
            descripcion,
            precio
        };
        // Se transfiere al admin en lugar de compartirse.
        transfer::public_transfer(producto, tx_context::sender(ctx));
    }

    /// ENTRY: Permite a un usuario comprar un producto.
    public entry fun comprar_producto(
        producto: Producto,
        caja: &mut CajaRegistradora,
        pago: coin::Coin<sui::SUI>,
        ctx: &mut tx_context::TxContext
    ) {
        // Se asegura de que el pago sea exacto.
        assert!(coin::value(&pago) == producto.precio, EPrecioIncorrecto);

        // Se une el pago al balance de la caja registradora.
        balance::join(&mut caja.fondos, coin::into_balance(pago));

        // Se transfiere el producto al comprador.
        transfer::public_transfer(producto, tx_context::sender(ctx));
    }

    /// ENTRY: Permite al admin retirar todas las ganancias de la caja.
    public entry fun retirar_fondos(
        _cap: &AdminCap,
        caja: &mut CajaRegistradora,
        ctx: &mut tx_context::TxContext
    ) {
        // Se extrae todo el balance de la caja.
        let ganancias: balance::Balance<sui::SUI> = balance::withdraw_all(&mut caja.fondos);

        // Se asegura de que había algo que retirar.
        assert!(balance::value(&ganancias) > 0, ECajaVacia);

        // Se convierte el balance en un objeto Coin y se transfiere al admin.
        transfer::public_transfer(coin::from_balance(ganancias, ctx), tx_context::sender(ctx));
    }
}