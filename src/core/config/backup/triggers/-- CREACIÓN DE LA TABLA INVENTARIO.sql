-- CREACIÓN DE LA TABLA INVENTARIO
CREATE TABLE inventario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    id_lote INT DEFAULT NULL,
    fechamovimiento DATE NOT NULL,
    tipo_movimiento ENUM('ingreso', 'salida') NOT NULL,
    ingreso INT DEFAULT 0,
    cant_disponible_x_lote INT DEFAULT 0,
    salida INT DEFAULT 0,
    cant_salida INT DEFAULT 0,
    cant_faltante_salida INT DEFAULT 0,
    id_lote_venta INT DEFAULT NULL,
    stock_actual INT DEFAULT 0
);

-- TRIGGER PARA ACTUALIZAR INVENTARIO AUTOMÁTICAMENTE
DELIMITER $$

CREATE TRIGGER actualizar_inventario
AFTER INSERT ON inventario
FOR EACH ROW
BEGIN
    -- Variables locales para manejo de operaciones
    DECLARE restante_salida INT;       -- Cantidad restante por cubrir en una salida
    DECLARE lote_actual INT;           -- Lote procesado actualmente
    DECLARE cantidad_disponible INT;  -- Cantidad disponible en el lote actual
    DECLARE total_stock INT;           -- Stock total disponible en inventario
    
    IF NEW.tipo_movimiento = 'ingreso' THEN
        -- Para ingreso: actualizar cantidades disponibles y stock total
        SET NEW.cant_disponible_x_lote = NEW.ingreso;
        
        -- Actualizar el stock acumulativo
        SET total_stock = (SELECT IFNULL(SUM(cant_disponible_x_lote), 0) FROM inventario WHERE tipo_movimiento = 'ingreso') + NEW.ingreso;
        SET NEW.stock_actual = total_stock;

    ELSEIF NEW.tipo_movimiento = 'salida' THEN
        -- Para salida: distribuir la cantidad solicitada en los lotes disponibles
        SET restante_salida = NEW.cant_salida;

        -- Iterar sobre lotes disponibles para cubrir la salida
        WHILE restante_salida > 0 DO
            -- Seleccionar el próximo lote con productos disponibles
            SELECT id_lote, cant_disponible_x_lote
            INTO lote_actual, cantidad_disponible
            FROM inventario
            WHERE id_producto = NEW.id_producto
              AND cant_disponible_x_lote > 0
            ORDER BY fechamovimiento ASC
            LIMIT 1;

            -- Salir si no hay más lotes disponibles
            IF lote_actual IS NULL THEN
                SET NEW.cant_faltante_salida = restante_salida;
                LEAVE;
            END IF;

            -- Actualizar cantidades en el lote seleccionado
            IF restante_salida <= cantidad_disponible THEN
                SET cantidad_disponible = cantidad_disponible - restante_salida;
                SET NEW.cant_salida = restante_salida;
                SET restante_salida = 0;
            ELSE
                SET restante_salida = restante_salida - cantidad_disponible;
                SET cantidad_disponible = 0;
            END IF;

            -- Actualizar la base de datos para el lote procesado
            UPDATE inventario
            SET cant_disponible_x_lote = cantidad_disponible
            WHERE id_lote = lote_actual;

            -- Asignar el lote de venta actual
            SET NEW.id_lote_venta = lote_actual;
        END WHILE;

        -- Calcular y actualizar el stock acumulativo tras la salida
        SET total_stock = (SELECT IFNULL(SUM(cant_disponible_x_lote), 0) FROM inventario WHERE tipo_movimiento = 'ingreso') - NEW.cant_salida;
        SET NEW.stock_actual = total_stock;
    END IF;
END$$

DELIMITER ;