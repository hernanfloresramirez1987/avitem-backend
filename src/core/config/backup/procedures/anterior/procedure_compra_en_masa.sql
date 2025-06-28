DROP PROCEDURE IF EXISTS registro_compra2;
DELIMITER //

CREATE PROCEDURE registro_compra2 (
    IN p_fechaCompra DATE,
    IN p_totalCompra DECIMAL(10, 2),
    IN p_idProveedor BIGINT,
    IN detalles JSON,  -- Datos del detalle de la compra (producto, cantidad, precio)
    OUT p_idCompra INT,
    OUT p_resultado VARCHAR(100),
    OUT p_status INT
)
BEGIN
    DECLARE v_idCompra INT;
    DECLARE v_idProducto BIGINT;
    DECLARE v_cantidad INT;
    DECLARE v_precioUnitario DECIMAL(10, 2);
    DECLARE v_codigoLote VARCHAR(100);
    DECLARE v_contador INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'Error: No se pudo completar el registro. Transacción revertida.';
        SET p_status = 400;
    END;

    START TRANSACTION;

    -- Insertar en la tabla de compras
    INSERT INTO compra (fechaCompra, total, id_proveedor)
    VALUES (p_fechaCompra, p_totalCompra, p_idProveedor);

    SET v_idCompra = LAST_INSERT_ID();  -- Obtener el ID de la compra recién insertada

    -- Recorrer el array de detalles de compra en formato JSON
    WHILE v_contador < JSON_LENGTH(detalles) DO
        SET v_idProducto = JSON_UNQUOTE(JSON_EXTRACT(detalles, CONCAT('$[', v_contador, '].idProducto')));
        SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(detalles, CONCAT('$[', v_contador, '].cantidad')));
        SET v_precioUnitario = JSON_UNQUOTE(JSON_EXTRACT(detalles, CONCAT('$[', v_contador, '].precioUnitario')));

        -- Insertar el detalle de la compra
        INSERT INTO detalle_compra (id_compra, id_producto, cantidad, precioUnitario)
        VALUES (v_idCompra, v_idProducto, v_cantidad, v_precioUnitario);

        -- Crear el código de lote y registrar el lote de productos
        SET v_codigoLote = CONCAT('L', NOW(), '-', v_idCompra, '-', v_contador);

        INSERT INTO lote_producto (id_producto, codigoLote, cantidad, fechaIngreso)
        VALUES (v_idProducto, v_codigoLote, v_cantidad, p_fechaCompra);

        SET v_contador = v_contador + 1;
    END WHILE;

    -- Si se realizó la inserción con éxito, confirmamos la transacción
    IF ROW_COUNT() > 0 THEN
        SET p_resultado = 'Compra registrada exitosamente.';
        SET p_status = 201;
        COMMIT;
    ELSE
        SET p_resultado = 'Error: No se pudo registrar la compra.';
        SET p_status = 400;
        ROLLBACK;
    END IF;

END //

DELIMITER ;