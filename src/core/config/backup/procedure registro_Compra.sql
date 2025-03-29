DROP PROCEDURE IF EXISTS registro_Compra_y_Detalle_mas_Lote_update_Product;
DELIMITER $$

CREATE PROCEDURE registro_Compra_y_Detalle_mas_Lote_update_Product(
IN p_fechaCompra DATE,
IN p_total DECIMAL(10,2),
IN p_id_proveedor BIGINT(20) UNSIGNED,
IN p_detalle JSON,
IN p_fechaVencimiento DATE, -- Fecha de vencimiento del nuevo lote
OUT p_resultado VARCHAR(100),
OUT p_status INT
)
BEGIN
DECLARE v_id_compra BIGINT(20) UNSIGNED;
DECLARE i INT DEFAULT 0;
DECLARE v_cantidad INT;
DECLARE v_precioUnitario DECIMAL(10,2);
DECLARE v_precioVenta DECIMAL(10,2);
DECLARE v_id_producto INT;
DECLARE v_numLote INT;
DECLARE v_cantidadStock INT;
DECLARE v_id_almacen INT;
DECLARE v_stocktotal INT;
DECLARE v_id_lote INT;

DECLARE v_validProveedor INT;
DECLARE v_productExists INT;
DECLARE v_error BOOLEAN DEFAULT FALSE;

-- Manejador de excepciones
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
   ROLLBACK;
   SET p_resultado = 'Error: No se pudo completar el registro. Transacción revertida.';
   SET p_status = 400;
