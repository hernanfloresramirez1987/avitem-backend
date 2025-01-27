DROP PROCEDURE IF EXISTS registrar_venta_y_descuento;
DELIMITER //

CREATE PROCEDURE registrar_venta_y_descuento(
 IN p_fechaVenta DATE,
 IN p_total DECIMAL(10,2),
 IN p_id_cliente BIGINT(20),
 IN p_id_empleado BIGINT(20),
 IN p_confactura INT,
 IN p_tokenSIN VARCHAR(255),
 IN p_detalle JSON,
 OUT p_resultado VARCHAR(100),
 OUT p_status INT)

BEGIN  -- Añadida etiqueta al bloque principal
  DECLARE v_id_venta BIGINT(20);
  DECLARE i INT DEFAULT 0;
  DECLARE v_cantidad INT;
  DECLARE v_precioUnitario DECIMAL(10,2);
  DECLARE v_id_producto INT;
  DECLARE v_stockDisponible INT;
  DECLARE v_productExists INT ;
  DECLARE v_stocktotal INT;
  DECLARE v_cantidadStock INT;
  DECLARE v_id_almacen INT;

  -- Manejador de excepciones
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
      ROLLBACK;
      SET p_resultado = 'Error: No se pudo completar la venta. Transacción revertida.';
      SET p_status = 400;
  END;

  START TRANSACTION;

    -- Validar cantidades de los productos en el JSON detalle
    WHILE JSON_LENGTH(p_detalle) > i DO
        SET v_cantidad = JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].cantidad'));
        SET v_id_producto = JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].id_producto'));
        SET v_precioUnitario = JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].precioUnitario'));

        -- Obtener la cantidad disponible (cantidadStock)
        SELECT cantidadStock
        INTO v_stockDisponible
        FROM producto WHERE id = v_id_producto;

        -- Verificar si la cantidad solicitada supera el stock disponible
        IF v_cantidad > v_stockDisponible THEN
            ROLLBACK;
            SET p_resultado = CONCAT('Error: Stock insuficiente para el producto con ID: ', v_id_producto);
            SET p_status = 400;
        END IF;

        SET i = i + 1;
    END WHILE;

    -- Insertar la venta en la tabla 'venta'
    INSERT INTO venta (fechaVenta, total, tokenSIM, id_cliente, id_empleado, confactura)
    VALUES (p_fechaVenta, p_total, p_tokenSIN, p_id_cliente, p_id_empleado, p_confactura);
  
    -- Verificar si la inserción fue exitosa
    IF ROW_COUNT() = 0 THEN
        SELECT 'Error en INSERT venta', v_id_producto, v_cantidad, v_precioUnitario;
        ROLLBACK;
    END IF;

    -- Obtener el ID de la venta recién insertada
    SET v_id_venta = LAST_INSERT_ID();

    -- Reiniciar índice para procesar los detalles
    SET i = 0;
    -- Procesar cada producto en el JSON detalle
    WHILE i < JSON_LENGTH(p_detalle) DO
            SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].cantidad')));
            SET v_precioUnitario = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].precioUnitario')));
            SET v_id_producto = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].id_producto')));
            SET v_id_almacen = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].id_almacen')));

           -- Validar que los campos necesarios sean positivos
           IF v_cantidad <= 0 OR v_precioUnitario <= 0 THEN
               SET p_resultado = CONCAT('Error: Cantidad o Precio unitario deben ser mayores a cero (detalle index ', i, ').');
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

           UPDATE producto
           SET cantidadStock = v_cantidadStock - v_cantidad
           WHERE id = v_id_producto;


            -- Insertar en detalle_venta
            INSERT INTO detalle_venta (cantidad, precioUnitario, id_venta, id_producto)
            VALUES (v_cantidad, v_precioUnitario, v_id_venta, v_id_producto);

            -- SELECT cantidadStock INTO v_stocktotal FROM producto
            -- WHERE id = v_id_producto;

            -- SET v_stocktotal = v_stocktotal - v_cantidad;

            INSERT INTO inventario (cantidadStock, fechaInventario, id_producto, id_almacen, cantidadReservada, cantidadDespachada, fechaIngreso, fechaSalida, idLote)
            VALUES ((v_cantidadStock - v_cantidad), CURRENT_DATE, v_id_producto, v_id_almacen, v_cantidad, v_cantidad, CURRENT_DATE, CURRENT_DATE, 0);
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
        SET p_resultado = 'Registro de ventas completado exitosamente';
        SET p_status = 201;
        COMMIT;
    ELSE
        SET p_resultado = 'Error: No se pudo completar el registro de la venta o los detalles';
        SET p_status = 400;
        ROLLBACK;
    END IF;
END //

DELIMITER ;

CALL registrar_venta_y_descuento(
  '2025-01-12',
  777,
  2,
  5,
  1,
  '@#$%^&*token',
  '[
    {"cantidad":4,"precioUnitario":35,"id_producto":25},
    {"cantidad":6,"precioUnitario":90,"id_producto":24}
  ]',
  @resultado,
  @status
);
SELECT @resultado AS Resultado, @status AS Status;