END;
   -- Validar que el total de la compra sea positivo
   IF p_total <= 0 THEN
       SET p_resultado = 'Error: El total de la compra debe ser mayor a cero.';
       SET p_status = 400;
       SET v_error = TRUE;
   END IF;
   -- Validar que el proveedor exista
   IF NOT v_error THEN
       SELECT COUNT(*) INTO v_validProveedor FROM proveedor WHERE id = p_id_proveedor;
       IF v_validProveedor = 0 THEN
           SET p_resultado = 'Error: El proveedor especificado no existe.';
           SET p_status = 404;
           SET v_error = TRUE;
       END IF;
   END IF;
   -- Validar que la fecha de vencimiento sea futura
   IF NOT v_error AND p_fechaVencimiento <= CURDATE() THEN
       SET p_resultado = 'Error: La fecha de vencimiento debe ser posterior a la fecha actual.';
       SET p_status = 400;
       SET v_error = TRUE;
   END IF;
   IF v_error THEN
       ROLLBACK;
   END IF;

   -- Iniciar la transacción
   START TRANSACTION;

       -- Insertar la compra
       INSERT INTO compra (fechaCompra, total, id_proveedor)
       VALUES (p_fechaCompra, p_total, p_id_proveedor);
       -- Obtener el ID de la compra recién insertada
       SET v_id_compra = LAST_INSERT_ID();
       -- Obtener el último número de lote e incrementarlo
       SET v_numLote = COALESCE((SELECT MAX(CAST(numLote AS SIGNED)) FROM lote_producto), 0) + 1;
       -- Iterar sobre los detalles proporcionados (usando un JSON de detalles)
       WHILE i < JSON_LENGTH(p_detalle) DO
            SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].cantidad')));
            SET v_precioUnitario = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].precioUnitario')));
            SET v_precioVenta = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].precioVenta')));
            SET v_id_producto = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].id_producto')));
            SET v_id_almacen = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].id_almacen')));
           -- Validar que los campos necesarios sean positivos
           IF v_cantidad <= 0 OR v_precioUnitario <= 0 OR v_precioVenta <= 0 THEN
               SET p_resultado = CONCAT('Error: Cantidad, precio unitario y precio de venta deben ser mayores a cero (detalle index ', i, ').');
               SET p_status = 400;
               ROLLBACK;
           END IF;
           -- Validar que el producto exista
           SELECT COUNT(*) INTO v_productExists FROM producto WHERE id = v_id_producto;
           IF v_productExists = 0 THEN
               SET p_resultado = CONCAT('Error: El producto con ID ', v_id_producto, ' no existe (detalle index ', i, ').');
               SET p_status = 404;
               ROLLBACK;
           END IF;
           -- Seleccionar el stock actual del producto
           SELECT cantidadStock INTO v_cantidadStock
           FROM producto
           WHERE id = v_id_producto;
           -- Insertar el detalle de la compra en 'detalle_compra'
           INSERT INTO detalle_compra (cantidad, precioUnitario, id_compra, id_producto)
           VALUES (v_cantidad, v_precioUnitario, v_id_compra, v_id_producto);
           -- Verificar si la inserción fue exitosa
           IF ROW_COUNT() = 0 THEN
               SELECT 'Error en INSERT detalle_compra', v_id_producto, v_cantidad, v_precioUnitario;
               ROLLBACK;
           END IF;
           -- Insertar el lote en 'lote_producto' linea 108 - 115
           INSERT INTO lote_producto (numLote, fechaReabastecimiento, cantidadReabastecida, fechaVencimiento, precioCompra, precioVenta, id_producto)
           VALUES (v_numLote, p_fechaCompra, v_cantidad, p_fechaVencimiento, v_precioUnitario, v_precioVenta, v_id_producto);
            -- Verificar si la inserción fue exitosa
           IF ROW_COUNT() = 0 THEN
               SELECT 'Error en INSERT lote_producto', v_numLote, p_fechaCompra, v_cantidad, p_fechaVencimiento, v_precioUnitario, v_precioVenta, v_id_producto;
               ROLLBACK;
           END IF;           

           SET v_id_lote = LAST_INSERT_ID();

           UPDATE producto
           SET cantidadStock = v_cantidadStock + v_cantidad
           WHERE id = v_id_producto;

            SELECT cantidadStock INTO v_stocktotal FROM producto
            WHERE id = v_id_producto;

            INSERT INTO inventario (cantidadStock, fechaInventario, id_producto, id_almacen, cantidadReservada, cantidadDespachada, fechaIngreso, fechaSalida, idLote)
            VALUES (v_stocktotal, CURRENT_DATE, v_id_producto, v_id_almacen, 0, 0, CURRENT_DATE, CURRENT_DATE, v_id_lote);
            -- Verificar si la inserción fue exitosa
            IF ROW_COUNT() = 0 THEN
               SELECT 'Error en INSERT inventory', v_numLote, v_cantidadStock, p_fechaCompra, v_id_producto, v_id_almacen, v_cantidad, v_precioUnitario, v_precioVenta, v_id_producto;
               ROLLBACK;
            END IF;
           -- Incrementar el índice para el siguiente elemento del JSON
           SET i = i + 1;
       END WHILE;
    -- Verificar si las inserciones fueron exitosas
    IF ROW_COUNT() > 0 THEN
        SET p_resultado = 'Registro de compras completado exitosamente';
        SET p_status = 201;
        COMMIT;
    ELSE
        SET p_resultado = 'Error: No se pudo completar el registro de la compra o los detalles';
        SET p_status = 400;
        ROLLBACK;
    END IF;
END $$

DELIMITER ;


CALL registro_Compra_y_Detalle_mas_Lote_update_Product(
  '2025-01-12',
  3215,
  6,  '[{"cantidad":79,"precioUnitario":35,"precioVenta":60,"id_producto":22, "id_almacen": 1},{"cantidad":5,"precioUnitario":90,"precioVenta":150,"id_producto":20, "id_almacen": 1}]',
  '2025-01-12',
  @resultado,
  @status
);
SELECT @resultado AS Resultado, @status AS Status;

CALL registro_Compra_y_Detalle_mas_Lote_update_Product(
 '2025-01-12',
 777,
 6,  
'[
{"cantidad":10,"precioUnitario":35,"precioVenta":60,"id_producto":24, "id_almacen": 1},
{"cantidad":5,"precioUnitario":90,"precioVenta":150,"id_producto":25, "id_almacen": 1}
]',
 '2025-01-12',
 @resultado,
 @status
);
SELECT @resultado AS Resultado, @status AS Status;